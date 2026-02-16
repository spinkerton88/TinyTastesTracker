import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String? // Matches Auth UID
    var email: String
    var createdAt: Date
    var currentChildId: String?
    
    // Additional account-level settings can go here
    var isPremium: Bool = false
    
    init(id: String? = nil,
         email: String,
         createdAt: Date = Date(),
         currentChildId: String? = nil,
         isPremium: Bool = false) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.currentChildId = currentChildId
        self.isPremium = isPremium
    }
}
