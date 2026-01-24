//
//  SampleDataGenerator.swift
//  TinyTastesTracker
//
//  Generates realistic sample data for demo mode and first-time user experience
//

import Foundation
import SwiftData
import UIKit

struct SampleDataGenerator {
    
    // MARK: - Main Generation Method
    
    /// Generate complete sample dataset
    // MARK: - Main Generation Method

    /// Generate complete sample dataset
    static func generateSampleData(context: ModelContext, backupUserData: Bool = true) {
        // Backup user data first if requested
        if backupUserData {
            _ = UserDataBackupService.backupUserData(context: context)
        }

        // Clear existing data
        clearAllData(context: context)
        
        // Generate profiles
        let profiles = generateProfiles(context: context)
        
        // Generate data for each profile
        for profile in profiles {
            generateGrowthMeasurements(for: profile, context: context)
            
            if profile.babyName == "Emma" { // Newborn focus
                generateNewbornLogs(context: context)
            } else if profile.babyName == "Liam" { // Toddler focus
                generateToddlerDataForLiam(context: context)
            } else if profile.babyName == "Olivia" { // Explorer focus
                generateExplorerDataForOlivia(context: context)
            }
        }
        
        // Generate recipes (shared across profiles)
        generateRecipes(context: context)
        
        // Save all changes
        try? context.save()
    }
    
    // MARK: - Profile Generation
    
    private static func generateProfiles(context: ModelContext) -> [UserProfile] {
        let profiles = [
            UserProfile(
                babyName: "Emma",
                birthDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
                gender: .girl,
                knownAllergies: nil,
                preferredMode: .newborn
            ),
            UserProfile(
                babyName: "Liam",
                birthDate: Calendar.current.date(byAdding: .month, value: -24, to: Date())!, // 2 years old
                gender: .boy,
                knownAllergies: ["Peanuts", "Dairy"],
                preferredMode: .toddler
            ),
            UserProfile(
                babyName: "Olivia",
                birthDate: Calendar.current.date(byAdding: .month, value: -8, to: Date())!, // 8 months
                gender: .girl,
                knownAllergies: nil,
                preferredMode: .explorer
            )
        ]
        
        for profile in profiles {
            context.insert(profile)
        }
        
        return profiles
    }
    
    // MARK: - Growth Measurements
    
    private static func generateGrowthMeasurements(for profile: UserProfile, context: ModelContext) {
        let ageInMonths = profile.ageInMonths
        let measurementCount = min(ageInMonths + 1, 12) // Include birth
        
        // Starting weights/heights based on profile
        var currentWeight: Double
        var currentHeight: Double
        var currentHead: Double
        
        if profile.babyName == "Liam" {
            // Toddler: Slower growth, larger starting point
            currentWeight = 24.0
            currentHeight = 32.0
            currentHead = 18.0
        } else if profile.babyName == "Olivia" {
            // Explorer: Rapid infant growth
            currentWeight = 16.0
            currentHeight = 26.0
            currentHead = 16.5
        } else {
            // Newborn: Tiny
            currentWeight = 7.5
            currentHeight = 20.0
            currentHead = 13.5
        }
        
        for i in 0..<measurementCount {
            let date = Calendar.current.date(byAdding: .month, value: -measurementCount + i, to: Date())!
            
            // Varied growth rates
            if profile.babyName == "Liam" {
                currentWeight += Double.random(in: 0.3...0.5)
                currentHeight += Double.random(in: 0.2...0.4)
            } else {
                currentWeight += Double.random(in: 1.0...1.5)
                currentHeight += Double.random(in: 0.8...1.2)
                currentHead += Double.random(in: 0.3...0.5)
            }
            
            let measurement = GrowthMeasurement(
                date: date,
                weight: currentWeight,
                height: currentHeight,
                headCircumference: currentHead,
                notes: i % 3 == 0 ? "Well-child visit" : nil
            )
            
            context.insert(measurement)
        }
    }
    
    // MARK: - Newborn Logs (Emma)
    
