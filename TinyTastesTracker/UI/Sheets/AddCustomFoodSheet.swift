//
//  AddCustomFoodSheet.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 01/03/26.
//

import SwiftUI

struct AddCustomFoodSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter

    @State private var foodName = ""
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var analyzedDetails: CustomFoodDetails?
    @State private var debounceTask: Task<Void, Never>?

    @State private var generatedImage: UIImage?
    @State private var isGeneratingImage = false

    // Editable fields (pre-filled by AI)
    @State private var emoji = "🍽️"
    @State private var category: FoodCategory = .vegetables
    @State private var allergyWarning = ""
    @State private var nutritionHighlights = ""
    @State private var servingTip = ""
    @State private var isChokeHazard = false
    @State private var color: FoodColor = .green
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Name") {
                    TextField("e.g. Dragonfruit", text: $foodName)
                        .autocorrectionDisabled()
                        .onChange(of: foodName) { oldValue, newValue in
                            // Auto-analyze when user stops typing
                            debounceTask?.cancel()
                            
                            guard !newValue.isEmpty, newValue.count >= 3 else {
                                return
                            }
                            
                            debounceTask = Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                                
                                if !Task.isCancelled {
                                    await MainActor.run {
                                        analyzeAndGenerateFood()
                                    }
                                }
                            }
                        }
                }
                
                if isAnalyzing || isGeneratingImage {
                    Section {
                        HStack {
                            ProgressView()
                                .padding(.trailing)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isAnalyzing ? "Analyzing \"\(foodName)\"..." : "Generating Photo...")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(isAnalyzing ? "Detecting allergens and nutrition info" : "Creating a studio-style photo for you")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                if let error = analysisError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                // Generated Image Preview
                if let image = generatedImage {
                    Section {
                        VStack {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 4)
                                
                                Button {
                                    regenerateImage()
                                } label: {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(8)
                                .disabled(isGeneratingImage)
                            }
                            
                            if isGeneratingImage {
                                ProgressView()
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } header: {
                        Text("Photo")
                    }
                }
                
                // Details Form
                Section("Details") {

                    
                    Picker("Category", selection: $category) {
                        ForEach(FoodCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                    
                    Picker("Color Group", selection: $color) {
                        ForEach(FoodColor.allCases, id: \.self) { col in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(col.displayColor)
                                Text(col.rawValue)
                            }.tag(col)
                        }
                    }
                    
                    Toggle("Choking Hazard?", isOn: $isChokeHazard)
                        .tint(.red)
                }
                
                Section("Nutrition & Serving") {
                    TextField("Nutrition Highlights", text: $nutritionHighlights, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("How to Serve (Baby Safe)", text: $servingTip, axis: .vertical)
                        .lineLimit(2...4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Allergy Warning")
                                .font(.subheadline)
                            
                            if !allergyWarning.isEmpty && analyzedDetails != nil {
                                HStack(spacing: 4) {
                                    Image("sage.leaf.sprig")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 12, height: 12)
                                    Text("Auto-detected")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        
                        TextField("e.g., Contains dairy, eggs", text: $allergyWarning, axis: .vertical)
                            .lineLimit(1...3)
                        
                        if !allergyWarning.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(allergyWarning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                
                Section {
                    Button(action: saveFood) {
                        Text("Save Custom Food")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                    }
                    .listRowBackground(appState.themeColor)
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("Add Custom Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func regenerateImage() {
        guard !foodName.isEmpty else { return }
        isGeneratingImage = true
        
        Task {
            do {
                let image = try await ImageGenerationService.shared.generateFoodImage(for: foodName)
                await MainActor.run {
                    self.generatedImage = image
                    self.isGeneratingImage = false
                }
            } catch {
                print("Error regenerating image: \(error)")
                await MainActor.run {
                    self.isGeneratingImage = false
                }
            }
        }
    }
    
    private func analyzeAndGenerateFood() {
        guard !foodName.isEmpty else { return }
        
        // Check Explorer Mode Restriction
        if appState.currentMode == .explorer {
            // Check if food exists in standard list
            if Constants.allFoods.contains(where: { $0.name.localizedCaseInsensitiveContains(foodName) }) {
                analysisError = "This food is already in the 100 Foods list! Search for it in the main tracker."
                return
            }
        }
        
        isAnalyzing = true
        analysisError = nil
        
        Task {
            do {
                // 1. Analyze Data
                let details = try await appState.analyzeCustomFood(name: foodName)
                
                if !Task.isCancelled {
                   await MainActor.run {
                       self.analyzedDetails = details
                       self.populateFields(with: details)
                       self.isAnalyzing = false
                       self.isGeneratingImage = true
                   }
                   
                   // 2. Generate Image
                   do {
                       let image = try await ImageGenerationService.shared.generateFoodImage(for: foodName)
                       if !Task.isCancelled {
                          await MainActor.run {
                              self.generatedImage = image
                              self.isGeneratingImage = false
                          }
                       }
                   } catch {
                       print("⚠️ Image generation failed: \(error.localizedDescription). Using placeholder.")
                       if !Task.isCancelled {
                          await MainActor.run {
                              self.isGeneratingImage = false
                          }
                       }
                   }
                }
                
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.analysisError = "Analysis failed. Please fill details manually."
                        self.isAnalyzing = false
                        self.isGeneratingImage = false
                    }
                }
            }
        }
    }
    
    private func populateFields(with details: CustomFoodDetails) {
        self.emoji = details.emoji
        self.nutritionHighlights = details.nutritionHighlights
        self.servingTip = details.howToServe
        self.isChokeHazard = details.chokeHazard
        self.allergyWarning = details.allergens.joined(separator: ", ")
        
        // Best effort category matching
        if let matchedCat = FoodCategory.allCases.first(where: { $0.rawValue.lowercased() == details.category.lowercased() }) {
            self.category = matchedCat
        }
        
        // Best effort color matching
        if let matchedColor = FoodColor.allCases.first(where: { $0.rawValue.lowercased() == details.color.lowercased() }) {
            self.color = matchedColor
        }
    }
    
    private func saveFood() {
        Task {
            do {
                let id = foodName.uppercased().replacingOccurrences(of: " ", with: "_")
                
                var savedFileName: String? = nil
                if let image = generatedImage {
                    savedFileName = saveImageToDocuments(image, name: "custom_food_\(id)")
                }
                
                let allergensList = allergyWarning.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                // Create new food
                guard let ownerId = appState.currentOwnerId else {
                    errorPresenter.present(FirebaseError.invalidData)
                    return
                }
                
                let newFood = CustomFood(
                    id: id,
                    ownerId: ownerId,
                    name: foodName,
                    emoji: emoji,
                    category: category,
                    allergens: allergensList,
                    nutritionHighlights: nutritionHighlights,
                    howToServe: servingTip,
                    chokeHazard: isChokeHazard,
                    color: color,
                    imageFileName: savedFileName
                )
                
                try await appState.saveCustomFood(newFood)
                errorPresenter.showSuccess("Custom food added")
                dismiss()
            } catch {
                errorPresenter.present(error)
            }
        }
    }
    
    private func saveImageToDocuments(_ image: UIImage, name: String) -> String? {
        guard let data = image.pngData() else { return nil }
        let fileName = "\(name).png"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}
