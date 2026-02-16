//
//  BalancePage.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI
import Charts

struct BalancePage: View {
    @Bindable var appState: AppState
    
    @State private var showingNutrientSuggestions = false
    @State private var selectedNutrientForAi: Nutrient?
    @State private var aiSuggestions: [NutrientFoodSuggestion] = []
    @State private var isLoadingSuggestions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(color: appState.themeColor)
                
                ScrollView {
                VStack(spacing: 24) {
                    // weekly meal count chart
                    weeklyPlateSection
                    
                    // Eat the Rainbow
                    rainbowSection
                    
                    // Critical Nutrients
                    nutrientsSection
                }
                .padding()
            }
            }
            // .background(Color(.systemGroupedBackground)) // Removed in favor of gradient
            .navigationTitle("Nutrition Balance")
            .withSage(context: "User is viewing Nutrition Balance. Weekly goals and rainbow progress.", appState: appState)
        }

        .onChange(of: selectedNutrientForAi) { oldValue, newValue in
            if let nutrient = newValue {
                fetchSuggestions(for: nutrient)
            }
        }
    }
    
    // MARK: - Sections
    
    private var weeklyPlateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Plate")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Breakdown of food groups served in the last 7 days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Chart {
                ForEach(FoodCategory.allCases.filter { $0 != .snacks && $0 != .beverages }, id: \.self) { category in
                    let count = countForCategory(category)
                    BarMark(
                        x: .value("Count", count),
                        y: .value("Category", category.rawValue.capitalized)
                    )
                    .foregroundStyle(by: .value("Category", category.rawValue.capitalized))
                    .annotation(position: .trailing) {
                        Text("\(count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 250)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var rainbowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Eat the Rainbow")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if hasFullRainbow {
                    Label("Week Complete!", systemImage: "trophy.fill")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(FoodColor.allCases, id: \.self) { color in
                        if color != .white && color != .brown {
                            RainbowCircle(
                                color: color,
                                count: appState.rainbowProgress[color] ?? 0
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var nutrientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Critical Nutrients")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                nutrientBar(.iron, target: 5)
                nutrientBar(.calcium, target: 7)
                nutrientBar(.vitaminC, target: 7)
                nutrientBar(.omega3, target: 3)
                nutrientBar(.protein, target: 14)
            }
        }
    }
    
    private func nutrientBar(_ nutrient: Nutrient, target: Int) -> some View {
        NutrientProgressBar(
            nutrient: nutrient,
            count: appState.weeklyNutritionSummary[nutrient] ?? 0,
            target: target,
            isExpanded: selectedNutrientForAi == nutrient,
            isLoading: isLoadingSuggestions && selectedNutrientForAi == nutrient,
            suggestions: selectedNutrientForAi == nutrient ? aiSuggestions : [],
            onToggleExpand: {
                withAnimation {
                    if selectedNutrientForAi == nutrient {
                        selectedNutrientForAi = nil
                    } else {
                        selectedNutrientForAi = nutrient
                    }
                }
            }
        )
    }
    
    // MARK: - Helpers
    
    private func countForCategory(_ category: FoodCategory) -> Int {
        let last7Days = Date().addingTimeInterval(-7 * 24 * 3600)
        let recentMeals = appState.mealLogs.filter { $0.timestamp >= last7Days }
        let allFoodIds = recentMeals.flatMap { $0.foods }
        
        return allFoodIds.filter { foodId in
            // 1. Check primary category from generic FoodItem lookup
            if let food = appState.allKnownFoods.first(where: { $0.id == foodId }),
               food.category == category {
                return true
            }
            
            // 2. If not a primary match, check if it's a CustomFood with containedCategories
            if let customFood = appState.customFoods.first(where: { $0.id == foodId }),
               customFood.containedCategories.contains(category) {
                return true
            }
            
            return false
        }.count
    }
    
    private var hasFullRainbow: Bool {
        let progress = appState.rainbowProgress
        let colors: [FoodColor] = [.red, .orange, .yellow, .green, .purple]
        return colors.allSatisfy { (progress[$0] ?? 0) > 0 }
    }
    
    private func fetchSuggestions(for nutrient: Nutrient) {
        isLoadingSuggestions = true
        aiSuggestions = []
        
        Task {
            do {
                let suggestions = try await appState.suggestFoodsForNutrient(nutrient)
                await MainActor.run {
                    self.aiSuggestions = suggestions
                    self.isLoadingSuggestions = false
                }
            } catch {
                print("Error calculating nutrient suggestions: \(error)")
                await MainActor.run {
                    self.isLoadingSuggestions = false
                }
            }
        }
    }
}


