//
//  GeminiService.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//  Refactored for Cloudflare Proxy on 01/22/26.
//

import Foundation
import UIKit
// import GoogleGenerativeAI - Removed for Backend Proxy

// MARK: - Response Models

struct SafetyRating: Codable {
    let status: String
    let reason: String
    let ageAppropriate: Bool
}

struct SleepPrediction: Codable {
    let predictionStatus: String
    let nextSweetSpotStart: String?
    let confidence: String?
}

struct SleepPredictionResponse: Codable {
    let predictionStatus: String
    let nextSweetSpotStart: String?
    let nextSweetSpotEnd: String?
    let confidence: String
    let reasoning: String
}

struct RecipeResponse: Codable {
    let title: String
    let ingredients: String
    let instructions: String
}

struct PickyEaterStrategyResponse: Codable {
    let strategyType: String
    let steps: [String]
    let estimatedWeeks: Int
    let explanation: String
}

struct NutrientFoodSuggestion: Codable {
    let foodName: String
    let foodEmoji: String?
    let reasoning: String
    let servingTip: String
}

struct FlavorPairing: Codable {
    let title: String
    let description: String
    let whyItWorks: String
    let ingredients: [String]
}

struct FlavorPairingResponse: Codable {
    let pairings: [FlavorPairing]
    let chefTips: String
}

struct CustomFoodDetails: Codable {
    let emoji: String
    let category: String
    let allergens: [String]
    let nutritionHighlights: String
    let howToServe: String
    let chokeHazard: Bool
    let color: String // Dominant color
    var containedColors: [String]? // All colors in the dish
    var containedCategories: [String]? // All categories in the dish
    let nutrients: [String]
}

struct MedicationSafetyInfo: Codable {
    let status: String  // "Safe", "Caution", "Consult Doctor"
    let dosageGuidance: String
    let warnings: [String]
    let ageAppropriate: Bool
    let summary: String
}

// Redundant NewbornSafetyReport struct removed (defined in SafetyCheckView.swift)


enum GeminiError: Error {
    case apiKeyNotFound
    case retryLimitExceeded
    case invalidResponse
    case serverError(Int)
}

class GeminiService {
    // private var model: GenerativeModel? -- Removed
    private let maxRetries = 3
    private let retryDelays: [TimeInterval] = [4, 8, 16]
    private var backendURL: URL?
    
    init() {
        loadConfiguration()
    }

    private func loadConfiguration() {
        let urlString = SecureAPIKeyManager.shared.getBackendURL()
        // Append the model path we expect on the server if the base URL is just the host
        // But for flexibility, let's assume the backend handles the routing or we append here.
        // The worker expects: /v1beta/models/gemini-2.0-flash:generateContent
        
        if let url = URL(string: urlString) {
             // We'll append the path in makeRequest
             self.backendURL = url
             print("✅ Gemini Service configured with Backend: \(urlString)")
        } else {
             print("❌ ERROR: Invalid Backend URL.")
        }
    }

    /// Execute an API call with rate limiting, usage monitoring, retry logic, and error handling
    private func executeWithSecurity<T>(
        callType: APICallType,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Check network connectivity first
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.noInternetConnection
        }
        
        // Check rate limit
        do {
            try APIRateLimiter.shared.checkRateLimit()
        } catch {
            // Map rate limit errors to AppError
            if let rateLimitError = error as? RateLimitError {
                switch rateLimitError {
                case .minuteLimitExceeded(let retryAfter),
                     .hourLimitExceeded(let retryAfter),
                     .dayLimitExceeded(let retryAfter):
                    throw AppError.rateLimitExceeded(retryAfter: retryAfter)
                }
            }
            throw AppError.from(error)
        }

