//
//  UserDataBackupService.swift
//  TinyTastesTracker
//
//  Service for backing up and restoring user data when using sample data mode
//

import Foundation
import SwiftData

struct UserDataBackupService {

    // MARK: - Backup Models

    struct BackupData: Codable {
        let profiles: [UserProfileBackup]
        let nursingLogs: [NursingLogBackup]
        let sleepLogs: [SleepLogBackup]
        let diaperLogs: [DiaperLogBackup]
        let bottleLogs: [BottleFeedLogBackup]
        let growthMeasurements: [GrowthMeasurementBackup]
        let mealLogs: [MealLogBackup]
        let triedFoodLogs: [TriedFoodLogBackup]
        let recipes: [RecipeBackup]
        let customFoods: [CustomFoodBackup]
        let mealPlanEntries: [MealPlanEntryBackup]
        let shoppingListItems: [ShoppingListItemBackup]
        let backupDate: Date
    }

    struct UserProfileBackup: Codable {
        let id: UUID
        let babyName: String
        let birthDate: Date
        let gender: String
        let knownAllergies: [String]?
        let preferredMode: String?
        let substitutedFoods: [String: String]?
    }

    struct NursingLogBackup: Codable {
        let id: UUID
        let timestamp: Date
        let duration: TimeInterval
        let side: String
    }

    struct SleepLogBackup: Codable {
        let id: UUID
        let startTime: Date
        let endTime: Date
        let quality: String
    }

    struct DiaperLogBackup: Codable {
        let id: UUID
        let timestamp: Date
        let type: String
    }

    struct BottleFeedLogBackup: Codable {
        let id: UUID
        let timestamp: Date
        let amount: Double
        let feedType: String
        let notes: String?
    }

    struct GrowthMeasurementBackup: Codable {
        let id: UUID
        let date: Date
        let weight: Double?
        let height: Double?
        let headCircumference: Double?
        let notes: String?
    }

    struct MealLogBackup: Codable {
        let id: UUID
        let timestamp: Date
        let mealType: String
        let foods: [String]
        let feedingStrategy: String
        let notes: String
    }

    struct TriedFoodLogBackup: Codable {
        let id: String
        let date: Date
        let reaction: Int
        let meal: String
        let allergyReaction: String
        let messyFaceImage: Data?
        let tryCount: Int
        let reactionSigns: [String]
        let quantity: String
    }

    struct RecipeBackup: Codable {
        let id: UUID
        let title: String
        let ingredients: String
        let instructions: String
        let tags: [String]
        let mealTypes: [String]
        let createdAt: Date
    }

    struct CustomFoodBackup: Codable {
        let id: String
        let name: String
        let emoji: String
        let category: String
        let allergens: [String]
        let nutritionHighlights: String
        let howToServe: String
        let chokeHazard: Bool
        let color: String
        let containedColors: [String]
        let containedCategories: [String]
        let nutrients: [String]
    }

    struct MealPlanEntryBackup: Codable {
        let id: UUID
        let date: Date
        let mealType: String
        let recipeId: UUID
        let recipeName: String
    }

    struct ShoppingListItemBackup: Codable {
        let id: UUID
        let name: String
        let quantity: String?
        let unit: String?
        let category: String
        let source: String
        let isCompleted: Bool
        let createdAt: Date
    }

    // MARK: - Public Methods

