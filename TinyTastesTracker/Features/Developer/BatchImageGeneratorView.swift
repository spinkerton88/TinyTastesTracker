//
//  BatchImageGeneratorView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/19/26.
//

import SwiftUI

struct BatchImageGeneratorView: View {
    @State private var foods: [FoodStatus] = []
    @State private var isGenerating = false
    @State private var progress: Double = 0
    @State private var currentProcessingFood: String = ""
    @State private var log: [String] = []
    @State private var showingLog = false
    
    struct FoodStatus: Identifiable, Equatable {
        let id: String
        let name: String
        let category: FoodCategory
        var hasAsset: Bool
        var hasLocalFile: Bool
        var generatedImage: UIImage?
        var status: Status
        
        enum Status: Equatable {
            case pending
            case generating
            case success
            case failed(String)
            case skipped
        }
    }
    
    var body: some View {
        List {
            Section {
                if isGenerating {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Processing: \(currentProcessingFood)")
                            .font(.headline)
                        ProgressView(value: progress, total: 1.0)
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)
                } else {
                    Button(action: startBatchGeneration) {
                        Label { Text("Generate All Missing Images") } icon: { Image("sage.leaf.sprig") }
                            .font(.headline)
                    }
                    .disabled(foods.isEmpty)
                }
            }
            
            Section("Statistics") {
                LabeledContent("Total Foods", value: "\(foods.count)")
                LabeledContent("Missing Images", value: "\(foods.filter { !$0.hasAsset && !$0.hasLocalFile }.count)")
                LabeledContent("Local Overrides", value: "\(foods.filter { $0.hasLocalFile }.count)")
            }
            
            ForEach(FoodCategory.allCases, id: \.self) { category in
                let categoryFoods = foods.filter { $0.category == category }
                if !categoryFoods.isEmpty {
                    Section(category.rawValue.capitalized) {
                        ForEach(categoryFoods) { food in
                            FoodStatusRow(food: food)
                        }
                    }
                }
            }
        }
        .navigationTitle("Image Generator")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: loadStatuses) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isGenerating)
            }
        }
        .onAppear {
            loadStatuses()
        }
    }
    
    private func loadStatuses() {
        let allFoods = Constants.allFoods
        foods = allFoods.map { food in
            let assetName = "food_\(food.id.lowercased().replacingOccurrences(of: " ", with: "_"))"
            let hasAsset = UIImage(named: assetName) != nil
            let hasLocal = ImageGenerationService.shared.hasLocalImage(for: food.id)
            
            return FoodStatus(
                id: food.id,
                name: food.name,
                category: food.category,
                hasAsset: hasAsset,
                hasLocalFile: hasLocal,
                status: .pending
            )
        }.sorted { $0.name < $1.name }
    }
    
    private func startBatchGeneration() {
        let missingFoods = foods.filter { !$0.hasAsset && !$0.hasLocalFile }
        guard !missingFoods.isEmpty else { return }
        
        isGenerating = true
        progress = 0
        let total = Double(missingFoods.count)
        
        Task {
            for (index, foodStatus) in missingFoods.enumerated() {
                if Task.isCancelled { break }
                
                await MainActor.run {
                    currentProcessingFood = foodStatus.name
                    progress = Double(index) / total
                    if let idx = foods.firstIndex(where: { $0.id == foodStatus.id }) {
                        foods[idx].status = .generating
                    }
                }
                
                do {
                    // Generate Image
                    let image = try await ImageGenerationService.shared.generateFoodImage(for: foodStatus.name)
                    
                    // Save Locally
                    _ = ImageGenerationService.shared.saveImageForFood(image: image, foodId: foodStatus.id)
                    
                    await MainActor.run {
                        if let idx = foods.firstIndex(where: { $0.id == foodStatus.id }) {
                            foods[idx].hasLocalFile = true
                            foods[idx].generatedImage = image
                            foods[idx].status = .success
                        }
                    }
                    
                    // Small delay to prevent rate limiting if necessary
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    
                } catch {
                    await MainActor.run {
                        if let idx = foods.firstIndex(where: { $0.id == foodStatus.id }) {
                            foods[idx].status = .failed(error.localizedDescription)
                        }
                    }
                    print("Error generating \(foodStatus.name): \(error)")
                }
            }
            
            await MainActor.run {
                isGenerating = false
                progress = 1.0
                currentProcessingFood = "Complete!"
            }
        }
    }
}

struct FoodStatusRow: View {
    let food: BatchImageGeneratorView.FoodStatus
    
    var body: some View {
        HStack {
            // Identifier Icon
            if let image = food.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if food.hasLocalFile {
                Image(systemName: "photo.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 40)
            } else if food.hasAsset {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(.green)
                    .frame(width: 40)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 40)
            }
            
            VStack(alignment: .leading) {
                Text(food.name)
                    .font(.body)
                
                HStack(spacing: 4) {
                    if food.hasAsset {
                        Text("Asset")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    if food.hasLocalFile {
                        Text("Local")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    if !food.hasAsset && !food.hasLocalFile {
                        Text("Missing")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            switch food.status {
            case .pending:
                EmptyView()
            case .generating:
                ProgressView()
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .skipped:
                Image(systemName: "arrow.turn.up.right")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
