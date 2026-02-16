//
//  FoodTrackerPage.swift
//  TinyTastesTracker
import SwiftUI

struct FoodTrackerPage: View {
    @Bindable var appState: AppState
    
    @State private var selectedFood: FoodItem?
    @State private var showAllergenWarning = false
    @State private var pendingFoodSelection: FoodItem?

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var filterStatus: FilterStatus = .all
    
    // Camera States
    @State private var showingCamera = false
    @State private var isIdentifyingFood = false
    @State private var identificationError: String?
    @State private var showIdentificationAlert = false
    @State private var aiIdentifiedFoodName = ""
    @State private var showingAddCustomFood = false
    
    // Unmark State
    @State private var showUnmarkConfirmation = false
    @State private var pendingUnmarkFood: FoodItem?
    @State private var showUndoToast = false
    @State private var lastUnmarkedFoodId: String?
    
    enum FilterStatus {
        case all, toTry, tried
    }
    
    private var filteredFoods: [FoodItem] {
        let showOnlyTried: Bool? = {
            switch filterStatus {
            case .all: return nil
            case .toTry: return false
            case .tried: return true
            }
        }()

        // Filter out recipes from the explorer list (pure "ingredients" only)
        let explorableFoods = appState.allKnownFoods.filter { !$0.id.hasPrefix("RECIPE_") }

        return appState.filteredFoods(
            searchText: searchText,
            category: selectedCategory,
            showOnlyTried: showOnlyTried,
            from: explorableFoods
        )
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
    
    // MARK: - Views
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("\(appState.triedFoodsCount)/100 Foods Tried")
                .font(.title2)
                .fontWeight(.bold)
            
            ProgressView(value: Double(appState.triedFoodsCount), total: 100)
                .tint(appState.themeColor)
                .frame(height: 8)
                .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Clear search")
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Status Filters
                FilterChip(
                    title: "All",
                    isSelected: filterStatus == .all,
                    color: appState.themeColor
                ) {
                    filterStatus = .all
                    selectedCategory = nil
                }
                
                FilterChip(
                    title: "To Try",
                    isSelected: filterStatus == .toTry,
                    color: appState.themeColor
                ) {
                    filterStatus = .toTry
                    selectedCategory = nil
                }
                
                FilterChip(
                    title: "Tried",
                    isSelected: filterStatus == .tried,
                    color: appState.themeColor
                ) {
                    filterStatus = .tried
                    selectedCategory = nil
                }
                
                Divider()
                    .frame(height: 30)
                
                // Category Filters
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue.capitalized,
                        isSelected: selectedCategory == category,
                        color: appState.themeColor
                    ) {
                        if selectedCategory == category {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                            filterStatus = .all
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var foodGridContent: some View {
        Group {
            if filteredFoods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48)) // Large decorative emoji
                        .foregroundStyle(.secondary)
                    Text("No foods found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Try adjusting your filters")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                    ForEach(foodsByCategory, id: \.category) { section in
                        Section {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                                ForEach(section.foods) { food in
                                    FoodItemCard(
                                        food: food,
                                        isTried: appState.isFoodTried(food.id),
                                        themeColor: appState.themeColor,
                                        knownAllergies: appState.userProfile?.knownAllergies ?? []
                                    )
                                    .onTapGesture {
                                        checkAllergensAndSelect(food)
                                    }
                                    .contextMenu {
                                        if appState.isFoodTried(food.id) {
                                            Button(role: .destructive) {
                                                pendingUnmarkFood = food
                                                showUnmarkConfirmation = true
                                            } label: {
                                                Label("Unmark as Tried", systemImage: "xmark.circle")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } header: {
                            HStack {
                                Text(section.category.rawValue.capitalized)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(appState.themeColor)

                                Spacer()

                                Text("\(section.foods.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    // floatingCameraButton removed per HIG audit

    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            GradientBackground(color: appState.themeColor)
            
            ScrollView {
                VStack(spacing: 20) {
                progressHeader
                searchBar
                filterChips
                
                // Results count
                if searchText.isEmpty && selectedCategory == nil && filterStatus == .all {
                    // Don't show count for default view
                } else {
                    Text("\(filteredFoods.count) foods")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                
                foodGridContent
            }
            .padding(.bottom, 100)
        }
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                // Loading Overlay
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
                .navigationTitle("100 Foods Challenge")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink(destination: MessyFaceGalleryView(appState: appState)) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .accessibilityLabel("Messy Face Gallery")
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            Button(action: { showingAddCustomFood = true }) {
                                ZStack(alignment: .bottomTrailing) {
                                    // Carrot SF Symbol as main icon
                                    Image(systemName: "carrot.fill")

                                    // Plus badge overlay
                                    Circle()
                                        .fill(appState.themeColor)
                                        .frame(width: 14, height: 14)
                                        .overlay {
                                            Image(systemName: "plus")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        .offset(x: 3, y: 3)
                                }
                            }
                            .accessibilityLabel("Add Custom Food")
                            
                            Button(action: {
                                HapticManager.impact(style: .medium)
                                showingCamera = true
                            }) {
                                Image(systemName: "camera.fill")
                            }
                            .accessibilityLabel("Identify food with camera")
                        }
                    }
                }
            .withSage(context: "User is checking 100 Foods progress. Tried: \(appState.triedFoodsCount)/100.", appState: appState)
                .sheet(item: $selectedFood) { food in
                FoodDetailModal(food: food, appState: appState)
            }
            .overlay(alignment: .bottom) {
                if showUndoToast {
                    ToastView(
                        message: "Marked as not tried",
                        buttonTitle: "Undo",
                        action: performUndo
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation {
                                showUndoToast = false
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(
                    title: "Identify Food",
                    subtitle: "Point camera at food to identify",
                    iconName: "carrot.fill"
                ) { capturedImage in
                    Task {
                        await identifyAndSelectFood(from: capturedImage)
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomFood) {
                AddCustomFoodSheet(appState: appState)
            }
            .alert("Food Identified", isPresented: $showIdentificationAlert) {
                Button("Search Manually", role: .cancel) {
                    searchText = aiIdentifiedFoodName
                }
                Button("OK", role: .cancel) {}
            } message: {
                if let error = identificationError {
                    Text(error)
                } else {
                    Text("Identified: \(aiIdentifiedFoodName)\n\nThis food isn't in our database yet. Try searching for it manually or log a similar food.")
                }
            }
            .alert("Allergen Warning", isPresented: $showAllergenWarning) {
                Button("Cancel", role: .cancel) {
                    pendingFoodSelection = nil
                }
                Button("Continue Anyway", role: .destructive) {
                    if let food = pendingFoodSelection {
                        selectedFood = food
                    }
                    pendingFoodSelection = nil
                }
            } message: {
                if let food = pendingFoodSelection {
                    let matchingAllergens = getMatchingAllergens(for: food)
                    Text("⚠️ This food contains: \(matchingAllergens.joined(separator: ", "))\n\nYour baby has a known allergy to these ingredients. Are you sure you want to continue?")
                }
            }
            .confirmationDialog(
                "Unmark as Tried?",
                isPresented: $showUnmarkConfirmation,
                titleVisibility: .visible,
                presenting: pendingUnmarkFood
            ) { food in
                Button("Unmark", role: .destructive) {
                    lastUnmarkedFoodId = food.id
                    appState.unmarkFoodAsTried(food.id)
                    withAnimation {
                        showUndoToast = true
                    }
                    pendingUnmarkFood = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingUnmarkFood = nil
                }
            } message: { food in
                Text("This will remove '\(food.name)' from your tried foods list and update your rainbow progress.")
            }
        }
    }
    
    private func performUndo() {
        if let foodId = lastUnmarkedFoodId {
            appState.undoUnmarkFood(foodId)
            withAnimation {
                showUndoToast = false
            }
            lastUnmarkedFoodId = nil
            HapticManager.success()
        }
    }

    private func checkAllergensAndSelect(_ food: FoodItem) {
        let matchingAllergens = getMatchingAllergens(for: food)
        
        if !matchingAllergens.isEmpty {
            // Food contains known allergens - show warning
            pendingFoodSelection = food
            showAllergenWarning = true
            HapticManager.warning()
        } else {
            // Safe to select
            selectedFood = food
        }
    }
    
    private func getMatchingAllergens(for food: FoodItem) -> [String] {
        guard let knownAllergies = appState.userProfile?.knownAllergies else {
            return []
        }
        
        return food.allergens.filter { foodAllergen in
            knownAllergies.contains { knownAllergy in
                foodAllergen.localizedCaseInsensitiveContains(knownAllergy) ||
                knownAllergy.localizedCaseInsensitiveContains(foodAllergen)
            }
        }
    }
    
    private func identifyAndSelectFood(from image: UIImage) async {
        isIdentifyingFood = true
        identificationError = nil
        
        do {
            let identifiedName = try await appState.identifyFood(from: image)
            aiIdentifiedFoodName = identifiedName
            
            // Try to find matching food in database
            let matchedFood = Constants.allFoods.first { food in
                food.name.localizedCaseInsensitiveContains(identifiedName) ||
                identifiedName.localizedCaseInsensitiveContains(food.name)
            }
            
            await MainActor.run {
                isIdentifyingFood = false
                
                if let food = matchedFood {
                    // Success! Pre-select this food and open modal
                    HapticManager.success()
                    selectedFood = food
                } else {
                    // Food not in database, show alert with suggestion
                    HapticManager.warning()
                    showIdentificationAlert = true
                }
            }
        } catch {
            await MainActor.run {
                isIdentifyingFood = false
                identificationError = "Failed to identify food. Please try again or search manually."
                HapticManager.error()
                showIdentificationAlert = true
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 12) // Increased touch target (HIG)
                .background(isSelected ? color : Color.gray.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct FoodItemCard: View {
    let food: FoodItem
    let isTried: Bool
    let themeColor: Color
    let knownAllergies: [String]
    
    private var hasKnownAllergen: Bool {
        food.allergens.contains { foodAllergen in
            knownAllergies.contains { knownAllergy in
                foodAllergen.localizedCaseInsensitiveContains(knownAllergy) ||
                knownAllergy.localizedCaseInsensitiveContains(foodAllergen)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            FoodImageView(food: food, size: 50)
                .opacity(isTried ? 0.5 : 1.0)

            Text(food.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(isTried ? .secondary : .primary)
        }
        .frame(width: 80, height: 80)
        .background(isTried ? Color.gray.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    hasKnownAllergen ? Color.red : (isTried ? themeColor : Color.gray.opacity(0.3)),
                    lineWidth: hasKnownAllergen ? 3 : 2
                )
        )
        .overlay(alignment: .topTrailing) {
            if isTried {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(themeColor)
                    .padding(4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(food.name)
        .accessibilityValue(isTried ? "Tried" : "Not Tried")
        .accessibilityHint(isTried ? "Double tap to view details" : "Double tap to view details or mark as tried")
        .accessibilityAddTraits(.isButton)
    }
}