    private static func generateNewbornLogs(context: ModelContext) {
        let daysToGenerate = 7
        
        for dayOffset in 0..<daysToGenerate {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            // Frequent nursing
            for _ in 0..<Int.random(in: 8...10) {
                let timestamp = date.addingTimeInterval(TimeInterval.random(in: 0...86400))
                let nursing = NursingLog(
                    timestamp: timestamp,
                    duration: TimeInterval.random(in: 900...2400),
                    side: Bool.random() ? .left : .right
                )
                context.insert(nursing)
            }
            
            // Diapers
            for _ in 0..<Int.random(in: 8...10) {
                let timestamp = date.addingTimeInterval(TimeInterval.random(in: 0...86400))
                let diaper = DiaperLog(
                    timestamp: timestamp,
                    type: [.wet, .dirty, .both].randomElement()!
                )
                context.insert(diaper)
            }
            
            // Sleep
            for _ in 0..<Int.random(in: 4...6) {
                let startTime = date.addingTimeInterval(TimeInterval.random(in: 0...86400))
                let duration = TimeInterval.random(in: 3600...10800) // 1-3 hours
                let sleep = SleepLog(
                    startTime: startTime,
                    endTime: startTime.addingTimeInterval(duration),
                    quality: [.good, .excellent].randomElement()!
                )
                context.insert(sleep)
            }
        }
    }
    
    // MARK: - Toddler Data (Liam)
    
    private static func generateToddlerDataForLiam(context: ModelContext) {
        let daysToGenerate = 14
        // High nutrient foods for Liam to populate charts
        let foods = [
            "CHICKEN", "BEEF", "SALMON", "BROCCOLI", "SPINACH", // Iron/Protein
            "YOGURT", "CHEESE", "MILK", "ORANGE", "EGG", // Calcium/Vit C
            "BANANA", "APPLE", "PASTA", "RICE", "AVOCADO" // Energy
        ]
        
        for dayOffset in 0..<daysToGenerate {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            let mealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
            
            for mealType in mealTypes {
                let timestamp = date.addingTimeInterval(TimeInterval.random(in: 28000...70000))
                let foodCount = Int.random(in: 2...4)
                let mealFoods = (0..<foodCount).map { _ in foods.randomElement()! }
                
                let meal = MealLog(
                    foods: mealFoods,
                    feedingStrategy: [.divisionOfResponsibility, .modeling].randomElement()!,
                    timestamp: timestamp,
                    mealType: mealType
                )
                context.insert(meal)
                
                // Track tried foods
                for foodId in mealFoods {
                    let existing = try? context.fetch(FetchDescriptor<TriedFoodLog>(
                        predicate: #Predicate { $0.id == foodId }
                    )).first
                    
                    if existing == nil {
                        // Liam has tried everything but might dislike some
                        let reaction = ["BROCCOLI", "SPINACH"].contains(foodId) ? Int.random(in: 1...3) : Int.random(in: 4...5)
                        
                        let tried = TriedFoodLog(
                            id: foodId,
                            date: timestamp,
                            reaction: reaction,
                            meal: mealType
                        )
                        context.insert(tried)
                    }
                }
            }
        }
    }
    
    // MARK: - Explorer Data (Olivia)
    
    private static func generateExplorerDataForOlivia(context: ModelContext) {
        let daysToGenerate = 14
        // Simple first foods
        let foods = ["AVOCADO", "SWEET_POTATO", "BANANA", "PEAR", "OATMEAL", "CARROT"]
        
        for dayOffset in 0..<daysToGenerate {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            // Only 1-2 meals per day
            for _ in 0..<Int.random(in: 1...2) {
                let timestamp = date.addingTimeInterval(TimeInterval.random(in: 36000...60000))
                let foodId = foods.randomElement()!
                
                let meal = MealLog(
                    foods: [foodId],
                    feedingStrategy: .foodPlay,
                    timestamp: timestamp,
                    mealType: .lunch
                )
                context.insert(meal)
                
                let existing = try? context.fetch(FetchDescriptor<TriedFoodLog>(
                    predicate: #Predicate { $0.id == foodId }
                )).first
                
                if existing == nil {
                    // Olivia loves everything
                    let tried = TriedFoodLog(
                        id: foodId,
                        date: timestamp,
                        reaction: 5,
                        meal: .lunch
                    )
                    context.insert(tried)
                }
            }
        }
    }

