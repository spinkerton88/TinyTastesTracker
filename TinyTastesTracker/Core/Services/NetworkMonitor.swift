//
//  NetworkMonitor.swift
//  TinyTastesTracker
//
//  Real-time network connectivity monitoring
//

import Foundation
import Network
import Observation

/// Connection type for network monitoring
enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

/// Monitors network connectivity in real-time
@Observable
class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.tinytastes.networkmonitor")
    
    var isConnected: Bool = true
    var connectionType: ConnectionType = .wifi
    var isExpensive: Bool = false // Cellular or metered WiFi
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.connectionType = self?.determineConnectionType(path) ?? .unknown
                
                // Notify when connection is restored
                if path.status == .satisfied {
                    NotificationCenter.default.post(name: .networkRestored, object: nil)
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    /// Check if network is available for operations
    var canPerformOperations: Bool {
        return isConnected
    }
    
    /// Check if we should warn about expensive connection
    var shouldWarnAboutExpensiveConnection: Bool {
        return isExpensive && connectionType == .cellular
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkRestored = Notification.Name("networkRestored")
}
