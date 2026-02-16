import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ParentProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var name: String?
    var joinedDate: Date
    var icloudStatus: String? // Keeping for legacy/migration context if needed, otherwise could be removed
    
    init(id: String? = nil,
         ownerId: String,
         name: String? = nil,
         joinedDate: Date = Date(),
         icloudStatus: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.joinedDate = joinedDate
        self.icloudStatus = icloudStatus
    }
}