    // MARK: - Recipes
    
    private static func generateRecipes(context: ModelContext) {
        let sampleRecipes = [
            (
                title: "Sweet Potato Mash",
                ingredients: "1 large sweet potato\n2 tbsp breast milk or formula\nPinch of cinnamon",
                instructions: "1. Peel and dice sweet potato\n2. Steam until tender (15-20 minutes)\n3. Mash with breast milk/formula\n4. Add cinnamon\n5. Let cool before serving"
            ),
            (
                title: "Banana Oat Pancakes",
                ingredients: "1 ripe banana\n1 egg\n1/4 cup oats\nPinch of vanilla",
                instructions: "1. Mash banana in bowl\n2. Mix in egg and oats\n3. Add vanilla\n4. Cook small pancakes on griddle\n5. Cut into strips for baby"
            ),
            (
                title: "Veggie Pasta",
                ingredients: "1/2 cup pasta\n1/4 cup broccoli\n1/4 cup peas\n1 tbsp olive oil\n1 tbsp parmesan",
                instructions: "1. Cook pasta according to package\n2. Steam vegetables\n3. Mix pasta and veggies\n4. Drizzle with olive oil\n5. Sprinkle parmesan"
            ),
            (
                title: "Chicken & Rice",
                ingredients: "1/4 cup chicken breast\n1/2 cup brown rice\n1/4 cup carrots\n1 cup chicken broth",
                instructions: "1. Dice chicken into small pieces\n2. Cook rice in broth\n3. Steam carrots\n4. Mix all ingredients\n5. Ensure chicken is fully cooked"
            ),
            (
                title: "Berry Yogurt Bowl",
                ingredients: "1/2 cup plain yogurt\n1/4 cup blueberries\n1/4 cup strawberries\n1 tbsp ground flaxseed",
                instructions: "1. Place yogurt in bowl\n2. Mash berries slightly\n3. Mix berries into yogurt\n4. Sprinkle flaxseed on top\n5. Serve immediately"
            ),
            (
                title: "Avocado Toast Fingers",
                ingredients: "1 slice whole wheat bread\n1/2 ripe avocado\nPinch of garlic powder",
                instructions: "1. Toast bread lightly\n2. Mash avocado\n3. Spread on toast\n4. Sprinkle garlic powder\n5. Cut into finger-sized strips"
            ),
            (
                title: "Mini Egg Muffins",
                ingredients: "3 eggs\n1/4 cup cheese\n1/4 cup spinach\n1/4 cup diced bell pepper",
                instructions: "1. Preheat oven to 350°F\n2. Beat eggs in bowl\n3. Mix in cheese and vegetables\n4. Pour into muffin tin\n5. Bake 15-20 minutes"
            ),
            (
                title: "Apple Cinnamon Oatmeal",
                ingredients: "1/2 cup oats\n1 cup milk\n1/2 apple, diced\n1/4 tsp cinnamon",
                instructions: "1. Cook oats in milk\n2. Add diced apple\n3. Sprinkle cinnamon\n4. Cook until apples soften\n5. Let cool before serving"
            )
        ]
        
        for recipe in sampleRecipes {
            let newRecipe = Recipe(
                title: recipe.title,
                ingredients: recipe.ingredients,
                instructions: recipe.instructions,
                imageData: nil, // Could add sample images
                thumbnailData: nil
            )
            
            context.insert(newRecipe)
        }
    }
    
    // MARK: - Clear Data

    static func clearAllData(context: ModelContext) {
        // Delete all existing data
        do {
            // Profiles
            try context.delete(model: UserProfile.self)
            
            // Logs
            try context.delete(model: NursingLog.self)
            try context.delete(model: SleepLog.self)
            try context.delete(model: DiaperLog.self)
            try context.delete(model: BottleFeedLog.self)
            try context.delete(model: GrowthMeasurement.self)
            try context.delete(model: MealLog.self)
            try context.delete(model: TriedFoodLog.self)
            
            // Recipes
            try context.delete(model: Recipe.self)
            try context.delete(model: CustomFood.self)
            try context.delete(model: MealPlanEntry.self)
            try context.delete(model: ShoppingListItem.self)
            
            try context.save()
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}