    /// Backup all user data to UserDefaults
    static func backupUserData(context: ModelContext) -> Bool {
        do {
            // Fetch all data
            let profiles = try context.fetch(FetchDescriptor<UserProfile>())
            let nursingLogs = try context.fetch(FetchDescriptor<NursingLog>())
            let sleepLogs = try context.fetch(FetchDescriptor<SleepLog>())
            let diaperLogs = try context.fetch(FetchDescriptor<DiaperLog>())
            let bottleLogs = try context.fetch(FetchDescriptor<BottleFeedLog>())
            let growthMeasurements = try context.fetch(FetchDescriptor<GrowthMeasurement>())
            let mealLogs = try context.fetch(FetchDescriptor<MealLog>())
            let triedFoodLogs = try context.fetch(FetchDescriptor<TriedFoodLog>())
            let recipes = try context.fetch(FetchDescriptor<Recipe>())
            let customFoods = try context.fetch(FetchDescriptor<CustomFood>())
            let mealPlanEntries = try context.fetch(FetchDescriptor<MealPlanEntry>())
            let shoppingListItems = try context.fetch(FetchDescriptor<ShoppingListItem>())

            // Convert to backup models
            let backup = BackupData(
                profiles: profiles.map { convertProfile($0) },
                nursingLogs: nursingLogs.map { convertNursingLog($0) },
                sleepLogs: sleepLogs.map { convertSleepLog($0) },
                diaperLogs: diaperLogs.map { convertDiaperLog($0) },
                bottleLogs: bottleLogs.map { convertBottleLog($0) },
                growthMeasurements: growthMeasurements.map { convertGrowthMeasurement($0) },
                mealLogs: mealLogs.map { convertMealLog($0) },
                triedFoodLogs: triedFoodLogs.map { convertTriedFoodLog($0) },
                recipes: recipes.map { convertRecipe($0) },
                customFoods: customFoods.map { convertCustomFood($0) },
                mealPlanEntries: mealPlanEntries.map { convertMealPlanEntry($0) },
                shoppingListItems: shoppingListItems.map { convertShoppingListItem($0) },
                backupDate: Date()
            )

            // Encode and save
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(backup)
            UserDefaults.standard.set(data, forKey: "userDataBackup")

            print("✅ User data backed up successfully")
            return true
        } catch {
            print("❌ Error backing up user data: \(error)")
            return false
        }
    }

