//
//  Constants.swift
//  TinyTastesTracker
//

import SwiftUI

enum FoodCategory: String, Codable, CaseIterable {
    case vegetables, fruits, proteins, grains, dairy, snacks, beverages
}

enum FoodColor: String, Codable, CaseIterable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case purple = "Purple"
    case white = "White"
    case brown = "Brown"

    var displayColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .warningOrangeAccessible
        case .yellow: return .yellow
        case .green: return .green
        case .purple: return .purple
        case .white: return .gray.opacity(0.3)
        case .brown: return .brown
        }
    }
}

enum Nutrient: String, Codable, CaseIterable {
    case iron = "Iron"
    case calcium = "Calcium"
    case vitaminC = "Vitamin C"
    case omega3 = "Omega-3"
    case protein = "Protein"

    var color: Color {
        switch self {
        case .iron: return Color(red: 184/255, green: 115/255, blue: 51/255) // Rust
        case .calcium: return Color(red: 100/255, green: 116/255, blue: 139/255) // Slate gray (visible in light mode)
        case .vitaminC: return .warningOrangeAccessible
        case .omega3: return Color(red: 0/255, green: 119/255, blue: 182/255) // Ocean blue
        case .protein: return Color(red: 139/255, green: 69/255, blue: 19/255) // Brown
        }
    }

    var icon: String {
        switch self {
        case .iron: return "bolt.fill"
        case .calcium: return "shield.fill"
        case .vitaminC: return "sun.max.fill"
        case .omega3: return "drop.fill"
        case .protein: return "flame.fill"
        }
    }
}

enum AllergyRisk: String, Codable, CaseIterable {
    case low = "Low Risk"
    case medium = "Medium Risk"
    case high = "High Risk"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .warningOrangeAccessible
        case .high: return .red
        }
    }
}

struct FoodItem: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let category: FoodCategory
    let allergens: [String]
    let allergyRisk: AllergyRisk
    let nutritionHighlights: String
    let howToServe: String
    let chokeHazard: Bool
    let color: FoodColor
    let nutrients: [Nutrient]
    let imageFileName: String? // Deprecated: kept for backward compatibility
    let imageStoragePath: String? // Firebase Storage path for cloud sync

    init(id: String, name: String, emoji: String, category: FoodCategory,
         allergens: [String] = [], allergyRisk: AllergyRisk = .low,
         nutritionHighlights: String = "",
         howToServe: String = "", chokeHazard: Bool = false,
         color: FoodColor = .brown, nutrients: [Nutrient] = [],
         imageFileName: String? = nil, imageStoragePath: String? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.category = category
        self.allergens = allergens
        self.allergyRisk = allergyRisk
        self.nutritionHighlights = nutritionHighlights
        self.howToServe = howToServe
        self.chokeHazard = chokeHazard
        self.color = color
        self.nutrients = nutrients
        self.imageFileName = imageFileName
        self.imageStoragePath = imageStoragePath
    }
}

struct Constants {
    static let allFoods: [FoodItem] = [
        // VEGETABLES (25 foods)
        FoodItem(id: "AVOCADO", name: "Avocado", emoji: "🥑", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Healthy fats, folate, fiber, potassium",
                howToServe: "6+ months: Mashed or thin strips. 9+ months: Small cubes. Great first food!",
                chokeHazard: false,
                color: .green, nutrients: []),

        FoodItem(id: "SWEET_POTATO", name: "Sweet Potato", emoji: "🍠", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin A, fiber, potassium, vitamin C",
                howToServe: "6+ months: Pureed or mashed. 9+ months: Soft cubes or wedges",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC],
                imageFileName: "food_sweet_potato"),

        FoodItem(id: "CARROT", name: "Carrot", emoji: "🥕", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin A, beta-carotene, fiber",
                howToServe: "6+ months: Steamed soft until mashable. 9+ months: Soft sticks. Avoid raw until 12+ months",
                chokeHazard: true,
                color: .orange, nutrients: [.vitaminC],
                imageFileName: "food_carrot"),

        FoodItem(id: "BROCCOLI", name: "Broccoli", emoji: "🥦", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin K, iron, calcium, fiber",
                howToServe: "6+ months: Steamed soft florets, mashed. 9+ months: Soft small florets as finger food",
                chokeHazard: false,
                color: .green, nutrients: [.iron, .vitaminC, .calcium],
                imageFileName: "food_broccoli"),

