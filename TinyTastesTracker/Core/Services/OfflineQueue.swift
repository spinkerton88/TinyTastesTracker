//
//  OfflineQueue.swift
//  TinyTastesTracker
//
//  Persistent queue for offline operations
//

import Foundation
import FirebaseFirestore

/// Represents a queued operation with all necessary data
struct QueuedOperation: Identifiable, Codable {
    let id: String
    let type: PendingOperation.OperationType
    let timestamp: Date
    let payload: Data // JSON-encoded operation data
    var retryCount: Int
    let priority: PendingOperation.OperationPriority
    
    init(id: String = UUID().uuidString,
         type: PendingOperation.OperationType,
         timestamp: Date = Date(),
         payload: Data,
         retryCount: Int = 0,
         priority: PendingOperation.OperationPriority = .normal) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
        self.retryCount = retryCount
        self.priority = priority
    }
}

/// Manages offline operation queue with persistence
class OfflineQueue {
    static let shared = OfflineQueue()
    
    private let queueKey = "offlineOperationQueue"
    private let maxRetries = 3
    private var isProcessing = false
    
    private init() {
        setupNetworkObserver()
    }
    
    // MARK: - Queue Management
    
    func enqueue(_ operation: QueuedOperation) {
        var queue = loadQueue()
        queue.append(operation)
        saveQueue(queue)
        
        // Add to sync status manager
        let pendingOp = PendingOperation(
            id: operation.id,
            type: operation.type,
            timestamp: operation.timestamp,
            retryCount: operation.retryCount,
            priority: operation.priority
        )
        SyncStatusManager.shared.addPendingOperation(pendingOp)
        
        // Try to process immediately if online
        if NetworkMonitor.shared.isConnected {
            Task {
                await processQueue()
            }
        }
    }
    
    func dequeue(_ id: String) {
        var queue = loadQueue()
        queue.removeAll { $0.id == id }
        saveQueue(queue)
        SyncStatusManager.shared.removePendingOperation(id)
    }
    
    // MARK: - Queue Processing
    
    func processQueue() async {
        guard !isProcessing else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        var queue = loadQueue()
        
        // Sort by priority and timestamp
        queue.sort { op1, op2 in
            if op1.priority.rawValue != op2.priority.rawValue {
                return op1.priority.rawValue > op2.priority.rawValue
            }
            return op1.timestamp < op2.timestamp
        }
        
        for operation in queue {
            do {
                try await retryOperation(operation.id)
                dequeue(operation.id)
            } catch {
                // Handle retry failure
                var updatedOp = operation
                updatedOp.retryCount += 1
                
                if updatedOp.retryCount >= maxRetries {
                    // Max retries reached, move to errors
                    let pendingOp = PendingOperation(
                        id: operation.id,
                        type: operation.type,
                        timestamp: operation.timestamp,
                        retryCount: operation.retryCount,
                        priority: operation.priority
                    )
                    SyncStatusManager.shared.markOperationFailed(
                        pendingOp,
                        error: FirebaseError.from(error)
                    )
                    dequeue(operation.id)
                } else {
                    // Update retry count
                    if let index = queue.firstIndex(where: { $0.id == operation.id }) {
                        queue[index] = updatedOp
                        saveQueue(queue)
                    }
                }
            }
        }
    }
    
    func retryOperation(_ id: String) async throws {
        let queue = loadQueue()
        guard let operation = queue.first(where: { $0.id == id }) else {
            throw FirebaseError.documentNotFound
        }
        
        // Retry with exponential backoff
        let delay = calculateBackoff(retryCount: operation.retryCount)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // The actual retry logic will be handled by the specific managers
        // This just signals that the operation should be retried
        NotificationCenter.default.post(
            name: .retryQueuedOperation,
            object: operation
        )
    }
    
    // MARK: - Persistence
    
    private func loadQueue() -> [QueuedOperation] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([QueuedOperation].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveQueue(_ queue: [QueuedOperation]) {
        if let encoded = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(encoded, forKey: queueKey)
        }
    }
    
    // MARK: - Helpers
    
    private func calculateBackoff(retryCount: Int) -> TimeInterval {
        // Exponential backoff with jitter: 1s, 2s, 4s
        let baseDelay = pow(2.0, Double(retryCount))
        let jitter = Double.random(in: 0...0.5)
        return baseDelay + jitter
    }
    
    private func setupNetworkObserver() {
        NotificationCenter.default.addObserver(
            forName: .networkRestored,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.processQueue()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .retryPendingOperation,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let operation = notification.object as? PendingOperation {
                Task {
                    try? await self?.retryOperation(operation.id)
                }
            }
        }
    }
    
    // MARK: - Public Helpers
    
    var queuedOperationCount: Int {
        loadQueue().count
    }
    
    var hasQueuedOperations: Bool {
        !loadQueue().isEmpty
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let retryQueuedOperation = Notification.Name("retryQueuedOperation")
}
