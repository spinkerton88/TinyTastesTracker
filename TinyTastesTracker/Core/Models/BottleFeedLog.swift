import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum FeedingType: String, Codable {
    case breastMilk
    case formula
    case mixed
}

struct BottleFeedLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var timestamp: Date
    var amount: Double // in oz
    var feedType: FeedingType
    var notes: String?
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         timestamp: Date = Date(),
         amount: Double,
         feedType: FeedingType,
         notes: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.timestamp = timestamp
        self.amount = amount
        self.feedType = feedType
        self.notes = notes
    }
}
