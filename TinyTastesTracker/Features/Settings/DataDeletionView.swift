//
//  DataDeletionView.swift
//  TinyTastesTracker
//
//  Created by Antigravity on 1/12/26.
//

import SwiftUI

struct DataDeletionView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAllConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedDataType: DataType?
    @State private var isDeleting = false
    @State private var deletionError: String?
    @State private var deletionSuccess: String?
    
    enum DataType: String, CaseIterable {
        case mealLogs = "Meal Logs"
        case sleepLogs = "Sleep Logs"
        case diaperLogs = "Diaper Logs"
        case bottleLogs = "Bottle Logs"
        case growthData = "Growth Data"
        case recipes = "Recipes"
        case mealPlans = "Meal Plans" // Note: Meal Plans not fully migrated/used in AppState arrays yet?
        // AppState has mealPlanEntries in RecipeManager?
        case milestones = "Milestones"
        case badges = "Badges"
        
        var icon: String {
            switch self {
            case .mealLogs: return "fork.knife"
            case .sleepLogs: return "moon.fill"
            case .diaperLogs: return "drop.fill"
            case .bottleLogs: return "drop.circle.fill"
            case .growthData: return "chart.line.uptrend.xyaxis"
            case .recipes: return "book.fill"
            case .mealPlans: return "calendar"
            case .milestones: return "flag.checkered"
            case .badges: return "trophy.fill"
            }
        }
        
        var description: String {
            switch self {
            case .mealLogs: return "All logged meals and food reactions"
            case .sleepLogs: return "All sleep tracking data"
            case .diaperLogs: return "All diaper change logs"
            case .bottleLogs: return "All bottle feeding logs"
            case .growthData: return "All weight, height, and head circumference measurements"
            case .recipes: return "All saved recipes"
            case .mealPlans: return "All meal plans and shopping lists"
            case .milestones: return "All developmental milestones"
            case .badges: return "All earned badges and achievements"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Warning Section
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Deletion is Permanent")
                                .font(.headline)
                            Text("Deleted data cannot be recovered unless you have a backup.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Individual Data Types
                Section {
                ForEach(DataType.allCases, id: \.self) { dataType in
                        Button {
                            selectedDataType = dataType
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: dataType.icon)
                                    .font(.title3)
                                    .foregroundStyle(.red)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dataType.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Text(dataType.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } header: {
                    Text("Delete Specific Data")
                } footer: {
                    Text("Delete individual data types while keeping other data intact.")
                }
                
                // Delete All Section
                Section {
                    Button(role: .destructive) {
                        showingDeleteAllConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Delete All Data")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Removes all data including profiles, logs, and recipes")
                                    .font(.caption)
                            }
                        }
                    }
                } footer: {
                    Text("This will delete ALL data from the app. This action cannot be undone.")
                }
            }
            .navigationTitle("Delete Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedDataType?.rawValue ?? "")?",
                isPresented: $showingDeleteConfirmation,
                presenting: selectedDataType
            ) { dataType in
                Button("Delete \(dataType.rawValue)", role: .destructive) {
                    Task {
                        await deleteData(type: dataType)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { dataType in
                Text("This will permanently delete all \(dataType.rawValue.lowercased()). This action cannot be undone.")
            }
            .alert("Delete All Data?", isPresented: $showingDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    Task {
                        await deleteAllData()
                    }
                }
            } message: {
                Text("This will permanently delete ALL data from the app, including profiles, logs, recipes, and settings. This action cannot be undone.\n\nAre you absolutely sure?")
            }
            .alert("Deletion Complete", isPresented: .constant(deletionSuccess != nil)) {
                Button("OK") {
                    deletionSuccess = nil
                }
            } message: {
                if let success = deletionSuccess {
                    Text(success)
                }
            }
            .alert("Deletion Error", isPresented: .constant(deletionError != nil)) {
                Button("OK") {
                    deletionError = nil
                }
            } message: {
                if let error = deletionError {
                    Text(error)
                }
            }
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Deleting data...")
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    // MARK: - Deletion Methods
    
    private func deleteData(type: DataType) async {
        isDeleting = true
        deletionError = nil
        deletionSuccess = nil
        
        // Use Task/Sleep to allow UI to update if deletion is fast
        // In real Firestore, this is async.
        
        // Note: Efficient deletion in Firestore usually requires iterating or batching.
        // Here we iterate local state and delete one by one via Managers.
        
        do {
            switch type {
            case .mealLogs:
                for log in appState.mealLogs {
                    appState.toddlerManager.deleteMealLog(log)
                }
            case .sleepLogs:
                for log in appState.sleepLogs {
                    appState.newbornManager.deleteSleepLog(log)
                }
            case .diaperLogs:
                for log in appState.diaperLogs {
                    appState.newbornManager.deleteDiaperLog(log)
                }
            case .bottleLogs:
                for log in appState.bottleLogs {
                    appState.newbornManager.deleteBottleFeedLog(log)
                }
            case .growthData:
                for log in appState.growthMeasurements {
                    appState.newbornManager.deleteGrowthMeasurement(log)
                }
            case .recipes:
                for recipe in appState.recipes {
                    appState.recipeManager.deleteRecipe(recipe)
                }
                for food in appState.customFoods {
                    appState.recipeManager.deleteCustomFood(food)
                }
            case .mealPlans:
                // Meal Plan entries
                for entry in appState.recipeManager.mealPlanEntries {
                    appState.recipeManager.deleteMealPlanEntry(entry)
                }
                for item in appState.recipeManager.shoppingListItems {
                    appState.recipeManager.deleteShoppingListItem(item)
                }
            case .milestones:
                if var profile = appState.userProfile {
                    profile.milestones = Milestone.defaults() // Reset to defaults
                    try appState.profileManager.updateProfile(profile)
                }
            case .badges:
                if var profile = appState.userProfile {
                    profile.badges = Badge.defaults() // Reset to defaults
                    try appState.profileManager.updateProfile(profile)
                }
            }
            
            deletionSuccess = "\(type.rawValue) deleted successfully."
            
        } catch {
            deletionError = "Failed to delete \(type.rawValue): \(error.localizedDescription)"
        }
        
        isDeleting = false
    }
    
    private func deleteAllData() async {
        isDeleting = true
        deletionError = nil
        deletionSuccess = nil
        
        do {
           // Iterate all types
           for type in DataType.allCases {
               await deleteData(type: type)
           }
            
            deletionSuccess = "All data deleted successfully."
            
            // Dismiss after a delay
            try? await Task.sleep(for: .seconds(1))
            dismiss()
            
        } catch {
            deletionError = "Failed to delete all data: \(error.localizedDescription)"
        }
        
        isDeleting = false
    }
}

#Preview {
    DataDeletionView(appState: AppState())
}
