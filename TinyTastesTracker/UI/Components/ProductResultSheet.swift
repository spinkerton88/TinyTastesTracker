//
//  ProductResultSheet.swift
//  TinyTastesTracker
//
//  Displays scanned product information from OpenFoodFacts
//

import SwiftUI

struct ProductResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    let productInfo: ProductInfo
    let appState: AppState
    
    @State private var matchedFoods: [FoodItem] = []
    @State private var showMatchedFoods = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image (if available)
                    if let imageUrlString = productInfo.imageUrl,
                       let imageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 60)) // Large decorative icon
                                    .foregroundStyle(.secondary)
                                    .frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Product Name & Brand
                    VStack(alignment: .leading, spacing: 8) {
                        Text(productInfo.productName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let brand = productInfo.brand {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Allergen Warning (if any)
                    if productInfo.hasAllergens {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Allergen Warning", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            
                            ForEach(productInfo.allergens, id: \.self) { allergen in
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6)) // Tiny star rating
                                        .foregroundStyle(.orange)
                                    Text(allergen.capitalized)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Divider()
                    }
                    
                    // Ingredients
                    if let ingredients = productInfo.ingredients {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Ingredients", systemImage: "list.bullet")
                                .font(.headline)
                            
                            Text(ingredients)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                    }
                    
                    // Nutrients
                    if let nutrients = productInfo.nutrients {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Nutrients (per 100g)", systemImage: "chart.bar.fill")
                                .font(.headline)
                            
                            Text(nutrients.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                    }
                    
                    // Categories
                    if !productInfo.categories.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Categories", systemImage: "tag.fill")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(productInfo.categories.prefix(5), id: \.self) { category in
                                    Text(category.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(appState.themeColor.opacity(0.1))
                                        .foregroundStyle(appState.themeColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Match to Food Database
                    VStack(spacing: 12) {
                        Button {
                            findMatchingFoods()
                            showMatchedFoods = true
                        } label: {
                            Label("Find Similar Foods in Database", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(appState.themeColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if showMatchedFoods {
                            if matchedFoods.isEmpty {
                                Text("No matching foods found in the 100 Foods database.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding()
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Similar Foods:")
                                        .font(.headline)
                                    
                                    ForEach(matchedFoods) { food in
                                        HStack {
                                            Text(food.emoji)
                                                .font(.title2)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(food.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text(food.category.rawValue.capitalized)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if appState.isFoodTried(food.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(appState.themeColor)
                                            }
                                        }
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding(.top)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Scanned Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func findMatchingFoods() {
        // Simple fuzzy matching based on product name and categories
        let searchTerms = productInfo.productName.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 } // Filter out small words
        
        var matches: [FoodItem] = []
        
        // Check each food in the database
        for food in Constants.allFoods {
            let foodName = food.name.lowercased()
            
            // Check if any search term matches the food name
            for term in searchTerms {
                if foodName.contains(term) || term.contains(foodName) {
                    matches.append(food)
                    break
                }
            }
        }
        
        // Also check category matching
        for category in productInfo.categories {
            let categoryLower = category.lowercased()
            
            // Map common category keywords to FoodCategory
            if categoryLower.contains("vegetable") || categoryLower.contains("veggie") {
                matches.append(contentsOf: Constants.allFoods.filter { $0.category == .vegetables })
            } else if categoryLower.contains("fruit") {
                matches.append(contentsOf: Constants.allFoods.filter { $0.category == .fruits })
            } else if categoryLower.contains("dairy") || categoryLower.contains("cheese") || categoryLower.contains("yogurt") {
                matches.append(contentsOf: Constants.allFoods.filter { $0.category == .dairy })
            } else if categoryLower.contains("meat") || categoryLower.contains("protein") || categoryLower.contains("fish") {
                matches.append(contentsOf: Constants.allFoods.filter { $0.category == .proteins })
            } else if categoryLower.contains("grain") || categoryLower.contains("cereal") || categoryLower.contains("bread") {
                matches.append(contentsOf: Constants.allFoods.filter { $0.category == .grains })
            }
        }
        
        // Remove duplicates and limit to top 5
        matchedFoods = Array(Set(matches.map { $0.id }))
            .compactMap { id in Constants.allFoods.first(where: { $0.id == id }) }
            .prefix(5)
            .map { $0 }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// Loading state view
struct ProductLoadingView: View {
    let barcode: String
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var productInfo: ProductInfo?
    @State private var error: OpenFoodFactsError?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Looking up product...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(barcode)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else if let error = error {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50)) // Large decorative icon
                        .foregroundStyle(.orange)
                    
                    Text("Product Not Found")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        Task {
                            await loadProduct()
                        }
                    } label: {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .padding()
                            .background(appState.themeColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding()
            } else if let productInfo = productInfo {
                ProductResultSheet(productInfo: productInfo, appState: appState)
            }
        }
        .task {
            await loadProduct()
        }
    }
    
    private func loadProduct() async {
        isLoading = true
        error = nil

        do {
            let info = try await appState.lookupBarcode(barcode)
            productInfo = info
        } catch let openFoodError as OpenFoodFactsError {
            error = openFoodError
        } catch {
            self.error = .networkError(error)
        }

        isLoading = false
    }
}
