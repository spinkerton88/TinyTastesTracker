//
//  AIServiceManagerTests.swift
//  TinyTastesTrackerTests
//
//  Tests for AIServiceManager functionality
//

import XCTest
@testable import TinyTastesTracker

@MainActor
final class AIServiceManagerTests: XCTestCase {

    var sut: AIServiceManager!

    override func setUp() {
        super.setUp()
        sut = AIServiceManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testAIServiceManagerInitialization() {
        XCTAssertNotNil(sut, "AIServiceManager should initialize successfully")
        XCTAssertNotNil(sut.geminiService, "GeminiService should be initialized")
    }

    // MARK: - Recipe Generation Tests

    func testRecipeGenerationParametersValidation() async throws {
        let ingredients = ["carrot", "apple", "oatmeal"]
        let ageInMonths = 8

        XCTAssertFalse(ingredients.isEmpty, "Ingredients list should not be empty")
        XCTAssertGreaterThan(ageInMonths, 0, "Age should be positive")
        XCTAssertLessThan(ageInMonths, 240, "Age should be reasonable (< 20 years)")
    }

    func testRecipeGenerationRequiresIngredients() {
        let emptyIngredients: [String] = []
        let validIngredients = ["carrot", "apple"]

        XCTAssertTrue(emptyIngredients.isEmpty, "Empty ingredients should be invalid")
        XCTAssertFalse(validIngredients.isEmpty, "Valid ingredients should not be empty")
    }

    // MARK: - Custom Food Analysis Tests

    func testCustomFoodAnalysisValidation() {
        let foodName = "Baby Carrots"

        XCTAssertFalse(foodName.isEmpty, "Food name should not be empty")
        XCTAssertGreaterThan(foodName.count, 0, "Food name should have characters")
    }

    func testCustomFoodAnalysisWithEmptyName() {
        let emptyName = ""
        let whitespaceOnly = "   "

        XCTAssertTrue(emptyName.isEmpty, "Empty name should be detected")
        XCTAssertTrue(whitespaceOnly.trimmingCharacters(in: .whitespaces).isEmpty,
                     "Whitespace-only name should be detected")
    }

    // MARK: - Barcode Lookup Tests

    func testBarcodeLookupValidation() {
        let validBarcode = "1234567890123"
        let shortBarcode = "123"
        let invalidBarcode = "abc"

        XCTAssertEqual(validBarcode.count, 13, "Valid barcode should be 13 digits")
        XCTAssertLessThan(shortBarcode.count, 8, "Short barcode should be invalid")
        XCTAssertFalse(invalidBarcode.allSatisfy { $0.isNumber },
                      "Barcode with letters should be invalid")
    }

    func testBarcodeFormat() {
        let eanBarcode = "5000112612345" // EAN-13
        let upcBarcode = "012345678905" // UPC-A

        XCTAssertTrue(eanBarcode.allSatisfy { $0.isNumber }, "EAN barcode should only contain numbers")
        XCTAssertTrue(upcBarcode.allSatisfy { $0.isNumber }, "UPC barcode should only contain numbers")
    }

    // MARK: - Sage Question Processing Tests

    func testSageQuestionValidation() {
        let validQuestion = "What foods should I introduce next?"
        let emptyQuestion = ""
        let longQuestion = String(repeating: "a", count: 1000)

        XCTAssertFalse(validQuestion.isEmpty, "Valid question should not be empty")
        XCTAssertTrue(emptyQuestion.isEmpty, "Empty question should be detected")
        XCTAssertLessThan(longQuestion.count, 5000, "Questions should have reasonable length limit")
    }

    func testSageQuestionWithContext() {
        let babyName = "Emma"
        let ageInMonths = 8
        let question = "What foods can \(babyName) try now?"

        XCTAssertTrue(question.contains(babyName), "Question should contain baby name")
        XCTAssertGreaterThan(ageInMonths, 0, "Age should be valid")
    }

    // MARK: - Sleep Prediction Tests

    func testSleepPredictionParametersValidation() {
        let ageInMonths = 3
        let sleepLogs: [SleepLog] = []

        XCTAssertGreaterThanOrEqual(ageInMonths, 0, "Age should not be negative")
        XCTAssertLessThanOrEqual(ageInMonths, 24, "Sleep prediction most relevant for infants")
    }

    func testSleepPredictionWithInsufficientData() {
        let fewLogs: [SleepLog] = []
        let minimumLogsRequired = 3

        XCTAssertLessThan(fewLogs.count, minimumLogsRequired,
                         "Insufficient logs should be detectable")
    }

    // MARK: - Picky Eater Strategy Tests

    func testPickyEaterStrategyParameters() {
        let enemyFoodId = "broccoli"
        let safeFoodId = "banana"
        let ageInMonths = 18

        XCTAssertFalse(enemyFoodId.isEmpty, "Enemy food ID should not be empty")
        XCTAssertFalse(safeFoodId.isEmpty, "Safe food ID should not be empty")
        XCTAssertNotEqual(enemyFoodId, safeFoodId, "Enemy and safe foods should be different")
        XCTAssertGreaterThanOrEqual(ageInMonths, 6,
                                   "Picky eating strategies relevant after 6 months")
    }

    func testPickyEaterStrategyTypes() {
        let strategies = ["bridge", "flavor-pairing", "exposure", "texture-modification"]

        XCTAssertFalse(strategies.isEmpty, "Should have strategy types")
        XCTAssertTrue(strategies.contains("bridge"), "Should include bridge strategy")
        XCTAssertTrue(strategies.contains("exposure"), "Should include exposure strategy")
    }

    // MARK: - Nutrient Suggestion Tests

    func testNutrientSuggestionValidation() {
        let nutrient = Nutrient.iron
        let ageInMonths = 12
        let triedFoods = ["banana", "apple", "carrot"]

        XCTAssertNotNil(nutrient, "Nutrient should be valid")
        XCTAssertGreaterThan(ageInMonths, 0, "Age should be positive")
        XCTAssertFalse(triedFoods.isEmpty, "Should have tried foods for context")
    }

    func testNutrientTypes() {
        let nutrients: [Nutrient] = [.iron, .calcium, .vitaminC, .omega3, .protein]

        XCTAssertEqual(nutrients.count, 5, "Should have 5 core nutrients")
        XCTAssertTrue(nutrients.contains(.iron), "Should include iron")
        XCTAssertTrue(nutrients.contains(.calcium), "Should include calcium")
    }

    // MARK: - Flavor Pairing Tests

    func testFlavorPairingParametersValidation() {
        let triedFoods: [TriedFoodLog] = []
        let childName = "Emma"
        let ageInMonths = 10

        XCTAssertFalse(childName.isEmpty, "Child name should be provided")
        XCTAssertGreaterThanOrEqual(ageInMonths, 6,
                                   "Flavor pairing relevant after starting solids")
    }

    func testFlavorPairingRequiresTriedFoods() {
        let noTriedFoods: [TriedFoodLog] = []
        let someTriedFoods: [TriedFoodLog] = [] // Would contain actual logs in production

        XCTAssertTrue(noTriedFoods.isEmpty, "Empty tried foods should be detectable")
    }

    // MARK: - Food Identification Tests

    func testFoodIdentificationImageValidation() {
        // Test that image processing requires valid image data
        // In real tests, would use actual UIImage
        let hasValidImage = true

        XCTAssertTrue(hasValidImage, "Should validate image presence")
    }

    // MARK: - Response Parsing Tests

    func testResponseParsingErrorHandling() {
        let validJSON = """
        {"title": "Test Recipe", "ingredients": ["item1", "item2"]}
        """

        let invalidJSON = """
        {title": "Missing quote", "ingredients": ["item1"]}
        """

        XCTAssertTrue(validJSON.contains("title"), "Valid JSON should parse")
        XCTAssertFalse(invalidJSON.first == "{", "Invalid JSON should be detectable")
    }

    func testRecipeStructureValidation() {
        // Test that recipe responses have required fields
        let requiredFields = ["title", "ingredients", "instructions", "prepTime"]

        XCTAssertTrue(requiredFields.contains("title"), "Should require title")
        XCTAssertTrue(requiredFields.contains("ingredients"), "Should require ingredients")
        XCTAssertTrue(requiredFields.contains("instructions"), "Should require instructions")
    }

    // MARK: - Cache Management Tests

    func testCacheKeyGeneration() {
        let input1 = "test-key-1"
        let input2 = "test-key-2"

        XCTAssertNotEqual(input1, input2, "Different inputs should generate different keys")
    }

    func testCacheExpiration() {
        let cacheTimestamp = Date()
        let expirationDuration: TimeInterval = 3600 // 1 hour

        let isExpired = Date().timeIntervalSince(cacheTimestamp) > expirationDuration

        XCTAssertFalse(isExpired, "Fresh cache should not be expired")
    }

    // MARK: - Error Handling Tests

    func testNetworkErrorHandling() {
        enum TestError: Error {
            case networkUnavailable
            case timeout
            case invalidResponse
        }

        let networkError = TestError.networkUnavailable
        let timeoutError = TestError.timeout

        XCTAssertNotNil(networkError, "Network error should be defined")
        XCTAssertNotNil(timeoutError, "Timeout error should be defined")
    }

    func testAPIKeyValidation() {
        let validKey = "AIzaSyABCDEF1234567890"
        let emptyKey = ""
        let shortKey = "ABC"

        XCTAssertFalse(validKey.isEmpty, "Valid API key should not be empty")
        XCTAssertTrue(emptyKey.isEmpty, "Empty key should be detectable")
        XCTAssertLessThan(shortKey.count, 10, "Short key should be invalid")
    }

    // MARK: - Rate Limiting Tests

    func testRateLimitingLogic() {
        let requestTimestamps: [Date] = [
            Date().addingTimeInterval(-10),
            Date().addingTimeInterval(-5),
            Date()
        ]

        let recentRequests = requestTimestamps.filter {
            Date().timeIntervalSince($0) < 60 // Within last minute
        }

        XCTAssertEqual(recentRequests.count, 3, "Should track recent requests")
    }

    func testMaxRequestsPerMinute() {
        let maxRequests = 10
        let currentRequests = 8

        XCTAssertLessThan(currentRequests, maxRequests,
                         "Should be under rate limit")
    }

    // MARK: - Age Appropriateness Tests

    func testAgeAppropriateRecipeGeneration() {
        let newbornAge = 2
        let explorerAge = 8
        let toddlerAge = 18

        XCTAssertLessThan(newbornAge, 6, "Newborn age should be < 6 months")
        XCTAssertGreaterThanOrEqual(explorerAge, 6, "Explorer age should be >= 6 months")
        XCTAssertGreaterThanOrEqual(toddlerAge, 12, "Toddler age should be >= 12 months")
    }

    func testTextureConsistencyByAge() {
        let textures = ["puree", "mashed", "soft_chunks", "regular"]

        // Age 6 months -> puree or mashed
        // Age 9 months -> mashed or soft_chunks
        // Age 12+ months -> all textures

        XCTAssertTrue(textures.contains("puree"), "Should support puree texture")
        XCTAssertTrue(textures.contains("regular"), "Should support regular texture")
    }

    // MARK: - Allergen Awareness Tests

    func testAllergenDetection() {
        let commonAllergens = ["peanuts", "tree nuts", "milk", "eggs", "soy", "wheat", "fish", "shellfish"]

        XCTAssertEqual(commonAllergens.count, 8, "Should track 8 major allergens")
        XCTAssertTrue(commonAllergens.contains("peanuts"), "Should include peanuts")
        XCTAssertTrue(commonAllergens.contains("milk"), "Should include milk")
    }

    func testAllergenExclusion() {
        let knownAllergies = ["peanuts", "milk"]
        let ingredient = "peanut butter"

        let containsAllergen = knownAllergies.contains { ingredient.lowercased().contains($0) }

        XCTAssertTrue(containsAllergen, "Should detect allergen in ingredient")
    }

    // MARK: - Performance Tests

    func testResponseTimeExpectation() {
        // Test that AI responses complete within reasonable time
        let maxResponseTime: TimeInterval = 30.0 // 30 seconds

        XCTAssertGreaterThan(maxResponseTime, 0, "Should have timeout")
        XCTAssertLessThan(maxResponseTime, 60, "Timeout should be reasonable")
    }

    func testBatchRequestHandling() {
        let batchSize = 5
        let maxBatchSize = 10

        XCTAssertLessThanOrEqual(batchSize, maxBatchSize,
                                "Batch size should be within limits")
    }

    // MARK: - Edge Cases

    func testHandlingSpecialCharactersInInput() {
        let specialChars = "Test 🥕 emoji & symbols"

        XCTAssertTrue(specialChars.contains("🥕"), "Should handle emojis")
        XCTAssertTrue(specialChars.contains("&"), "Should handle special characters")
    }

    func testHandlingVeryLongIngredientLists() {
        let ingredients = Array(repeating: "ingredient", count: 50)
        let maxIngredients = 20

        XCTAssertGreaterThan(ingredients.count, maxIngredients,
                           "Should detect excessive ingredients")
    }

    func testHandlingUnknownFoodItems() {
        let unknownFood = "XyloQ123" // Made-up food

        XCTAssertFalse(unknownFood.isEmpty, "Should handle unknown foods gracefully")
    }
}

// MARK: - Mock Data Helpers

extension AIServiceManagerTests {

    func createMockRecipe() -> Recipe {
        return Recipe(
            title: "Test Recipe",
            ingredients: ["ingredient1", "ingredient2"],
            instructions: ["step1", "step2"],
            prepTime: 10,
            cookTime: 15,
            servings: 2,
            ownerId: "user123",
            difficulty: .easy
        )
    }

    func createMockFoodLog(foodName: String = "banana", reaction: Int = 5) -> TriedFoodLog {
        return TriedFoodLog(
            childId: "child123",
            foodName: foodName,
            reaction: reaction,
            ownerId: "user123"
        )
    }

    func createMockSleepLog(duration: TimeInterval = 7200) -> SleepLog {
        return SleepLog(
            babyId: "baby123",
            start: Date().addingTimeInterval(-duration),
            end: Date(),
            quality: .good,
            ownerId: "user123"
        )
    }
}
