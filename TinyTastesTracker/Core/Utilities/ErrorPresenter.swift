//
//  ErrorPresenter.swift
//  TinyTastesTracker
//
//  Observable error presentation system for UI layer
//

import Foundation
import SwiftUI

@Observable
class ErrorPresenter {
    static let shared = ErrorPresenter()
    
    var currentError: AppError?
    var isShowingError: Bool = false
    
    private init() {}
    
    /// Present an error to the user
    func present(_ error: Error) {
        let appError = AppError.from(error)
        
        // Log if needed
        if appError.shouldLog {
            print("❌ Error: \(appError.localizedDescription ?? "Unknown")")
            if let suggestion = appError.recoverySuggestion {
                print("   💡 Suggestion: \(suggestion)")
            }
        }
        
        // Update UI state on main thread
        Task { @MainActor in
            self.currentError = appError
            self.isShowingError = true
        }
    }
    
    /// Dismiss the current error
    func dismiss() {
        Task { @MainActor in
            self.isShowingError = false
            // Clear after animation completes
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                self.currentError = nil
            }
        }
    }
    
    /// Present an AppError directly
    func present(_ appError: AppError) {
        if appError.shouldLog {
            print("❌ Error: \(appError.localizedDescription ?? "Unknown")")
            if let suggestion = appError.recoverySuggestion {
                print("   💡 Suggestion: \(suggestion)")
            }
        }
        
        Task { @MainActor in
            self.currentError = appError
            self.isShowingError = true
        }
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
    @State private var errorPresenter = ErrorPresenter.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorPresenter.isShowingError) {
                Button("OK") {
                    errorPresenter.dismiss()
                }
            } message: {
                if let error = errorPresenter.currentError {
                    VStack(alignment: .leading, spacing: 8) {
                        if let description = error.errorDescription {
                            Text(description)
                                .font(.headline)
                        }
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
    }
}
