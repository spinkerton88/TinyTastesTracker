//
//  HapticManager.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//  Enhanced for accessibility on 1/14/26.
//

import UIKit
import SwiftUI

/// Centralized haptic feedback management with accessibility support
class HapticManager {
    
    // MARK: - Visual Feedback Callback
    
    /// Callback type for visual feedback alternatives
    typealias VisualFeedbackCallback = (HapticType) -> Void
    
    /// Shared visual feedback callback
    static var visualFeedbackCallback: VisualFeedbackCallback?
    
    // MARK: - Haptic Types
    
    enum HapticType {
        case success
        case warning
        case error
        case selection
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    }
    
    // MARK: - Success Notification
    
    /// Success notification haptic (✓)
    static func success() {
        performHaptic(.success)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Warning Notification
    
    /// Warning notification haptic (!)
    static func warning() {
        performHaptic(.warning)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // MARK: - Error Notification
    
    /// Error notification haptic (✗)
    static func error() {
        performHaptic(.error)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Haptic
    
    /// Selection haptic (subtle click)
    static func selection() {
        performHaptic(.selection)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Impact Haptic
    
    /// Impact haptic with customizable intensity
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        performHaptic(.impact(style))
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Haptic
    
    /// Notification haptic with customizable type
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let hapticType: HapticType
        switch type {
        case .success: hapticType = .success
        case .warning: hapticType = .warning
        case .error: hapticType = .error
        @unknown default: hapticType = .selection
        }
        
        performHaptic(hapticType)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Private Helpers
    
    /// Trigger visual feedback callback if Reduce Motion is enabled
    private static func performHaptic(_ type: HapticType) {
        // Always trigger visual feedback callback if set
        visualFeedbackCallback?(type)
        
        // If Reduce Motion is enabled, rely more on visual feedback
        if UIAccessibility.isReduceMotionEnabled {
            // Haptic still fires, but visual feedback becomes primary
            AccessibilityManager.shared.announce(hapticAccessibilityLabel(for: type))
        }
    }
    
    /// Get accessibility label for haptic type
    private static func hapticAccessibilityLabel(for type: HapticType) -> String {
        switch type {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .selection: return "Selected"
        case .impact: return "Action"
        }
    }
}

