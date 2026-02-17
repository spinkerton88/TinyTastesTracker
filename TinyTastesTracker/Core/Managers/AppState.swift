//
//  AppState.swift
//  TinyTastesTracker
//
//  Refactored to Coordinator Pattern
//  AppState now coordinates domain-specific managers and Firestore data
//

import Foundation
import SwiftUI
import ActivityKit
import WidgetKit
import FirebaseAuth
import Observation

@MainActor
@Observable
class AppState {
    // MARK: - Authentication & Profile Management
    let authenticationManager: AuthenticationManager
    let profileManager = ProfileManager()
    let notificationManager = NotificationManager()
    let errorPresenter = ErrorPresenter()

    /// The signed-in user/parent account (fetched from Firestore)
    var userAccount: ParentProfile?

    /// Active user profile (The child profile we are tracking)
    var userProfile: ChildProfile? {
        profileManager.activeProfile
    }

    // MARK: - Domain Managers

    let newbornManager: NewbornManager
    let toddlerManager: ToddlerManager
    let recipeManager = RecipeManager()
    let healthManager = HealthManager()
    let aiServiceManager = AIServiceManager()
    let profileSharingManager: ProfileSharingManager

    // MARK: - Initialization

    init(authenticationManager: AuthenticationManager? = nil) {
        let authManager = authenticationManager ?? AuthenticationManager()
        self.authenticationManager = authManager
        self.profileSharingManager = ProfileSharingManager(authenticationManager: authManager)

        // Initialize managers with dependencies
        self.newbornManager = NewbornManager(notificationManager: notificationManager, errorPresenter: errorPresenter)
        self.toddlerManager = ToddlerManager(notificationManager: notificationManager)

        // Set up dependency injection
        recipeManager.aiServiceManager = aiServiceManager

        // Connect ToddlerManager to RecipeManager's food data
        toddlerManager.getAllKnownFoods = { [weak self] in
            self?.recipeManager.allKnownFoods ?? []
        }
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
    
    // Helper to get current Owner ID (Parent ID)
    var currentOwnerId: String? {
        authenticationManager.userSession?.uid
    }
    
    // Helper to get current Child ID
    var currentChildId: String? {
        userProfile?.id
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
            // UUID or String? RecipeManager usually stores objects.
            // Check by ID string match.
            if let recipe = recipeManager.recipes.first(where: { $0.id == uuidString || $0.id == foodId }) {
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
        let babyName = userProfile?.name ?? "the baby"
        let age = userProfile?.ageInMonths ?? 0

        switch currentMode {
        case .newborn:
            return "Baby: \(babyName), Age: \(age) months. Focus: Sleep schedule optimization and growth tracking."
        case .explorer:
            let tried = toddlerManager.foodLogs.map { resolveFoodName($0.foodName) }.joined(separator: ", ")
            return "Baby: \(babyName), Age: \(age) months. Focus: Introduction to solids and flavor exploration. Tastes Tried: \(tried)"
        case .toddler:
            let liked = toddlerManager.foodLogs.filter { $0.reaction >= 4 }.map { resolveFoodName($0.foodName) }.joined(separator: ", ")
            return "Toddler: \(babyName), Age: \(age) months. Focus: Nutrition balance (Iron, Calcium) and overcoming picky eating. Likes: \(liked)"
        }
    }

    // MARK: - Convenience Delegation Methods

    var geminiService: GeminiService {
        aiServiceManager.geminiService
    }

    // MARK: - Profile Sharing Delegates

    /// Invite a user to share a child profile
    func inviteUser(toProfile profileId: String, email: String) async throws -> ProfileInvitation {
        guard let currentUserId = currentOwnerId else {
            throw SharingError.notAuthorized
        }
        return try await profileSharingManager.createInvitation(
            childProfileId: profileId,
            invitedEmail: email,
            currentUserId: currentUserId
        )
    }

    /// Accept an invitation using a 6-digit code
    func acceptInvite(code: String) async throws {
        guard let userId = currentOwnerId else {
            throw SharingError.notAuthorized
        }
        try await profileSharingManager.acceptInvitation(
            inviteCode: code,
            userId: userId
        )
    }

    /// Revoke a user's access to a profile (owner only)
    func revokeAccess(fromProfile profileId: String, userId: String) async throws {
        guard let currentUserId = currentOwnerId else {
            throw SharingError.notAuthorized
        }
        try await profileSharingManager.revokeAccess(
            childProfileId: profileId,
            userId: userId,
            currentUserId: currentUserId
        )
    }

    /// Remove current user from a shared profile
    func removeSelfFromProfile(_ profileId: String) async throws {
        guard let userId = currentOwnerId else {
            throw SharingError.notAuthorized
        }
        try await profileSharingManager.removeSelfFromProfile(
            childProfileId: profileId,
            userId: userId
        )
    }

    /// Load users who have access to a profile
    func loadSharedUsers(forProfile profileId: String) async throws -> [SharedUser] {
        try await profileSharingManager.loadSharedUsers(forProfile: profileId)
    }

    /// Load invitations sent by current user
    func loadSentInvitations() async throws -> [ProfileInvitation] {
        guard let userId = currentOwnerId else { return [] }
        return try await profileSharingManager.loadSentInvitations(userId: userId)
    }

    /// Load pending invitations for a specific profile
    func loadPendingInvitations(forProfile profileId: String) async throws -> [ProfileInvitation] {
        try await profileSharingManager.loadPendingInvitations(forProfile: profileId)
    }

    /// Decline a received invitation
    func declineInvitation(_ invitationId: String) async throws {
        try await profileSharingManager.declineInvitation(invitationId: invitationId)
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

    var savedMedications: [SavedMedication] {
        newbornManager.savedMedications
    }

    var pediatricianSummaries: [PediatricianSummary] {
        healthManager.pediatricianSummaries
    }

    // Newborn Manager Delegates (Updated signatures)
    
    func saveNursingLog(startTime: Date, duration: TimeInterval, side: NursingSide) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.saveNursingLog(startTime: startTime, duration: duration, side: side, ownerId: ownerId, babyId: childId)
    }

    func saveSleepLog(start: Date, end: Date, quality: SleepQuality) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.saveSleepLog(start: start, end: end, quality: quality, ownerId: ownerId, babyId: childId)
    }

    func saveDiaperLog(type: DiaperType) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.saveDiaperLog(type: type, ownerId: ownerId, babyId: childId)
    }

