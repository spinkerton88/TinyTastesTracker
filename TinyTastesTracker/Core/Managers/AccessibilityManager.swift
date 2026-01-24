//
//  AccessibilityManager.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/14/26.
//

import SwiftUI
import Combine

/// Centralized manager for accessibility utilities and state detection
@Observable
class AccessibilityManager {
    
    // MARK: - Singleton
    
    static let shared = AccessibilityManager()
    
    // MARK: - Published State
    
    private(set) var isVoiceOverRunning = false
    private(set) var isReduceMotionEnabled = false
    private(set) var isBoldTextEnabled = false
    private(set) var preferredContentSizeCategory: ContentSizeCategory = .medium
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupAccessibilityObservers()
        updateAccessibilityState()
    }
    
    // MARK: - Setup
    
    private func setupAccessibilityObservers() {
        // VoiceOver
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateVoiceOverState()
            }
            .store(in: &cancellables)
        
        // Reduce Motion
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateReduceMotionState()
            }
            .store(in: &cancellables)
        
        // Bold Text
        NotificationCenter.default.publisher(for: UIAccessibility.boldTextStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBoldTextState()
            }
            .store(in: &cancellables)
        
        // Content Size Category
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateContentSizeCategory()
            }
            .store(in: &cancellables)
    }
    
    private func updateAccessibilityState() {
        updateVoiceOverState()
        updateReduceMotionState()
        updateBoldTextState()
        updateContentSizeCategory()
    }
    
    private func updateVoiceOverState() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    }
    
    private func updateReduceMotionState() {
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    }
    
    private func updateBoldTextState() {
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
    }
    
    private func updateContentSizeCategory() {
        preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
    }
    
    // MARK: - Helper Methods
    
    /// Post an accessibility announcement for VoiceOver users
    /// - Parameters:
    ///   - message: The message to announce
    ///   - priority: The priority of the announcement (default: .default)
    func announce(_ message: String, priority: UIAccessibilityPriority = .default) {
        guard isVoiceOverRunning else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Post a screen changed notification for VoiceOver
    /// - Parameter element: Optional element to focus on
    func announceScreenChanged(focusOn element: Any? = nil) {
        guard isVoiceOverRunning else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: element)
        }
    }
    
    /// Post a layout changed notification for VoiceOver
    /// - Parameter element: Optional element to focus on
    func announceLayoutChanged(focusOn element: Any? = nil) {
        guard isVoiceOverRunning else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: element)
        }
    }
    
    /// Check if Dynamic Type is set to an accessibility size
    var isAccessibilitySize: Bool {
        preferredContentSizeCategory.isAccessibilityCategory
    }
    
    /// Get a scaled value based on Dynamic Type
    /// - Parameters:
    ///   - baseValue: The base value at default text size
    ///   - maximumValue: Optional maximum value to cap at
    /// - Returns: Scaled value
    func scaledValue(_ baseValue: CGFloat, maximum maximumValue: CGFloat? = nil) -> CGFloat {
        let scale = preferredContentSizeCategory.scaleFactor
        let scaled = baseValue * scale
        
        if let max = maximumValue {
            return min(scaled, max)
        }
        
        return scaled
    }
}

// MARK: - ContentSizeCategory Extension

extension ContentSizeCategory {
    init(_ uiCategory: UIContentSizeCategory) {
        switch uiCategory {
        case .extraSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .extraLarge
        case .extraExtraLarge: self = .extraExtraLarge
        case .extraExtraExtraLarge: self = .extraExtraExtraLarge
        case .accessibilityMedium: self = .accessibilityMedium
        case .accessibilityLarge: self = .accessibilityLarge
        case .accessibilityExtraLarge: self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: self = .accessibilityExtraExtraExtraLarge
        default: self = .large
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.6
        case .accessibilityExtraLarge: return 1.8
        case .accessibilityExtraExtraLarge: return 2.0
        case .accessibilityExtraExtraExtraLarge: return 2.3
        @unknown default: return 1.0
        }
    }
}
