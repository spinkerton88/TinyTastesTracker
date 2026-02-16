import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum NursingSide: String, Codable {
    case left
    case right
}

struct NursingLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var timestamp: Date
    var duration: TimeInterval // in seconds
    var side: NursingSide
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         timestamp: Date = Date(),
         duration: TimeInterval,
         side: NursingSide) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.timestamp = timestamp
        self.duration = duration
        self.side = side
    }
}
