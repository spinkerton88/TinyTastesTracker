import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

enum AppMode: String, Codable {
    case newborn = "NEWBORN"
    case explorer = "EXPLORER"
    case toddler = "TODDLER"
}

enum Gender: String, Codable {
    case boy
    case girl
    case other
}

struct ChildProfile: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var ownerId: String
    var name: String
    var birthDate: Date
    var gender: Gender
    var knownAllergies: [String]?
    var preferredMode: AppMode?
    var milestones: [Milestone]?
    var badges: [Badge]?
    var substitutedFoods: [String: String]?
    var sharedWith: [String]? // User IDs who have access to this profile

    // Computed Properties
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }

    var currentMode: AppMode {
        if let preferredMode = preferredMode {
            return preferredMode
        }

        switch ageInMonths {
        case 0..<6:
            return .newborn
        case 6..<12:
            return .explorer
        default:
            return .toddler
        }
    }

    /// Check if current authenticated user is the owner (for UI use)
    var isOwner: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }
        return ownerId == currentUserId
    }

    /// Check if a specific user is the owner (for programmatic use)
    func isOwner(userId: String) -> Bool {
        return ownerId == userId
    }

    var isShared: Bool {
        guard let sharedWith = sharedWith else { return false }
        return !sharedWith.isEmpty
    }

    init(id: String? = nil,
         ownerId: String,
         name: String,
         birthDate: Date,
         gender: Gender,
         knownAllergies: [String]? = nil,
         preferredMode: AppMode? = nil,
         milestones: [Milestone]? = nil,
         badges: [Badge]? = nil,
         substitutedFoods: [String: String]? = nil,
         sharedWith: [String]? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.knownAllergies = knownAllergies
        self.preferredMode = preferredMode
        self.milestones = milestones ?? Milestone.defaults()
        self.badges = badges ?? Badge.defaults()
        self.substitutedFoods = substitutedFoods ?? [:]
        self.sharedWith = sharedWith
    }
}
