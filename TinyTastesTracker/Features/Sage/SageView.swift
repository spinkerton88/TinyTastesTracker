//
//  SageView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/2/26.
//

import SwiftUI

struct SageView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // UI State
    @State private var currentState: SageState = .menu
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Feature States
    @State private var pairings: FlavorPairingResponse?
    @State private var sleepPrediction: SleepPredictionResponse?
    @State private var suggestedRecipe: Recipe?
    @State private var pickyEaterStrategies: [PickyEaterStrategyResponse] = []
    @State private var selectedStrategyIndex = 0
    
    // Navigation States
    @State private var showingChat = false
    @State private var showingVoiceChat = false
    @State private var showingPickyEaterInput = false
    
    // Picky Eater Input
    @State private var targetFood = ""
    @State private var safeFood = ""
    
    // Strategy Types
    private let strategyTypes = ["The Bridge", "The Stealth Mode", "The Fun Factor", "Repeated Exposure", "Food Chaining"]
    
    enum SageState {
        case menu
        case results
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header (Always Visible)
                    headerView
                    
                    if isLoading {
                        loadingView
                    } else {
                        switch currentState {
                        case .menu:
                            menuView
                        case .results:
                            resultsScrollView
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityLabel(AccessibilityIdentifiers.Sage.closeButton)
                        .accessibilityHint("Closes Sage assistant")
                }
                
                if currentState == .results {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("New Search") {
                            withAnimation {
                                currentState = .menu
                                errorMessage = nil
                            }
                        }
                        .accessibilityHint("Returns to Sage menu")
                    }
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var headerView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(appState.themeColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image("sage.leaf.sprig")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundStyle(appState.themeColor)
            }
            
            Text(modeTitle)
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
            
            Text(modeSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(modeTitle). \(modeSubtitle)")
    }
    
    private var menuView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Mode-specific options
                switch appState.currentMode {
                case .newborn:
                    SageOptionButton(
                        title: "Predict Sleep Window",
                        subtitle: "Analyze recently logged sleep patterns",
                        icon: "clock.arrow.circlepath",
                        color: .blue
                    ) {
                        Task { await generateSleepPrediction() }
                    }
                    .accessibilityLabel(AccessibilityIdentifiers.Sage.sleepPredictionButton)
                    .accessibilityHint("Predicts next sleep window based on recent patterns")
                    
                case .explorer:
                    SageOptionButton(
                        title: "Find Flavor Pairings",
                        subtitle: "Get 3 unique combos based on tried foods",
                        icon: "fork.knife.circle",
                        color: .orange
                    ) {
                         Task { await generateFlavorPairings() }
                    }
                    .accessibilityLabel(AccessibilityIdentifiers.Sage.flavorPairingsButton)
                    .accessibilityHint("Generates flavor pairing suggestions")
                    
                case .toddler:
                     SageOptionButton(
                        title: "Suggest a Recipe",
                        subtitle: "Create a meal based on favorite foods",
                        icon: "book.pages.fill",
                        color: .orange
                    ) {
                        Task { await generateToddlerRecipe() }
                    }
                    
                    SageOptionButton(
                        title: "Picky Eater Strategy",
                        subtitle: "Bridge from a safe food to a new food",
                        icon: "arrow.triangle.swap",
                        color: .blue
                    ) {
                        showingPickyEaterInput = true
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                // Universal options: Chat and Voice
                SageOptionButton(
                    title: "Ask a Question",
                    subtitle: "Text chat with Sage for advice",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .purple
                ) {
                    showingChat = true
                }
                .accessibilityLabel(AccessibilityIdentifiers.Sage.chatButton)
                .accessibilityHint("Opens text chat with Sage")

                // TEMPORARILY DISABLED: Voice chat requires WebSocket support
                // TODO: Re-enable after adding Cloudflare Durable Objects or alternative WebSocket backend
                /*
                SageOptionButton(
                    title: "Voice Chat",
                    subtitle: "Talk to Sage hands-free",
                    icon: "mic.fill",
                    color: .green
                ) {
                    showingVoiceChat = true
                }
                .accessibilityLabel(AccessibilityIdentifiers.Sage.voiceChatButton)
                .accessibilityHint("Opens voice chat with Sage")
                */
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingChat) {
            SageChatView(appState: appState, initialContext: appState.sageContext)
        }
        .sheet(isPresented: $showingVoiceChat) {
            VoiceChatView(appState: appState, initialContext: appState.sageContext)
        }
        .sheet(isPresented: $showingPickyEaterInput) {
            PickyEaterInputSheet(
                targetFood: $targetFood,
                safeFood: $safeFood,
                onSubmit: {
                    showingPickyEaterInput = false
                    Task { await generatePickyEaterStrategy() }
                }
            )
        }
    }
    
    private var resultsScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch appState.currentMode {
                case .newborn:
                    if let prediction = sleepPrediction {
                        SleepPredictionResultView(prediction: prediction)
                    }
                case .explorer:
                    if let pairings = pairings {
                        FlavorPairingsList(response: pairings) { pairing in
                            // Convert FlavorPairing to Recipe and save
                            let recipe = Recipe(
                                ownerId: appState.currentOwnerId ?? "",
                                title: pairing.title,
                                ingredients: pairing.ingredients.joined(separator: "\n"),
                                instructions: """
                                \(pairing.description)
                                
                                Why it works: \(pairing.whyItWorks)
                                """,
                                tags: ["Sage Suggestion", "Flavor Pairing"]
                            )
                            Task {
                                try? await appState.saveRecipe(recipe)
                            }
                        }
                    }
                case .toddler:
                    if let recipe = suggestedRecipe {
                        RecipeCardView(
                            recipe: recipe,
                            themeColor: appState.themeColor,
                            onSave: {
                                Task {
                                    try? await appState.saveRecipe(recipe)
                                }
                                dismiss()
                            },
                            onRegenerate: {
                                Task { await generateToddlerRecipe() }
                            }
                        )
                    }
                    
                    if !pickyEaterStrategies.isEmpty {
                        PickyEaterStrategyCard(
                            strategies: pickyEaterStrategies,
                            selectedIndex: $selectedStrategyIndex,
                            themeColor: appState.themeColor,
                            onRegenerate: {
                                Task { await generatePickyEaterStrategy() }
                            },
                            onSave: { strategy in
                                let recipe = Recipe(
                                    ownerId: appState.currentOwnerId ?? "",
                                    title: "\(strategy.strategyType): \(targetFood)",
                                    ingredients: "Target: \(targetFood)\nSafe: \(safeFood)",
                                    instructions: strategy.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n"),
                                    tags: ["Sage Strategy", "Picky Eater", strategy.strategyType]
                                )
                                Task {
                                    try? await appState.saveRecipe(recipe)
                                }
                            }
                        )
                    }
                }

                // Disclaimer
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                    Text("Sage is your feeding assistant. Use judgment.")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding()
            }
            .padding()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(appState.themeColor)
            Text("Sage is thinking...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityIdentifiers.Sage.loadingIndicator)
    }
    
    // MARK: - Helpers
    
    private var modeIcon: String {
        // Use sage leaf sprig icon for Sage assistant branding
        return "sage.leaf.sprig"
    }
    
    private var modeTitle: String {
        "Sage Assistant"
    }
    
    private var modeSubtitle: String {
        switch appState.currentMode {
        case .newborn: return "Here to help with sleep and growth."
        case .explorer: return "Let's explore new flavors together."
        case .toddler: return "Meal planning and nutrition helper."
        }
    }
    
    // MARK: - Actions
    
    private func generateSleepPrediction() async {
        isLoading = true
        errorMessage = nil
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let prediction = try await appState.predictNextSleepWindow()
            await MainActor.run {
                self.sleepPrediction = prediction
                self.currentState = .results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to predict sleep."
                self.isLoading = false
            }
        }
    }
    
    private func generateFlavorPairings() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await appState.generateFlavorPairings()
            await MainActor.run {
                self.pairings = response
                self.currentState = .results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate pairings."
                self.isLoading = false
            }
        }
    }
    
    private func generateToddlerRecipe() async {
        isLoading = true
        errorMessage = nil
        do {
            let lovedFoods = appState.foodLogs.filter { $0.reaction >= 4 }.compactMap { log in
                 Constants.allFoods.first(where: { $0.id == log.id })?.name
            }
            let ingredients = lovedFoods.isEmpty ? ["Sweet Potato", "Chicken", "Spinach"] : Array(lovedFoods.prefix(3))
            
            let recipe = try await appState.generateRecipe(ingredients: ingredients)
            await MainActor.run {
                self.suggestedRecipe = recipe
                self.currentState = .results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to suggest recipe."
                self.isLoading = false
            }
        }
    }
    
    private func generatePickyEaterStrategy() async {
        guard !targetFood.isEmpty, !safeFood.isEmpty else {
            errorMessage = "Please enter both foods."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Generate all 5 strategy types in parallel
        await withTaskGroup(of: PickyEaterStrategyResponse?.self) { group in
            for strategyType in strategyTypes {
                group.addTask {
                    try? await self.appState.generatePickyEaterStrategy(
                        enemyFoodId: self.targetFood,
                        safeFoodId: self.safeFood,
                        preferredStrategy: strategyType
                    )
                }
            }
            
            var results: [PickyEaterStrategyResponse] = []
            for await result in group {
                if let strategy = result {
                    results.append(strategy)
                }
            }
            
            await MainActor.run {
                if results.isEmpty {
                    self.errorMessage = "Failed to generate strategies."
                } else {
                    self.pickyEaterStrategies = results
                    self.selectedStrategyIndex = 0
                    self.currentState = .results
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Subcomponents

struct SageOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint(AccessibilityIdentifiers.actionHint(for: title.lowercased()))
    }
}

struct RecipeCardView: View {
    let recipe: Recipe
    let themeColor: Color
    var onSave: (() -> Void)?
    var onRegenerate: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(recipe.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(themeColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients").font(.headline)
                Text(recipe.ingredients)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Instructions").font(.headline)
                Text(recipe.instructions)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Regenerate Button
                if let onRegenerate = onRegenerate {
                    Button(action: onRegenerate) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Another")
                        }
                        .font(.headline)
                        .foregroundStyle(themeColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Save Button
                if let onSave = onSave {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}



struct FlavorPairingsList: View {
    let response: FlavorPairingResponse
    var onSave: ((FlavorPairing) -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Text(response.chefTips)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            ForEach(response.pairings, id: \.title) { pairing in
                FlavorPairingCard(pairing: pairing, onSave: onSave != nil ? { onSave?(pairing) } : nil)
            }
        }
    }
}

struct FlavorPairingCard: View {
    let pairing: FlavorPairing
    var onSave: (() -> Void)?
    
    @State private var isSaved = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pairing.title)
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
                Image(systemName: "fork.knife")
                    .foregroundStyle(.purple.opacity(0.5))
            }
            
            Text(pairing.description)
                .font(.body)
                .fontWeight(.medium)
            
            Divider()
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
                
                Text(pairing.whyItWorks)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Save Button
            if let onSave = onSave {
                Button {
                    onSave()
                    withAnimation { isSaved = true }
                } label: {
                    HStack {
                        Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                        Text(isSaved ? "Saved!" : "Save to Recipes")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSaved ? .green : .purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSaved ? Color.green.opacity(0.1) : Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isSaved)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// A simple display view for a pre-fetched SleepPredictionResponse
struct SleepPredictionResultView: View {
    let prediction: SleepPredictionResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.blue)
                Text("Sleep Prediction")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if prediction.predictionStatus == "Ready",
               let start = prediction.nextSweetSpotStart,
               let end = prediction.nextSweetSpotEnd {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Sweet Spot")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(start) - \(end)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Text(prediction.confidence)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(confidenceColor.opacity(0.2))
                        .foregroundStyle(confidenceColor)
                        .clipShape(Capsule())
                }
                .padding()
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(prediction.reasoning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.orange)
                    Text(prediction.reasoning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var confidenceColor: Color {
        switch prediction.confidence.lowercased() {
        case "high": return .green
        case "medium": return .yellow
        default: return .orange
        }
    }
}

// MARK: - Picky Eater Components

struct PickyEaterInputSheet: View {
    @Binding var targetFood: String
    @Binding var safeFood: String
    let onSubmit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Target food (e.g., Broccoli)", text: $targetFood)
                } header: {
                    Text("Food to introduce")
                } footer: {
                    Text("The food your child currently refuses or dislikes.")
                }
                
                Section {
                    TextField("Safe food (e.g., Pasta)", text: $safeFood)
                } header: {
                    Text("Safe food")
                } footer: {
                    Text("A food your child already loves and eats reliably.")
                }
            }
            .navigationTitle("Picky Eater Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        onSubmit()
                    }
                    .disabled(targetFood.isEmpty || safeFood.isEmpty)
                }
            }
        }
    }
}

struct PickyEaterStrategyCard: View {
    let strategies: [PickyEaterStrategyResponse]
    @Binding var selectedIndex: Int
    let themeColor: Color
    var onRegenerate: (() -> Void)?
    var onSave: ((PickyEaterStrategyResponse) -> Void)?
    
    @State private var isSaved = false
    
    private var currentStrategy: PickyEaterStrategyResponse {
        strategies.indices.contains(selectedIndex) ? strategies[selectedIndex] : strategies[0]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Strategy Selector
            if strategies.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(strategies.indices, id: \.self) { index in
                            Button {
                                withAnimation { selectedIndex = index }
                            } label: {
                                Text(strategies[index].strategyType)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedIndex == index ? themeColor : Color(UIColor.tertiarySystemBackground))
                                    .foregroundStyle(selectedIndex == index ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            // Header
            HStack {
                Image(systemName: "arrow.triangle.swap")
                    .foregroundStyle(themeColor)
                Text(currentStrategy.strategyType)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("~\(currentStrategy.estimatedWeeks) weeks")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeColor.opacity(0.1))
                    .foregroundStyle(themeColor)
                    .clipShape(Capsule())
            }
            
            Text(currentStrategy.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
            
            // Steps
            VStack(alignment: .leading, spacing: 12) {
                Text("Steps")
                    .font(.headline)
                
                ForEach(Array(currentStrategy.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(themeColor)
                            .clipShape(Circle())
                        
                        Text(step)
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                // Regenerate Button
                if let onRegenerate = onRegenerate {
                    Button {
                        onRegenerate()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Regenerate")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(themeColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(themeColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // Save to Recipes Button
                if let onSave = onSave {
                    Button {
                        onSave(currentStrategy)
                        withAnimation { isSaved = true }
                    } label: {
                        HStack {
                            Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                            Text(isSaved ? "Saved!" : "Save Plan")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSaved ? .green : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSaved ? Color.green.opacity(0.1) : themeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(isSaved)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onChange(of: selectedIndex) { _, _ in
            isSaved = false
        }
    }
}
