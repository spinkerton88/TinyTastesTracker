//
//  Badge.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 2/4/26.
//

import Foundation

enum BadgeType: String, Codable {
    // Newborn
    case sleepPro = "SLEEP_PRO" // 10 sleeps
    case milkMonster = "MILK_MONSTER" // 20 feeds
    case growthChart = "GROWTH_CHART" // 3 measurements
    
    // Explorer
    case greenMachine = "GREEN_MACHINE" // 5 green veggies
    case fruitNinja = "FRUIT_NINJA" // 5 fruits
    case proteinPower = "PROTEIN_POWER" // 3 proteins
    case firstTen = "FIRST_TEN" // 10 foods
    
    // Toddler
    case littleChef = "LITTLE_CHEF" // 5 recipes
    case balancedPlate = "BALANCED_PLATE" // 1 balanced meal
    case streakMaster = "STREAK_MASTER" // 3 days streak
}

struct Badge: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var userDescription: String
    var category: AppMode
    var icon: String
    var isUnlocked: Bool
    var dateUnlocked: Date?
    var progress: Int
    var target: Int
    var type: BadgeType
    
    init(id: String = UUID().uuidString,
         title: String,
         userDescription: String,
         category: AppMode,
         icon: String,
         isUnlocked: Bool = false,
         dateUnlocked: Date? = nil,
         progress: Int = 0,
         target: Int,
         type: BadgeType) {
        self.id = id
        self.title = title
        self.userDescription = userDescription
        self.category = category
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.dateUnlocked = dateUnlocked
        self.progress = progress
        self.target = target
        self.type = type
    }
    
    static func defaults() -> [Badge] {
        return [
            // Newborn
            Badge(title: "Sleep Pro", userDescription: "Log 10 Sleep sessions", category: .newborn, icon: "moon.stars.fill", target: 10, type: .sleepPro),
            Badge(title: "Milk Monster", userDescription: "Log 20 Feeds", category: .newborn, icon: "drop.fill", target: 20, type: .milkMonster),
            Badge(title: "Growth Chart", userDescription: "Log Height/Weight 3 times", category: .newborn, icon: "ruler.fill", target: 3, type: .growthChart),
            
            // Explorer
            Badge(title: "Green Machine", userDescription: "Try 5 Green Vegetables", category: .explorer, icon: "leaf.fill", target: 5, type: .greenMachine),
            Badge(title: "Fruit Ninja", userDescription: "Try 5 different Fruits", category: .explorer, icon: "apple.logo", target: 5, type: .fruitNinja),
            Badge(title: "Protein Power", userDescription: "Try 3 Protein sources", category: .explorer, icon: "fish.fill", target: 3, type: .proteinPower),
            Badge(title: "The First 10", userDescription: "Log 10 unique foods", category: .explorer, icon: "10.circle.fill", target: 10, type: .firstTen),
            
            // Toddler
            Badge(title: "Little Chef", userDescription: "Make 5 recipes", category: .toddler, icon: "cooktop.fill", target: 5, type: .littleChef),
            Badge(title: "Balanced Plate", userDescription: "Log a meal with all macros", category: .toddler, icon: "chart.pie.fill", target: 1, type: .balancedPlate),
            Badge(title: "Streak Master", userDescription: "Log meals 3 days in a row", category: .toddler, icon: "flame.fill", target: 3, type: .streakMaster)
        ]
    }
}
