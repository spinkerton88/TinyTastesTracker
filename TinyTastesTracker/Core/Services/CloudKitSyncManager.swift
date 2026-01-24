//
//  CloudKitSyncManager.swift
//  TinyTastesTracker
//
//  Service for monitoring iCloud sync status and account availability.
//  Note: Actual data synchronization is handled automatically by SwiftData/CoreData.
//

import Foundation
import CloudKit
import SwiftData
import Network

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing // Note: SwiftData doesn't easily expose "syncing" state directly without Core Data observing
    case active
    case error(String)
    case accountNotAvailable
    
    var displayText: String {
        switch self {
        case .idle:
            return "Waiting for changes"
        case .syncing:
            return "Syncing..."
        case .active:
            return "CloudKit Active"
        case .error(let message):
            return "Sync Error: \(message)"
        case .accountNotAvailable:
            return "iCloud Not Signed In"
        }
    }
    
    var iconName: String {
        switch self {
        case .idle: return "checkmark.icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .active: return "icloud.fill"
        case .error: return "exclamationmark.icloud"
        case .accountNotAvailable: return "icloud.slash"
        }
    }
}

// MARK: - CloudKit Sync Manager

@MainActor
class CloudKitSyncManager: ObservableObject {
    
    // MARK: - Properties

    static let shared = CloudKitSyncManager()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var isAccountAvailable: Bool = false
    @Published var lastSyncDate: Date?
    
    private var container: CKContainer?
    private let monitor = NWPathMonitor()
    
    // MARK: - Initialization

    init() {
        // Initialize monitor
        startNetworkMonitoring()
        
        // Initial account check (safe even if CloudKit disabled)
        Task {
            await checkAccountStatus()
        }
        
        // Only observe CloudKit changes if it might be available
        // Note: This won't crash even if CloudKit is disabled
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accountChanged),
            name: .CKAccountChanged,
            object: nil
        )
    }
    
    deinit {
        monitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupContainer() {
        // Only try to set up container if not already done
        guard container == nil else { return }
        
        // Check if CloudKit entitlements are configured
        // If the entitlements file has empty arrays, CloudKit is disabled
        guard isCloudKitEntitled() else {
            print("⚠️ CloudKit entitlements not configured")
            self.syncStatus = .error("CloudKit not configured")
            self.isAccountAvailable = false
            return
        }
        
        // Create container - this should be safe now
        let containerID = "iCloud.tinytastestracker"
        self.container = CKContainer(identifier: containerID)
    }
    
    /// Check if CloudKit is properly entitled in the app
    private func isCloudKitEntitled() -> Bool {
        // Check if iCloud container identifiers are configured
        guard let entitlements = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.icloud-container-identifiers") as? [String],
              !entitlements.isEmpty else {
            return false
        }
        
        // Check if CloudKit service is enabled
        guard let services = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.icloud-services") as? [String],
              services.contains("CloudKit") else {
            return false
        }
        
        return true
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        if container == nil {
            setupContainer()
        }
        
        guard let container = container else {
            self.syncStatus = .error("CloudKit not configured")
            return
        }

        do {
            let accountStatus = try await container.accountStatus()
            
            switch accountStatus {
            case .available:
                self.isAccountAvailable = true
                self.syncStatus = .active
            case .couldNotDetermine, .restricted, .noAccount, .temporarilyUnavailable:
                self.isAccountAvailable = false
                self.syncStatus = .accountNotAvailable
            @unknown default:
                self.isAccountAvailable = false
                self.syncStatus = .error("Unknown account status")
            }
        } catch {
            self.isAccountAvailable = false
            self.syncStatus = .error(error.localizedDescription)
        }
    }
    
    @objc private func accountChanged() {
        Task {
            await checkAccountStatus()
        }
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if path.status == .satisfied {
                    // Back online, re-check account
                    if self.syncStatus == .error("No Internet Connection") {
                        await self.checkAccountStatus()
                    }
                } else {
                    self.syncStatus = .error("No Internet Connection")
                }
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    // MARK: - Diagnostics
    
    /// Forces a re-check of account status.
    /// Note: Cannot force SwiftData sync explicitly via this API, but checking account usually triggers system checks.
    func refreshStatus() async {
        await checkAccountStatus()
    }
}

