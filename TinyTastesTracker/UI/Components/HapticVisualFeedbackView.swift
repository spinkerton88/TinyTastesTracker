//
//  HapticVisualFeedbackView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/14/26.
//

import SwiftUI

/// View modifier that provides visual feedback for haptic events
struct HapticVisualFeedbackModifier: ViewModifier {
    
    @State private var feedbackType: HapticManager.HapticType?
    @State private var showFeedback = false
    
    let accessibilityManager = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .center) {
                if showFeedback, let type = feedbackType {
                    feedbackView(for: type)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                setupFeedbackCallback()
            }
    }
    
    private func setupFeedbackCallback() {
        HapticManager.visualFeedbackCallback = { [self] type in
            Task { @MainActor in
                self.feedbackType = type
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.showFeedback = true
                }
                
                // Auto-dismiss after delay
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                withAnimation(.easeOut(duration: 0.2)) {
                    self.showFeedback = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func feedbackView(for type: HapticManager.HapticType) -> some View {
        let config = feedbackConfiguration(for: type)
        
        ZStack {
            Circle()
                .fill(config.color.opacity(0.2))
                .frame(width: 60, height: 60)
            
            Image(systemName: config.icon)
                .font(.title2)
                .foregroundStyle(config.color)
        }
        .scaleEffect(showFeedback ? 1.0 : 0.5)
        .opacity(showFeedback ? 1.0 : 0.0)
    }
    
    private func feedbackConfiguration(for type: HapticManager.HapticType) -> (color: Color, icon: String) {
        switch type {
        case .success:
            return (.green, "checkmark.circle.fill")
        case .warning:
            return (.orange, "exclamationmark.triangle.fill")
        case .error:
            return (.red, "xmark.circle.fill")
        case .selection:
            return (.blue, "hand.tap.fill")
        case .impact:
            return (.purple, "circle.fill")
        }
    }
}

// MARK: - View Extension

extension View {
    /// Add visual feedback for haptic events
    /// - Returns: Modified view with haptic visual feedback overlay
    func hapticVisualFeedback() -> some View {
        modifier(HapticVisualFeedbackModifier())
    }
}

// MARK: - Standalone Visual Feedback View

/// A standalone view that shows visual feedback for accessibility
struct VisualFeedbackIndicator: View {
    let type: HapticManager.HapticType
    let message: String?
    
    @State private var isVisible = true
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(color)
            
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isVisible = true
            }
        }
    }
    
    private var icon: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .selection: return "hand.tap.fill"
        case .impact: return "circle.fill"
        }
    }
    
    private var color: Color {
        switch type {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .selection: return .blue
        case .impact: return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        VisualFeedbackIndicator(type: .success, message: "Saved successfully")
        VisualFeedbackIndicator(type: .warning, message: "Please review")
        VisualFeedbackIndicator(type: .error, message: "Failed to save")
        VisualFeedbackIndicator(type: .selection, message: nil)
    }
    .padding()
}
