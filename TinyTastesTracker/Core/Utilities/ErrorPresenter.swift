//
//  ErrorPresenter.swift
//  TinyTastesTracker
//
//  Observable error presentation system for UI layer
//

import Foundation
import SwiftUI

/// Presentation style for errors
enum ErrorPresentationStyle {
    case alert      // Full alert dialog
    case toast      // Brief toast notification
    case banner     // Persistent banner
}

@Observable
class ErrorPresenter {
    var currentError: FirebaseError?
    var isShowingError: Bool = false
    var presentationStyle: ErrorPresentationStyle = .alert
    var retryAction: (() async -> Void)?

    // Toast notifications
    var toastMessage: String?
    var isShowingToast: Bool = false

    init() {}
    
    /// Present an error to the user
    func present(_ error: Error, style: ErrorPresentationStyle = .alert, retryAction: (() async -> Void)? = nil) {
        let firebaseError = FirebaseError.from(error)
        
        // Log error
        print("❌ Error: \(firebaseError.errorDescription ?? "Unknown")")
        if let suggestion = firebaseError.recoverySuggestion {
            print("   💡 Suggestion: \(suggestion)")
        }
        
        // Update UI state on main thread
        Task { @MainActor in
            self.currentError = firebaseError
            self.presentationStyle = style
            self.retryAction = retryAction
            
            if style == .toast {
                self.showToast(firebaseError.errorDescription ?? "An error occurred")
            } else {
                self.isShowingError = true
            }
        }
    }
    
    /// Present a FirebaseError directly
    func present(_ error: FirebaseError, style: ErrorPresentationStyle = .alert, retryAction: (() async -> Void)? = nil) {
        print("❌ Error: \(error.errorDescription ?? "Unknown")")
        if let suggestion = error.recoverySuggestion {
            print("   💡 Suggestion: \(suggestion)")
        }
        
        Task { @MainActor in
            self.currentError = error
            self.presentationStyle = style
            self.retryAction = retryAction
            
            if style == .toast {
                self.showToast(error.errorDescription ?? "An error occurred")
            } else {
                self.isShowingError = true
            }
        }
    }
    
    /// Show a toast notification
    func showToast(_ message: String, duration: TimeInterval = 3.0) {
        Task { @MainActor in
            self.toastMessage = message
            self.isShowingToast = true
            
            // Auto-dismiss after duration
            Task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                self.isShowingToast = false
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s for animation
                self.toastMessage = nil
            }
        }
    }
    
    /// Dismiss the current error
    func dismiss() {
        Task { @MainActor in
            self.isShowingError = false
            self.retryAction = nil
            // Clear after animation completes
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                self.currentError = nil
            }
        }
    }
    
    /// Execute retry action
    func retry() async {
        if let action = retryAction {
            dismiss()
            await action()
        }
    }
    
    /// Show success toast with haptic feedback
    func showSuccess(_ message: String, duration: TimeInterval = 2.0) {
        HapticManager.success()
        showToast(message, duration: duration)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds global error presentation to any view
    func withErrorPresentation() -> some View {
        self.modifier(ErrorPresentationModifier())
    }
}

struct ErrorPresentationModifier: ViewModifier {
    @Environment(\.errorPresenter) private var errorPresenter

    func body(content: Content) -> some View {
        content
            .alert(errorPresenter.currentError?.errorDescription ?? "Error",
                   isPresented: Binding(
                       get: { errorPresenter.isShowingError },
                       set: { errorPresenter.isShowingError = $0 }
                   )) {
                // Retry button if error is retryable
                if let error = errorPresenter.currentError, error.isRetryable, errorPresenter.retryAction != nil {
                    Button("Retry") {
                        Task {
                            await errorPresenter.retry()
                        }
                    }
                }

                Button("OK") {
                    errorPresenter.dismiss()
                }
            } message: {
                if let error = errorPresenter.currentError {
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                    }
                }
            }
            .overlay(alignment: .top) {
                // Toast notification overlay
                if errorPresenter.isShowingToast, let message = errorPresenter.toastMessage {
                    ToastView(message: message, buttonTitle: nil, action: nil)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(), value: errorPresenter.isShowingToast)
                }
            }
    }
}

// MARK: - Environment Key

private struct ErrorPresenterKey: EnvironmentKey {
    static let defaultValue = ErrorPresenter()
}

extension EnvironmentValues {
    var errorPresenter: ErrorPresenter {
        get { self[ErrorPresenterKey.self] }
        set { self[ErrorPresenterKey.self] = newValue }
    }
}
