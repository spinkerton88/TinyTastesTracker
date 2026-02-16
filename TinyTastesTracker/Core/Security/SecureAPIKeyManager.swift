//
//  SecureAPIKeyManager.swift
//  TinyTastesTracker
//
//  Secure API management via Backend Proxy
//
//  ⚠️ SECURITY NOTE:
//  This app uses a backend proxy to handle all Gemini AI requests.
//  No API keys are stored locally within the application code or files.
//

import Foundation

/// Manages retrieval of backend proxy configuration
class SecureAPIKeyManager {

    static let shared = SecureAPIKeyManager()

    private init() {}

    // MARK: - Proxy Configuration

    /// Retrieves the Backend Proxy URL
    func getBackendURL() -> String {
        // Try to get from plist first
        if let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let backendURL = config["BACKEND_URL"] as? String,
           !backendURL.isEmpty {
            return backendURL
        }
        
        // Deployed Cloudflare Worker URL fallback
        return "https://tiny-tastes-gemini-proxy.tiny-tastes-gemini-proxy.workers.dev"
    }

    // MARK: - Security Validation

    /// Validates that the proxy configuration is present
    func validateSecurity() -> (isValid: Bool, warnings: [String]) {
        var warnings: [String] = []
        var isValid = true

        if let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let _ = config["BACKEND_URL"] as? String {
            // Valid
        } else {
            warnings.append("⚠️ BACKEND_URL missing from GenerativeAI-Info.plist")
            isValid = false
        }

        return (isValid, warnings)
    }
}
