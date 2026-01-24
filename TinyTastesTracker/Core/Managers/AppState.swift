//
//  AppState.swift
//  TinyTastesTracker
//
//  Refactored to Coordinator Pattern
//  AppState now coordinates domain-specific managers instead of handling all logic

import Foundation
import SwiftUI
import SwiftData
import ActivityKit
import WidgetKit

@Observable
class AppState {
    // MARK: - Profile Management
    let profileManager = ProfileManager()

    /// The signed-in user/parent account
    var userAccount: ParentProfile?

    /// Active user profile (backward compatible property)
    var userProfile: UserProfile? {
        profileManager.activeProfile
    }

    // MARK: - Domain Managers
    let newbornManager = NewbornManager()
    let toddlerManager = ToddlerManager()
    let recipeManager = RecipeManager()
    let aiServiceManager = AIServiceManager()

    // MARK: - Initialization

    init() {
        // Set up dependency injection
        recipeManager.aiServiceManager = aiServiceManager
    }

    // MARK: - App-wide Properties

    var currentMode: AppMode {
        userProfile?.currentMode ?? .explorer
    }

    var themeColor: Color {
        switch currentMode {
        case .newborn: return Constants.newbornColor
        case .explorer: return Constants.explorerColor
        case .toddler: return Constants.toddlerColor
        }
    }

    var geminiApiKey: String? {
        guard let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["API_KEY"] as? String else {
            return nil
        }
        return apiKey
    }

    // MARK: - Sage Context (combines data from multiple managers)
    
