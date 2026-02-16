import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class FirestoreService<T: Codable & Identifiable> where T.ID == String? {
    private let db = Firestore.firestore()
    private let collectionName: String
    
    // Listener recovery infrastructure
    private var activeListeners: [String: ListenerRegistration] = [:]
    private var listenerRetryCount: [String: Int] = [:]
    private var listenerCallbacks: [String: ([T]) -> Void] = [:]
    private var listenerUserIds: [String: String] = [:]
    private let maxListenerRetries = 5
    
    init(collectionName: String) {
        self.collectionName = collectionName
    }
    
    // MARK: - CREATE
    func add(_ item: T) async throws {
        try await db.collection(collectionName).addDocument(from: item)
    }

    func add(_ item: T, withId id: String) async throws {
        try await db.collection(collectionName).document(id).setData(from: item)
    }
    
    // MARK: - READ (Single)
    func getDocument(id: String) async throws -> T {
        let snapshot = try await db.collection(collectionName).document(id).getDocument()
        return try snapshot.data(as: T.self)
    }
    
    // MARK: - READ (Collection Stream) with Recovery
    func addListener(forUserId userId: String, completion: @escaping ([T]) -> Void) -> ListenerRegistration {
        let listenerId = UUID().uuidString
        
        // Store callback and userId for potential reconnection
        listenerCallbacks[listenerId] = completion
        listenerUserIds[listenerId] = userId
        
        let listener = setupListener(id: listenerId, userId: userId, completion: completion)
        activeListeners[listenerId] = listener
        
        return listener
    }
    
    private func setupListener(id: String, userId: String, completion: @escaping ([T]) -> Void) -> ListenerRegistration {
        return db.collection(collectionName)
            .whereField("ownerId", isEqualTo: userId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleListenerError(
                        id: id,
                        error: error,
                        userId: userId,
                        completion: completion
                    )
                } else if let documents = querySnapshot?.documents {
                    let items = documents.compactMap { try? $0.data(as: T.self) }
                    completion(items)
                    // Reset retry count on success
                    self.listenerRetryCount[id] = 0
                }
            }
    }
    
    private func handleListenerError(
        id: String,
        error: Error,
        userId: String,
        completion: @escaping ([T]) -> Void
    ) {
        let retryCount = listenerRetryCount[id] ?? 0
        
        guard retryCount < maxListenerRetries else {
            print("❌ Listener \(id) for \(collectionName) failed after \(maxListenerRetries) retries")
            // Error is already logged, calling code can handle presentation if needed
            // Clean up
            activeListeners.removeValue(forKey: id)
            listenerRetryCount.removeValue(forKey: id)
            listenerCallbacks.removeValue(forKey: id)
            listenerUserIds.removeValue(forKey: id)
            return
        }
        
        listenerRetryCount[id] = retryCount + 1
        
        // Exponential backoff with jitter
        let baseDelay = pow(2.0, Double(retryCount))
        let jitter = Double.random(in: 0...0.3) * baseDelay
        let delay = baseDelay + jitter
        
        print("⚠️ Listener \(id) for \(collectionName) error, retrying in \(String(format: "%.1f", delay))s (attempt \(retryCount + 1)/\(maxListenerRetries))")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            // Remove old listener
            self.activeListeners[id]?.remove()
            
            // Create new listener
            let newListener = self.setupListener(
                id: id,
                userId: userId,
                completion: completion
            )
            
            self.activeListeners[id] = newListener
        }
    }
    
    /// Remove a listener and clean up tracking
    func removeListener(id: String) {
        activeListeners[id]?.remove()
        activeListeners.removeValue(forKey: id)
        listenerRetryCount.removeValue(forKey: id)
        listenerCallbacks.removeValue(forKey: id)
        listenerUserIds.removeValue(forKey: id)
    }
    
    /// Reconnect all active listeners (useful after network restoration)
    func reconnectAllListeners() {
        print("🔄 Reconnecting \(activeListeners.count) listeners for \(collectionName)")
        
        for (id, _) in activeListeners {
            guard let userId = listenerUserIds[id],
                  let completion = listenerCallbacks[id] else {
                continue
            }
            
            // Remove old listener
            activeListeners[id]?.remove()
            
            // Reset retry count
            listenerRetryCount[id] = 0
            
            // Create new listener
            let newListener = setupListener(id: id, userId: userId, completion: completion)
            activeListeners[id] = newListener
        }
    }
    
    // MARK: - READ (Collection One-time)
    func fetch(forUserId userId: String) async throws -> [T] {
        let snapshot = try await db.collection(collectionName)
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }
    
    // MARK: - UPDATE
    func update(_ item: T) async throws {
        guard let id = item.id else { return }
        try await db.collection(collectionName).document(id).setData(from: item, merge: true)
    }
    
    // MARK: - DELETE
    func delete(id: String) async throws {
        try await db.collection(collectionName).document(id).delete()
    }
}
