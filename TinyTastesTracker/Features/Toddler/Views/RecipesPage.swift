//
//  RecipesPage.swift
//  TinyTastesTracker
//

import SwiftUI
import PhotosUI

struct RecipesPage: View {
    @Bindable var appState: AppState

    @State private var selectedTab: RecipeTab = .plan
    @State private var showingShoppingList = false

    enum RecipeTab: String, CaseIterable {
        case plan = "Plan"
        case recipes = "Recipes"
    }

    private var uncompletedShoppingCount: Int {
        appState.shoppingListItems.filter { !$0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(color: appState.themeColor)

                VStack(spacing: 0) {
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    ForEach(RecipeTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Recipe View Selection")
                .padding()

                // Content
                if selectedTab == .plan {
                    WeeklyMealPlanView(appState: appState)
                } else {
                    RecipeBoxView(appState: appState)
                }
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedTab == .plan {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingShoppingList = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "cart")
                                    .font(.title3)

                                if uncompletedShoppingCount > 0 {
                                    Text("\(uncompletedShoppingCount)")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        .accessibilityLabel("Shopping List")
                        .accessibilityValue("\(uncompletedShoppingCount) items")
                    }
                }
            }
            .sheet(isPresented: $showingShoppingList) {
                ShoppingListView(appState: appState)
            }
            .withSage(context: "User is managing recipes. Recipe count: \(appState.recipes.count).", appState: appState)
        }
    }
}

// MARK: - Weekly Meal Plan View

struct WeeklyMealPlanView: View {
    @Bindable var appState: AppState
    @State private var weekStart = Calendar.current.startOfWeek(for: Date())
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Meal Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Tap a slot to add a recipe.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundStyle(appState.themeColor.opacity(0.3))
                }
                .padding()
                .background(appState.themeColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Days of Week
                ForEach(0..<7, id: \.self) { dayOffset in
                    DayMealCard(
                        date: Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart)!,
                        appState: appState
                    )
                }
            }
            .padding(.vertical)
        }
    }
}

struct DayMealCard: View {
    let date: Date
    @Bindable var appState: AppState

    @State private var showingItemPicker = false
    @State private var selectedMealType: MealType?

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var mealEntries: [MealType: [MealPlanEntry]] {
        appState.getMealPlanEntries(for: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                Text(date, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
                if isToday {
                    Text("TODAY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appState.themeColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            
            // Meal Slots Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { mealType in
                    MealSlot(
                        mealType: mealType,
                        entries: mealEntries[mealType] ?? [],
                        onTap: {
                            selectedMealType = mealType
                            showingItemPicker = true
                        },
                        onRemove: { entry in
                            appState.removeMealPlanEntry(entry)
                            // Regenerate shopping list
                            if let ownerId = appState.currentOwnerId {
                                appState.generateShoppingListFromMealPlan()
                            }
                        }
                    )
                    .accessibilityLabel(mealType.rawValue.capitalized)
                    .accessibilityHint(mealEntries[mealType]?.isEmpty ?? true ? "Tap to add items" : "Tap to add more items")
                }
            }
        }
        .padding()
        .background(isToday ? appState.themeColor.opacity(0.05) : .clear)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isToday ? appState.themeColor : Color.gray.opacity(0.2), lineWidth: isToday ? 2 : 1)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingItemPicker) {
            if let mealType = selectedMealType {
                ItemPickerSheet(
                    date: date,
                    mealType: mealType,
                    appState: appState
                )
            }
        }
    }
}

struct MealSlot: View {
    let mealType: MealType
    let entries: [MealPlanEntry]
    let onTap: () -> Void
    let onRemove: (MealPlanEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mealType.rawValue.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)

