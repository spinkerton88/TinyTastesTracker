//
//  RecommendationsData.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/1/26.
//

import Foundation

struct RecommendationCategory: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let minAgeMonths: Int
    let maxAgeMonths: Int?
    let foodIds: [String]
    
    var foods: [FoodItem] {
        return foodIds.compactMap { id in
            Constants.allFoods.first { $0.id == id }
        }
    }
}

struct RecommendationsData {
    static let categories: [RecommendationCategory] = [
        RecommendationCategory(
            id: "6_MONTHS",
            title: "6 Months",
            subtitle: "First Tastes",
            minAgeMonths: 6,
            maxAgeMonths: 6,
            foodIds: [
                "AVOCADO", "SWEET_POTATO", "BANANA", "YOGURT", "OATMEAL", 
                "APPLE", "CARROT", "BROCCOLI", "PEAS", "GREEN_BEANS",
                "BUTTERNUT_SQUASH", "PEAR", "PEACH"
            ]
        ),
        RecommendationCategory(
            id: "7_8_MONTHS",
            title: "7-8 Months",
            subtitle: "Allergens & Flavors",
            minAgeMonths: 7,
            maxAgeMonths: 8,
            foodIds: [
                "EGG", "PEANUT_BUTTER", "SALMON", "CHICKEN", "BEEF",
                "CHEESE", "TOFU", "LENTILS", "SPINACH", "BEET",
                "MANGO", "BLUEBERRY", "RASPBERRY", "QUINOA"
            ]
        ),
        RecommendationCategory(
            id: "9_11_MONTHS",
            title: "9-11 Months",
            subtitle: "Pincer Grasp & Textures",
            minAgeMonths: 9,
            maxAgeMonths: 11,
            foodIds: [
                "PASTA", "BREAD", "CHEERIOS", "BELL_PEPPER", "TOMATO",
                "CUCUMBER", "STRAWBERRY", "BLACKBERRY", "WATERMELON",
                "BLACK_BEANS", "CHICKPEAS", "HUMMUS", "TURKEY"
            ]
        ),
        RecommendationCategory(
            id: "12_PLUS",
            title: "12+ Months",
            subtitle: "Table Foods",
            minAgeMonths: 12,
            maxAgeMonths: nil,
            foodIds: [
                "HONEY", "MILK", "GRAPE", "POPCORN", // Note: Need to check if these are in Constants or safe
                "CORN", "SHRIMP", "PORK", "ORANGE", "PINEAPPLE",
                "KIWI", "NUTS" // Nuts usually as butter or ground
            ]
        )
    ]
}
