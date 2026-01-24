//
//  CommonAllergens.swift
//  TinyTastesTracker
//
//  Common food allergens and intolerances for baby tracking
//

import Foundation

struct CommonAllergens {
    // MARK: - True Allergies (IgE-mediated, potentially life-threatening)
    
    /// FDA-recognized major food allergens that can cause severe immune reactions
    static let trueAllergies: [String] = [
        "Peanut",
        "Tree Nut",
        "Egg",
        "Dairy",
        "Fish",
        "Shellfish",
        "Sesame",
        "Soy",
        "Wheat"
    ]
    
    // MARK: - Intolerances & Sensitivities (Non-IgE, digestive/non-life-threatening)
    
    /// Food intolerances and sensitivities that cause discomfort but are not life-threatening
    static let intolerances: [String] = [
        "Lactose Intolerance",
        "Gluten Intolerance",
        "Corn Sensitivity",
        "Strawberry Sensitivity",
        "Tomato Sensitivity",
        "Citrus Sensitivity"
    ]
    
    // MARK: - Combined List
    
    /// All allergens and intolerances combined (for backward compatibility)
    static let all: [String] = trueAllergies + intolerances
    
    // MARK: - Categorization
    
    enum AllergenCategory {
        case trueAllergy
        case intolerance
    }
    
    /// Determine if an allergen is a true allergy or intolerance
    static func category(for allergen: String) -> AllergenCategory {
        if trueAllergies.contains(where: { $0.localizedCaseInsensitiveCompare(allergen) == .orderedSame }) {
            return .trueAllergy
        }
        return .intolerance
    }
    
    /// Check if an allergen is a true allergy (potentially life-threatening)
    static func isTrueAllergy(_ allergen: String) -> Bool {
        return category(for: allergen) == .trueAllergy
    }
    
    // MARK: - Icons
    
    static func icon(for allergen: String) -> String {
        switch allergen.lowercased() {
        case "dairy": return "🥛"
        case "egg": return "🥚"
        case "peanut": return "🥜"
        case "tree nut": return "🌰"
        case "soy": return "🫘"
        case "wheat": return "🌾"
        case "fish": return "🐟"
        case "shellfish": return "🦐"
        case "sesame": return "🫘"
        case "lactose intolerance": return "🥛"
        case "gluten intolerance": return "🌾"
        case "corn sensitivity": return "🌽"
        case "strawberry sensitivity": return "🍓"
        case "tomato sensitivity": return "🍅"
        case "citrus sensitivity": return "🍊"
        default: return "⚠️"
        }
    }
}
