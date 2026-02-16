import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct GrowthMeasurement: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var babyId: String
    var date: Date
    var weight: Double? // in lbs
    var height: Double? // in inches
    var headCircumference: Double? // in inches
    var notes: String?
    
    init(id: String? = nil,
         ownerId: String,
         babyId: String,
         date: Date = Date(),
         weight: Double? = nil,
         height: Double? = nil,
         headCircumference: Double? = nil,
         notes: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.babyId = babyId
        self.date = date
        self.weight = weight
        self.height = height
        self.headCircumference = headCircumference
        self.notes = notes
    }
}