            if entries.isEmpty {
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(entries) { entry in
                        HStack {
                            Text(entry.displayName)
                                .font(.subheadline)
                                .lineLimit(2)
                            Spacer()
                            Button(action: { onRemove(entry) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                        }
                    }

                    // "Add more" button
                    Button(action: onTap) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add more")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(!entries.isEmpty ? Color(.secondarySystemBackground) : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ItemPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    let date: Date
    let mealType: MealType
    @Bindable var appState: AppState

    enum ItemType: String, CaseIterable {
        case recipe = "Recipe"
        case food = "Food"
    }

    @State private var selectedItemType: ItemType = .recipe
    @State private var showAllMealTypes = false

    private var filteredRecipes: [Recipe] {
        if showAllMealTypes {
            return appState.recipes
        } else {
            return appState.recipes.filter { recipe in
                recipe.mealTypes.contains(mealType)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Item Type Picker
                Picker("Item Type", selection: $selectedItemType) {
                    ForEach(ItemType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content based on selection
                if selectedItemType == .recipe {
                    VStack(spacing: 0) {
                        // Meal Type Filter Toggle
                        HStack {
                            Toggle("Show all meal types", isOn: $showAllMealTypes)
                                .tint(appState.themeColor)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))

                        // Recipe List
                        if filteredRecipes.isEmpty {
                            ContentUnavailableView {
                                Label("No Recipes", systemImage: "fork.knife")
                            } description: {
                                if showAllMealTypes {
                                    Text("You haven't created any recipes yet.")
                                } else {
                                    Text("No recipes found for \(mealType.rawValue).\nTurn on 'Show all meal types' to see all recipes.")
                                }
                            }
                        } else {
                            List(filteredRecipes) { recipe in
                                Button {
                                    addRecipeToMealPlan(recipe)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(recipe.ingredients)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Food List
                    List(appState.allKnownFoods) { food in
                        Button {
                            addFoodToMealPlan(food)
                        } label: {
                            HStack {
                                Text(food.emoji)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(food.category.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to \(mealType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addRecipeToMealPlan(_ recipe: Recipe) {
        // Get existing entries for this meal to determine sortOrder
        let existingEntries = appState.getMealPlanEntries(for: date)[mealType] ?? []
        let nextSortOrder = existingEntries.count

        if let ownerId = appState.currentOwnerId, let childId = appState.currentChildId {
            let entry = MealPlanEntry(
                ownerId: ownerId,
                childId: childId,
                date: date,
                mealType: mealType,
                recipeId: recipe.id ?? UUID().uuidString, // Fallback if ID invalid, though should be valid from DB
                recipeName: recipe.title,
                sortOrder: nextSortOrder
            )
            appState.addMealPlanEntry(entry)

            // Regenerate shopping list
            appState.generateShoppingListFromMealPlan()
        }
        dismiss()
    }

    private func addFoodToMealPlan(_ food: FoodItem) {
        // Get existing entries for this meal to determine sortOrder
        let existingEntries = appState.getMealPlanEntries(for: date)[mealType] ?? []
        let nextSortOrder = existingEntries.count

        if let ownerId = appState.currentOwnerId, let childId = appState.currentChildId {
            let entry = MealPlanEntry(
                ownerId: ownerId,
                childId: childId,
                date: date,
                mealType: mealType,
                foodId: food.id,
                foodName: food.name,
                sortOrder: nextSortOrder
            )
            appState.addMealPlanEntry(entry)
        }
        dismiss()
    }
}

struct RecipePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    let date: Date
    let mealType: MealType
    @Bindable var appState: AppState

    @State private var showAllMealTypes = false

    private var filteredRecipes: [Recipe] {
        if showAllMealTypes {
            return appState.recipes
        } else {
            return appState.recipes.filter { recipe in
                recipe.mealTypes.contains(mealType)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Toggle
                HStack {
                    Toggle("Show all meal types", isOn: $showAllMealTypes)
                        .tint(appState.themeColor)
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                if filteredRecipes.isEmpty {
                    ContentUnavailableView {
                        Label("No Recipes", systemImage: "fork.knife")
                    } description: {
                        if showAllMealTypes {
                            Text("You haven't created any recipes yet.")
                        } else {
                            Text("No recipes found for \(mealType.rawValue).\nTurn on 'Show all meal types' to see all recipes.")
                        }
                    }
                } else {
                    List(filteredRecipes) { recipe in
                        Button {
                            if let ownerId = appState.currentOwnerId, let childId = appState.currentChildId {
                                let entry = MealPlanEntry(
                                    ownerId: ownerId,
                                    childId: childId,
                                    date: date,
                                    mealType: mealType,
                                    recipeId: recipe.id ?? UUID().uuidString,
                                    recipeName: recipe.title
                                )
                                appState.addMealPlanEntry(entry)
                                // Regenerate shopping list
                                appState.generateShoppingListFromMealPlan()
                            }
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(recipe.ingredients)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select a Recipe for \(mealType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Recipe Box View

struct RecipeBoxView: View {
    @Bindable var appState: AppState
    @State private var activeSheet: SheetType?
    @State private var showingShoppingList = false
    @State private var showingRecipeScanSheet = false

    enum SheetType: Identifiable {
        case aiGenerator
        case manualCreator
        case scanRecipe

        var id: Int {
            hashValue
        }
    }
    
    var body: some View {
        // Create a bindable proxy for the recipe manager to allow binding to its properties
        @Bindable var recipeManager = appState.recipeManager

        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with count
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Recipe Box")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(appState.recipes.count) recipes saved")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            activeSheet = .manualCreator
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("New")
                            }
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(appState.themeColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .accessibilityLabel("Create New Recipe")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Quick Actions
                    HStack(spacing: 12) {
                        Button {
                            activeSheet = .aiGenerator
                        } label: {
                            VStack(spacing: 8) {
                                SageIcon(size: .medium, style: .gradient)
                                Text("Chef Sage")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .foregroundStyle(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .accessibilityLabel("Smart Recipe Chef")
                        .accessibilityHint("Generate a recipe automatically")
                        
                        Button {
                            activeSheet = .scanRecipe
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                .foregroundStyle(.blue)
                                Text("Scan Recipe")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .accessibilityLabel("Scan Recipe from Image")
                    }
                    .padding(.horizontal)
                    
                    // Recipe List
                    if appState.recipes.isEmpty {
                        ContentUnavailableView(
                            "No Recipes Yet",
                            systemImage: "book.closed",
                            description: Text("Create your first recipe automatically or with manual entry")
                        )
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach($recipeManager.recipes) { $recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: $recipe, appState: appState)) {
                                    RecipeListRow(recipe: $recipe.wrappedValue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .refreshable {
                            // Pull to refresh - reload data
                            if let ownerId = appState.currentOwnerId {
                                appState.recipeManager.loadData(ownerId: ownerId)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Shopping List Button
            Button {
                showingShoppingList = true
            } label: {
                HStack {
                    Image(systemName: "cart")
                    Text("View Shopping List")
                    Spacer()
                    if !appState.shoppingListItems.isEmpty {
                        Text("\(appState.shoppingListItems.filter { !$0.isCompleted }.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(appState.themeColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .sheet(item: $activeSheet) { type in
            switch type {
            case .aiGenerator:
                AIRecipeGeneratorSheet(appState: appState)
            case .manualCreator:
                RecipeFormView(appState: appState, mode: .new)
            case .scanRecipe:
                RecipeScannerSheet(appState: appState)
            }
        }
        .sheet(isPresented: $showingShoppingList) {
            ShoppingListView(appState: appState)
        }
    }
}

struct RecipeListRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 12) {
            // Use thumbnail for list view performance
            if let data = recipe.thumbnailData ?? recipe.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(recipe.ingredients.components(separatedBy: ",").count > 1 ? "\(recipe.ingredients.components(separatedBy: ",").count) ingredients" : "1 ingredient")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

//MARK: - Shopping List

struct ShoppingListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Bindable var appState: AppState
    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var newItemUnit = ""
    @State private var activeSheet: SheetType?
    @State private var remindersManager = RemindersIntegrationManager()
    @State private var showingExportAlert = false
    @State private var exportError: Error?
    @State private var isExporting = false
    @State private var collapsedCategories: Set<GroceryCategory> = []
    
    enum SheetType: Identifiable {
        case foodList
        case recipePicker
        case addItemDetail
        
        var id: Int {
            hashValue
        }
    }
    
    var groupedItems: [GroceryCategory: [ShoppingListItem]] {
        Dictionary(grouping: appState.shoppingListItems) { $0.category }
    }
    
    var sortedCategories: [GroceryCategory] {
        groupedItems.keys.sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Controls Header
                VStack(spacing: 12) {
                    HStack {
                        TextField("Add item...", text: $newItemName)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        if !newItemName.isEmpty {
                            Button("Add") {
                                activeSheet = .addItemDetail
                            }
                            .foregroundStyle(appState.themeColor)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            activeSheet = .foodList
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Add from Food List")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            activeSheet = .recipePicker
                        } label: {
                            HStack {
                                Image(systemName: "book")
                                Text("Add from Recipe")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Shopping list items grouped by category
                List {
                    if appState.shoppingListItems.isEmpty {
                        ContentUnavailableView(
                            "No items yet",
                            systemImage: "cart",
                            description: Text("Add items to your shopping list")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(sortedCategories, id: \.self) { category in
                            Section {
                                if !collapsedCategories.contains(category) {
                                    ForEach(groupedItems[category] ?? []) { item in
                                        ShoppingItemRow(item: item, appState: appState)
                                    }
                                    .onDelete { indexSet in
                                        deleteItems(at: indexSet, in: category)
                                    }
                                }
                            } header: {
                                Button {
                                    withAnimation {
                                        if collapsedCategories.contains(category) {
                                            collapsedCategories.remove(category)
                                        } else {
                                            collapsedCategories.insert(category)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(category.icon)
                                        Text(category.rawValue)
                                            .font(.headline)
                                        Spacer()
                                        let itemCount = groupedItems[category]?.filter { !$0.isCompleted }.count ?? 0
                                        if itemCount > 0 {
                                            Text("\(itemCount)")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(appState.themeColor)
                                                .clipShape(Capsule())
                                        }
                                        Image(systemName: collapsedCategories.contains(category) ? "chevron.right" : "chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            exportToReminders()
                        } label: {
                            Label("Export to Reminders", systemImage: "checklist")
                        }
                        .disabled(appState.shoppingListItems.isEmpty)
                        
                        ShareLink(item: generateShareText()) {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }
                        .disabled(appState.shoppingListItems.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .foodList:
                    FoodPickerSheet(appState: appState)
                case .recipePicker:
                    GenericRecipePickerSheet(appState: appState) { recipe in
                        // Add ingredients from recipe with parsing
                        if let ownerId = appState.currentOwnerId {
                            for ingredient in recipe.parsedIngredients {
                                let parsed = appState.recipeManager.parseIngredient(ingredient)
                                let category = appState.recipeManager.categorizeIngredient(parsed.name)
                                let item = ShoppingListItem(
                                    ownerId: ownerId,
                                    name: parsed.name,
                                    quantity: parsed.quantity,
                                    unit: parsed.unit,
                                    category: category,
                                    source: .manual
                                )
                                Task {
                                    try? await appState.addShoppingListItem(item)
                                }
                            }
                        }
                    }
                case .addItemDetail:
                    AddItemDetailSheet(
                        itemName: $newItemName,
                        quantity: $newItemQuantity,
                        unit: $newItemUnit,
                        appState: appState,
                        onAdd: {
                            if let ownerId = appState.currentOwnerId {
                                let category = appState.recipeManager.categorizeIngredient(newItemName)
                                let item = ShoppingListItem(
                                    ownerId: ownerId,
                                    name: newItemName,
                                    quantity: newItemQuantity.isEmpty ? nil : newItemQuantity,
                                    unit: newItemUnit.isEmpty ? nil : newItemUnit,
                                    category: category,
                                    source: .manual
                                )
                                Task {
                                    try? await appState.addShoppingListItem(item)
                                }
                            }
                            newItemName = ""
                            newItemQuantity = ""
                            newItemUnit = ""
                        }
                    )
                }
            }
            .alert("Export to Reminders", isPresented: $showingExportAlert) {
                Button("OK") {}
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                } else {
                    Text("Shopping list exported successfully!")
                }
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView("Exporting to Reminders...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    private func deleteItems(at indexSet: IndexSet, in category: GroceryCategory) {
        let items = groupedItems[category] ?? []
        for index in indexSet {
            appState.removeShoppingListItem(items[index])
        }
    }
    
    private func exportToReminders() {
        isExporting = true
        Task {
            do {
                try await remindersManager.exportShoppingList(appState.shoppingListItems)
                await MainActor.run {
                    isExporting = false
                    exportError = nil
                    showingExportAlert = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error
                    showingExportAlert = true
                }
            }
        }
    }
    
    private func generateShareText() -> String {
        var text = "🛒 Shopping List\n\n"
        
        for category in sortedCategories {
            let items = groupedItems[category] ?? []
            let activeItems = items.filter { !$0.isCompleted }
            
            if !activeItems.isEmpty {
                text += "\(category.icon) \(category.rawValue)\n"
                for item in activeItems {
                    text += "  • "
                    if let quantity = item.quantity {
                        text += quantity
                        if let unit = item.unit {
                            text += " \(unit)"
                        }
                        text += " "
                    }
                    text += "\(item.name)\n"
                }
                text += "\n"
            }
        }
        
        return text
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingListItem
    @Bindable var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    try? await appState.toggleShoppingItemComplete(item)
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? appState.themeColor : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                
                if let quantity = item.quantity {
                    HStack(spacing: 4) {
                        Text(quantity)
                        if let unit = item.unit {
                            Text(unit)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if item.source == .recipe {
                Image(systemName: "book.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AddItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Binding var itemName: String
    @Binding var quantity: String
    @Binding var unit: String
    @Bindable var appState: AppState
    let onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $itemName)
                    
                    HStack {
                        TextField("Quantity (optional)", text: $quantity)
                            .keyboardType(.decimalPad)
                        
                        TextField("Unit", text: $unit)
                            .frame(maxWidth: 100)
                    }
                }
                
                Section {
                    Text("Examples: 2 cups, 1 lb, 3 cans")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                        dismiss()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }
}


struct FoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Bindable var appState: AppState
    @State private var searchText = ""
    
    var filteredFoods: [FoodItem] {
        if searchText.isEmpty {
            return Constants.allFoods
        }
        return Constants.allFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredFoods) { food in
                Button {
                    if let ownerId = appState.currentOwnerId {
                        let item = ShoppingListItem(ownerId: ownerId, name: food.name, source: .manual)
                        Task {
                            try? await appState.addShoppingListItem(item)
                        }
                    }
                    dismiss()
                } label: {
                    HStack {
                        Text(food.emoji)
                            .font(.title2)
                        Text(food.name)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search foods")
            .navigationTitle("Add Food to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Unchanged Components (RecipeDetailView, RecipeFormView, AIRecipeGeneratorSheet)

struct RecipeDetailView: View {
    @Binding var recipe: Recipe
    var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isLoadingSubstitutions = false
    @State private var substitutionSuggestions: String?
    @State private var showingApplySubstitution = false
    
    private var allergicIngredients: [String] {
        guard let knownAllergies = appState.userProfile?.knownAllergies else {
            return []
        }
        
        // Check each ingredient text against known allergens
        return recipe.parsedIngredients.filter { ingredient in
            // Skip ingredients that explicitly say they're allergen-free
            let lowerIngredient = ingredient.lowercased()
            if lowerIngredient.contains("-free") || lowerIngredient.contains("free") {
                return false
            }
            
            return knownAllergies.contains { allergy in
                ingredient.localizedCaseInsensitiveContains(allergy) ||
                allergy.localizedCaseInsensitiveContains(ingredient) ||
                // Also check common allergen terms
                (allergy.localizedCaseInsensitiveContains("dairy") && 
                 (ingredient.localizedCaseInsensitiveContains("milk") ||
                  ingredient.localizedCaseInsensitiveContains("cheese") ||
                  ingredient.localizedCaseInsensitiveContains("butter") ||
                  ingredient.localizedCaseInsensitiveContains("cream") ||
                  ingredient.localizedCaseInsensitiveContains("yogurt")))
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                         .resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(height: 250)
                         .clipped()
                         .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Text(recipe.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                // Allergen Warning Section
                if !allergicIngredients.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            Text("Allergen Warning")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                        
                        Text("This recipe contains ingredients your baby is allergic to:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(allergicIngredients, id: \.self) { ingredient in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.red)
                                Text(ingredient)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if isLoadingSubstitutions {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Getting substitution suggestions...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        } else if let suggestions = substitutionSuggestions {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggestions:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(appState.themeColor)
                                
                                Text(suggestions)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Button(action: { showingApplySubstitution = true }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Apply These Substitutions")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.top, 8)
                        } else {
                            Button(action: getSubstitutionSuggestions) {
                                HStack {
                                    Image("sage.leaf.sprig")
                                    Text("Get Substitution Suggestions")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(appState.themeColor)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.top, 8)
                            .accessibilityLabel("Get Smart Substitution Suggestions")
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(appState.themeColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recipe.parsedIngredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(appState.themeColor)
                                    .padding(.top, 6)
                                Text(ingredient)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(appState.themeColor)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(recipe.parsedInstructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(appState.themeColor)
                                    .clipShape(Circle())
                                Text(instruction)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            RecipeFormView(appState: appState, mode: .edit(recipe))
        }
        .alert("Delete Recipe?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                appState.deleteRecipe(recipe)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
        .withSage(context: "User is viewing recipe: \(recipe.title).", appState: appState)
        .navigationTitle(" ")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Apply Substitutions?", isPresented: $showingApplySubstitution) {
            Button("Update Recipe") {
                applySubstitutions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update the recipe with allergen-free substitutions. The ingredients will be replaced with safe alternatives.")
        }
    }
    
    private func applySubstitutions() {
        guard let suggestions = substitutionSuggestions else { return }
        
        Task {
            do {
                let prompt = """
                Original recipe ingredients:
                \(recipe.ingredients)
                
                Substitutions to apply:
                \(suggestions)
                
                Please rewrite the ingredients list with the substitutions applied. Keep the same format and measurements, just replace the allergenic ingredients. Return ONLY the modified ingredients list, nothing else.
                """
                
                let modifiedIngredients = try await appState.geminiService.askSageAssistant(
                    question: prompt,
                    context: "Applying recipe substitutions",
                    currentScreenContext: "Recipe modification"
                )
                
                await MainActor.run {
                    // Update the current recipe instead of creating a new one
                    recipe.ingredients = modifiedIngredients
                    recipe.title = "\(recipe.title) (Allergen-Free)"
                }
                
                // Save changes to persistence
                try await appState.saveRecipe(recipe)
                
                await MainActor.run {
                    errorPresenter.showSuccess("Recipe updated")
                    substitutionSuggestions = nil
                    showingApplySubstitution = false
                }
            } catch {
                await MainActor.run {
                    errorPresenter.present(error)
                }
            }
        }
    }
    
    private func getSubstitutionSuggestions() {
        isLoadingSubstitutions = true
        
        Task {
            do {
                let prompt = """
                I have a recipe that contains these allergenic ingredients: \(allergicIngredients.joined(separator: ", "))
                
                The baby is allergic to: \(appState.userProfile?.knownAllergies?.joined(separator: ", ") ?? "")
                
                Please suggest safe substitutions for each allergenic ingredient. Keep it concise and practical for baby food. Format as:
                - [Ingredient]: Replace with [substitute]
                """
                
                let suggestions = try await appState.geminiService.askSageAssistant(
                    question: prompt,
                    context: "Recipe: \(recipe.title)",
                    currentScreenContext: "Recipe substitution suggestions"
                )
                
                await MainActor.run {
                    self.substitutionSuggestions = suggestions
                    self.isLoadingSubstitutions = false
                }
            } catch {
                await MainActor.run {
                    self.substitutionSuggestions = "Unable to get suggestions. Please consult with your pediatrician about safe substitutions."
                    self.isLoadingSubstitutions = false
                }
            }
        }
    }
}

struct RecipeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    var appState: AppState
    
    enum Mode {
        case new
        case edit(Recipe)
    }
    
    let mode: Mode
    
    @State private var title = ""
    @State private var ingredients = ""
    @State private var instructions = ""
    @State private var selectedImageData: Data?
    @State private var selectedPhotosPickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    
    init(appState: AppState, mode: Mode) {
        self.appState = appState
        self.mode = mode
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Image(systemName: "camera")
                                            .font(.title)
                                            .foregroundStyle(.secondary)
                                    )
                            }
                            
                            HStack(spacing: 20) {
                                Button("Take Photo") {
                                    showingCamera = true
                                }
                                
                                PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                                    Text("Upload")
                                }
                                .accessibilityLabel("Upload Recipe Photo")
                            }
                            .font(.subheadline)
                            .padding(.top, 8)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section(header: Text("Recipe Details")) {
                    TextField("Recipe Title", text: $title)
                    
                    VStack(alignment: .leading) {
                        Text("Ingredients (one per line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $ingredients)
                            .frame(height: 100)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Instructions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $instructions)
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle(isNew ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let recipe) = mode {
                    title = recipe.title
                    ingredients = recipe.ingredients
                    instructions = recipe.instructions
                    selectedImageData = recipe.imageData
                }
            }
            .onChange(of: selectedPhotosPickerItem) {
                Task {
                    if let data = try? await selectedPhotosPickerItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    private var isNew: Bool {
        switch mode {
        case .new: return true
        case .edit: return false
        }
    }
    
    private func saveRecipe() {
        Task {
            do {
                switch mode {
                case .new:
                    if let ownerId = appState.currentOwnerId {
                        let recipe = Recipe(
                            ownerId: ownerId,
                            title: title,
                            ingredients: ingredients,
                            instructions: instructions,
                            imageData: selectedImageData
                        )
                        try await appState.saveRecipe(recipe)
                    }
                    
                case .edit(let recipe):
                    var updatedRecipe = recipe
                    updatedRecipe.title = title
                    updatedRecipe.ingredients = ingredients
                    updatedRecipe.instructions = instructions
                    updatedRecipe.imageData = selectedImageData
                    
                    try await appState.saveRecipe(updatedRecipe)
                }
                
                errorPresenter.showSuccess("Recipe saved")
                dismiss()
            } catch {
                errorPresenter.present(error)
            }
        }
    }
}

struct AIRecipeGeneratorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Bindable var appState: AppState
    
    @State private var ingredientsInput = ""
    @State private var isGenerating = false
    @State private var generatedRecipe: Recipe?
    
    var body: some View {
        NavigationStack {
            Group {
                if let recipe = generatedRecipe {
                    // Preview Mode
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(recipe.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ingredients")
                                    .font(.headline)
                                    .foregroundStyle(appState.themeColor)
                                
                                Text(recipe.ingredients)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Instructions")
                                    .font(.headline)
                                    .foregroundStyle(appState.themeColor)
                                
                                Text(recipe.instructions)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 12) {
                            Button {
                                saveRecipe(recipe)
                            } label: {
                                Text("Save to Cookbook")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(appState.themeColor)
                                    .clipShape(Capsule())
                            }
                            
                            Button("Try Again") {
                                withAnimation {
                                    generatedRecipe = nil
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                    .navigationTitle("Recipe Preview")
                } else {
                    // Input Mode
                    Form {
                        Section("Ingredients") {
                            TextEditor(text: $ingredientsInput)
                                .frame(height: 100)
                            Text("Enter available ingredients separated by commas")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Section {
                            Button {
                                generateRecipe()
                            } label: {
                                if isGenerating {
                                    HStack {
                                        ProgressView()
                                        Text("Generating...")
                                    }
                                } else {
                                    HStack {
                                        SageIcon(size: .medium, style: .gradient)
                                        Text("Generate Recipe")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                            }
                            .disabled(ingredientsInput.isEmpty || isGenerating)
                            .accessibilityLabel("Generate Recipe")
                            .accessibilityHint("Creates a recipe based on entered ingredients")
                        }
                    }
                    .navigationTitle("Chef Sage")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func generateRecipe() {
        let ingredients = ingredientsInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        isGenerating = true
        Task {
            do {
                let recipe = try await appState.generateRecipe(ingredients: ingredients)
                
                await MainActor.run {
                    self.generatedRecipe = recipe
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorPresenter.present(error)
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func saveRecipe(_ recipe: Recipe) {
        guard let ownerId = appState.currentOwnerId else { return }
        
        Task {
            do {
                var recipeToSave = recipe
                recipeToSave.ownerId = ownerId
                try await appState.saveRecipe(recipeToSave)
                await MainActor.run {
                    errorPresenter.showSuccess("Recipe saved")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorPresenter.present(error)
                }
            }
        }
    }
}

// Helper extension for Calendar
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}

struct GenericRecipePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Bindable var appState: AppState
    let onSelect: (Recipe) -> Void
    
    var body: some View {
        NavigationStack {
            List(appState.recipes) { recipe in
                Button {
                    onSelect(recipe)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(recipe.ingredients)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .navigationTitle("Select Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if appState.recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes",
                        systemImage: "book.closed",
                        description: Text("Create recipes first to add their ingredients.")
                    )
                }
            }
        }
    }
}
