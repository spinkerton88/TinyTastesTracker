import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PumpingLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var timestamp: Date
    var leftBreastOz: Double
    var rightBreastOz: Double
    var notes: String?
    
    var totalYield: Double {
        leftBreastOz + rightBreastOz
    }
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         timestamp: Date = Date(),
         leftBreastOz: Double,
         rightBreastOz: Double,
         notes: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.timestamp = timestamp
        self.leftBreastOz = leftBreastOz
        self.rightBreastOz = rightBreastOz
        self.notes = notes
    }
}
