//
//  SyncStatusManager.swift
//  TinyTastesTracker
//
//  Tracks sync status for all Firebase operations
//

import Foundation
import Observation

/// Represents a pending operation waiting to sync
struct PendingOperation: Identifiable, Codable {
    let id: String
    let type: OperationType
    let timestamp: Date
    var retryCount: Int
    let priority: OperationPriority
    
    enum OperationType: String, Codable {
        case nursingLog
        case sleepLog
        case diaperLog
        case bottleFeedLog
        case pumpingLog
        case medicationLog
        case growthMeasurement
        case mealLog
        case foodLog
        case recipe
        case customFood
        case shoppingListItem
        case mealPlanEntry
        case savedMedication
    }
    
    enum OperationPriority: Int, Codable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
    }
}

/// Represents a sync error
struct SyncError: Identifiable {
    let id: String
    let operation: PendingOperation
    let error: FirebaseError
    let timestamp: Date
}

/// Manages sync status across the app
@Observable
class SyncStatusManager {
    static let shared = SyncStatusManager()
    
    var pendingOperations: [PendingOperation] = []
    var isSyncing: Bool = false
    var lastSyncTime: Date?
    var syncErrors: [SyncError] = []
    
    private let maxRetries = 3
    
    private init() {
        loadPendingOperations()
        setupNetworkObserver()
    }
    
    // MARK: - Operation Management
    
    func addPendingOperation(_ operation: PendingOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    func removePendingOperation(_ id: String) {
        pendingOperations.removeAll { $0.id == id }
        savePendingOperations()
    }
    
    func markOperationFailed(_ operation: PendingOperation, error: FirebaseError) {
        var updatedOperation = operation
        updatedOperation.retryCount += 1
        
        if updatedOperation.retryCount >= maxRetries {
            // Move to errors list
            let syncError = SyncError(
                id: UUID().uuidString,
                operation: operation,
                error: error,
                timestamp: Date()
            )
            syncErrors.append(syncError)
            removePendingOperation(operation.id)
        } else {
            // Update retry count
            if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
                pendingOperations[index] = updatedOperation
                savePendingOperations()
            }
        }
    }
    
    func clearSyncError(_ id: String) {
        syncErrors.removeAll { $0.id == id }
    }
    
    func clearAllSyncErrors() {
        syncErrors.removeAll()
    }
    
    // MARK: - Retry Logic
    
    func retryFailedOperations() async {
        guard !isSyncing else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        // Sort by priority (highest first)
        let sortedOperations = pendingOperations.sorted { $0.priority.rawValue > $1.priority.rawValue }
        
        for operation in sortedOperations {
            // Retry logic will be handled by OfflineQueue
            // This just triggers the retry
            NotificationCenter.default.post(
                name: .retryPendingOperation,
                object: operation
            )
        }
        
        lastSyncTime = Date()
    }
    
    // MARK: - Persistence
    
    private func savePendingOperations() {
        if let encoded = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(encoded, forKey: "pendingOperations")
        }
    }
    
    private func loadPendingOperations() {
        if let data = UserDefaults.standard.data(forKey: "pendingOperations"),
           let decoded = try? JSONDecoder().decode([PendingOperation].self, from: data) {
            pendingOperations = decoded
        }
    }
    
    // MARK: - Network Observer
    
    private func setupNetworkObserver() {
        NotificationCenter.default.addObserver(
            forName: .networkRestored,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.retryFailedOperations()
            }
        }
    }
    
    // MARK: - Status Helpers
    
    var hasPendingOperations: Bool {
        !pendingOperations.isEmpty
    }
    
    var hasErrors: Bool {
        !syncErrors.isEmpty
    }
    
    var statusMessage: String {
        if !NetworkMonitor.shared.isConnected {
            return "Offline"
        } else if isSyncing {
            return "Syncing..."
        } else if hasPendingOperations {
            return "\(pendingOperations.count) pending"
        } else if hasErrors {
            return "\(syncErrors.count) errors"
        } else if let lastSync = lastSyncTime {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "All changes saved"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let retryPendingOperation = Notification.Name("retryPendingOperation")
}
