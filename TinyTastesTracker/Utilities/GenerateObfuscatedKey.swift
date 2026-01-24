//
//  GenerateObfuscatedKey.swift
//  TinyTastesTracker
//
//  Utility to generate obfuscated API key parts
//  USAGE: Uncomment the code in your app initialization, run once, then delete this file
//

import Foundation

#if DEBUG
class ObfuscatedKeyGenerator {

    /// Run this once with your new API key to generate obfuscated parts
    static func generateAndPrint(apiKey: String) {
        print("\n" + String(repeating: "=", count: 80))
        print("🔐 OBFUSCATED API KEY GENERATOR")
        print(String(repeating: "=", count: 80))

        let xorKey: [UInt8] = [0x7A, 0x45, 0x3C, 0x91, 0x2F, 0x64, 0x8B, 0x1E]

        // Convert to data
        guard let keyData = apiKey.data(using: .utf8) else {
            print("❌ ERROR: Failed to convert API key to data")
            return
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

        print("\n✅ Generated obfuscated key parts:")
        print("\nCopy these to SecureAPIKeyManager.swift:")
        print("\nprivate let keyParts: [String] = [")
        for (index, part) in chunks.enumerated() {
            let comma = index < chunks.count - 1 ? "," : ""
            print("    \"\(part)\"\(comma)")
        }
        print("]")

        print("\n" + String(repeating: "=", count: 80))
        print("⚠️  IMPORTANT: Delete this output and this file after copying!")
        print(String(repeating: "=", count: 80) + "\n")
    }
}

// UNCOMMENT THIS IN YOUR APP INITIALIZATION (e.g., TinyTastesTrackerApp.swift init)
// THEN RUN THE APP ONCE, COPY THE OUTPUT, AND DELETE THIS FILE

/*

 HOW TO USE:

 1. In TinyTastesTrackerApp.swift, add this to init():

    init() {
        #if DEBUG
        // Read your new API key from plist
        if let path = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let apiKey = config["API_KEY"] as? String {
            ObfuscatedKeyGenerator.generateAndPrint(apiKey: apiKey)
        }
        #endif
    }

 2. Build and run the app in the simulator

 3. Check Xcode console for the output

 4. Copy the generated keyParts array to SecureAPIKeyManager.swift

 5. DELETE the #if DEBUG code from TinyTastesTrackerApp.swift

 6. DELETE this GenerateObfuscatedKey.swift file

 7. Optionally delete GenerativeAI-Info.plist (if using obfuscated key only)

 */

#endif