    /// Helper to resolve food/recipe ID to display name
    private func resolveFoodName(_ foodId: String) -> String {
        // Check if it's a recipe ID (format: RECIPE_UUID)
        if foodId.hasPrefix("RECIPE_") {
            let uuidString = String(foodId.dropFirst(7)) // Remove "RECIPE_" prefix
            if let uuid = UUID(uuidString: uuidString),
               let recipe = recipeManager.recipes.first(where: { $0.id == uuid }) {
                return recipe.title
            }
        }
        
        // Check if it's a known food from allKnownFoods
        if let food = recipeManager.allKnownFoods.first(where: { $0.id == foodId }) {
            return food.name
        }
        
        // Fall back to the ID itself, but make it more readable
        return foodId.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var sageContext: String {
        let babyName = userProfile?.babyName ?? "the baby"
        let age = userProfile?.ageInMonths ?? 0

        switch currentMode {
        case .newborn:
            return "Baby: \(babyName), Age: \(age) months. Focus: Sleep schedule optimization and growth tracking."
        case .explorer:
            let tried = toddlerManager.foodLogs.map { resolveFoodName($0.id) }.joined(separator: ", ")
            return "Baby: \(babyName), Age: \(age) months. Focus: Introduction to solids and flavor exploration. Tastes Tried: \(tried)"
        case .toddler:
            let liked = toddlerManager.foodLogs.filter { $0.reaction >= 4 }.map { resolveFoodName($0.id) }.joined(separator: ", ")
            return "Toddler: \(babyName), Age: \(age) months. Focus: Nutrition balance (Iron, Calcium) and overcoming picky eating. Likes: \(liked)"
        }
    }

    // MARK: - Convenience Delegation Methods (for backward compatibility)

    // Direct property access delegation
    var geminiService: GeminiService {
        aiServiceManager.geminiService
    }

    var mealLogs: [MealLog] {
        toddlerManager.mealLogs
    }

    var foodLogs: [TriedFoodLog] {
        toddlerManager.foodLogs
    }

    var recipes: [Recipe] {
        recipeManager.recipes
    }

    var customFoods: [CustomFood] {
        recipeManager.customFoods
    }

    var mealPlanEntries: [MealPlanEntry] {
        recipeManager.mealPlanEntries
    }

    var shoppingListItems: [ShoppingListItem] {
        recipeManager.shoppingListItems
    }

    var nursingLogs: [NursingLog] {
        newbornManager.nursingLogs
    }

    var sleepLogs: [SleepLog] {
        newbornManager.sleepLogs
    }

    var diaperLogs: [DiaperLog] {
        newbornManager.diaperLogs
    }

    var bottleFeedLogs: [BottleFeedLog] {
        newbornManager.bottleFeedLogs
    }
    
    var bottleLogs: [BottleFeedLog] {
        bottleFeedLogs
    }

    var growthMeasurements: [GrowthMeasurement] {
        newbornManager.growthMeasurements
    }
    
    var pumpingLogs: [PumpingLog] {
        newbornManager.pumpingLogs
    }
    
    var medicationLogs: [MedicationLog] {
        newbornManager.medicationLogs
    }

    // Newborn Manager Delegates
    func saveNursingLog(startTime: Date, duration: TimeInterval, side: NursingSide, context: ModelContext) {
        newbornManager.saveNursingLog(startTime: startTime, duration: duration, side: side, context: context, userProfile: userProfile)
    }

    func saveSleepLog(start: Date, end: Date, quality: SleepQuality, context: ModelContext) {
        newbornManager.saveSleepLog(start: start, end: end, quality: quality, context: context)
    }

    func saveDiaperLog(type: DiaperType, context: ModelContext) {
        newbornManager.saveDiaperLog(type: type, context: context)
    }

    func saveBottleFeedLog(amount: Double, feedType: FeedingType, notes: String? = nil, context: ModelContext) {
        newbornManager.saveBottleFeedLog(amount: amount, feedType: feedType, notes: notes, context: context, userProfile: userProfile)
    }
    
    func savePumpingLog(leftBreastOz: Double, rightBreastOz: Double, notes: String? = nil, context: ModelContext) {
        newbornManager.savePumpingLog(leftBreastOz: leftBreastOz, rightBreastOz: rightBreastOz, notes: notes, context: context)
    }
    
    func saveMedicationLog(medicineName: String, babyWeight: Double, dosage: String, safetyInfo: String? = nil, notes: String? = nil, context: ModelContext) {
        newbornManager.saveMedicationLog(medicineName: medicineName, babyWeight: babyWeight, dosage: dosage, safetyInfo: safetyInfo, notes: notes, context: context)
    }

    func saveGrowthMeasurement(weight: Double?, height: Double?, headCircumference: Double?, notes: String? = nil, context: ModelContext) {
        newbornManager.saveGrowthMeasurement(weight: weight, height: height, headCircumference: headCircumference, notes: notes, context: context)
    }
    
    // Delete methods
    func deleteNursingLog(_ log: NursingLog, context: ModelContext) {
        newbornManager.deleteNursingLog(log, context: context)
    }
    
    func deleteSleepLog(_ log: SleepLog, context: ModelContext) {
        newbornManager.deleteSleepLog(log, context: context)
    }
    
    func deleteDiaperLog(_ log: DiaperLog, context: ModelContext) {
        newbornManager.deleteDiaperLog(log, context: context)
    }
    
    func deleteBottleFeedLog(_ log: BottleFeedLog, context: ModelContext) {
        newbornManager.deleteBottleFeedLog(log, context: context)
    }
    
    func deletePumpingLog(_ log: PumpingLog, context: ModelContext) {
        newbornManager.deletePumpingLog(log, context: context)
    }
    
    func deleteMedicationLog(_ log: MedicationLog, context: ModelContext) {
        newbornManager.deleteMedicationLog(log, context: context)
    }
    
    func deleteGrowthMeasurement(_ measurement: GrowthMeasurement, context: ModelContext) {
        newbornManager.deleteGrowthMeasurement(measurement, context: context)
    }

    var last24HourStats: (feedingCount: Int, diaperCount: Int, totalSleepHours: Double) {
        newbornManager.last24HourStats
    }

    func getDailyFeedingData(days: Int = 7) -> [DailyFeedingData] {
        newbornManager.getDailyFeedingData(days: days)
    }

    func getWeeklySleepData() -> [DailySleepData] {
        newbornManager.getWeeklySleepData()
    }

    func getFeedingComparison(period: ComparisonPeriod) -> FeedingComparison {
        newbornManager.getFeedingComparison(period: period)
    }

    func getSleepComparison(period: ComparisonPeriod) -> SleepComparison {
        newbornManager.getSleepComparison(period: period)
    }

    @MainActor
    func startSleepActivity() {
        newbornManager.startSleepActivity(babyName: userProfile?.babyName ?? "Baby")
    }

    @MainActor
    func stopSleepActivity() {
        newbornManager.stopSleepActivity()
    }

    // Toddler Manager Delegates
    var triedFoodsCount: Int {
        toddlerManager.triedFoodsCount
    }

    func isFoodTried(_ foodId: String) -> Bool {
        toddlerManager.isFoodTried(foodId)
    }

    func saveFoodLog(_ log: TriedFoodLog, context: ModelContext) {
        toddlerManager.saveFoodLog(log, context: context)
    }

    func saveMealLog(_ log: MealLog, context: ModelContext) {
        toddlerManager.saveMealLog(log, context: context)
    }

    func deleteFoodLog(_ log: TriedFoodLog, context: ModelContext) {
        toddlerManager.deleteFoodLog(log, context: context)
    }

    func deleteMealLog(_ log: MealLog, context: ModelContext) {
        toddlerManager.deleteMealLog(log, context: context)
    }

    func unmarkFoodAsTried(_ foodId: String, context: ModelContext) {
        toddlerManager.unmarkFoodAsTried(foodId, context: context)
    }
    
    func undoUnmarkFood(_ foodId: String, context: ModelContext) {
        toddlerManager.undoUnmarkFood(foodId, context: context)
    }

    func filteredFoods(searchText: String, category: FoodCategory?, showOnlyTried: Bool?, from foods: [FoodItem]) -> [FoodItem] {
        toddlerManager.filteredFoods(searchText: searchText, category: category, showOnlyTried: showOnlyTried, from: foods)
    }

    func categoryProgress(_ category: FoodCategory) -> (tried: Int, total: Int) {
        toddlerManager.categoryProgress(category)
    }

    var rainbowProgress: [FoodColor: Int] {
        toddlerManager.rainbowProgress
    }

    var weeklyNutritionSummary: [Nutrient: Int] {
        toddlerManager.weeklyNutritionSummary
    }

    func detectNutrientGaps() -> [Nutrient] {
        toddlerManager.detectNutrientGaps()
    }

    func updateNutrientGoals(
        iron: Int,
        calcium: Int,
        vitaminC: Int,
        omega3: Int,
        protein: Int,
        context: ModelContext
    ) {
        guard let userId = userProfile?.id else { return }
        toddlerManager.updateNutrientGoals(
            iron: iron,
            calcium: calcium,
            vitaminC: vitaminC,
            omega3: omega3,
            protein: protein,
            userId: userId,
            context: context
        )
    }

    func getCategoryDistribution() -> [CategoryDistribution] {
        toddlerManager.getCategoryDistribution()
    }

    func getNutrientProgress() -> [NutrientProgress] {
        toddlerManager.getNutrientProgress()
    }

    func getColorProgress() -> [ColorProgress] {
        toddlerManager.getColorProgress()
    }
    
    func checkForHighRiskAllergen(foodId: String) -> (foodName: String, allergenName: String)? {
        toddlerManager.checkForHighRiskAllergen(foodId: foodId)
    }

    // Recipe Manager Delegates
    var allKnownFoods: [FoodItem] {
        recipeManager.allKnownFoods
    }

    func saveRecipe(_ recipe: Recipe, context: ModelContext) {
        recipeManager.saveRecipe(recipe, context: context)
    }

    func deleteRecipe(_ recipe: Recipe, context: ModelContext) {
        recipeManager.deleteRecipe(recipe, context: context)
    }

    func saveCustomFood(_ food: CustomFood, context: ModelContext) {
        recipeManager.saveCustomFood(food, context: context)
    }

    func createCustomFoodFromRecipe(_ recipe: Recipe, context: ModelContext) -> CustomFood {
        recipeManager.createCustomFoodFromRecipe(recipe, context: context)
    }

    func addMealPlanEntry(_ entry: MealPlanEntry, context: ModelContext) {
        recipeManager.addMealPlanEntry(entry, context: context)
    }

    func removeMealPlanEntry(_ entry: MealPlanEntry, context: ModelContext) {
        recipeManager.removeMealPlanEntry(entry, context: context)
    }

    func getMealPlanEntries(for date: Date) -> [MealType: MealPlanEntry] {
        recipeManager.getMealPlanEntries(for: date)
    }

    func addShoppingListItem(_ item: ShoppingListItem, context: ModelContext) {
        recipeManager.addShoppingListItem(item, context: context)
    }

    func toggleShoppingItemComplete(_ item: ShoppingListItem) {
        recipeManager.toggleShoppingItemComplete(item)
    }

    func removeShoppingListItem(_ item: ShoppingListItem, context: ModelContext) {
        recipeManager.removeShoppingListItem(item, context: context)
    }

    func generateShoppingListFromMealPlan(context: ModelContext) {
        recipeManager.generateShoppingListFromMealPlan(context: context)
    }

    // AI Service Manager Delegates
    func analyzeCustomFood(name: String) async throws -> CustomFoodDetails {
        try await aiServiceManager.analyzeCustomFood(name: name)
    }

    func analyzePackage(image: UIImage) async throws -> CustomFoodDetails {
        try await aiServiceManager.analyzePackage(image: image)
    }

    func lookupBarcode(_ code: String) async throws -> ProductInfo {
        try await aiServiceManager.lookupBarcode(code)
    }

    func identifyFood(from image: UIImage) async throws -> String {
        try await aiServiceManager.identifyFood(from: image)
    }

    @MainActor
    func generateRecipe(ingredients: [String]) async throws -> Recipe {
        try await aiServiceManager.generateRecipe(
            ingredients: ingredients,
            ageInMonths: userProfile?.ageInMonths ?? 12
        )
    }

    func askSage(question: String) async throws -> String {
        try await aiServiceManager.askSage(
            question: question,
            babyName: userProfile?.babyName ?? "Unknown",
            ageInMonths: userProfile?.ageInMonths ?? 0,
            foodLogs: toddlerManager.foodLogs,
            allKnownFoods: recipeManager.allKnownFoods
        )
    }

    func predictNextSleepWindow() async throws -> SleepPredictionResponse {
        let prediction = try await aiServiceManager.predictNextSleepWindow(
            sleepLogs: newbornManager.sleepLogs,
            ageInMonths: userProfile?.ageInMonths ?? 3
        )

        // Save prediction to widget
        let widgetPrediction = SleepPredictionData(
            predictionStatus: prediction.predictionStatus,
            nextSweetSpotStart: prediction.nextSweetSpotStart,
            nextSweetSpotEnd: prediction.nextSweetSpotEnd,
            confidence: prediction.confidence,
            reasoning: prediction.reasoning
        )
        WidgetDataManager.saveSleepPrediction(widgetPrediction)

        return prediction
    }

    func generatePickyEaterStrategy(enemyFoodId: String, safeFoodId: String, preferredStrategy: String? = nil) async throws -> PickyEaterStrategyResponse {
        try await aiServiceManager.generatePickyEaterStrategy(
            enemyFoodId: enemyFoodId,
            safeFoodId: safeFoodId,
            preferredStrategy: preferredStrategy,
            ageInMonths: userProfile?.ageInMonths ?? 24,
            allKnownFoods: recipeManager.allKnownFoods
        )
    }

    func suggestFoodsForNutrient(_ nutrient: Nutrient) async throws -> [NutrientFoodSuggestion] {
        try await aiServiceManager.suggestFoodsForNutrient(
            nutrient,
            ageInMonths: userProfile?.ageInMonths ?? 24,
            triedFoodIds: toddlerManager.foodLogs.map { $0.id }
        )
    }

    func generateFlavorPairings() async throws -> FlavorPairingResponse {
        try await aiServiceManager.generateFlavorPairings(
            triedFoods: toddlerManager.foodLogs,
            childName: userProfile?.babyName ?? "Baby"
        )
    }
    
    // MARK: - Notification Management
    
    func rescheduleFeedNotification() {
        guard let babyName = userProfile?.babyName else { return }
        Task {
            await newbornManager.scheduleFeedReminderIfEnabled(childName: babyName)
        }
    }

    // MARK: - Data Loading (coordinates all managers)

    func loadData(context: ModelContext) {
        // Load User Account
        let accountDescriptor = FetchDescriptor<ParentProfile>()
        if let accounts = try? context.fetch(accountDescriptor), let account = accounts.first {
            self.userAccount = account
        }

        // Load all profiles and set active profile
        profileManager.loadProfiles(context: context)

        // Delegate loading to each manager
        newbornManager.loadData(context: context)
        toddlerManager.loadData(context: context, userId: userProfile?.id)
        recipeManager.loadData(context: context)

        // Update toddler manager with known foods from recipe manager
        toddlerManager.updateKnownFoods(recipeManager.allKnownFoods)
    }
}
