import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum DiaperType: String, Codable {
    case wet
    case dirty
    case both
}

struct DiaperLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var timestamp: Date
    var type: DiaperType
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         timestamp: Date = Date(),
         type: DiaperType) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.timestamp = timestamp
        self.type = type
    }
}
