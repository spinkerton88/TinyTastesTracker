//
//  ToddlerPage.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct ToddlerPage: View {
    @Bindable var appState: AppState
    
    var body: some View {
        TabView {
            MealBuilderView(appState: appState)
                .tabItem {
                    Label("Meal Builder", systemImage: "fork.knife.circle.fill")
                }
            
            BalancePage(appState: appState)
                .tabItem {
                    Label("Balance", systemImage: "chart.bar.fill")
                }
        }
    }
}

// MARK: - Meal Builder View

struct MealBuilderView: View {
    @Bindable var appState: AppState
    
    @State private var selectedFoods: Set<String> = []
    @State private var showingSaveSheet = false
    
    // Search & Filter States
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    
    // Camera & Scan States
    enum ScanMode { case food, package }
    @State private var scanMode: ScanMode = .food
    @State private var showingCamera = false
    @State private var showingBarcodeScanner = false
    @State private var showingRecipePicker = false
    
    @State private var isIdentifyingFood = false
    @State private var identificationError: String?
    @State private var showIdentificationAlert = false
    @State private var aiIdentifiedFoodName = ""
    
    private var filteredFoods: [FoodItem] {
        appState.allKnownFoods.filter { food in
            let matchesSearch = searchText.isEmpty ||
                food.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil ||
                food.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    // Group foods by category for section headers
    private var foodsByCategory: [(category: FoodCategory, foods: [FoodItem])] {
        let grouped = Dictionary(grouping: filteredFoods) { $0.category }

        // Sort by category order (vegetables, fruits, proteins, grains, dairy, snacks, beverages)
        let categoryOrder: [FoodCategory] = [.vegetables, .fruits, .proteins, .grains, .dairy, .snacks, .beverages]

        return categoryOrder.compactMap { category in
            guard let foods = grouped[category], !foods.isEmpty else { return nil }
            return (category: category, foods: foods.sorted { $0.name < $1.name })
        }
    }

    private let gridColumns = [
        GridItem(.adaptive(minimum: 70), spacing: 8)
    ]
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: appState.themeColor
                ) {
                    selectedCategory = nil
                }

                ForEach(FoodCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue.capitalized,
                        isSelected: selectedCategory == category,
                        color: appState.themeColor
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    private var selectedFoodsView: some View {
        Group {
            if !selectedFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected (\(selectedFoods.count))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedFoods), id: \.self) { foodId in
                                if let food = appState.allKnownFoods.first(where: { $0.id == foodId }) {
                                    SelectedFoodChip(food: food, themeColor: appState.themeColor) {
                                        selectedFoods.remove(foodId)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var foodGrid: some View {
        LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
            ForEach(foodsByCategory, id: \.category) { section in
                Section {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(section.foods) { food in
                            CompactFoodItem(
                                food: food,
                                isSelected: selectedFoods.contains(food.id),
                                themeColor: appState.themeColor
                            ) {
                                HapticManager.selection()
                                if selectedFoods.contains(food.id) {
                                    selectedFoods.remove(food.id)
                                } else {
                                    selectedFoods.insert(food.id)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(section.category.rawValue.capitalized)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(appState.themeColor)

                        Spacer()

                        Text("\(section.foods.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
            }
        }
    }

    private var foodTraySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FoodTrayHeader(
                appState: appState,
                scanMode: $scanMode,
                showingCamera: $showingCamera,
                showingRecipePicker: $showingRecipePicker,
                showingBarcodeScanner: $showingBarcodeScanner
            )

            searchBar
            categoryFilters
            selectedFoodsView

            Text("\(filteredFoods.count) foods")
                .font(.caption)
                .foregroundStyle(.secondary)

            foodGrid
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(color: appState.themeColor)

                ScrollView {
                    VStack(spacing: 24) {
                        TodaysPlateSection(
                            selectedFoods: $selectedFoods,
                            showingSaveSheet: $showingSaveSheet,
                            appState: appState
                        )

                        foodTraySection
                    }
                    .padding()
                }
            }
            .navigationTitle("Meal Planner")
            .withSage(context: "User is planning a meal in Toddler Mode. Selected foods: \(Array(selectedFoods).joined(separator: ", ")).", appState: appState)
            .sheet(isPresented: $showingSaveSheet) {
                SaveMealSheet(
                    selectedFoods: Array(selectedFoods),
                    appState: appState,
                    onSave: {
                        selectedFoods.removeAll()
                    }
                )
            }
            .sheet(isPresented: $showingRecipePicker) {
                GenericRecipePickerSheet(appState: appState) { recipe in
                    let customFood = appState.createCustomFoodFromRecipe(recipe)
                    if let foodId = customFood.id {
                        selectedFoods.insert(foodId)
                    }
                    HapticManager.success()
                }
            }
            .fullScreenCover(isPresented: $showingBarcodeScanner) {
                BarcodeScannerSheet(appState: appState, onBarcodeScanned: { code in
                    Task {
                        await handleBarcodeScan(code)
                    }
                })
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { capturedImage in
                    Task {
                        if scanMode == .food {
                            await identifyAndAddFood(from: capturedImage)
                        } else {
                            await analyzeAndAddPackage(from: capturedImage)
                        }
                    }
                }
            }
            .alert("Food Identified", isPresented: $showIdentificationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = identificationError {
                    Text(error)
                } else {
                    Text("Identified: \(aiIdentifiedFoodName)\n\nMake sure you've logged this food in Explorer mode first before adding to meals.")
                }
            }
            .overlay {
                if isIdentifyingFood {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Identifying food...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
        }
    }
    
    private func identifyAndAddFood(from image: UIImage) async {
        isIdentifyingFood = true
        identificationError = nil
        
        do {
            let identifiedName = try await appState.identifyFood(from: image)
            aiIdentifiedFoodName = identifiedName
            
            // Try to find matching food in known foods (standard + custom)
            let matchedFoodId = appState.allKnownFoods.first { food in
                food.name.localizedCaseInsensitiveContains(identifiedName) ||
                identifiedName.localizedCaseInsensitiveContains(food.name)
            }?.id
            
            await MainActor.run {
                isIdentifyingFood = false
                
                if let foodId = matchedFoodId {
                    // Success! Add to selected foods
                    HapticManager.success()
                    selectedFoods.insert(foodId)
                } else {
                    // Food not found
                    HapticManager.warning()
                    showIdentificationAlert = true
                }
            }
        } catch {
            await MainActor.run {
                isIdentifyingFood = false
                identificationError = "Failed to identify food. Please try again."
                HapticManager.error()
                showIdentificationAlert = true
            }
        }
    }
    
    private func analyzeAndAddPackage(from image: UIImage) async {
        isIdentifyingFood = true
        identificationError = nil
        
        do {
            let details = try await appState.analyzePackage(image: image)
            
            await MainActor.run {
                let id = "PKG_\(details.category)_\(Date().timeIntervalSince1970)"
                
                // Determine category
                let cat = FoodCategory(rawValue: details.category.lowercased()) ?? .snacks
                let col = FoodColor(rawValue: details.color.capitalized) ?? .brown
                
                let newFood = CustomFood(
                    id: id,
                    ownerId: appState.currentOwnerId ?? "",
                    name: "Scanned Item",
                    emoji: details.emoji,
                    category: cat,
                    allergens: details.allergens,
                    nutritionHighlights: details.nutritionHighlights,
                    howToServe: details.howToServe,
                    chokeHazard: details.chokeHazard,
                    color: col
                )
                
                Task {
                    do {
                        try await appState.saveCustomFood(newFood)
                        if let foodId = newFood.id {
                            selectedFoods.insert(foodId)
                        }
                        errorPresenter.showSuccess("Food added")
                    } catch {
                        errorPresenter.present(error)
                    }
                }
                
                isIdentifyingFood = false
            }
        } catch {
             await MainActor.run {
                isIdentifyingFood = false
                identificationError = "Failed to analyze package."
                HapticManager.error()
                showIdentificationAlert = true
            }
        }
    }

    private func handleBarcodeScan(_ code: String) async {
        isIdentifyingFood = true
        do {
            let product = try await appState.lookupBarcode(code)
            await MainActor.run {
                // Check if exists in known foods
                if let existing = appState.allKnownFoods.first(where: { $0.name.localizedCaseInsensitiveContains(product.productName) }) {
                    selectedFoods.insert(existing.id)
                    HapticManager.success()
                } else {
                    // Create Custom Food
                    let id = "BARCODE_\(code)"
                    let cat = product.categories.first.flatMap { FoodCategory(rawValue: $0.lowercased()) } ?? .snacks
                    
                    let newFood = CustomFood(
                        id: id,
                        ownerId: appState.currentOwnerId ?? "",
                        name: product.productName,
                        emoji: "📦",
                        category: cat,
                        allergens: product.allergens,
                        nutritionHighlights: product.nutrients?.summary ?? "",
                        howToServe: "Check package instructions",
                        chokeHazard: false,
                        color: .brown
                    )
                    
                    Task {
                        do {
                            try await appState.saveCustomFood(newFood)
                            if let foodId = newFood.id {
                                selectedFoods.insert(foodId)
                            }
                            errorPresenter.showSuccess("Food added")
                        } catch {
                            errorPresenter.present(error)
                        }
                    }
                }
                isIdentifyingFood = false
            }
        } catch {
            await MainActor.run {
                isIdentifyingFood = false
                identificationError = "Product not found or network error."
                showIdentificationAlert = true
            }
        }
    }
}

// MARK: - Food Tray Header

struct FoodTrayHeader: View {
    let appState: AppState
    @Binding var scanMode: MealBuilderView.ScanMode
    @Binding var showingCamera: Bool
    @Binding var showingRecipePicker: Bool
    @Binding var showingBarcodeScanner: Bool
    
    var body: some View {
        HStack {
            Text("Food Tray")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            
            HStack(spacing: 8) {
                // Add Recipe Button
                Button {
                    showingRecipePicker = true
                } label: {
                    Image(systemName: "book.fill")
                    .font(.caption2) // Was .system(size: 14)
                    .padding(8)
                    .background(appState.themeColor.opacity(0.1))
                    .foregroundStyle(appState.themeColor)
                    .clipShape(Circle())
                }
                
                // Scan Menu
                Menu {
                    Button {
                        HapticManager.impact(style: .medium)
                        scanMode = .food
                        showingCamera = true
                    } label: {
                        Label("Scan Food", systemImage: "camera")
                    }
                    
                    Button {
                        HapticManager.impact(style: .medium)
                        scanMode = .package
                        showingCamera = true
                    } label: {
                        Label("Scan Package", systemImage: "cube.box")
                    }
                    
                    Button {
                        HapticManager.impact(style: .medium)
                        showingBarcodeScanner = true
                    } label: {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                        Text("Scan")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(appState.themeColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Category Filter Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Selected Food Chip

struct SelectedFoodChip: View {
    let food: FoodItem // Passed directly, so correct
    let themeColor: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(food.name)
                .font(.caption)
                .fontWeight(.medium)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeColor)
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Remove \(food.name)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Compact Food Item for Grid

struct CompactFoodItem: View {
    let food: FoodItem // Passed directly
    let isSelected: Bool
    let themeColor: Color
    let onTap: () -> Void
    
    // ... body remains same
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? themeColor : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    FoodImageView(food: food, size: 50)
                    
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body) // Was .system(size: 16)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(themeColor).frame(width: 14, height: 14))
                            }
                            Spacer()
                        }
                        .padding(4)
                    }
                }
                
                Text(food.name)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? themeColor : .primary)
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(food.name)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint(isSelected ? "Double tap to remove from plate" : "Double tap to add to plate")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Interactive Plate View

// MARK: - Interactive Plate View

struct PlateView: View {
    let selectedFoods: [String]
    let themeColor: Color
    let appState: AppState // Add AppState dependency
    @State private var showConfetti = false
    
    // ... existing properties ...
    private var colorBalance: [FoodColor: Int] {
        var colors: [FoodColor: Int] = [:]
        for foodId in selectedFoods {
            // First check if it's a known food (could be standard or custom)
            if let food = appState.allKnownFoods.first(where: { $0.id == foodId }) {
                // Check if it's a CustomFood with containedColors
                if let customFood = appState.customFoods.first(where: { $0.id == foodId }),
                   !customFood.containedColors.isEmpty {
                    // Add all contained colors
                    for color in customFood.containedColors {
                        colors[color, default: 0] += 1
                    }
                } else {
                    // Fallback to single color
                    colors[food.color, default: 0] += 1
                }
            }
        }
        return colors
    }
    
    private var isBalanced: Bool {
        colorBalance.keys.count >= 5
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Interactive Plate
            ZStack {
                // Plate base with shadow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(UIColor.secondarySystemBackground),
                                Color(UIColor.tertiarySystemBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                
                // Rainbow progress ring
                RainbowProgressRing(colorBalance: colorBalance, isBalanced: isBalanced)
                    .frame(width: 240, height: 240)
                
                // Drop zones and food items
                ZStack {
                    // Food items arranged on plate
                    ForEach(Array(selectedFoods.prefix(6).enumerated()), id: \.element) { index, foodId in
                        let angle = Double(index) * (360.0 / Double(min(selectedFoods.count, 6)))
                        
                        PlateFoodItem(foodId: foodId, appState: appState) // Pass AppState
                            .offset(
                                x: cos(angle * .pi / 180) * 70,
                                y: sin(angle * .pi / 180) * 70
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 200, height: 200)
                
                // Confetti overlay
                if showConfetti {
                    ConfettiView()
                        .frame(width: 300, height: 300)
                        .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedFoods)
            .onChange(of: isBalanced) { _, balanced in
                if balanced {
                    showConfetti = true
                    HapticManager.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showConfetti = false
                    }
                }
            }
            
            // Balance indicator
            if !selectedFoods.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: isBalanced ? "star.fill" : "star")
                        .foregroundStyle(isBalanced ? .yellow : .gray)
                        .font(.title3)
                    
                    Text(isBalanced ? "Rainbow Balanced!" : "\(colorBalance.keys.count)/5 colors")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isBalanced ? themeColor : .secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isBalanced ? themeColor.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Nutrition summary
            if !selectedFoods.isEmpty {
                NutritionSummaryBadges(selectedFoods: selectedFoods, appState: appState)
            }
        }
    }
}

// MARK: - Rainbow Progress Ring

struct RainbowProgressRing: View {
    let colorBalance: [FoodColor: Int]
    let isBalanced: Bool
    
    private let rainbowColors: [FoodColor] = [.red, .orange, .yellow, .green, .purple]
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            // Colored segments
            ForEach(Array(rainbowColors.enumerated()), id: \.element) { index, color in
                let hasColor = colorBalance[color] != nil
                
                Circle()
                    .trim(from: CGFloat(index) / 5, to: CGFloat(index + 1) / 5)
                    .stroke(
                        hasColor ? color.displayColor : Color.clear,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .opacity(hasColor ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: hasColor)
            }
            
            // Glow effect when balanced
            if isBalanced {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: rainbowColors.map { $0.displayColor },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 12
                    )
                    .blur(radius: 8)
                    .opacity(0.6)
                    .scaleEffect(1.05)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rainbow Progress")
        .accessibilityValue(isBalanced ? "Balanced! 5 out of 5 colors" : "\(colorBalance.keys.count) out of 5 colors")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Plate Food Item

struct PlateFoodItem: View {
    let foodId: String
    let appState: AppState // Add dependency
    @State private var appeared = false
    
    private var food: FoodItem? {
        appState.allKnownFoods.first(where: { $0.id == foodId })
    }
    
    var body: some View {
        ZStack {
            // Color background
            Circle()
                .fill(food?.color.displayColor.opacity(0.3) ?? Color.gray.opacity(0.2))
                .frame(width: 56, height: 56)
            
            // Food emoji
            if let food = food {
                FoodImageView(food: food, size: 40)
                    .scaleEffect(appeared ? 1.0 : 0.3)
            } else {
                Text("🍽️")
                    .font(.title)
                    .scaleEffect(appeared ? 1.0 : 0.3)
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}

// MARK: - Nutrition Summary Badges

struct NutritionSummaryBadges: View {
    let selectedFoods: [String]
    let appState: AppState // Add dependency
    
    private var nutrients: Set<Nutrient> {
        var allNutrients: Set<Nutrient> = []
        for foodId in selectedFoods {
            if let food = appState.allKnownFoods.first(where: { $0.id == foodId }) {
                food.nutrients.forEach { allNutrients.insert($0) }
            }
        }
        return allNutrients
    }
    
    var body: some View {
        if !nutrients.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nutrients")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(nutrients), id: \.self) { nutrient in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(nutrient.color)
                                    .frame(width: 6, height: 6)
                                Text(nutrient.rawValue)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(nutrient.color.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}


// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        let x: CGFloat
        let y: CGFloat
        let rotation: Double
        let scale: CGFloat
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 8, height: 12)
                    .rotationEffect(.degrees(piece.rotation))
                    .scaleEffect(piece.scale)
                    .position(x: piece.x, y: piece.y)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        confettiPieces = (0..<30).map { _ in
            ConfettiPiece(
                color: colors.randomElement() ?? .yellow,
                x: CGFloat.random(in: 50...250),
                y: CGFloat.random(in: -50...100),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5)
            )
        }
    }
}

// MARK: - Interactive Food Tray Item

struct FoodTrayItem: View {
    let foodId: String
    let isSelected: Bool
    let themeColor: Color
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var food: FoodItem? {
        Constants.allFoods.first(where: { $0.id == foodId })
    }
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            onTap()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Background with gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [themeColor, themeColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(
                            color: isSelected ? themeColor.opacity(0.3) : Color.black.opacity(0.1),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? 4 : 2
                        )
                    
                    // Color indicator ring
                    if let foodColor = food?.color {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(foodColor.displayColor, lineWidth: 3)
                            .frame(width: 90, height: 90)
                            .opacity(isSelected ? 0.5 : 1.0)
                    }
                    
                    // Food emoji
                    Text(food?.emoji ?? "🍽️")
                        .font(.system(size: 40)) // Large decorative icon
                        .scaleEffect(isPressed ? 0.85 : 1.0)
                    
                    // Selection checkmark
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(themeColor)
                                        .font(.title3) // Was .system(size: 24)
                                }
                            }
                            Spacer()
                        }
                        .padding(6)
                    }
                }
                
                // Food name
                Text(food?.name ?? foodId)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? themeColor : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 90)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(BounceButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Bounce Button Style

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Save Meal Sheet (Enhanced)

struct SaveMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    
    let selectedFoods: [String]
    @Bindable var appState: AppState
    let onSave: () -> Void
    
    @State private var mealTime = Date()
    @State private var notes = ""
    @State private var selectedStrategy: FeedingStrategy = .none
    @State private var mealType: MealType = .lunch
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Details") {
                    DatePicker("Time", selection: $mealTime)
                    Picker("Meal Type", selection: $mealType) {
                        Text("Breakfast").tag(MealType.breakfast)
                        Text("Lunch").tag(MealType.lunch)
                        Text("Dinner").tag(MealType.dinner)
                        Text("Snack").tag(MealType.snack)
                    }
                }
                
                Section("Foods") {
                    ForEach(selectedFoods, id: \.self) { foodId in
                        if let food = appState.allKnownFoods.first(where: { $0.id == foodId }) {
                            HStack {
                                Text(food.emoji)
                                Text(food.name)
                                Spacer()
                                Circle()
                                    .fill(food.color.displayColor)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
                
                Section {
                    Picker("Feeding Strategy", selection: $selectedStrategy) {
                        ForEach(FeedingStrategy.allCases, id: \.self) { strategy in
                            Text(strategy.rawValue).tag(strategy)
                        }
                    }
                    Text(selectedStrategy.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Behavioral Approach")
                }
                
                Section("Notes") {
                    TextField("What happened?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Meal")
            .withSage(context: "User is logging a meal. Foods: \(selectedFoods.joined(separator: ", ")). Strategy: \(selectedStrategy.rawValue).", appState: appState)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Log") {
                        saveMeal()
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                determineMealType()
            }
        }
    }
    
    private func determineMealType() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 { mealType = .breakfast }
        else if hour < 15 { mealType = .lunch }
        else if hour < 17 { mealType = .snack }
        else { mealType = .dinner }
    }
    
    private func saveMeal() {
        Task {
            do {
                // Create full meal log
                let log = MealLog(
                    ownerId: appState.currentOwnerId ?? "",
                    childId: appState.currentChildId ?? "",
                    foods: selectedFoods,
                    feedingStrategy: selectedStrategy,
                    notes: notes,
                    timestamp: mealTime,
                    mealType: mealType
                )
                
                // Save via AppState (which also updates individual food history)
                try await appState.saveMealLog(log)
                errorPresenter.showSuccess("Meal logged")
            } catch {
                errorPresenter.present(error)
            }
        }
    }
}

// MARK: - Today's Plate Section Component

struct TodaysPlateSection: View {
    @Binding var selectedFoods: Set<String>
    @Binding var showingSaveSheet: Bool
    let appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build Today's Plate")
                .font(.title2)
                .fontWeight(.bold)
            
            if selectedFoods.isEmpty {
                Text("Select foods from the tray below to build a balanced meal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                PlateView(selectedFoods: Array(selectedFoods), themeColor: appState.themeColor, appState: appState)
            }
            
            if !selectedFoods.isEmpty {
                Button {
                    showingSaveSheet = true
                } label: {
                    Label("Review & Save Meal", systemImage: "checkmark.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appState.themeColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
