//
//  ColorContrastValidator.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/14/26.
//

import SwiftUI

/// Validates color contrast ratios for WCAG AA compliance
struct ColorContrastValidator {
    
    // MARK: - WCAG Standards
    
    /// WCAG AA minimum contrast ratio for normal text (4.5:1)
    static let minimumNormalTextRatio: CGFloat = 4.5
    
    /// WCAG AA minimum contrast ratio for large text (3:1)
    static let minimumLargeTextRatio: CGFloat = 3.0
    
    /// WCAG AAA minimum contrast ratio for normal text (7:1)
    static let minimumNormalTextRatioAAA: CGFloat = 7.0
    
    /// WCAG AAA minimum contrast ratio for large text (4.5:1)
    static let minimumLargeTextRatioAAA: CGFloat = 4.5
    
    // MARK: - Validation
    
    /// Calculate the contrast ratio between two colors
    /// - Parameters:
    ///   - foreground: The foreground color (usually text)
    ///   - background: The background color
    /// - Returns: Contrast ratio (1:1 to 21:1)
    static func contrastRatio(between foreground: Color, and background: Color) -> CGFloat {
        let fgLuminance = relativeLuminance(of: foreground)
        let bgLuminance = relativeLuminance(of: background)
        
        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Check if a color combination meets WCAG AA standards
    /// - Parameters:
    ///   - foreground: The foreground color (usually text)
    ///   - background: The background color
    ///   - isLargeText: Whether the text is large (18pt+ or 14pt+ bold)
    /// - Returns: True if the combination meets WCAG AA standards
    static func meetsWCAGAA(foreground: Color, background: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(between: foreground, and: background)
        let minimumRatio = isLargeText ? minimumLargeTextRatio : minimumNormalTextRatio
        return ratio >= minimumRatio
    }
    
    /// Check if a color combination meets WCAG AAA standards
    /// - Parameters:
    ///   - foreground: The foreground color (usually text)
    ///   - background: The background color
    ///   - isLargeText: Whether the text is large (18pt+ or 14pt+ bold)
    /// - Returns: True if the combination meets WCAG AAA standards
    static func meetsWCAGAAA(foreground: Color, background: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(between: foreground, and: background)
        let minimumRatio = isLargeText ? minimumLargeTextRatioAAA : minimumNormalTextRatioAAA
        return ratio >= minimumRatio
    }
    
    /// Get a compliance level description for a color combination
    /// - Parameters:
    ///   - foreground: The foreground color
    ///   - background: The background color
    ///   - isLargeText: Whether the text is large
    /// - Returns: Compliance level description
    static func complianceLevel(foreground: Color, background: Color, isLargeText: Bool = false) -> String {
        let ratio = contrastRatio(between: foreground, and: background)
        
        if meetsWCAGAAA(foreground: foreground, background: background, isLargeText: isLargeText) {
            return "WCAG AAA (\(String(format: "%.2f", ratio)):1)"
        } else if meetsWCAGAA(foreground: foreground, background: background, isLargeText: isLargeText) {
            return "WCAG AA (\(String(format: "%.2f", ratio)):1)"
        } else {
            return "Fails WCAG (\(String(format: "%.2f", ratio)):1)"
        }
    }
    
    // MARK: - Color Adjustment
    
    /// Suggest an adjusted foreground color to meet WCAG AA standards
    /// - Parameters:
    ///   - foreground: The original foreground color
    ///   - background: The background color
    ///   - isLargeText: Whether the text is large
    /// - Returns: Adjusted color that meets WCAG AA, or nil if already compliant
    static func adjustedColor(foreground: Color, background: Color, isLargeText: Bool = false) -> Color? {
        if meetsWCAGAA(foreground: foreground, background: background, isLargeText: isLargeText) {
            return nil // Already compliant
        }
        
        // Try darkening or lightening the foreground color
        let bgLuminance = relativeLuminance(of: background)
        
        // If background is light, darken foreground; if dark, lighten foreground
        if bgLuminance > 0.5 {
            return darkenUntilCompliant(foreground: foreground, background: background, isLargeText: isLargeText)
        } else {
            return lightenUntilCompliant(foreground: foreground, background: background, isLargeText: isLargeText)
        }
    }
    
    // MARK: - Private Helpers
    
    private static func relativeLuminance(of color: Color) -> CGFloat {
        guard let components = UIColor(color).cgColor.components else { return 0 }
        
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        
        let rLinear = linearize(r)
        let gLinear = linearize(g)
        let bLinear = linearize(b)
        
        return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear
    }
    
    private static func linearize(_ component: CGFloat) -> CGFloat {
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
        }
    }
    
    private static func darkenUntilCompliant(foreground: Color, background: Color, isLargeText: Bool) -> Color {
        let uiColor = UIColor(foreground)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Iteratively darken
        for _ in 0..<20 {
            brightness *= 0.9
            let adjusted = Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(alpha))
            
            if meetsWCAGAA(foreground: adjusted, background: background, isLargeText: isLargeText) {
                return adjusted
            }
        }
        
        // Fallback to black
        return .black
    }
    
    private static func lightenUntilCompliant(foreground: Color, background: Color, isLargeText: Bool) -> Color {
        let uiColor = UIColor(foreground)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Iteratively lighten
        for _ in 0..<20 {
            brightness = min(1.0, brightness * 1.1 + 0.05)
            let adjusted = Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(alpha))
            
            if meetsWCAGAA(foreground: adjusted, background: background, isLargeText: isLargeText) {
                return adjusted
            }
        }
        
        // Fallback to white
        return .white
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension ColorContrastValidator {
    
    /// Print a contrast report for debugging
    static func printContrastReport(foreground: Color, background: Color, label: String = "Color Pair") {
        let ratio = contrastRatio(between: foreground, and: background)
        let aa = meetsWCAGAA(foreground: foreground, background: background)
        let aaLarge = meetsWCAGAA(foreground: foreground, background: background, isLargeText: true)
        let aaa = meetsWCAGAAA(foreground: foreground, background: background)
        let aaaLarge = meetsWCAGAAA(foreground: foreground, background: background, isLargeText: true)
        
        print("""
        
        ═══════════════════════════════════════
        Contrast Report: \(label)
        ═══════════════════════════════════════
        Ratio: \(String(format: "%.2f", ratio)):1
        
        WCAG AA (Normal):  \(aa ? "✅ PASS" : "❌ FAIL")
        WCAG AA (Large):   \(aaLarge ? "✅ PASS" : "❌ FAIL")
        WCAG AAA (Normal): \(aaa ? "✅ PASS" : "❌ FAIL")
        WCAG AAA (Large):  \(aaaLarge ? "✅ PASS" : "❌ FAIL")
        ═══════════════════════════════════════
        
        """)
    }
}
#endif