    func saveBottleFeedLog(amount: Double, feedType: FeedingType, notes: String? = nil) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.saveBottleFeedLog(amount: amount, feedType: feedType, notes: notes, ownerId: ownerId, babyId: childId)
    }
    
    func savePumpingLog(leftBreastOz: Double, rightBreastOz: Double, notes: String? = nil) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.savePumpingLog(leftBreastOz: leftBreastOz, rightBreastOz: rightBreastOz, notes: notes, ownerId: ownerId, babyId: childId)
    }
    
    func saveMedicationLog(medicineName: String, babyWeight: Double, dosage: String, safetyInfo: String? = nil, notes: String? = nil) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.saveMedicationLog(medicineName: medicineName, babyWeight: babyWeight, dosage: dosage, safetyInfo: safetyInfo, notes: notes, ownerId: ownerId, babyId: childId)
    }

    func saveGrowthMeasurement(weight: Double?, height: Double?, headCircumference: Double?, notes: String? = nil) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.saveGrowthMeasurement(weight: weight, height: height, headCircumference: headCircumference, notes: notes, ownerId: ownerId, babyId: childId)
    }
    
    // MARK: - Update Delegate Methods
    
    func updateNursingLog(_ log: NursingLog) {
        newbornManager.updateNursingLog(log)
    }
    
    func updateSleepLog(_ log: SleepLog) {
        newbornManager.updateSleepLog(log)
    }
    
    func updateDiaperLog(_ log: DiaperLog) {
        newbornManager.updateDiaperLog(log)
    }
    
    func updateBottleFeedLog(_ log: BottleFeedLog) {
        newbornManager.updateBottleFeedLog(log)
    }
    
    func updatePumpingLog(_ log: PumpingLog) {
        newbornManager.updatePumpingLog(log)
    }
    
    func updateMedicationLog(_ log: MedicationLog) {
        newbornManager.updateMedicationLog(log)
    }
    
    func updateGrowthMeasurement(_ measurement: GrowthMeasurement) {
        newbornManager.updateGrowthMeasurement(measurement)
    }
    
    // Delete methods
    func deleteNursingLog(_ log: NursingLog) {
        newbornManager.deleteNursingLog(log)
    }
    
    func deleteSleepLog(_ log: SleepLog) {
        newbornManager.deleteSleepLog(log)
    }
    
    func deleteDiaperLog(_ log: DiaperLog) {
        newbornManager.deleteDiaperLog(log)
    }
    
    func deleteBottleFeedLog(_ log: BottleFeedLog) {
        newbornManager.deleteBottleFeedLog(log)
    }
    
    func deletePumpingLog(_ log: PumpingLog) {
        newbornManager.deletePumpingLog(log)
    }
    
    func deleteMedicationLog(_ log: MedicationLog) {
        newbornManager.deleteMedicationLog(log)
    }
    
    func deleteGrowthMeasurement(_ measurement: GrowthMeasurement) {
        newbornManager.deleteGrowthMeasurement(measurement)
    }

    // MARK: - Saved Medications

    func saveSavedMedication(medicineName: String, defaultDosage: String, notes: String? = nil) async throws {
        guard let ownerId = currentOwnerId else {
            throw FirebaseError.invalidData
        }
        try await newbornManager.saveSavedMedication(medicineName: medicineName, defaultDosage: defaultDosage, notes: notes, ownerId: ownerId)
    }

    func updateSavedMedicationUsage(_ medication: SavedMedication) {
        newbornManager.updateSavedMedicationUsage(medication)
    }

    func deleteSavedMedication(_ medication: SavedMedication) {
        newbornManager.deleteSavedMedication(medication)
    }

    func analyzeMedicationBottle(image: UIImage) async throws -> MedicationBottleAnalysis {
        try await aiServiceManager.geminiService.analyzeMedicationBottle(image: image)
    }

    var last24HourStats: (feedingCount: Int, diaperCount: Int, totalSleepHours: Double) {
        newbornManager.last24HourStats
    }
    
    var todayStats: (wetDiapers: Int, dirtyDiapers: Int, feedingCount: Int, sleepHours: Double) {
        newbornManager.todayStats
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
        newbornManager.startSleepActivity(babyName: userProfile?.name ?? "Baby")
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

    func saveFoodLog(_ log: TriedFoodLog) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await toddlerManager.saveFoodLog(log, ownerId: ownerId, childId: childId)
    }

    func saveMealLog(_ log: MealLog) async throws {
        guard let ownerId = currentOwnerId, let childId = currentChildId else {
            throw FirebaseError.invalidData
        }
        try await toddlerManager.saveMealLog(log, ownerId: ownerId, childId: childId)
    }

    func deleteFoodLog(_ log: TriedFoodLog) {
        toddlerManager.deleteFoodLog(log)
    }

    func deleteMealLog(_ log: MealLog) {
        toddlerManager.deleteMealLog(log)
    }

    func unmarkFoodAsTried(_ foodId: String) {
        toddlerManager.unmarkFoodAsTried(foodId)
    }
    
    func undoUnmarkFood(_ foodId: String) {
        toddlerManager.undoUnmarkFood(foodId)
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
        protein: Int
    ) {
        guard let ownerId = currentOwnerId, let childId = currentChildId else { return }
        toddlerManager.updateNutrientGoals(
            iron: iron,
            calcium: calcium,
            vitaminC: vitaminC,
            omega3: omega3,
            protein: protein,
            ownerId: ownerId,
            childId: childId
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

    func shouldShowAllergenMonitoring(for foodId: String) -> (foodName: String, allergenName: String, allergyRisk: AllergyRisk)? {
        guard let food = recipeManager.allKnownFoods.first(where: { $0.id == foodId }),
              !food.allergens.isEmpty else { return nil }

        // Return (foodName, primaryAllergen, allergyRisk) for ANY allergen
        let primaryAllergen = food.allergens.first!
        return (food.name, primaryAllergen, food.allergyRisk)
    }

    // Recipe Manager Delegates
    var allKnownFoods: [FoodItem] {
        recipeManager.allKnownFoods
    }

    func saveRecipe(_ recipe: Recipe) async throws {
        guard let ownerId = currentOwnerId else {
            throw FirebaseError.invalidData
        }
        try await recipeManager.saveRecipe(recipe, ownerId: ownerId)
    }

    func deleteRecipe(_ recipe: Recipe) {
        recipeManager.deleteRecipe(recipe)
    }

    func saveCustomFood(_ food: CustomFood) async throws {
        guard let ownerId = currentOwnerId else {
            throw FirebaseError.invalidData
        }
        try await recipeManager.saveCustomFood(food, ownerId: ownerId)
    }

    /// Save a custom food with an image - uploads to Firebase Storage for cross-device sync
    func saveCustomFoodWithImage(_ food: CustomFood, image: UIImage) async throws -> CustomFood {
        guard let ownerId = currentOwnerId else {
            throw NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "No owner ID"])
        }
        return try await recipeManager.saveCustomFoodWithImage(food, image: image, ownerId: ownerId)
    }

    func createCustomFoodFromRecipe(_ recipe: Recipe) -> CustomFood {
        guard let ownerId = currentOwnerId else { return recipeManager.customFoods.first ?? CustomFood.empty } // Fallback shouldn't happen
        return recipeManager.createCustomFoodFromRecipe(recipe, ownerId: ownerId)
    }

    func addMealPlanEntry(_ entry: MealPlanEntry) async throws {
        try await recipeManager.addMealPlanEntry(entry)
    }

    func removeMealPlanEntry(_ entry: MealPlanEntry) async throws {
        try await recipeManager.deleteMealPlanEntry(entry)
    }

    func getMealPlanEntries(for date: Date) -> [MealType: [MealPlanEntry]] {
        guard let childId = currentChildId else { return [:] }

        // Get all entries from RecipeManager and filter by current child
        let allEntries = recipeManager.getMealPlanEntries(for: date)

        // Filter each meal type's entries by childId
        var filteredEntries: [MealType: [MealPlanEntry]] = [:]
        for (mealType, entries) in allEntries {
            let childEntries = entries.filter { $0.childId == childId }
            if !childEntries.isEmpty {
                filteredEntries[mealType] = childEntries
            }
        }

        return filteredEntries
    }

    func addShoppingListItem(_ item: ShoppingListItem) async throws {
        try await recipeManager.addShoppingListItem(item)
    }

    func toggleShoppingItemComplete(_ item: ShoppingListItem) async throws {
        try await recipeManager.toggleShoppingItemComplete(item)
    }

    func removeShoppingListItem(_ item: ShoppingListItem) {
        recipeManager.deleteShoppingListItem(item)
    }

    func generateShoppingListFromMealPlan() {
        guard let ownerId = currentOwnerId else { return }
        recipeManager.generateShoppingListFromMealPlan(ownerId: ownerId)
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
            babyName: userProfile?.name ?? "Unknown",
            ageInMonths: userProfile?.ageInMonths ?? 0,
            foodLogs: toddlerManager.foodLogs,
            allKnownFoods: recipeManager.allKnownFoods
        )
    }

    func predictNextSleepWindow() async throws -> SleepPredictionResponse {
        let childName = userProfile?.name ?? "Baby"
        let prediction = try await aiServiceManager.predictNextSleepWindow(
            sleepLogs: newbornManager.sleepLogs,
            ageInMonths: userProfile?.ageInMonths ?? 3,
            childName: childName
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
        // Map logs to ids
        // Ensure we check 'foodName' is the ID in toddler logs refactor
        let triedIds = toddlerManager.foodLogs.map { $0.foodName }
        
        return try await aiServiceManager.suggestFoodsForNutrient(
            nutrient,
            ageInMonths: userProfile?.ageInMonths ?? 24,
            triedFoodIds: triedIds
        )
    }

    func generateFlavorPairings() async throws -> FlavorPairingResponse {
        try await aiServiceManager.generateFlavorPairings(
            triedFoods: toddlerManager.foodLogs,
            childName: userProfile?.name ?? "Baby",
            ageInMonths: userProfile?.ageInMonths ?? 12
        )
    }
    
    // MARK: - Notification Management
    
    func rescheduleFeedNotification() {
        guard let babyName = userProfile?.name else { return }
        Task {
            await newbornManager.scheduleFeedReminderIfEnabled(childName: babyName)
        }
    }

    // MARK: - Data Loading

    func loadData(forUser userId: String) {
        // Fetch ParentProfile (User Account) if needed, or just rely on Auth.
        // If we store extended account info:
        Task {
            // Load ParentProfile logic (if needed)
            // self.userAccount = try? await FirestoreService<ParentProfile>...
        }

        // Load all child profiles
        profileManager.loadProfiles(userId: userId)
        
        // Listen for profile changes to reload toddler data
        // ProfileManager posts notification, or we observe activeProfileId.
        // Since we coordinate here, we should perhaps hook into ProfileManager.
        
        // Load data for managers
        newbornManager.loadData(ownerId: userId)
        recipeManager.loadData(ownerId: userId)
        healthManager.loadData(ownerId: userId)
        
        // Toddler data is child-specific. We need to load it when active profile is ready.
        // We can add a listener to activeProfileId or activeProfile changes.
        // For now, load default logic in updateToddlerData().
    }
    
    /// Called when switching active child profile
    func updateActiveChildData(childId: String?) {
        guard let ownerId = currentOwnerId, let childId = childId else {
             // Clear toddler data if no child?
             return
        }
        toddlerManager.loadData(ownerId: ownerId, childId: childId)
    }
}
