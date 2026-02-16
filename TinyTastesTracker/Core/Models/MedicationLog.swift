import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct MedicationLog: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var timestamp: Date
    var medicineName: String
    var babyWeight: Double // in lbs
    var dosage: String
    var safetyInfo: String? // AI-generated safety information
    var notes: String?
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         timestamp: Date = Date(),
         medicineName: String,
         babyWeight: Double,
         dosage: String,
         safetyInfo: String? = nil,
         notes: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.timestamp = timestamp
        self.medicineName = medicineName
        self.babyWeight = babyWeight
        self.dosage = dosage
        self.safetyInfo = safetyInfo
        self.notes = notes
    }
}
