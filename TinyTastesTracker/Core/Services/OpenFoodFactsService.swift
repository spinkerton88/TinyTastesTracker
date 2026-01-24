//
//  OpenFoodFactsService.swift
//  TinyTastesTracker
//
//  Enhanced with barcode scanning support
//

import Foundation

enum OpenFoodFactsError: LocalizedError {
    case invalidBarcode
    case productNotFound
    case networkError(Error)
    case parseError
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return "Invalid barcode format"
        case .productNotFound:
            return "Product not found in database"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError:
            return "Failed to parse product data"
        case .timeout:
            return "Request timed out"
        }
    }
}

struct ProductInfo: Codable {
    let productName: String
    let brand: String?
    let imageUrl: String?
    let ingredients: String?
    let allergens: [String]
    let categories: [String]
    let nutrients: ProductNutrients?
    
    var hasAllergens: Bool {
        !allergens.isEmpty
    }
}

struct ProductNutrients: Codable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let fat: Double?
    let fiber: Double?
    let sodium: Double?
    let iron: Double?
    let calcium: Double?
    let vitaminC: Double?
    
    // Returns a formatted string of key nutrients
    var summary: String {
        var parts: [String] = []
        if let protein = proteins {
            parts.append("Protein: \(String(format: "%.1f", protein))g")
        }
        if let iron = iron {
            parts.append("Iron: \(String(format: "%.1f", iron))mg")
        }
        if let calcium = calcium {
            parts.append("Calcium: \(String(format: "%.1f", calcium))mg")
        }
        if let vitC = vitaminC {
            parts.append("Vitamin C: \(String(format: "%.1f", vitC))mg")
        }
        return parts.isEmpty ? "No nutrient data available" : parts.joined(separator: ", ")
    }
}

class OpenFoodFactsService {
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product/"
    private let timeoutInterval: TimeInterval = 10.0
    
    func lookupBarcode(_ code: String) async throws -> ProductInfo {
        // Validate barcode format (basic check)
        guard !code.isEmpty, code.allSatisfy({ $0.isNumber }) else {
            throw OpenFoodFactsError.invalidBarcode
        }
        
        let urlString = "\(baseURL)\(code).json"
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidBarcode
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval
        request.setValue("TinyTastesTracker-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw OpenFoodFactsError.productNotFound
            }
            throw OpenFoodFactsError.networkError(URLError(.badServerResponse))
        }
        
        // Parse JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int,
              status == 1,
              let product = json["product"] as? [String: Any] else {
            throw OpenFoodFactsError.productNotFound
        }
        
        // Extract product information
        let productName = product["product_name"] as? String ?? 
                         product["product_name_en"] as? String ?? 
                         "Unknown Product"
        
        let brand = product["brands"] as? String
        let imageUrl = product["image_url"] as? String
        let ingredients = product["ingredients_text"] as? String ?? 
                         product["ingredients_text_en"] as? String
        
        // Parse allergens
        var allergens: [String] = []
        if let allergensString = product["allergens"] as? String {
            allergens = allergensString
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .map { $0.replacingOccurrences(of: "en:", with: "") }
                .filter { !$0.isEmpty }
        }
        if let allergensTags = product["allergens_tags"] as? [String] {
            allergens.append(contentsOf: allergensTags.map { 
                $0.replacingOccurrences(of: "en:", with: "").capitalized 
            })
        }
        allergens = Array(Set(allergens)) // Remove duplicates
        
        // Parse categories
        var categories: [String] = []
        if let categoriesString = product["categories"] as? String {
            categories = categoriesString
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        
        // Parse nutrients (per 100g)
        var nutrients: ProductNutrients?
        if let nutriments = product["nutriments"] as? [String: Any] {
            nutrients = ProductNutrients(
                energyKcal: nutriments["energy-kcal_100g"] as? Double,
                proteins: nutriments["proteins_100g"] as? Double,
                carbohydrates: nutriments["carbohydrates_100g"] as? Double,
                fat: nutriments["fat_100g"] as? Double,
                fiber: nutriments["fiber_100g"] as? Double,
                sodium: nutriments["sodium_100g"] as? Double,
                iron: nutriments["iron_100g"] as? Double,
                calcium: nutriments["calcium_100g"] as? Double,
                vitaminC: nutriments["vitamin-c_100g"] as? Double
            )
        }
        
        return ProductInfo(
            productName: productName,
            brand: brand,
            imageUrl: imageUrl,
            ingredients: ingredients,
            allergens: allergens,
            categories: categories,
            nutrients: nutrients
        )
    }
}