    /// Restore user data from backup
    static func restoreUserData(context: ModelContext) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: "userDataBackup") else {
            print("⚠️ No backup data found")
            return false
        }

        do {
            // Clear current data first
            clearAllData(context: context)

            // Decode backup
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: data)

            // Restore profiles
            for profileBackup in backup.profiles {
                let profile = UserProfile(
                    id: profileBackup.id,
                    babyName: profileBackup.babyName,
                    birthDate: profileBackup.birthDate,
                    gender: Gender(rawValue: profileBackup.gender) ?? .other,
                    knownAllergies: profileBackup.knownAllergies,
                    preferredMode: profileBackup.preferredMode.flatMap { AppMode(rawValue: $0) }
                )
                profile.substitutedFoods = profileBackup.substitutedFoods
                context.insert(profile)
            }

            // Restore logs
            for log in backup.nursingLogs {
                let nursingLog = NursingLog(
                    id: log.id,
                    timestamp: log.timestamp,
                    duration: log.duration,
                    side: NursingSide(rawValue: log.side) ?? .left
                )
                context.insert(nursingLog)
            }

            for log in backup.sleepLogs {
                let sleepLog = SleepLog(
                    id: log.id,
                    startTime: log.startTime,
                    endTime: log.endTime,
                    quality: SleepQuality(rawValue: log.quality) ?? .good
                )
                context.insert(sleepLog)
            }

            for log in backup.diaperLogs {
                let diaperLog = DiaperLog(
                    id: log.id,
                    timestamp: log.timestamp,
                    type: DiaperType(rawValue: log.type) ?? .wet
                )
                context.insert(diaperLog)
            }

            for log in backup.bottleLogs {
                let bottleLog = BottleFeedLog(
                    id: log.id,
                    timestamp: log.timestamp,
                    amount: log.amount,
                    feedType: FeedingType(rawValue: log.feedType) ?? .breastMilk,
                    notes: log.notes
                )
                context.insert(bottleLog)
            }

            for measurement in backup.growthMeasurements {
                let growth = GrowthMeasurement(
                    id: measurement.id,
                    date: measurement.date,
                    weight: measurement.weight,
                    height: measurement.height,
                    headCircumference: measurement.headCircumference,
                    notes: measurement.notes
                )
                context.insert(growth)
            }

            for log in backup.mealLogs {
                let mealLog = MealLog(
                    id: log.id,
                    foods: log.foods,
                    feedingStrategy: FeedingStrategy(rawValue: log.feedingStrategy) ?? .none,
                    notes: log.notes,
                    timestamp: log.timestamp,
                    mealType: MealType(rawValue: log.mealType) ?? .lunch
                )
                context.insert(mealLog)
            }

            for log in backup.triedFoodLogs {
                let triedLog = TriedFoodLog(
                    id: log.id,
                    date: log.date,
                    reaction: log.reaction,
                    meal: MealType(rawValue: log.meal) ?? .lunch,
                    allergyReaction: AllergyReaction(rawValue: log.allergyReaction) ?? .none,
                    messyFaceImage: log.messyFaceImage,
                    tryCount: log.tryCount,
                    reactionSigns: log.reactionSigns,
                    quantity: log.quantity
                )
                context.insert(triedLog)
            }

            for recipe in backup.recipes {
                let newRecipe = Recipe(
                    id: recipe.id,
                    title: recipe.title,
                    ingredients: recipe.ingredients,
                    instructions: recipe.instructions,
                    tags: recipe.tags,
                    mealTypes: recipe.mealTypes.compactMap { MealType(rawValue: $0) },
                    imageData: nil,
                    thumbnailData: nil,
                    createdAt: recipe.createdAt
                )
                context.insert(newRecipe)
            }

            for food in backup.customFoods {
                let customFood = CustomFood(
                    id: food.id,
                    name: food.name,
                    emoji: food.emoji,
                    category: FoodCategory(rawValue: food.category) ?? .vegetables,
                    allergens: food.allergens,
                    nutritionHighlights: food.nutritionHighlights,
                    howToServe: food.howToServe,
                    chokeHazard: food.chokeHazard,
                    color: FoodColor(rawValue: food.color) ?? .green,
                    containedColors: food.containedColors.compactMap { FoodColor(rawValue: $0) },
                    containedCategories: food.containedCategories.compactMap { FoodCategory(rawValue: $0) },
                    nutrients: food.nutrients.compactMap { Nutrient(rawValue: $0) }
                )
                context.insert(customFood)
            }

            for entry in backup.mealPlanEntries {
                let mealPlanEntry = MealPlanEntry(
                    id: entry.id,
                    date: entry.date,
                    mealType: MealType(rawValue: entry.mealType) ?? .lunch,
                    recipeId: entry.recipeId,
                    recipeName: entry.recipeName
                )
                context.insert(mealPlanEntry)
            }

            for item in backup.shoppingListItems {
                let shoppingItem = ShoppingListItem(
                    id: item.id,
                    name: item.name,
                    quantity: item.quantity,
                    unit: item.unit,
                    category: GroceryCategory(rawValue: item.category) ?? .other,
                    isCompleted: item.isCompleted,
                    source: ItemSource(rawValue: item.source) ?? .manual
                )
                context.insert(shoppingItem)
            }

            try context.save()

            print("✅ User data restored successfully")
            return true
        } catch {
            print("❌ Error restoring user data: \(error)")
            return false
        }
    }

    /// Check if user has any data (not sample data)
    static func hasUserData(context: ModelContext) -> Bool {
        do {
            let profiles = try context.fetch(FetchDescriptor<UserProfile>())
            return !profiles.isEmpty
        } catch {
            return false
        }
    }

    /// Clear backup from UserDefaults
    static func clearBackup() {
        UserDefaults.standard.removeObject(forKey: "userDataBackup")
    }

    /// Check if backup exists
    static func hasBackup() -> Bool {
        return UserDefaults.standard.data(forKey: "userDataBackup") != nil
    }

    // MARK: - Private Helpers

    private static func clearAllData(context: ModelContext) {
        do {
            try context.delete(model: UserProfile.self)
            try context.delete(model: NursingLog.self)
            try context.delete(model: SleepLog.self)
            try context.delete(model: DiaperLog.self)
            try context.delete(model: BottleFeedLog.self)
            try context.delete(model: GrowthMeasurement.self)
            try context.delete(model: MealLog.self)
            try context.delete(model: TriedFoodLog.self)
            try context.delete(model: Recipe.self)
            try context.delete(model: CustomFood.self)
            try context.delete(model: MealPlanEntry.self)
            try context.delete(model: ShoppingListItem.self)
            try context.save()
        } catch {
            print("Error clearing data: \(error)")
        }
    }

    // MARK: - Conversion Helpers

    private static func convertProfile(_ profile: UserProfile) -> UserProfileBackup {
        UserProfileBackup(
            id: profile.id,
            babyName: profile.babyName,
            birthDate: profile.birthDate,
            gender: profile.gender.rawValue,
            knownAllergies: profile.knownAllergies,
            preferredMode: profile.preferredMode?.rawValue,
            substitutedFoods: profile.substitutedFoods
        )
    }

    private static func convertNursingLog(_ log: NursingLog) -> NursingLogBackup {
        NursingLogBackup(
            id: log.id,
            timestamp: log.timestamp,
            duration: log.duration,
            side: log.side.rawValue
        )
    }

    private static func convertSleepLog(_ log: SleepLog) -> SleepLogBackup {
        SleepLogBackup(
            id: log.id,
            startTime: log.startTime,
            endTime: log.endTime,
            quality: log.quality.rawValue
        )
    }

    private static func convertDiaperLog(_ log: DiaperLog) -> DiaperLogBackup {
        DiaperLogBackup(
            id: log.id,
            timestamp: log.timestamp,
            type: log.type.rawValue
        )
    }

    private static func convertBottleLog(_ log: BottleFeedLog) -> BottleFeedLogBackup {
        BottleFeedLogBackup(
            id: log.id,
            timestamp: log.timestamp,
            amount: log.amount,
            feedType: log.feedType.rawValue,
            notes: log.notes
        )
    }

    private static func convertGrowthMeasurement(_ measurement: GrowthMeasurement) -> GrowthMeasurementBackup {
        GrowthMeasurementBackup(
            id: measurement.id,
            date: measurement.date,
            weight: measurement.weight,
            height: measurement.height,
            headCircumference: measurement.headCircumference,
            notes: measurement.notes
        )
    }

    private static func convertMealLog(_ log: MealLog) -> MealLogBackup {
        MealLogBackup(
            id: log.id,
            timestamp: log.timestamp,
            mealType: log.mealType.rawValue,
            foods: log.foods,
            feedingStrategy: log.feedingStrategy.rawValue,
            notes: log.notes
        )
    }

    private static func convertTriedFoodLog(_ log: TriedFoodLog) -> TriedFoodLogBackup {
        TriedFoodLogBackup(
            id: log.id,
            date: log.date,
            reaction: log.reaction,
            meal: log.meal.rawValue,
            allergyReaction: log.allergyReaction.rawValue,
            messyFaceImage: log.messyFaceImage,
            tryCount: log.tryCount,
            reactionSigns: log.reactionSigns,
            quantity: log.quantity
        )
    }

    private static func convertRecipe(_ recipe: Recipe) -> RecipeBackup {
        RecipeBackup(
            id: recipe.id,
            title: recipe.title,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            tags: recipe.tags,
            mealTypes: recipe.mealTypes.map { $0.rawValue },
            createdAt: recipe.createdAt
        )
    }

    private static func convertCustomFood(_ food: CustomFood) -> CustomFoodBackup {
        CustomFoodBackup(
            id: food.id,
            name: food.name,
            emoji: food.emoji,
            category: food.category.rawValue,
            allergens: food.allergens,
            nutritionHighlights: food.nutritionHighlights,
            howToServe: food.howToServe,
            chokeHazard: food.chokeHazard,
            color: food.color.rawValue,
            containedColors: food.containedColors.map { $0.rawValue },
            containedCategories: food.containedCategories.map { $0.rawValue },
            nutrients: food.nutrients.map { $0.rawValue }
        )
    }

    private static func convertMealPlanEntry(_ entry: MealPlanEntry) -> MealPlanEntryBackup {
        MealPlanEntryBackup(
            id: entry.id,
            date: entry.date,
            mealType: entry.mealType.rawValue,
            recipeId: entry.recipeId,
            recipeName: entry.recipeName
        )
    }

    private static func convertShoppingListItem(_ item: ShoppingListItem) -> ShoppingListItemBackup {
        ShoppingListItemBackup(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            category: item.category.rawValue,
            source: item.source.rawValue,
            isCompleted: item.isCompleted,
            createdAt: item.createdAt
        )
    }
}
