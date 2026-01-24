//
//  AIResponseCache.swift
//  TinyTastesTracker
//
//  Smart caching system for AI responses with TTL and persistence
//

import Foundation
import CryptoKit

@Observable
class AIResponseCache {
    static let shared = AIResponseCache()
    
    // MARK: - Cache Configuration
    
    private let maxCacheAge: TimeInterval = 3600 // 1 hour
    private let maxCacheSize = 100 // Maximum number of cached items
    
    // MARK: - Cache Storage
    
    private struct CachedResponse: Codable {
        let response: String
        let timestamp: Date
        let callType: String
    }
    
    private var memoryCache: [String: CachedResponse] = [:]
    private let persistentCacheKey = "AIResponseCache"
    
    private init() {
        loadFromDisk()
        startCleanupTimer()
    }
    
    // MARK: - Cache Operations
    
    /// Get a cached response if available and not expired
    func get(for key: String) -> String? {
        guard let cached = memoryCache[key] else {
            return nil
        }
        
        // Check if expired
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > maxCacheAge {
            memoryCache.removeValue(forKey: key)
            saveToDisk()
            return nil
        }
        
        print("✅ Cache hit for key: \(key.prefix(20))... (age: \(Int(age))s)")
        return cached.response
    }
    
    /// Store a response in the cache
    func set(_ response: String, for key: String, callType: String = "general") {
        let cached = CachedResponse(
            response: response,
            timestamp: Date(),
            callType: callType
        )
        
        memoryCache[key] = cached
        
        // Enforce cache size limit
        if memoryCache.count > maxCacheSize {
            evictOldest()
        }
        
        saveToDisk()
        print("💾 Cached response for key: \(key.prefix(20))...")
    }
    
    /// Clear all cached responses
    func clear() {
        memoryCache.removeAll()
        saveToDisk()
        print("🗑️ Cache cleared")
    }
    
    /// Clear expired entries
    func clearExpired() {
        let now = Date()
        let expiredKeys = memoryCache.filter { key, cached in
            now.timeIntervalSince(cached.timestamp) > maxCacheAge
        }.map { $0.key }
        
        for key in expiredKeys {
            memoryCache.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            saveToDisk()
            print("🗑️ Cleared \(expiredKeys.count) expired cache entries")
        }
    }
    
    // MARK: - Cache Key Generation
    
    /// Generate a cache key from a prompt and type
    static func cacheKey(for prompt: String, type: String) -> String {
        let combined = "\(type):\(prompt)"
        let hash = SHA256.hash(data: Data(combined.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Generate a cache key for sleep predictions
    static func sleepCacheKey(ageInMonths: Int, lastWakeTime: Date?) -> String {
        let timeString = lastWakeTime?.timeIntervalSince1970.description ?? "none"
        return cacheKey(for: "sleep_\(ageInMonths)_\(timeString)", type: "sleep")
    }
    
    /// Generate a cache key for food analysis
    static func foodCacheKey(foodName: String) -> String {
        return cacheKey(for: foodName, type: "food_analysis")
    }
    
    /// Generate a cache key for recipe analysis
    static func recipeCacheKey(title: String, ingredients: String) -> String {
        return cacheKey(for: "\(title)_\(ingredients)", type: "recipe_analysis")
    }
    
    /// Generate a cache key for nutrient suggestions
    static func nutrientCacheKey(nutrient: String, ageInMonths: Int) -> String {
        return cacheKey(for: "\(nutrient)_\(ageInMonths)", type: "nutrient_suggestions")
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(memoryCache)
            UserDefaults.standard.set(data, forKey: persistentCacheKey)
        } catch {
            print("⚠️ Failed to save cache to disk: \(error)")
        }
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: persistentCacheKey) else {
            return
        }
        
        do {
            memoryCache = try JSONDecoder().decode([String: CachedResponse].self, from: data)
            print("✅ Loaded \(memoryCache.count) cached responses from disk")
            
            // Clear expired entries on load
            clearExpired()
        } catch {
            print("⚠️ Failed to load cache from disk: \(error)")
            memoryCache = [:]
        }
    }
    
    // MARK: - Cache Management
    
    private func evictOldest() {
        guard let oldestKey = memoryCache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key else {
            return
        }
        
        memoryCache.removeValue(forKey: oldestKey)
        print("🗑️ Evicted oldest cache entry")
    }
    
    private func startCleanupTimer() {
        // Clean up expired entries every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.clearExpired()
        }
    }
    
    // MARK: - Cache Statistics
    
    var cacheSize: Int {
        memoryCache.count
    }
    
    var cacheStats: String {
        let totalSize = memoryCache.count
        let now = Date()
        let validCount = memoryCache.filter { key, cached in
            now.timeIntervalSince(cached.timestamp) <= maxCacheAge
        }.count
        
        return "Cache: \(validCount)/\(totalSize) valid entries"
    }
}
