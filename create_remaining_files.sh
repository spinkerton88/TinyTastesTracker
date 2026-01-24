#!/bin/bash

# I'll create a condensed version of the main files for you
# After this, you can expand Constants.swift with the full 100 foods list

echo "Creating remaining Swift files..."
cd "/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker/TinyTastesTracker"

# Create simplified Constants (you'll need to expand this in Xcode)
cat > Utils/Constants.swift << 'EOF'
//
//  Constants.swift
//  TinyTastesTracker
//

import SwiftUI

enum FoodCategory: String, Codable, CaseIterable {
    case vegetables, fruits, proteins, grains, dairy
}

struct FoodItem: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let category: FoodCategory
}

struct Constants {
    // Simplified - expand with full 100 foods from walkthrough
    static let allFoods: [FoodItem] = [
        FoodItem(id: "AVOCADO", name: "Avocado", emoji: "🥑", category: .vegetables),
        FoodItem(id: "BANANA", name: "Banana", emoji: "🍌", category: .fruits),
        // TODO: Add remaining 98 foods
    ]
    
    static let newbornColor = Color(red: 244/255, green: 63/255, blue: 94/255)
    static let explorerColor = Color(red: 13/255, green: 148/255, blue: 136/255)
    static let toddlerColor = Color(red: 99/255, green: 102/255, blue: 241/255)
    
    static func themeColor(for mode: AppMode) -> Color {
        switch mode {
        case .newborn: return newbornColor
        case .explorer: return explorerColor
        case .toddler: return toddlerColor
        }
    }
}
EOF

echo "✅ Created Constants.swift"

