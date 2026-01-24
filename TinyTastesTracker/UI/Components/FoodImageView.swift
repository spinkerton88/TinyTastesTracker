//
//  FoodImageView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/16/26.
//

import SwiftUI

struct FoodImageView: View {
    let food: FoodItem
    let size: CGFloat
    
    // Derived asset name for built-in foods
    private var assetName: String {
        "food_\(food.id.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
    
    var body: some View {
        ZStack {
            // Subtle background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.15),
                            Color.gray.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Food image with circular mask
            Group {
                // Priority 1: Custom Food Image (from file property)
                if let imageFileName = food.imageFileName,
                   let uiImage = loadLocalImage(named: imageFileName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } 
                // Priority 2: Generated Override for Built-in Food (local file: food_{id}.png)
                else if let uiImage = loadLocalImage(named: "food_\(food.id.lowercased().replacingOccurrences(of: " ", with: "_")).png") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                // Priority 3: Built-in Asset
                else if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } 
                // Priority 4: Fallback to Emoji
                else {
                    Text(food.emoji)
                        .font(.system(size: size * 0.5))
                }
            }
            .frame(width: size * 0.85, height: size * 0.85)
            .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }
    
    private func loadLocalImage(named fileName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
}

#Preview {
    FoodImageView(
        food: FoodItem(id: "BANANA", name: "Banana", emoji: "🍌", category: .fruits),
        size: 100
    )
}
