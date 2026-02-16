//
//  SavedMedication.swift
//  TinyTastesTracker
//
//  Frequently-used medications that can be quickly selected
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct SavedMedication: Identifiable, Codable {
    @DocumentID var id: String?
    var ownerId: String
    var medicineName: String
    var defaultDosage: String
    var notes: String?
    var createdAt: Date
    var lastUsed: Date
    var usageCount: Int

    init(id: String? = nil,
         ownerId: String,
         medicineName: String,
         defaultDosage: String,
         notes: String? = nil,
         createdAt: Date = Date(),
         lastUsed: Date = Date(),
         usageCount: Int = 0) {
        self.id = id
        self.ownerId = ownerId
        self.medicineName = medicineName
        self.defaultDosage = defaultDosage
        self.notes = notes
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.usageCount = usageCount
    }
}

/// Response from analyzing medication bottle image
struct MedicationBottleAnalysis: Codable {
    var medicineName: String
    var activeIngredient: String?
    var dosageForm: String? // "liquid", "tablet", "capsule", etc.
    var concentration: String? // e.g., "160mg/5ml"
    var recommendedDosage: String?
    var warnings: [String]
}