        FoodItem(id: "BUTTERNUT_SQUASH", name: "Butternut Squash", emoji: "🎃", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin A, vitamin C, fiber, potassium",
                howToServe: "6+ months: Pureed or mashed. 9+ months: Soft roasted cubes",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC],
                imageFileName: "food_butternut_squash"),

        FoodItem(id: "PEAS", name: "Peas", emoji: "🫛", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, fiber, vitamin C, vitamin K",
                howToServe: "6+ months: Mashed or whole if soft. 9+ months: Whole, great for pincer grasp practice",
                chokeHazard: false,
                color: .green, nutrients: [.vitaminC, .protein],
                imageFileName: "food_peas"),

        FoodItem(id: "GREEN_BEANS", name: "Green Beans", emoji: "🫘", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin K, fiber, folate",
                howToServe: "6+ months: Steamed soft, cut into small pieces. 9+ months: Soft whole beans as finger food",
                chokeHazard: false,
                color: .green, nutrients: [.vitaminC],
                imageFileName: "food_green_beans"),

        FoodItem(id: "CAULIFLOWER", name: "Cauliflower", emoji: "🥬", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin K, fiber, folate",
                howToServe: "6+ months: Steamed soft and mashed. 9+ months: Soft roasted florets",
                chokeHazard: false,
                color: .white, nutrients: [.vitaminC],
                imageFileName: "food_cauliflower"),

        FoodItem(id: "ZUCCHINI", name: "Zucchini", emoji: "🥒", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, potassium, antioxidants",
                howToServe: "6+ months: Steamed soft strips or mashed. 9+ months: Roasted sticks or shredded",
                chokeHazard: false,
                color: .green, nutrients: [.vitaminC],
                imageFileName: "food_zucchini"),

        FoodItem(id: "CUCUMBER", name: "Cucumber", emoji: "🥒", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Hydration, vitamin K, antioxidants",
                howToServe: "6+ months: Peeled thick sticks (great for teething). 9+ months: Thin slices or sticks with skin",
                chokeHazard: false,
                color: .green, nutrients: [],
                imageFileName: "food_cucumber"),

        FoodItem(id: "BELL_PEPPER", name: "Bell Pepper", emoji: "🫑", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin A, antioxidants",
                howToServe: "6+ months: Roasted soft strips. 9+ months: Raw thin strips for teething, cooked pieces",
                chokeHazard: false,
                color: .red, nutrients: [.vitaminC],
                imageFileName: "food_bell_pepper"),

        FoodItem(id: "TOMATO", name: "Tomato", emoji: "🍅", category: .vegetables,
                allergens: [],
                allergyRisk: .medium,
                nutritionHighlights: "Vitamin C, lycopene, potassium",
                howToServe: "6+ months: Cooked and peeled, mashed or pureed. 9+ months: Quartered cherry tomatoes, chopped",
                chokeHazard: false,
                color: .red, nutrients: [.vitaminC],
                imageFileName: "food_tomato"),

        FoodItem(id: "SPINACH", name: "Spinach", emoji: "🥬", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Iron, calcium, vitamin K, folate",
                howToServe: "6+ months: Cooked and pureed or finely chopped. 9+ months: Mixed into foods, strips",
                chokeHazard: false,
                color: .green, nutrients: [.iron, .calcium],
                imageFileName: "food_spinach"),

        FoodItem(id: "KALE", name: "Kale", emoji: "🥬", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin K, vitamin C, calcium, iron",
                howToServe: "6+ months: Cooked soft and finely chopped. 9+ months: Baked kale chips or mixed into foods",
                chokeHazard: false,
                color: .green, nutrients: [.iron, .calcium, .vitaminC],
                imageFileName: "food_kale"),

        FoodItem(id: "BEET", name: "Beet", emoji: "🍠", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Folate, fiber, antioxidants, iron",
                howToServe: "6+ months: Roasted soft and mashed or pureed. 9+ months: Soft roasted cubes",
                chokeHazard: false,
                color: .red, nutrients: [.iron],
                imageFileName: "food_beet"),

        FoodItem(id: "ASPARAGUS", name: "Asparagus", emoji: "🌱", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Folate, vitamin K, fiber, vitamin C",
                howToServe: "6+ months: Steamed soft tips, mashed. 9+ months: Soft steamed spears as finger food",
                chokeHazard: false,
                color: .green, nutrients: [.vitaminC],
                imageFileName: "food_asparagus"),

        FoodItem(id: "CELERY", name: "Celery", emoji: "🌿", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin K, potassium, antioxidants",
                howToServe: "6+ months: Cooked soft and finely chopped. 9+ months: Remove strings, cut small. Avoid raw chunks",
                chokeHazard: true,
                color: .green, nutrients: [],
                imageFileName: "food_celery"),

        FoodItem(id: "EGGPLANT", name: "Eggplant", emoji: "🍆", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, antioxidants, potassium",
                howToServe: "6+ months: Roasted soft and mashed. 9+ months: Soft roasted strips or cubes",
                chokeHazard: false,
                color: .purple, nutrients: [],
                imageFileName: "food_eggplant"),

        FoodItem(id: "PARSNIP", name: "Parsnip", emoji: "🥕", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, vitamin C, folate, potassium",
                howToServe: "6+ months: Roasted soft and mashed. 9+ months: Soft roasted sticks",
                chokeHazard: false,
                color: .white, nutrients: [.vitaminC],
                imageFileName: "food_parsnip"),

        FoodItem(id: "TURNIP", name: "Turnip", emoji: "🥔", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, fiber, potassium",
                howToServe: "6+ months: Cooked soft and mashed. 9+ months: Soft roasted cubes",
                chokeHazard: false,
                color: .white, nutrients: [.vitaminC],
                imageFileName: "food_turnip"),

        FoodItem(id: "SNAP_PEAS", name: "Snap Peas", emoji: "🫛", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin K, fiber",
                howToServe: "6+ months: Remove pod, mash peas. 9+ months: Quartered pods steamed soft",
                chokeHazard: true,
                color: .green, nutrients: [.vitaminC],
                imageFileName: "food_snap_peas"),

        FoodItem(id: "EDAMAME", name: "Edamame", emoji: "🫛", category: .vegetables,
                allergens: ["soy"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, fiber, iron, calcium, folate",
                howToServe: "6+ months: Mashed beans (remove from pod). 9+ months: Whole beans, introduce early for allergy prevention",
                chokeHazard: false,
                color: .green, nutrients: [.protein, .iron, .calcium],
                imageFileName: "food_edamame"),

        FoodItem(id: "CORN", name: "Corn", emoji: "🌽", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, B vitamins, antioxidants",
                howToServe: "6+ months: Pureed or cut kernels off cob. 9+ months: Whole kernels, sliced from cob",
                chokeHazard: false,
                color: .yellow, nutrients: [],
                imageFileName: "food_corn"),

        FoodItem(id: "MUSHROOM", name: "Mushroom", emoji: "🍄", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "B vitamins, selenium, antioxidants",
                howToServe: "6+ months: Cooked soft and finely chopped. 9+ months: Quartered button mushrooms cooked soft",
                chokeHazard: false,
                color: .brown, nutrients: []),

        FoodItem(id: "ARTICHOKE", name: "Artichoke", emoji: "🥬", category: .vegetables,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, vitamin C, folate, antioxidants",
                howToServe: "6+ months: Cooked soft hearts, pureed or mashed. 9+ months: Soft chopped artichoke hearts",
                chokeHazard: false,
                color: .green, nutrients: [.vitaminC]),

        // FRUITS (25 foods)
        FoodItem(id: "BANANA", name: "Banana", emoji: "🍌", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Potassium, vitamin B6, vitamin C, fiber",
                howToServe: "6+ months: Mashed or thick strips (peel a bit for grip). 9+ months: Sliced rounds or half banana",
                chokeHazard: false,
                color: .yellow, nutrients: []),

        FoodItem(id: "APPLE", name: "Apple", emoji: "🍎", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, vitamin C, antioxidants",
                howToServe: "6+ months: Steamed soft slices or applesauce. 9+ months: Raw thin slices or grated. Avoid chunks",
                chokeHazard: true,
                color: .red, nutrients: [.vitaminC]),

        FoodItem(id: "PEAR", name: "Pear", emoji: "🍐", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, vitamin C, potassium",
                howToServe: "6+ months: Steamed soft slices or mashed. 9+ months: Ripe soft thin slices or strips",
                chokeHazard: false,
                color: .green, nutrients: [.vitaminC]),

        FoodItem(id: "PEACH", name: "Peach", emoji: "🍑", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin A, fiber, potassium",
                howToServe: "6+ months: Pureed or very ripe mashed. 9+ months: Thin ripe slices (peel removed)",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC]),

        FoodItem(id: "MANGO", name: "Mango", emoji: "🥭", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin A, fiber, folate",
                howToServe: "6+ months: Pureed or thick strips with peel left on for grip. 9+ months: Sliced pieces",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC]),

        FoodItem(id: "BLUEBERRY", name: "Blueberry", emoji: "🫐", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Antioxidants, vitamin C, fiber, vitamin K",
                howToServe: "6+ months: Mashed or quartered. 9+ months: Whole (if soft and small)",
                chokeHazard: true,
                color: .purple, nutrients: [.vitaminC]),

        FoodItem(id: "STRAWBERRY", name: "Strawberry", emoji: "🍓", category: .fruits,
                allergens: [],
                allergyRisk: .medium,
                nutritionHighlights: "Vitamin C, antioxidants, folate, fiber",
                howToServe: "6+ months: Mashed or thin slices. 9+ months: Quartered lengthwise or sliced",
                chokeHazard: false,
                color: .red, nutrients: [.vitaminC]),

        FoodItem(id: "RASPBERRY", name: "Raspberry", emoji: "🍓", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, vitamin C, antioxidants, folate",
                howToServe: "6+ months: Mashed or pureed. 9+ months: Whole or halved (soft)",
                chokeHazard: false,
                color: .red, nutrients: [.vitaminC]),

        FoodItem(id: "BLACKBERRY", name: "Blackberry", emoji: "🫐", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, vitamin C, vitamin K, antioxidants",
                howToServe: "6+ months: Mashed or pureed. 9+ months: Whole or halved (soft)",
                chokeHazard: false,
                color: .purple, nutrients: [.vitaminC]),

        FoodItem(id: "PLUM", name: "Plum", emoji: "🍑", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin K, fiber, potassium",
                howToServe: "6+ months: Pureed or very ripe mashed. 9+ months: Thin ripe slices (peel removed)",
                chokeHazard: false,
                color: .purple, nutrients: [.vitaminC]),

        FoodItem(id: "APRICOT", name: "Apricot", emoji: "🍑", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin A, vitamin C, fiber, potassium",
                howToServe: "6+ months: Pureed or very ripe mashed. 9+ months: Thin ripe slices (peel removed)",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC]),

        FoodItem(id: "WATERMELON", name: "Watermelon", emoji: "🍉", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Hydration, vitamin C, vitamin A, lycopene",
                howToServe: "6+ months: Small soft pieces (remove seeds/rind). 9+ months: Triangle pieces or sticks with rind on",
                chokeHazard: false,
                color: .red, nutrients: [.vitaminC]),

        FoodItem(id: "CANTALOUPE", name: "Cantaloupe", emoji: "🍈", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin A, vitamin C, potassium, fiber",
                howToServe: "6+ months: Pureed or soft small pieces. 9+ months: Thin slices or cubes",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC]),

        FoodItem(id: "PAPAYA", name: "Papaya", emoji: "🥭", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, vitamin A, folate, fiber",
                howToServe: "6+ months: Pureed or mashed ripe papaya. 9+ months: Soft sliced pieces",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC]),

        FoodItem(id: "KIWI", name: "Kiwi", emoji: "🥝", category: .fruits,
                allergens: [],
                allergyRisk: .medium,
                nutritionHighlights: "Vitamin C, vitamin K, fiber, folate",
                howToServe: "6+ months: Pureed or very ripe mashed. 9+ months: Thin slices or small pieces (peel removed)",
                chokeHazard: false,
                color: .green, nutrients: [.vitaminC]),

        FoodItem(id: "ORANGE", name: "Orange", emoji: "🍊", category: .fruits,
                allergens: [],
                allergyRisk: .medium,
                nutritionHighlights: "Vitamin C, folate, fiber, potassium",
                howToServe: "6+ months: Small pieces (membranes removed). 9+ months: Supremes or small segments",
                chokeHazard: false,
                color: .orange, nutrients: [.vitaminC]),

        FoodItem(id: "GRAPE", name: "Grape", emoji: "🍇", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Antioxidants, vitamin C, vitamin K",
                howToServe: "6+ months: ALWAYS quarter lengthwise until age 4! 9+ months: Still quarter lengthwise - major choking hazard",
                chokeHazard: true,
                color: .purple, nutrients: [.vitaminC]),

        FoodItem(id: "CHERRY", name: "Cherry", emoji: "🍒", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, antioxidants, fiber, potassium",
                howToServe: "6+ months: Pitted, quartered. 9+ months: Pitted, halved or quartered. Remove pits completely!",
                chokeHazard: true,
                color: .red, nutrients: [.vitaminC]),

        FoodItem(id: "PINEAPPLE", name: "Pineapple", emoji: "🍍", category: .fruits,
                allergens: [],
                allergyRisk: .medium,
                nutritionHighlights: "Vitamin C, manganese, fiber, antioxidants",
                howToServe: "6+ months: Very ripe pureed or small soft pieces. 9+ months: Thin strips or small pieces",
                chokeHazard: false,
                color: .yellow, nutrients: [.vitaminC]),

        FoodItem(id: "POMEGRANATE", name: "Pomegranate", emoji: "🍎", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Vitamin C, antioxidants, fiber, vitamin K",
                howToServe: "6+ months: Juice mixed into foods (seeds removed). 9+ months: Individual arils supervised closely",
                chokeHazard: true,
                color: .red, nutrients: [.vitaminC]),

        FoodItem(id: "FIG", name: "Fig", emoji: "🍈", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, potassium, calcium, iron",
                howToServe: "6+ months: Pureed or very ripe mashed. 9+ months: Soft quartered fresh figs",
                chokeHazard: false,
                color: .purple, nutrients: [.calcium, .iron]),

        FoodItem(id: "DATE", name: "Date", emoji: "🌰", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, potassium, iron, magnesium",
                howToServe: "6+ months: Pureed (pitted) or mixed into foods. 9+ months: Chopped small pieces (pitted)",
                chokeHazard: true,
                color: .brown, nutrients: [.iron]),

        FoodItem(id: "PRUNE", name: "Prune", emoji: "🍑", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, vitamin K, potassium (helps with constipation)",
                howToServe: "6+ months: Pureed prune or prune puree mixed in. 9+ months: Chopped soft prunes",
                chokeHazard: false,
                color: .purple, nutrients: []),

        FoodItem(id: "RAISIN", name: "Raisin", emoji: "🍇", category: .fruits,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Iron, fiber, potassium, antioxidants",
                howToServe: "6+ months: Avoid - choking hazard. 9+ months: Chopped finely or soaked soft (still risky until 12+ months)",
                chokeHazard: true,
                color: .purple, nutrients: [.iron]),

        FoodItem(id: "COCONUT", name: "Coconut", emoji: "🥥", category: .fruits,
                allergens: ["tree nuts"],
                allergyRisk: .high,
                nutritionHighlights: "Healthy fats, fiber, iron, manganese",
                howToServe: "6+ months: Coconut milk/cream in purees. 9+ months: Shredded unsweetened coconut. Introduce early",
                chokeHazard: false,
                color: .white, nutrients: [.iron]),

        // PROTEINS (20 foods)
        FoodItem(id: "CHICKEN", name: "Chicken", emoji: "🍗", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, B vitamins, selenium, zinc",
                howToServe: "6+ months: Shredded very soft chicken in sauce. 9+ months: Small soft pieces or strips",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "TURKEY", name: "Turkey", emoji: "🦃", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, B vitamins, selenium, zinc",
                howToServe: "6+ months: Shredded very soft turkey in sauce. 9+ months: Small soft pieces or ground turkey",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

       FoodItem(id: "BEEF", name: "Beef", emoji: "🥩", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Iron, protein, zinc, B vitamins",
                howToServe: "6+ months: Well-cooked ground beef or pureed. 9+ months: Small tender pieces or strips",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "PORK", name: "Pork", emoji: "🥓", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, thiamine, selenium, zinc",
                howToServe: "6+ months: Well-cooked shredded tender pork. 9+ months: Small tender pieces (avoid bacon until 12+ months)",
                chokeHazard: false,
                color: .brown, nutrients: [.protein]),

        FoodItem(id: "LAMB", name: "Lamb", emoji: "🍖", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, iron, zinc, B vitamins",
                howToServe: "6+ months: Well-cooked ground lamb or pureed. 9+ months: Small tender pieces",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "SALMON", name: "Salmon", emoji: "🐟", category: .proteins,
                allergens: ["fish"],
                allergyRisk: .high,
                nutritionHighlights: "Omega-3 DHA for brain, vitamin D, protein",
                howToServe: "6+ months: Flaked, boneless. 9+ months: Flakes or small pieces. Check carefully for bones! Introduce early",
                chokeHazard: false,
                color: .orange, nutrients: [.omega3, .protein]),

        FoodItem(id: "TUNA", name: "Tuna", emoji: "🐟", category: .proteins,
                allergens: ["fish"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, omega-3, vitamin D, selenium",
                howToServe: "6+ months: Canned in water, flaked. 9+ months: Flakes or small pieces. Limit mercury - choose light tuna",
                chokeHazard: false,
                color: .brown, nutrients: [.omega3, .protein]),

        FoodItem(id: "COD", name: "Cod", emoji: "🐟", category: .proteins,
                allergens: ["fish"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, vitamin B12, selenium, low mercury",
                howToServe: "6+ months: Flaked soft cooked cod. 9+ months: Small pieces. Check for bones carefully",
                chokeHazard: false,
                color: .white, nutrients: [.protein]),

        FoodItem(id: "TILAPIA", name: "Tilapia", emoji: "🐟", category: .proteins,
                allergens: ["fish"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, vitamin B12, selenium",
                howToServe: "6+ months: Flaked soft cooked tilapia. 9+ months: Small pieces. Check for bones carefully",
                chokeHazard: false,
                color: .white, nutrients: [.protein]),

        FoodItem(id: "SHRIMP", name: "Shrimp", emoji: "🍤", category: .proteins,
                allergens: ["shellfish"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, selenium, vitamin B12, iodine",
                howToServe: "6+ months: Finely chopped cooked shrimp. 9+ months: Chopped or whole if cut properly. Introduce early",
                chokeHazard: true,
                color: .orange, nutrients: [.protein]),

        FoodItem(id: "EGG", name: "Egg", emoji: "🥚", category: .proteins,
                allergens: ["eggs"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, vitamin D, choline for brain development, iron",
                howToServe: "6+ months: Scrambled soft or mashed hard-boiled. 9+ months: Strips, chopped, or omelet pieces. Introduce early!",
                chokeHazard: false,
                color: .yellow, nutrients: [.protein, .iron]),

        FoodItem(id: "TOFU", name: "Tofu", emoji: "🧈", category: .proteins,
                allergens: ["soy"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, calcium, iron, complete amino acids",
                howToServe: "6+ months: Silken tofu pureed or mashed. 9+ months: Small soft cubes or crumbled. Introduce early",
                chokeHazard: false,
                color: .white, nutrients: [.protein, .calcium, .iron]),

        FoodItem(id: "BLACK_BEANS", name: "Black Beans", emoji: "🫘", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, fiber, iron, folate, antioxidants",
                howToServe: "6+ months: Mashed or pureed. 9+ months: Whole beans (soft cooked) - great for pincer grasp",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "LENTILS", name: "Lentils", emoji: "🫘", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, iron, fiber, folate, potassium",
                howToServe: "6+ months: Well-cooked pureed or mashed. 9+ months: Whole soft lentils (dal texture)",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "CHICKPEAS", name: "Chickpeas", emoji: "🫘", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, fiber, iron, folate, manganese",
                howToServe: "6+ months: Mashed or hummus. 9+ months: Whole soft chickpeas, roasted soft",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "KIDNEY_BEANS", name: "Kidney Beans", emoji: "🫘", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, fiber, iron, folate, antioxidants",
                howToServe: "6+ months: Mashed well-cooked beans. 9+ months: Whole soft beans or mashed",
                chokeHazard: false,
                color: .red, nutrients: [.protein, .iron]),

        FoodItem(id: "PINTO_BEANS", name: "Pinto Beans", emoji: "🫘", category: .proteins,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, fiber, iron, folate, potassium",
                howToServe: "6+ months: Mashed well-cooked beans. 9+ months: Whole soft beans or refried beans",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "PEANUT_BUTTER", name: "Peanut Butter", emoji: "🥜", category: .proteins,
                allergens: ["peanuts"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, healthy fats, vitamin E, niacin",
                howToServe: "6+ months: Thin layer on toast or mixed into purees. 9+ months: Spread thin - NEVER by the spoonful! Introduce early",
                chokeHazard: true,
                color: .brown, nutrients: [.protein]),

        FoodItem(id: "ALMOND_BUTTER", name: "Almond Butter", emoji: "🌰", category: .proteins,
                allergens: ["tree nuts"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, healthy fats, vitamin E, magnesium, calcium",
                howToServe: "6+ months: Thin layer on toast or mixed into purees. 9+ months: Spread thin. Introduce early",
                chokeHazard: true,
                color: .brown, nutrients: [.protein, .calcium]),

        FoodItem(id: "HUMMUS", name: "Hummus", emoji: "🧆", category: .proteins,
                allergens: ["sesame"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, fiber, iron, folate, healthy fats",
                howToServe: "6+ months: Smooth hummus as dip or spread. 9+ months: Spread on foods or as dip. Introduce tahini early",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        // GRAINS (15 foods)
        FoodItem(id: "OATMEAL", name: "Oatmeal", emoji: "🥣", category: .grains,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Fiber, iron, B vitamins, zinc",
                howToServe: "6+ months: Well-cooked smooth oatmeal. 9+ months: Thicker texture, oat fingers",
                chokeHazard: false,
                color: .brown, nutrients: [.iron]),

        FoodItem(id: "RICE", name: "Rice", emoji: "🍚", category: .grains,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Carbs for energy, B vitamins, iron (if fortified)",
                howToServe: "6+ months: Well-cooked soft rice or rice cereal. 9+ months: Soft sticky rice balls or regular rice",
                chokeHazard: false,
                color: .white, nutrients: []),

        FoodItem(id: "QUINOA", name: "Quinoa", emoji: "🌾", category: .grains,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Complete protein, fiber, iron, magnesium",
                howToServe: "6+ months: Well-cooked mashed quinoa. 9+ months: Soft cooked quinoa mixed into foods",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "BARLEY", name: "Barley", emoji: "🌾", category: .grains,
                allergens: ["gluten"],
                allergyRisk: .medium,
                nutritionHighlights: "Fiber, selenium, B vitamins, iron",
                howToServe: "6+ months: Well-cooked soft barley cereal. 9+ months: Soft cooked barley in soups",
                chokeHazard: false,
                color: .brown, nutrients: [.iron]),

        FoodItem(id: "COUSCOUS", name: "Couscous", emoji: "🍚", category: .grains,
                allergens: ["wheat", "gluten"],
                allergyRisk: .high,
                nutritionHighlights: "Carbs for energy, B vitamins, selenium",
                howToServe: "6+ months: Well-cooked soft couscous. 9+ months: Regular couscous mixed with sauce. Introduce early",
                chokeHazard: false,
                color: .yellow, nutrients: []),

        FoodItem(id: "PASTA", name: "Pasta", emoji: "🍝", category: .grains,
                allergens: ["wheat", "gluten"],
                allergyRisk: .high,
                nutritionHighlights: "Carbs for energy, B vitamins, iron (if fortified)",
                howToServe: "6+ months: Very soft cooked small pasta shapes. 9+ months: Soft pasta shapes for self-feeding. Introduce early",
                chokeHazard: false,
                color: .yellow, nutrients: []),

        FoodItem(id: "BREAD", name: "Bread", emoji: "🍞", category: .grains,
                allergens: ["wheat", "gluten"],
                allergyRisk: .high,
                nutritionHighlights: "Carbs for energy, B vitamins, fiber (whole grain)",
                howToServe: "6+ months: Lightly toasted strips (easier to grip). 9+ months: Toast strips or small pieces. Choose whole grain. Introduce early",
                chokeHazard: false,
                color: .brown, nutrients: []),

        FoodItem(id: "CRACKERS", name: "Crackers", emoji: "🍘", category: .grains,
                allergens: ["wheat"],
                allergyRisk: .high,
                nutritionHighlights: "Carbs for energy, some iron and B vitamins",
                howToServe: "6+ months: Soft dissolvable crackers. 9+ months: Whole grain crackers (avoid sticky gums)",
                chokeHazard: true,
                color: .brown, nutrients: []),

        FoodItem(id: "TORTILLA", name: "Tortilla", emoji: "🫓", category: .grains,
                allergens: ["wheat"],
                allergyRisk: .high,
                nutritionHighlights: "Carbs for energy, fiber, B vitamins",
                howToServe: "6+ months: Small soft torn pieces. 9+ months: Strips or quesadilla pieces",
                chokeHazard: false,
                color: .brown, nutrients: []),

        FoodItem(id: "CHEERIOS", name: "Cheerios", emoji: "🥣", category: .grains,
                allergens: ["oats"],
                allergyRisk: .low,
                nutritionHighlights: "Iron, B vitamins, whole grain fiber",
                howToServe: "6+ months: Great for pincer grasp practice (softens in mouth). 9+ months: Dry cereal snack",
                chokeHazard: false,
                color: .yellow, nutrients: [.iron]),

        FoodItem(id: "MILLET", name: "Millet", emoji: "🌾", category: .grains,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, fiber, iron, magnesium, B vitamins",
                howToServe: "6+ months: Well-cooked soft millet porridge. 9+ months: Soft cooked millet in dishes",
                chokeHazard: false,
                color: .yellow, nutrients: [.iron, .protein]),

        FoodItem(id: "BUCKWHEAT", name: "Buckwheat", emoji: "🌾", category: .grains,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Protein, fiber, iron, magnesium (gluten-free)",
                howToServe: "6+ months: Well-cooked buckwheat porridge. 9+ months: Soft buckwheat groats or noodles",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "POLENTA", name: "Polenta", emoji: "🌽", category: .grains,
                allergens: [],
                allergyRisk: .low,
                nutritionHighlights: "Carbs for energy, vitamin A, iron",
                howToServe: "6+ months: Smooth cooked polenta. 9+ months: Firm polenta cut into strips or cubes",
                chokeHazard: false,
                color: .yellow, nutrients: [.iron]),

        FoodItem(id: "FARRO", name: "Farro", emoji: "🌾", category: .grains,
                allergens: ["gluten"],
                allergyRisk: .medium,
                nutritionHighlights: "Protein, fiber, iron, magnesium, B vitamins",
                howToServe: "6+ months: Well-cooked soft farro. 9+ months: Chewy cooked farro in dishes",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        FoodItem(id: "BULGUR", name: "Bulgur", emoji: "🌾", category: .grains,
                allergens: ["wheat", "gluten"],
                allergyRisk: .high,
                nutritionHighlights: "Fiber, protein, iron, B vitamins",
                howToServe: "6+ months: Well-cooked soft bulgur. 9+ months: Soft bulgur in dishes like tabbouleh",
                chokeHazard: false,
                color: .brown, nutrients: [.protein, .iron]),

        // DAIRY (15 foods)
        FoodItem(id: "YOGURT", name: "Yogurt", emoji: "🥛", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, calcium, probiotics, vitamin D",
                howToServe: "6+ months: Full-fat plain yogurt. 9+ months: Yogurt with soft fruits. Introduce early for allergy prevention",
                chokeHazard: false,
                color: .white, nutrients: [.calcium, .protein]),

        FoodItem(id: "PROVOLONE", name: "Provolone", emoji: "🧀", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, protein, vitamin B12, vitamin A",
                howToServe: "6+ months: Shredded or thin strips. 9+ months: Small cubes. Melts well for pasta and sandwiches.",
                chokeHazard: true,
                color: .yellow, nutrients: [.calcium, .protein]),

        FoodItem(id: "COTTAGE_CHEESE", name: "Cottage Cheese", emoji: "🧀", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, calcium, B vitamins, selenium",
                howToServe: "6+ months: Small curd cottage cheese. 9+ months: Mixed into foods or as side",
                chokeHazard: false,
                color: .white, nutrients: [.calcium, .protein]),

        FoodItem(id: "CREAM_CHEESE", name: "Cream Cheese", emoji: "🧈", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, vitamin A, fats",
                howToServe: "6+ months: Thin spread on toast. 9+ months: Spread or mixed into foods",
                chokeHazard: false,
                color: .white, nutrients: [.calcium]),

        FoodItem(id: "RICOTTA", name: "Ricotta", emoji: "🧀", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, calcium, vitamin A, selenium",
                howToServe: "6+ months: Smooth ricotta mixed into purees. 9+ months: Ricotta in pasta or on its own",
                chokeHazard: false,
                color: .white, nutrients: [.calcium, .protein]),

        FoodItem(id: "MOZZARELLA", name: "Mozzarella", emoji: "🧀", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, protein, vitamin B12",
                howToServe: "6+ months: Shredded fresh mozzarella. 9+ months: Small soft pieces or melted",
                chokeHazard: true,
                color: .white, nutrients: [.calcium, .protein]),

        FoodItem(id: "CHEDDAR", name: "Cheddar", emoji: "🧀", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, protein, vitamin A, vitamin B12",
                howToServe: "6+ months: Shredded cheddar. 9+ months: Small cubes or strips",
                chokeHazard: true,
                color: .yellow, nutrients: [.calcium, .protein]),

        FoodItem(id: "SWISS_CHEESE", name: "Swiss Cheese", emoji: "🧀", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, protein, vitamin B12, zinc",
                howToServe: "6+ months: Shredded swiss cheese. 9+ months: Small soft pieces",
                chokeHazard: true,
                color: .yellow, nutrients: [.calcium, .protein]),

        FoodItem(id: "PARMESAN", name: "Parmesan", emoji: "🧀", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, protein, vitamin A, phosphorus",
                howToServe: "6+ months: Finely grated on foods. 9+ months: Grated or small shaved pieces",
                chokeHazard: false,
                color: .yellow, nutrients: [.calcium, .protein]),

        FoodItem(id: "BUTTER", name: "Butter", emoji: "🧈", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Vitamin A, healthy fats",
                howToServe: "6+ months: Small amount on toast or mixed into purees. 9+ months: On cooked vegetables or bread",
                chokeHazard: false,
                color: .yellow, nutrients: []),

        FoodItem(id: "MILK", name: "Milk", emoji: "🥛", category: .dairy,
                allergens: ["dairy", "lactose"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, vitamin D, protein, vitamin B12",
                howToServe: "6+ months: Only in cooking. 9+ months: Only in cooking. 12+ months: Whole milk as beverage",
                chokeHazard: false,
                color: .white, nutrients: [.calcium, .protein]),

        FoodItem(id: "KEFIR", name: "Kefir", emoji: "🥛", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Protein, calcium, probiotics, B vitamins",
                howToServe: "6+ months: Small amount mixed into foods. 9+ months: Small servings as drink or with fruit",
                chokeHazard: false,
                color: .white, nutrients: [.calcium, .protein]),

        FoodItem(id: "SOUR_CREAM", name: "Sour Cream", emoji: "🧈", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, vitamin A, probiotics",
                howToServe: "6+ months: Small dollop mixed into foods. 9+ months: As topping or mixed in",
                chokeHazard: false,
                color: .white, nutrients: [.calcium]),

        FoodItem(id: "GREEK_YOGURT", name: "Greek Yogurt", emoji: "🥛", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "High protein, calcium, probiotics, vitamin B12",
                howToServe: "6+ months: Full-fat plain Greek yogurt. 9+ months: With soft fruits or as dip",
                chokeHazard: false,
                color: .white, nutrients: [.calcium, .protein]),

        FoodItem(id: "ICE_CREAM", name: "Ice Cream", emoji: "🍦", category: .dairy,
                allergens: ["dairy"],
                allergyRisk: .high,
                nutritionHighlights: "Calcium, some protein (high in sugar - occasional treat)",
                howToServe: "6+ months: Small taste on special occasions. 9+ months: Small portions as occasional treat (limit sugar)",
                chokeHazard: false,
                color: .white, nutrients: [.calcium]),
    ]

    static let newbornColor = Color(red: 244/255, green: 63/255, blue: 94/255)
    static let explorerColor = Color(red: 13/255, green: 148/255, blue: 136/255)
    static let toddlerColor = Color(red: 99/255, green: 102/255, blue: 241/255)
}

extension Color {
    /// A darker orange that meets WCAG AA contrast standards (4.5:1) against white backgrounds.
    /// Hex: #B45309 (180, 83, 9)
    static let warningOrangeAccessible = Color(red: 180/255, green: 83/255, blue: 9/255)
    
    /// Warning color that adapts to color scheme, ensuring accessibility
    static var warning: Color {
        // You might want to use a different shade for dark mode if needed,
        // but #B45309 might be too dark for dark mode background.
        // For now, let's use the accessible orange for light mode situations primarily.
        // If we need a dynamic color, we can use UIColor with traitCollection.
        return warningOrangeAccessible
    }
}
