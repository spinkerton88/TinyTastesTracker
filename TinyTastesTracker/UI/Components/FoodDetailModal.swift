//
//  FoodDetailModal.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI
import PhotosUI

struct FoodDetailModal: View {
    let food: FoodItem
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Logging State
    @State private var reaction = 4
    @State private var mealType: MealType = .lunch
    @State private var quantity: String = "bite"
    @State private var reactionSigns: Set<String> = []
    
    // Photo State
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var messyFaceData: Data?
    @State private var selectedExistingPhoto: TriedFoodLog?
    @State private var showExistingPhotoViewer = false
    
    // Allergen Monitoring State
    @State private var showAllergenPrompt = false
    @State private var allergenInfo: (foodName: String, allergenName: String)?
    
    let reactionOptions = ["Hives", "Vomiting", "Gas/Fussy", "Rash", "Diarrhea", "Other"]
    let quantityOptions = [
        ("bite", "Just a taste"),
        ("more", "More than a bite"),
        ("serving", "Full serving")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header Section
                    HStack(spacing: 16) {
                        FoodImageView(food: food, size: 80)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(food.category.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // MARK: - Safety Section
                    VStack(spacing: 12) {
                        // Allergy Risk Badge
                        HStack {
                            Label("Allergy Risk", systemImage: "shield.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(food.allergyRisk.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(food.allergyRisk.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(food.allergyRisk.color.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !food.allergens.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Allergen Warning", systemImage: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                
                                Text("Contains: \(food.allergens.joined(separator: ", ").capitalized)")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if food.chokeHazard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Choking Hazard")
                                        .font(.headline)
                                        .foregroundStyle(.orange)
                                    Text("Modify texture appropriately for age.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Nutrition Section (Always visible)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Nutrition", systemImage: "leaf.fill")
                            .font(.headline)
                            .foregroundStyle(appState.themeColor)
                        Text(food.nutritionHighlights.isEmpty ? "Complete nutrition information coming soon" : food.nutritionHighlights)
                            .font(.body)
                            .foregroundStyle(food.nutritionHighlights.isEmpty ? .secondary : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(appState.themeColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // MARK: - Preparation Guide (Always visible)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("How to Serve", systemImage: "fork.knife")
                            .font(.headline)
                        Text(food.howToServe.isEmpty ? "Serving instructions coming soon" : food.howToServe)
                            .font(.body)
                            .foregroundStyle(food.howToServe.isEmpty ? .secondary : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // MARK: - Existing Photos Section
                    if !existingPhotosForFood.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Previous Photos", systemImage: "photo.on.rectangle.angled")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(existingPhotosForFood, id: \.id) { log in
                                        if let imageData = log.messyFaceImage,
                                           let uiImage = UIImage(data: imageData) {
                                            Button {
                                                selectedExistingPhoto = log
                                                showExistingPhotoViewer = true
                                            } label: {
                                                VStack(spacing: 4) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 100, height: 100)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    
                                                    Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // MARK: - Logging Form
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Log This Food")
                            .font(.title2)
                            .fontWeight(.bold)

                        // 1. Food Preference Reaction Slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reaction")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("😖").font(.title2)
                                Slider(value: Binding(
                                    get: { Double(reaction) },
                                    set: { reaction = Int($0) }
                                ), in: 1...7, step: 1)
                                .tint(appState.themeColor)
                                Text("😍").font(.title2)
                            }
                            Text(reactionText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // 2. Signs of Reaction (Allergies/Sensitivities)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Signs of Reaction", systemImage: "exclamationmark.triangle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            // Display all buttons in a wrapping grid (no scrolling)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(reactionOptions, id: \.self) { sign in
                                    Button(action: { toggleReaction(sign) }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: reactionSigns.contains(sign) ? "checkmark.circle.fill" : "circle")
                                            Text(sign)
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(reactionSigns.contains(sign) ? Color.red.opacity(0.15) : Color.gray.opacity(0.1))
                                        .foregroundStyle(reactionSigns.contains(sign) ? .red : .primary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            if !reactionSigns.isEmpty {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                    Text("If symptoms are severe or persist, consult a pediatrician immediately.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        // 3. Meal Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Picker("Meal", selection: $mealType) {
                                Text("Breakfast").tag(MealType.breakfast)
                                Text("Lunch").tag(MealType.lunch)
                                Text("Dinner").tag(MealType.dinner)
                                Text("Snack").tag(MealType.snack)
                            }
                            .pickerStyle(.segmented)
                        }

                        // 4. Amount Eaten
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount Eaten")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 0) {
                                ForEach(quantityOptions, id: \.0) { option in
                                    Button(action: { quantity = option.0 }) {
                                        Text(option.1)
                                            .font(.caption)
                                            .fontWeight(quantity == option.0 ? .semibold : .regular)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(quantity == option.0 ? appState.themeColor : Color.clear)
                                            .foregroundStyle(quantity == option.0 ? .white : .primary)
                                    }

                                    if option.0 != quantityOptions.last?.0 {
                                        Divider()
                                            .frame(height: 20)
                                    }
                                }
                            }
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // 6. Photo Upload
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Messy Face Photo")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let data = messyFaceData, let uiImage = UIImage(data: data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button(action: { messyFaceData = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding(8)
                                }
                            } else {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(appState.themeColor)
                                }
                            }
                        }
                        
                        // Unmark Button
                        if isAlreadyTried {
                            Button(role: .destructive) {
                                showUnmarkConfirmation = true
                            } label: {
                                Label("Unmark as Tried", systemImage: "xmark.circle")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity) // increased touch target
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Log") {
                        saveLog()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(appState.themeColor)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        messyFaceData = ImageCompression.compressImage(image)
                    }
                }
            }
            .sheet(isPresented: $showAllergenPrompt) {
                if let info = allergenInfo, let profile = appState.userProfile {
                    AllergenMonitoringPrompt(
                        foodName: info.foodName,
                        allergenName: info.allergenName,
                        childName: profile.babyName
                    )
                }
            }
            .sheet(isPresented: $showExistingPhotoViewer) {
                if let log = selectedExistingPhoto {
                    PhotoViewerSheet(log: log, appState: appState, allLogs: existingPhotosForFood)
                }
            }
            .confirmationDialog(
                "Unmark as Tried?",
                isPresented: $showUnmarkConfirmation,
                titleVisibility: .visible
            ) {
                Button("Unmark", role: .destructive) {
                    appState.unmarkFoodAsTried(food.id, context: modelContext)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove it from your tried foods list and update your rainbow progress.")
            }
        }
    }
    
    private var reactionText: String {
        switch reaction {
        case 1: return "Hated it"
        case 2: return "Didn't like"
        case 3: return "Not sure"
        case 4: return "Neutral"
        case 5: return "Liked it"
        case 6: return "Loved it"
        case 7: return "Absolutely loved!"
        default: return "Neutral"
        }
    }
    
    private func toggleReaction(_ sign: String) {
        if reactionSigns.contains(sign) {
            reactionSigns.remove(sign)
        } else {
            reactionSigns.insert(sign)
        }
    }
    
    private func saveLog() {
        let log = TriedFoodLog(
            id: food.id,
            date: Date(),
            reaction: reaction,
            meal: mealType,
            messyFaceImage: messyFaceData,
            reactionSigns: Array(reactionSigns),
            quantity: quantity
        )
        appState.saveFoodLog(log, context: modelContext)
        
        // Check if this is a high-risk allergen food
        if let allergenData = appState.checkForHighRiskAllergen(foodId: food.id) {
            allergenInfo = allergenData
            showAllergenPrompt = true
        } else {
            dismiss()
        }
    }
    
    // Unmark Logic
    @State private var showUnmarkConfirmation = false
    
    private var isAlreadyTried: Bool {
        appState.isFoodTried(food.id)
    }
    
    // Computed property to get all photos for this food
    private var existingPhotosForFood: [TriedFoodLog] {
        appState.foodLogs
            .filter { $0.id == food.id && $0.messyFaceImage != nil && $0.isMarkedAsTried }
            .sorted { $0.date > $1.date }
    }
}
    

