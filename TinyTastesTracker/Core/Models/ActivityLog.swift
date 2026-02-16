import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ActivityLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var timestamp: Date
    var activityType: String // "play", "mood", "milestone", "other"
    var activityDescription: String
    var notes: String?
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         timestamp: Date,
         activityType: String,
         description: String,
         notes: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.timestamp = timestamp
        self.activityType = activityType
        self.activityDescription = description
        self.notes = notes
    }
}
