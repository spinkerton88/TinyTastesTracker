import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum SleepQuality: String, Codable {
    case poor
    case fair
    case good
    case excellent
}

struct SleepLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var startTime: Date
    var endTime: Date
    var quality: SleepQuality
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         startTime: Date,
         endTime: Date,
         quality: SleepQuality = .fair) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
    }
}
