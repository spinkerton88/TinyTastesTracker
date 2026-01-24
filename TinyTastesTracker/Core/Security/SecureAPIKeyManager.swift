//
//  SecureAPIKeyManager.swift
//  TinyTastesTracker
//
//  Secure API key management with obfuscation and monitoring
//
//  ⚠️ SECURITY NOTE:
//  API keys embedded in iOS apps can ALWAYS be extracted by determined attackers.
//  This implementation provides basic obfuscation and monitoring but is NOT
//  a complete security solution. For production, use a backend proxy service.
//

import Foundation
import CryptoKit

/// Manages secure storage and retrieval of API keys with obfuscation
class SecureAPIKeyManager {

    static let shared = SecureAPIKeyManager()

    private init() {}

    // MARK: - API Key Obfuscation

    /// Obfuscated API key components (split to avoid direct string matching)
    /// This is NOT encryption - it's basic obfuscation to avoid plaintext storage
    private let keyParts: [String] = [
        "QUl6YVN5Q21p",      // Base64 encoded parts
        "ZHNRcEozbGdS",      // Split into chunks to avoid
        "Q0UwYUFkaEkz",      // easy pattern matching in
        "cm1pQjhsTlFj",      // the compiled binary
        "NXc="              // Reassembled at runtime
    ]

    /// XOR cipher key for additional obfuscation layer
    private let xorKey: [UInt8] = [0x7A, 0x45, 0x3C, 0x91, 0x2F, 0x64, 0x8B, 0x1E]

    // MARK: - Key Retrieval

    /// Retrieves the deobfuscated API key
    /// - Returns: The Gemini API key, or nil if retrieval fails
    func getAPIKey() -> String? {
        // Try to get from obfuscated storage first
        if let key = getObfuscatedKey() {
            return key
        }

        // Fallback to plist (for development/testing)
        return getKeyFromPlist()
    }
    
    /// Retrieves the Backend Proxy URL
    func getBackendURL() -> String {
        // Deployed Cloudflare Worker URL
        return "https://tiny-tastes-gemini-proxy.tiny-tastes-gemini-proxy.workers.dev"
    }

    /// Deobfuscates and retrieves the API key from embedded storage
    private func getObfuscatedKey() -> String? {
        // Combine base64 encoded parts
        let combinedBase64 = keyParts.joined()

        // Decode from base64
        guard let decodedData = Data(base64Encoded: combinedBase64) else {
            print("⚠️ Failed to decode API key from base64")
            return nil
        }

        // Apply XOR deobfuscation
        let deobfuscatedData = decodedData.enumerated().map { index, byte in
            byte ^ xorKey[index % xorKey.count]
        }

        // Convert to string
        guard let apiKey = String(data: Data(deobfuscatedData), encoding: .utf8) else {
            print("⚠️ Failed to convert deobfuscated data to string")
            return nil
        }

        return apiKey
    }

    /// Fallback: Get API key from plist (development only)
    private func getKeyFromPlist() -> String? {
        guard let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["API_KEY"] as? String,
              !apiKey.isEmpty,
              apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            print("⚠️ No valid API key found in plist")
            return nil
        }

        print("⚠️ WARNING: Using API key from plist. This should only be used in development!")
        return apiKey
    }

    // MARK: - Key Obfuscation Utility

    /// Utility function to obfuscate a new API key (for developers)
    /// Use this function to generate obfuscated key parts when changing API keys
    /// - Parameter plainKey: The plaintext API key to obfuscate
    /// - Returns: Array of base64 encoded, obfuscated parts
    static func obfuscateKey(_ plainKey: String) -> [String] {
        let xorKey: [UInt8] = [0x7A, 0x45, 0x3C, 0x91, 0x2F, 0x64, 0x8B, 0x1E]

        // Convert to data
        guard let keyData = plainKey.data(using: .utf8) else {
            return []
        }

        // Apply XOR obfuscation
        let obfuscatedData = keyData.enumerated().map { index, byte in
            byte ^ xorKey[index % xorKey.count]
        }

        // Convert to base64
        let base64String = Data(obfuscatedData).base64EncodedString()

        // Split into chunks (to avoid easy pattern matching)
        let chunkSize = 12
        var chunks: [String] = []
        var currentIndex = base64String.startIndex

        while currentIndex < base64String.endIndex {
            let endIndex = base64String.index(currentIndex, offsetBy: chunkSize, limitedBy: base64String.endIndex) ?? base64String.endIndex
            let chunk = String(base64String[currentIndex..<endIndex])
            chunks.append(chunk)
            currentIndex = endIndex
        }

        return chunks
    }

    // MARK: - Security Validation

    /// Validates that the API key meets security requirements
    func validateAPIKeySecurity() -> (isSecure: Bool, warnings: [String]) {
        var warnings: [String] = []
        var isSecure = true

        // Check if using plist (insecure)
        if getKeyFromPlist() != nil {
            warnings.append("⚠️ API key found in plist file - this is INSECURE for production")
            isSecure = false
        }

        // Check if plist file exists and is not in gitignore
        if let _ = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist") {
            warnings.append("ℹ️ GenerativeAI-Info.plist exists - ensure it's in .gitignore")
        }

        // Verify obfuscated key is available
        if getObfuscatedKey() == nil {
            warnings.append("⚠️ No obfuscated API key configured - app may not function")
            isSecure = false
        }

        return (isSecure, warnings)
    }
}

// MARK: - Developer Utilities

#if DEBUG
extension SecureAPIKeyManager {
    /// Debug utility to print obfuscated key parts
    /// Only available in DEBUG builds
    func printObfuscatedKeyParts(for plainKey: String) {
        let parts = Self.obfuscateKey(plainKey)
        print("📝 Obfuscated API Key Parts (copy to keyParts array):")
        print("private let keyParts: [String] = [")
        for (index, part) in parts.enumerated() {
            let comma = index < parts.count - 1 ? "," : ""
            print("    \"\(part)\"\(comma)")
        }
        print("]")
    }
}
#endif

// MARK: - Usage Instructions

/*

 HOW TO UPDATE THE API KEY:

 1. Get your new Gemini API key from Google AI Studio

 2. Run this code in DEBUG mode to generate obfuscated parts:
    ```swift
    #if DEBUG
    let plainKey = "YOUR_NEW_API_KEY_HERE"
    SecureAPIKeyManager.shared.printObfuscatedKeyParts(for: plainKey)
    #endif
    ```

 3. Copy the printed array and replace the `keyParts` property above

 4. Remove the DEBUG code

 5. Verify the key works:
    ```swift
    if let key = SecureAPIKeyManager.shared.getAPIKey() {
        print("✅ API key retrieved successfully")
    }
    ```

 6. Delete GenerativeAI-Info.plist from your project (keep .example)

 ⚠️ IMPORTANT: This is basic obfuscation, NOT encryption!
 For production apps with sensitive API usage, use a backend proxy service.

 */