        // Track the call with monitoring and apply retry logic
        do {
            return try await APIUsageMonitor.shared.track(callType) {
                try await retryWithBackoff {
                    try await operation()
                }
            }
        } catch {
            // Map errors to AppError for consistent handling
            throw AppError.from(error)
        }
    }
    
    // MARK: - REST API Helper
    
    private func makeRequest(prompt: String, images: [Data]? = nil) async throws -> String {
        guard let baseURL = backendURL else { throw GeminiError.apiKeyNotFound }
        
        // Construct standard endpoint
        let endpoint = baseURL.appendingPathComponent("v1beta/models/gemini-2.0-flash:generateContent")
        
        // Build Parts
        var parts: [GeminiPart] = []
        
        // Text Part
        parts.append(GeminiPart(text: prompt, inlineData: nil))
        
        // Image Parts
        if let images = images {
            for imageData in images {
                let base64 = imageData.base64EncodedString()
                let blob = GeminiBlob(mimeType: "image/jpeg", data: base64)
                parts.append(GeminiPart(text: nil, inlineData: blob))
            }
        }
        
        let content = GeminiContent(role: "user", parts: parts)
        let requestBody = GeminiRequest(contents: [content], generationConfig: nil)
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Server Error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString)")
            }
            throw GeminiError.serverError(httpResponse.statusCode)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.text else {
            throw GeminiError.invalidResponse
        }
        
        return text
    }

    
    func identifyFoodFromImage(_ image: UIImage) async throws -> String {
        try await executeWithSecurity(callType: .imageAnalysis) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw GeminiError.invalidResponse
            }

            let prompt = "Identify this food item. Return only the food name."
            
            let text = try await self.makeRequest(prompt: prompt, images: [imageData])
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }


    func suggestRecipe(ingredients: [String], ageInMonths: Int) async throws -> Recipe {
        try await executeWithSecurity(callType: .recipeGeneration) {
            
            // Add timestamp to ensure variety in each generation
            let timestamp = Date().timeIntervalSince1970
            
            let prompt = """
            Create a baby-friendly recipe for a \(ageInMonths)-month-old using: \(ingredients.joined(separator: ", "))
            
            Request ID: \(timestamp)
            
            IMPORTANT VARIETY REQUIREMENT:
            - Create a UNIQUE recipe each time - do not repeat previous suggestions
            - Be creative with combinations, cooking methods, and presentation
            - Consider different cuisines and flavor profiles
            - Vary the texture and cooking techniques

            Return ONLY valid JSON in this exact format:
            {
              "title": "Recipe Name",
              "ingredients": "- 1 cup ingredient one\\n- 1/2 cup ingredient two\\n- 2 tbsp ingredient three",
              "instructions": "1. First step\\n2. Second step\\n3. Third step"
            }

            FORMATTING RULES:
            - Each ingredient MUST start with "- " (dash space) and be on its own line using \\n
            - Each instruction step MUST start with a number and be on its own line using \\n
            - Include quantities for all ingredients
            """

            let text = try await self.makeRequest(prompt: prompt)
            
            // Reusing existing parse logic via helper
            guard let jsonData = try? self.extractJSONData(from: text) else {
                 throw GeminiError.invalidResponse
            }

            do {
                let response = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
                return Recipe(title: response.title, ingredients: response.ingredients, instructions: response.instructions)
            } catch {
                // If JSON parsing fails, create a simple recipe from the text
                print("Failed to parse JSON, creating simple recipe from text")
                return Recipe(
                    title: "Recipe for \(ingredients.joined(separator: " & "))",
                    ingredients: ingredients.joined(separator: "\n"),
                    instructions: text
                )
            }
        }
    }

    // MARK: - Generic Text Generation
    
    func generateText(prompt: String) async throws -> String {
        try await executeWithSecurity(callType: .general) {
            return try await self.makeRequest(prompt: prompt)
        }
    }

    func askSageAssistant(question: String, context: String, currentScreenContext: String? = nil) async throws -> String {
        try await executeWithSecurity(callType: .general) {
            let prompt = """
            You are "Sage", a specialized research assistant for parents and caregivers.

            YOUR ROLE:
            - Tone: Clear, empathetic, and strictly evidence-based.
            - Authority: Base all advice on high-authority sources (AAP, CDC, WHO, NIH).
            - Safety: Prioritize child safety. For medical issues, always advise consulting a pediatrician.

            CONTEXT:
            \(context)

            CURRENT ACTIVITY CONTEXT:
            \(currentScreenContext ?? "No specific activity context.")

            USER QUESTION:
            \(question)

            RESPONSE REQUIREMENTS:
            1. Format: Use BULLET POINTS for readability. Keep text concise.
            2. Citations: You MUST cite your sources for every claim.
               - If using a peer-reviewed/authoritative source (AAP, CDC), cite normally (e.g., [AAP]).
               - If using a non-peer-reviewed source (blogs, news, forums), you MUST flag it explicitly inline: "(⚠️ Non-peer reviewed source: [Source Name])".
            3. MANDATORY: End your response with exactly 3 distinct "FOLLOWUP:" questions to drive engagement.

            Example format:
            *   Point one about nutrition [CDC].
            *   Point two about sleep safety [AAP].
            *   Point three from a blog (⚠️ Non-peer reviewed source: ParentingBlog).

            FOLLOWUP: [Question 1]
            FOLLOWUP: [Question 2]
            FOLLOWUP: [Question 3]
            """

            return try await self.makeRequest(prompt: prompt)
        }
    }

    func predictSleepWindow(recentSleepLogs: [SleepLog], currentTime: Date, lastWakeTime: Date?, ageInMonths: Int) async throws -> SleepPredictionResponse {
        // Generate cache key
        let cacheKey = AIResponseCache.sleepCacheKey(ageInMonths: ageInMonths, lastWakeTime: lastWakeTime)
        
        // Try cache first if offline
        if !NetworkMonitor.shared.isConnected {
            if let cachedJSON = AIResponseCache.shared.get(for: cacheKey),
               let jsonData = cachedJSON.data(using: .utf8),
               let cached = try? JSONDecoder().decode(SleepPredictionResponse.self, from: jsonData) {
                print("📱 Using cached sleep prediction (offline mode)")
                return cached
            }
            throw AppError.noInternetConnection
        }
        
        let response = try await executeWithSecurity(callType: .general) {
            // Format sleep logs for AI
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"

            let sleepSummary = recentSleepLogs.prefix(10).map { log in
                let start = dateFormatter.string(from: log.startTime)
                let end = dateFormatter.string(from: log.endTime)
                let duration = Int(log.duration / 3600.0)
                return "Slept from \(start) to \(end) (\(duration)h)"
            }.joined(separator: "\n")

            let currentTimeStr = dateFormatter.string(from: currentTime)
            let lastWakeStr = lastWakeTime.map { dateFormatter.string(from: $0) } ?? "Unknown"

            let prompt = """
            You are a pediatric sleep expert. Analyze the sleep patterns and predict the next optimal sleep window.

            BABY INFO:
            - Age: \(ageInMonths) months
            - Current time: \(currentTimeStr)
            - Last wake time: \(lastWakeStr)

            RECENT SLEEP LOG (last 48 hours):
            \(sleepSummary.isEmpty ? "No recent sleep data" : sleepSummary)

            TASK:
            Based on age-appropriate wake windows (\(ageInMonths) months), predict when the baby will be ready for the next sleep.

            Age-based wake windows:
            - 0-1 months: 45-60 min
            - 1-2 months: 60-90 min
            - 2-3 months: 75-90 min
            - 3-6 months: 1.5-2 hours
            - 6-9 months: 2-3 hours
            - 9-12 months: 2.5-3.5 hours

            Return ONLY valid JSON in this exact format:
            {
              "predictionStatus": "Ready" or "Needs More Data",
              "nextSweetSpotStart": "HH:MM" (24-hour format, or null if status is "Needs More Data"),
              "nextSweetSpotEnd": "HH:MM" (24-hour format, or null),
              "confidence": "High", "Medium", or "Low",
              "reasoning": "Brief explanation of the prediction based on patterns and wake windows"
            }
            """

            let text = try await self.makeRequest(prompt: prompt)

            do {
                let response = try self.extractAndDecodeJSON(from: text, type: SleepPredictionResponse.self)
                AIResponseCache.shared.set(text, for: cacheKey, callType: "sleep")
                return response
            } catch {
                print("Failed to parse sleep prediction JSON: \(error)")
                return SleepPredictionResponse(
                    predictionStatus: "Needs More Data",
                    nextSweetSpotStart: nil,
                    nextSweetSpotEnd: nil,
                    confidence: "Low",
                    reasoning: "Unable to analyze sleep patterns. Please log more sleep sessions."
                )
            }
        }
        
        return response
    }


    func generatePickyEaterStrategy(enemyFood: String, safeFood: String, ageInMonths: Int, preferredStrategy: String? = nil) async throws -> PickyEaterStrategyResponse {
        try await executeWithSecurity(callType: .nutritionAnalysis) {

            let strategyGuidance = if let preferred = preferredStrategy {
                """

                PREFERRED STRATEGY: \(preferred)
                Focus on creating a plan that aligns with this approach.
                """
            } else {
                ""
            }

            let prompt = """
            You are a pediatric feeding therapist and occupational therapist specializing in picky eating.
            Create a "Food Bridging" strategy to help a \(ageInMonths)-month-old toddler accept a new food.

            CONTEXT:
            - "Safe" food (accepted/loved): \(safeFood)
            - "Enemy" food (refused/disliked): \(enemyFood)\(strategyGuidance)

            TASK:
            Create a step-by-step bridging strategy that gradually moves from the safe food to the enemy food effectively.
            Consider texture, flavor, color, and visual similarities.
            Determine the best strategy type based on the foods and any preferred approach.

            Return ONLY valid JSON in this exact format:
            {
              "strategyType": "The Bridge" or "The Stealth Mode" or "The Fun Factor" or "Repeated Exposure" or "Food Chaining",
              "steps": ["Step 1 description", "Step 2 description", "Step 3 description", ...],
              "estimatedWeeks": 2,
              "explanation": "Brief explanation of why this bridge works based on sensory properties"
            }
            """

            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: PickyEaterStrategyResponse.self)
        }
    }

    func suggestNutrientRichFoods(nutrient: String, ageInMonths: Int, triedFoodIds: [String]) async throws -> [NutrientFoodSuggestion] {
        try await executeWithSecurity(callType: .nutritionAnalysis) {
            let triedFoodsList = triedFoodIds.joined(separator: ", ")

            let prompt = """
            You are a pediatric nutritionist.
            Suggest 5 age-appropriate foods rich in \(nutrient) for a \(ageInMonths)-month-old toddler.

            CONTEXT:
            - Nutrient needed: \(nutrient)
            - Foods already tried: \(triedFoodsList)
            - Goal: Suggest NEW or UNDERUTILIZED foods.

            Return ONLY valid JSON as an ARRAY of objects:
            [
              {
                "foodName": "Food Name",
                "foodEmoji": "🥑",
                "reasoning": "High in iron (X mg per serving)",
                "servingTip": "Serve mashed with..."
              },
              ...
            ]
            """

            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: [NutrientFoodSuggestion].self)
        }
    }

    func generateFlavorPairings(triedFoods: [TriedFoodLog], childName: String) async throws -> FlavorPairingResponse {
        try await executeWithSecurity(callType: .recipeGeneration) {
            // Group foods by reaction to give context
            let lovedFoods = triedFoods.filter { $0.reaction >= 5 }.map { $0.id }
            let allTried = triedFoods.map { $0.id }.joined(separator: ", ")

            let prompt = """
            You are "Sage", an AI Flavor Sommelier for infants and toddlers.
            Create 3 creative food pairings for \(childName).

            CONTEXT:
            - Loved Foods: \(lovedFoods.joined(separator: ", "))
            - All Tried Foods: \(allTried)

            TASK:
            Suggest 3 unique flavor combinations.
            - Rules: Use mostly foods they have tried, but you can introduce 1 new spice or ingredient per pairing to expand their palate.
            - Goal: sophisticated but baby-friendly flavor profiles (e.g., Sweet Potato + Cinnamon, Avocado + Cumin).

            SAFETY ALWAYS:
            - Remind parents to insure textures are appropriate for the baby's age.

            Return ONLY valid JSON in this exact format:
            {
              "pairings": [
                {
                  "title": "Name of Pairing (e.g. 'Sunshine Bowl')",
                  "description": "Sweet potato mashed with a pinch of cinnamon",
                  "whyItWorks": "The earthy sweetness of potato pairs perfectly with warm spices...",
                  "ingredients": ["Sweet Potato", "Cinnamon"]
                }
              ],
              "chefTips": "General tip about flavor exploration..."
            }
            """

            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: FlavorPairingResponse.self)
        }
    }
    
    // Helper to handle JSON extraction consistently
    private func extractAndDecodeJSON<T: Decodable>(from text: String?, type: T.Type) throws -> T {
        guard let data = try extractJSONData(from: text) else {
            throw GeminiError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // New helper to just get Data
    private func extractJSONData(from text: String?) throws -> Data? {
        guard var text = text else { return nil }
        
        // Extract JSON from markdown code blocks if present
        if text.contains("```json") {
            let components = text.components(separatedBy: "```json")
            if components.count > 1 {
                let jsonPart = components[1].components(separatedBy: "```")[0]
                text = jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if text.contains("```") {
            let components = text.components(separatedBy: "```")
            if components.count > 1 {
                text = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return text.data(using: .utf8)
    }

    // MARK: - Trend Analysis

    func analyzeTrend(
        dataType: String,
        currentValue: Double,
        historicalValues: [(date: Date, value: Double)],
        unit: String,
        ageInMonths: Int
    ) async throws -> TrendInsight {
        try await executeWithSecurity(callType: .general) {

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"

            let dataSummary = historicalValues.map { point in
                "\(dateFormatter.string(from: point.date)): \(String(format: "%.1f", point.value)) \(unit)"
            }.joined(separator: "\n")

            let prompt = """
            You are a pediatric health analyst. Analyze this growth/health trend data.

            DATA TYPE: \(dataType)
            BABY AGE: \(ageInMonths) months
            CURRENT VALUE: \(String(format: "%.1f", currentValue)) \(unit)

            HISTORICAL DATA:
            \(dataSummary)

            TASK:
            Analyze the trend and provide insights. Consider age-appropriate norms and growth patterns.

            Return ONLY valid JSON in this exact format:
            {
              "direction": "increasing" or "decreasing" or "stable",
              "summary": "One clear sentence about the overall trend",
              "causes": ["Possible cause 1", "Possible cause 2"],
              "predictions": "What parents can expect in the next 2-4 weeks",
              "recommendations": ["Actionable tip 1", "Actionable tip 2"],
              "alerts": ["When to see pediatrician", null if none]
            }
            """

            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: TrendInsight.self)
        }
    }

    // MARK: - CustomFood Analysis

    func analyzeCustomFood(name: String) async throws -> CustomFoodDetails {
        // Generate cache key
        let cacheKey = AIResponseCache.foodCacheKey(foodName: name)
        
        // Try cache first if offline
        if !NetworkMonitor.shared.isConnected {
            if let cachedJSON = AIResponseCache.shared.get(for: cacheKey),
               let jsonData = cachedJSON.data(using: .utf8),
               let cached = try? JSONDecoder().decode(CustomFoodDetails.self, from: jsonData) {
                print("📱 Using cached food analysis (offline mode)")
                return cached
            }
            throw AppError.noInternetConnection
        }
        
        let details = try await executeWithSecurity(callType: .nutritionAnalysis) {
            let prompt = """
            You are a nutritional database expert for babies/toddlers.
            Analyze the food item: "\(name)" and provide structured details.

            Return ONLY valid JSON in this exact format:
            {
              "emoji": "🥑",
              "category": "vegetables", "fruits", "proteins", "grains", "dairy", "snacks", or "beverages",
              "allergens": ["list", "of", "major", "allergens"] (or empty list),
              "nutritionHighlights": "Brief summary of key benefits (e.g. High in Vitamin C)",
              "howToServe": "Brief, safety-focused serving tip for 6-12 month olds",
              "chokeHazard": true/false,
              "color": "Green", "Red", "Orange", "Yellow", "Purple", "White", or "Brown",
              "nutrients": ["Iron", "Calcium", "Vitamin C", "Omega-3", "Protein"] (Include ONLY if it's a significant source)
            }
            """

            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: CustomFoodDetails.self)
        }
        
        // Cache successful response
        if let jsonData = try? JSONEncoder().encode(details),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            AIResponseCache.shared.set(jsonString, for: cacheKey, callType: "food_analysis")
        }
        
        return details
    }


    func analyzePackage(image: UIImage) async throws -> CustomFoodDetails {
        try await executeWithSecurity(callType: .imageAnalysis) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw GeminiError.invalidResponse
            }

            let prompt = """
            Analyze this food package/label. Identify the product and extract details.

            Return ONLY valid JSON in this exact format:
            {
              "emoji": "🍪",
              "category": "vegetables", "fruits", "proteins", "grains", "dairy", "snacks", or "beverages",
              "allergens": ["list", "of", "major", "allergens"] (or empty list),
              "nutritionHighlights": "Brief summary from label (e.g. 5g Protein)",
              "howToServe": "Brief serving tip (e.g. Cut into small pieces)",
              "chokeHazard": true/false,
              "color": "Brown" (approximate color of the food itself),
              "nutrients": ["Iron", "Calcium", "Vitamin C", "Omega-3", "Protein"] (Detect from label if high)
            }
            """

            let text = try await self.makeRequest(prompt: prompt, images: [imageData])
            return try self.extractAndDecodeJSON(from: text, type: CustomFoodDetails.self)
        }
    }



    func analyzeRecipe(title: String, ingredients: String) async throws -> CustomFoodDetails {
        try await executeWithSecurity(callType: .nutritionAnalysis) {
            let prompt = """
            Analyze this recipe for a toddler meal balance tracker:
            Title: "\(title)"
            Ingredients: "\(ingredients)"

            1. Determine the DOMINANT food category.
            2. Identify ALL distinct food categories present in the ingredients (e.g. Chicken = Proteins, Potato = Vegetables).
            3. Identify ALL distinct food colors present in the ingredients (e.g. Sweet Potato = Orange, Spinach = Green).

            Return ONLY valid JSON in this exact format:
            {
              "emoji": "🍲",
              "category": "vegetables", "fruits", "proteins", "grains", "dairy", "snacks", or "beverages",
              "allergens": ["list", "of", "allergens"],
              "nutritionHighlights": "Main benefits",
              "howToServe": "Serving tip",
              "chokeHazard": true/false,
              "color": "Green", // Dominant visual color
              "containedColors": ["Orange", "Green", "White"], // List of all food colors present
              "containedCategories": ["vegetables", "proteins"], // List of all food categories present
              "nutrients": ["Iron", "Calcium", "Vitamin C", "Omega-3", "Protein"]
            }
            """

            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: CustomFoodDetails.self)
        }
    }
    
    // MARK: - Medication Safety
    
    func getMedicationSafetyInfo(
        medicineName: String,
        babyWeight: Double,
        dosage: String,
        ageInMonths: Int
    ) async throws -> MedicationSafetyInfo {
        try await executeWithSecurity(callType: .general) {
            let prompt = """
            You are a pediatric pharmacist providing medication safety information for parents.
            
            MEDICATION DETAILS:
            - Medicine: \(medicineName)
            - Baby's Weight: \(String(format: "%.1f", babyWeight)) lbs
            - Dosage Given: \(dosage)
            - Baby's Age: \(ageInMonths) months
            
            TASK:
            Analyze this medication administration and provide safety guidance.
            
            IMPORTANT SAFETY RULES:
            1. If the medication or dosage seems unsafe, set status to "Consult Doctor"
            2. Always recommend consulting a pediatrician for prescription medications
            3. Provide age-appropriate guidance based on AAP/FDA guidelines
            4. Flag any potential overdose risks
            
            Return ONLY valid JSON in this exact format:
            {
              "status": "Safe" or "Caution" or "Consult Doctor",
              "dosageGuidance": "Brief guidance on whether dosage is appropriate for weight/age",
              "warnings": ["Warning 1", "Warning 2"] (or empty array if none),
              "ageAppropriate": true/false,
              "summary": "One-sentence overall assessment"
            }
            
            CRITICAL: Always err on the side of caution. When in doubt, recommend consulting a doctor.
            """
            
            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: MedicationSafetyInfo.self)
        }
    }
    
    // MARK: - Newborn Safety Check
    
    func checkNewbornSafety(
        wetDiapers: Int,
        dirtyDiapers: Int,
        feedings: Int,
        sleepHours: Double,
        ageInMonths: Int
    ) async throws -> NewbornSafetyReport {
        try await executeWithSecurity(callType: .general) {
            let prompt = """
            You are a pediatric nurse providing safety guidance to new parents.
            
            BABY'S DAILY METRICS (Last 24 hours):
            - Wet Diapers: \(wetDiapers)
            - Dirty Diapers: \(dirtyDiapers)
            - Feedings: \(feedings)
            - Sleep Hours: \(String(format: "%.1f", sleepHours))
            - Baby's Age: \(ageInMonths) months
            
            TASK:
            Analyze these metrics against AAP (American Academy of Pediatrics) guidelines for newborns and infants.
            
            GUIDELINES TO CONSIDER:
            - Newborns (0-1 month): 6-8 wet diapers/day, 3-4 dirty diapers/day, 8-12 feedings/day, 14-17 hours sleep
            - 1-3 months: 6-8 wet diapers/day, 2-4 dirty diapers/day, 7-9 feedings/day, 14-16 hours sleep
            - 4-6 months: 6-8 wet diapers/day, 1-2 dirty diapers/day, 5-7 feedings/day, 12-15 hours sleep
            
            CRITICAL SAFETY RULES:
            1. If metrics are significantly below normal ranges, set status to "Concern"
            2. If metrics are slightly below or above normal, set status to "Monitor"
            3. If metrics are within normal ranges, set status to "Normal"
            4. Always err on the side of caution - when in doubt, recommend calling the doctor
            5. Flag dehydration risks (low wet diapers) as high priority
            
            Return ONLY valid JSON in this exact format:
            {
              "overallStatus": "Normal" or "Monitor" or "Concern",
              "summary": "One-sentence overall assessment",
              "concerns": ["Concern 1", "Concern 2"] (or empty array if none),
              "recommendations": ["Recommendation 1", "Recommendation 2"],
              "callDoctorIf": true/false
            }
            
            IMPORTANT: Be supportive and reassuring while providing accurate medical guidance.
            """
            
            let text = try await self.makeRequest(prompt: prompt)
            return try self.extractAndDecodeJSON(from: text, type: NewbornSafetyReport.self)
        }
    }
    
    private func retryWithBackoff<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelays[attempt] * 1_000_000_000))
                    continue
                }
                throw error
            }
        }
        throw GeminiError.retryLimitExceeded
    }
}

// MARK: - Gemini REST Models
// (Moved here to ensure visibility without project file edits)

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
}

struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiBlob?
}

struct GeminiBlob: Codable {
    let mimeType: String
    let data: String // Base64 encoded
}

struct GeminiGenerationConfig: Codable {
    let temperature: Float?
    let topP: Float?
    let topK: Int?
    let maxOutputTokens: Int?
    let responseMimeType: String?
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
    
    // Helper to get text from the first candidate
    var text: String? {
        candidates?.first?.content?.parts.first?.text
    }
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiPromptFeedback: Codable {
    let blockReason: String?
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}
