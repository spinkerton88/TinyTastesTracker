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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nutrition Balance")
            .withSage(context: "User is viewing Nutrition Balance. Weekly goals and rainbow progress.", appState: appState)
        }
        .sheet(item: $selectedNutrientForAi) { nutrient in
            NutrientSuggestionsSheet(
                appState: appState,
                originalNutrient: nutrient, // Pass the original bound value if needed, or just use the item
                nutrient: nutrient,
                suggestions: aiSuggestions,
                isLoading: isLoadingSuggestions,
                onClose: { selectedNutrientForAi = nil }
            )
            .presentationDetents([.medium, .large])
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
                NutrientProgressBar(
                    nutrient: .iron,
                    count: appState.weeklyNutritionSummary[.iron] ?? 0,
                    target: 5,
                    onAskSage: { selectedNutrientForAi = .iron }
                )
                
                NutrientProgressBar(
                    nutrient: .calcium,
                    count: appState.weeklyNutritionSummary[.calcium] ?? 0,
                    target: 7,
                    onAskSage: { selectedNutrientForAi = .calcium }
                )
                
                NutrientProgressBar(
                    nutrient: .vitaminC,
                    count: appState.weeklyNutritionSummary[.vitaminC] ?? 0,
                    target: 7,
                    onAskSage: { selectedNutrientForAi = .vitaminC }
                )
                
                NutrientProgressBar(
                    nutrient: .omega3,
                    count: appState.weeklyNutritionSummary[.omega3] ?? 0,
                    target: 3,
                    onAskSage: { selectedNutrientForAi = .omega3 }
                )
                
                NutrientProgressBar(
                    nutrient: .protein,
                    count: appState.weeklyNutritionSummary[.protein] ?? 0,
                    target: 14,
                    onAskSage: { selectedNutrientForAi = .protein }
                )
            }
        }
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

// MARK: - Suggestions Sheet extension for Identifiable

extension Nutrient: Identifiable {
    public var id: String { self.rawValue }
}

struct NutrientSuggestionsSheet: View {
    @Bindable var appState: AppState
    let originalNutrient: Nutrient?
    let nutrient: Nutrient
    let suggestions: [NutrientFoodSuggestion]
    let isLoading: Bool
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Asking Sage...")
                } else if suggestions.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("No Suggestions")
                        } icon: {
                            Image("sage.leaf.sprig")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        }
                    } description: {
                        Text("Sage couldn't find any specific suggestions right now.")
                    }
                } else {
                    List(suggestions, id: \.foodName) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(item.foodEmoji ?? "🍽️")
                                    .font(.title2)
                                Text(item.foodName)
                                    .font(.headline)
                            }
                            
                            Text(item.reasoning)
                                .font(.subheadline)
                                .foregroundStyle(nutrient.color)
                            
                            Text("💡 " + item.servingTip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("\(nutrient.rawValue) Ideas")
            .withSage(context: "Sage suggested foods rich in \(nutrient.rawValue).", appState: appState)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
    }
}
