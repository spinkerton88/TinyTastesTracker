//
//  RecommendationsView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/1/26.
//

import SwiftUI

struct RecommendationsView: View {
    @Bindable var appState: AppState
    
    // Default expanded state: first category is expanded
    @State private var expandedCategories: Set<String> = ["6_MONTHS"]
    @State private var selectedFood: FoodItem?

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("A guide to introducing solids by age")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Header

                    // Categories
                    
                    // Categories
                    LazyVStack(spacing: 16) {
                        ForEach(RecommendationsData.categories) { category in
                            RecommendationSectionView(
                                category: category,
                                isExpanded: expandedCategories.contains(category.id),
                                appState: appState,
                                onToggle: {
                                    withAnimation {
                                        if expandedCategories.contains(category.id) {
                                            expandedCategories.remove(category.id)
                                        } else {
                                            expandedCategories.insert(category.id)
                                        }
                                    }
                                },
                                onSelectFood: { food in
                                    selectedFood = food
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Food Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedFood) { food in
                FoodDetailModal(food: food, appState: appState)
            }
        }
    }
}

// MARK: - Models & Parsing

struct SubstitutionResponse: Codable {
    let intro_text: String
    let alternatives: [SubstitutionAlternative]
}

struct SubstitutionAlternative: Codable, Hashable {
    let name: String
    let details: String
}

func parseSubstitutionJSON(_ jsonString: String) -> SubstitutionResponse? {
    // robustly extract JSON object between first '{' and last '}'
    var jsonContent = jsonString
    
    if let firstBrace = jsonString.firstIndex(of: "{"),
       let lastBrace = jsonString.lastIndex(of: "}") {
        // Ensure valid range
        if firstBrace <= lastBrace {
            let range = firstBrace...lastBrace
            jsonContent = String(jsonString[range])
        }
    }
    
    // Clean up potential markdown residue inside the object (rare but possible)
    let cleaned = jsonContent
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard let data = cleaned.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(SubstitutionResponse.self, from: data)
}

// MARK: - Food Substitution Sheet

struct FoodSubstitutionSheet: View {
    let food: FoodItem
    @Bindable var appState: AppState
    @Binding var suggestions: SubstitutionResponse? // Changed type
    @Binding var isLoading: Bool
    let onRequestSubstitution: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Food Header
                    HStack(spacing: 16) {
                        Text(food.emoji)
                            .font(.system(size: 60)) // Large decorative icon
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Contains allergens")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Allergen Warning
                    VStack(alignment: .leading, spacing: 8) {
                        Label("⚠️ Known Allergens", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        
                        ForEach(food.allergens, id: \.self) { allergen in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                Text(allergen.capitalized)
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Substitution Suggestions
                    if isLoading {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Finding whole food alternatives...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if let response = suggestions {
                        VStack(alignment: .leading, spacing: 24) {
                            // Intro Text (Non-selectable information)
                            Text(response.intro_text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Selectable List Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select a Safe Alternative")
                                    .font(.headline)
                                    .foregroundStyle(appState.themeColor)
                                
                                ForEach(response.alternatives, id: \.self) { alternative in
                                    Button(action: {
                                        applySubstitution(alternative.name)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(alternative.name)
                                                    .font(.body)
                                                    .fontWeight(.semibold) // Bold food name
                                                    .foregroundStyle(.primary)
                                                
                                                if !alternative.details.isEmpty {
                                                    Text(alternative.details)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.triangle.swap")
                                                .foregroundStyle(appState.themeColor)
                                        }
                                        .padding()
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                        .padding()
                    } else {
                        Button(action: onRequestSubstitution) {
                            HStack {
                                Image("sage.leaf.sprig")
                                Text("Find Safe Whole Food Alternatives")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appState.themeColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Food Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    

    
    private func applySubstitution(_ foodName: String) {
        // 1. Check if food exists in known foods
        let matchedFood = Constants.allFoods.first(where: { 
            $0.name.localizedCaseInsensitiveContains(foodName) ||
            foodName.localizedCaseInsensitiveContains($0.name)
        })
        
        let finalFood: FoodItem
        
        if let existing = matchedFood {
            finalFood = existing
        } else {
            // 2. If not found, create a placeholder custom food
            // Note: In a real app we might want to use AI to get full details for the custom food first
            // For now, we create a basic entry so it works immediately
            let customFood = CustomFood(
                id: UUID().uuidString,
                name: foodName,
                emoji: "🥗", // Generic healthy food emoji
                category: food.category, // Inherit category from substituted food
                allergens: [] // Assuming safe since user selected it as alternative
            )
            appState.saveCustomFood(customFood, context: modelContext)
            finalFood = customFood.toFoodItem
        }
        
        // 3. Persist the substitution mapping
        if appState.userProfile?.substitutedFoods == nil {
            appState.userProfile?.substitutedFoods = [:]
        }
        appState.userProfile?.substitutedFoods?[food.id] = finalFood.id
        
        // Save user profile changes (assuming context handles it automatically via SwiftData)
        // If explicit save needed: try? modelContext.save()
        
        HapticManager.success()
        dismiss()
    }
}

struct RecommendationSectionView: View {
    let category: RecommendationCategory
    let isExpanded: Bool
    let appState: AppState
    let onToggle: () -> Void
    let onSelectFood: (FoodItem) -> Void
    
    @State private var substitutionFood: FoodItem?
    @State private var substitutionResponse: SubstitutionResponse? // Changed type
    @State private var isLoadingSubstitution = false
    
    private func hasKnownAllergen(_ food: FoodItem) -> Bool {
        guard let knownAllergies = appState.userProfile?.knownAllergies else {
            return false
        }
        return food.allergens.contains { foodAllergen in
            knownAllergies.contains { knownAllergy in
                foodAllergen.localizedCaseInsensitiveContains(knownAllergy) ||
                knownAllergy.localizedCaseInsensitiveContains(foodAllergen)
            }
        }
    }
    
    // Check for substituted food
    private func getDisplayFood(for originalFood: FoodItem) -> FoodItem {
        guard let substitutedId = appState.userProfile?.substitutedFoods?[originalFood.id] else {
            return originalFood
        }
        
        // Find the substituted food in known foods
        if let substitutedFood = appState.allKnownFoods.first(where: { $0.id == substitutedId }) {
            return substitutedFood
        }
        
        return originalFood
    }
    
    // Check if food is substituted
    private func isSubstituted(_ food: FoodItem) -> Bool {
        return appState.userProfile?.substitutedFoods?[food.id] != nil
    }
    
    // Calculate progress
    private var triedCount: Int {
        category.foods.filter { appState.isFoodTried($0.id) }.count
    }
    
    private var totalCount: Int {
        category.foods.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Button
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(appState.themeColor)
                        
                        Text(category.subtitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(triedCount)/\(totalCount) tried")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
            }
            
            // Progress Bar (always visible)
            ProgressView(value: Double(triedCount), total: Double(totalCount))
                .tint(appState.themeColor)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 16) {
                    if category.foods.isEmpty {
                        Text("No foods found for this category.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                            ForEach(category.foods) { originalFood in
                                let displayFood = getDisplayFood(for: originalFood)
                                let isSubstitutedItem = isSubstituted(originalFood)
                                
                                FoodItemCard(
                                    food: displayFood,
                                    isTried: appState.isFoodTried(displayFood.id),
                                    themeColor: appState.themeColor,
                                    knownAllergies: appState.userProfile?.knownAllergies ?? []
                                )
                                .onTapGesture {
                                    onSelectFood(displayFood)
                                }
                                .contextMenu {
                                    // Only show substitution option if it's NOT already substituted AND has allergens
                                    if !isSubstitutedItem && hasKnownAllergen(originalFood) {
                                        Button(action: {
                                            substitutionFood = originalFood
                                        }) {
                                            Label("Find Safe Alternative", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                    }
                                    
                                    if isSubstitutedItem {
                                        Button(action: {
                                            // Optional: Allow reverting substitution?
                                            // For now just show details of substitute
                                            onSelectFood(displayFood)
                                        }) {
                                            Label("Revert to \(originalFood.name)", systemImage: "arrow.utensils.briefcase")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            appState.userProfile?.substitutedFoods?.removeValue(forKey: originalFood.id)
                                        }) {
                                            Label("Remove Substitution", systemImage: "trash")
                                        }
                                    }
                                    
                                    Button(action: {
                                        onSelectFood(displayFood)
                                    }) {
                                        Label("View Details", systemImage: "info.circle")
                                    }
                                    

                                }
                            }
                        }
                        .padding()

                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(item: $substitutionFood) { food in
            FoodSubstitutionSheet(
                food: food,
                appState: appState,
                suggestions: $substitutionResponse,
                isLoading: $isLoadingSubstitution,
                onRequestSubstitution: {
                    getSubstitutionFor(food)
                }
            )
        }
        .onChange(of: substitutionFood?.id) { _, newValue in
            if newValue != nil {
                substitutionResponse = nil
                isLoadingSubstitution = false
            }
        }
    }
    
    private func getSubstitutionFor(_ food: FoodItem) {
        isLoadingSubstitution = true
        
        Task {
            do {
                let allergens = food.allergens.filter { foodAllergen in
                    (appState.userProfile?.knownAllergies ?? []).contains { knownAllergy in
                        foodAllergen.localizedCaseInsensitiveContains(knownAllergy) ||
                        knownAllergy.localizedCaseInsensitiveContains(foodAllergen)
                    }
                }
                
                let prompt = """
                The baby is allergic to: \(allergens.joined(separator: ", "))
                
                I need to substitute "\(food.name)" which contains these allergens.
                
                Please suggest 3-4 safe, age-appropriate alternatives for a \(appState.userProfile?.ageInMonths ?? 6) month old baby.
                
                PRIORITY: Suggest foods that specifically mimic the TEXTURE, TASTE, or CULINARY FUNCTION of "\(food.name)".
                - Look for similar consistency (e.g., creamy for cheese, spreadable for butter).
                - Look for similar savory/sweet profile.
                
                Return the response as perfect JSON with this exact structure:
                {
                  "intro_text": "Short, reassuring 1-2 sentence advice about substituting this allergen.",
                  "alternatives": [
                     { "name": "Food Name (Whole food only)", "details": "Brief phrase on why it's good (e.g. 'Creamy texture')" }
                  ]
                }
                
                CRITICAL:
                1. Output PURE JSON ONLY. No markdown, no code blocks.
                2. Suggest ONLY WHOLE FOODS. No blends or recipes.
                """
                
                let suggestions = try await appState.geminiService.askSageAssistant(
                    question: prompt,
                    context: "Food substitution for \(food.name)",
                    currentScreenContext: "Recommendations - allergen substitution"
                )
                
                await MainActor.run {
                    if let parsed = parseSubstitutionJSON(suggestions) {
                        self.substitutionResponse = parsed
                    } else {
                        // Fallback if structured parsing fails
                        self.substitutionResponse = SubstitutionResponse(
                            intro_text: "Here are some suggestions based on your request:",
                            alternatives: [
                                SubstitutionAlternative(
                                    name: "Suggestions from Sage",
                                    details: suggestions
                                )
                            ]
                        )
                    }
                    self.isLoadingSubstitution = false
                }
            } catch {
                await MainActor.run {
                    self.substitutionResponse = SubstitutionResponse(
                        intro_text: "Unable to get specific suggestions at this time. Please try again or consult with your pediatrician.",
                        alternatives: []
                    )
                    self.isLoadingSubstitution = false
                }
            }
        }
    }
}


