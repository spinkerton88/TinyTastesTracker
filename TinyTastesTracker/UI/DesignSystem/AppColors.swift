//
//  AppColors.swift
//  TinyTastesTracker
//
//  Centralized color design tokens
//

import SwiftUI

enum AppColors {
    // MARK: - Theme Colors
    static let newborn = Color(hex: "#FF6B9D")
    static let explorer = Color(hex: "#4CAF50")
    static let toddler = Color(hex: "#2196F3")

    // MARK: - Semantic Colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)

    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)

    static let separator = Color(.separator)

    // MARK: - Status Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue

    // MARK: - Food Reaction Colors
    static let loved = Color.green
    static let liked = Color.mint
    static let neutral = Color.yellow
    static let disliked = Color.orange
    static let refused = Color.red

    // MARK: - Nutrient Colors
    static let iron = Color.red.opacity(0.8)
    static let calcium = Color.blue.opacity(0.8)
    static let vitaminC = Color.orange.opacity(0.8)
    static let omega3 = Color.cyan.opacity(0.8)
    static let protein = Color.purple.opacity(0.8)

    // MARK: - Chart Colors
    static let chartPrimary = Color.blue
    static let chartSecondary = Color.green
    static let chartTertiary = Color.orange
    static let chartQuaternary = Color.purple

    // MARK: - Category Colors
    static let vegetables = Color.green
    static let fruits = Color.red
    static let proteins = Color.orange
    static let grains = Color.yellow
    static let dairy = Color.blue

    // MARK: - Helper Methods
    static func themeColor(for mode: AppMode) -> Color {
        switch mode {
        case .newborn: return newborn
        case .explorer: return explorer
        case .toddler: return toddler
        }
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
