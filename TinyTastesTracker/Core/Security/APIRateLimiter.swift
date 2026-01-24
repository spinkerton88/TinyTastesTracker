//
//  APIRateLimiter.swift
//  TinyTastesTracker
//
//  Rate limiting for API calls to prevent quota exhaustion and abuse
//

import Foundation

/// Rate limiting configuration for API calls
struct RateLimitConfig {
    let maxRequestsPerMinute: Int
    let maxRequestsPerHour: Int
    let maxRequestsPerDay: Int

    static let `default` = RateLimitConfig(
        maxRequestsPerMinute: 10,    // 10 requests per minute
        maxRequestsPerHour: 100,     // 100 requests per hour
        maxRequestsPerDay: 1000      // 1000 requests per day
    )

    static let strict = RateLimitConfig(
        maxRequestsPerMinute: 5,
        maxRequestsPerHour: 50,
        maxRequestsPerDay: 500
    )
}

/// Errors thrown by rate limiter
enum RateLimitError: LocalizedError {
    case minuteLimitExceeded(retryAfter: TimeInterval)
    case hourLimitExceeded(retryAfter: TimeInterval)
    case dayLimitExceeded(retryAfter: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .minuteLimitExceeded(let seconds):
            return "Too many requests. Please wait \(Int(seconds)) seconds before trying again."
        case .hourLimitExceeded(let seconds):
            return "Hourly limit exceeded. Please wait \(Int(seconds / 60)) minutes."
        case .dayLimitExceeded:
            return "Daily limit exceeded. Please try again tomorrow."
        }
    }

    var retryAfter: TimeInterval {
        switch self {
        case .minuteLimitExceeded(let time),
             .hourLimitExceeded(let time),
             .dayLimitExceeded(let time):
            return time
        }
    }
}

/// Manages rate limiting for API calls
class APIRateLimiter {

    static let shared = APIRateLimiter()

    private let config: RateLimitConfig
    private let queue = DispatchQueue(label: "com.tinytastes.ratelimiter", attributes: .concurrent)

    // Request timestamps for tracking
    private var requestTimestamps: [Date] = []

    // MARK: - Initialization

    init(config: RateLimitConfig = .default) {
        self.config = config
    }

    // MARK: - Rate Limiting

    /// Check if a request can be made, throwing an error if rate limit exceeded
    /// - Throws: RateLimitError if rate limit is exceeded
    func checkRateLimit() throws {
        try queue.sync {
            let now = Date()
            cleanOldTimestamps(before: now)

            // Check minute limit
            let lastMinute = now.addingTimeInterval(-60)
            let minuteCount = requestTimestamps.filter { $0 >= lastMinute }.count
            if minuteCount >= config.maxRequestsPerMinute {
                let oldestInMinute = requestTimestamps.first(where: { $0 >= lastMinute }) ?? now
                let retryAfter = 60 - now.timeIntervalSince(oldestInMinute)
                throw RateLimitError.minuteLimitExceeded(retryAfter: max(0, retryAfter))
            }

            // Check hour limit
            let lastHour = now.addingTimeInterval(-3600)
            let hourCount = requestTimestamps.filter { $0 >= lastHour }.count
            if hourCount >= config.maxRequestsPerHour {
                let oldestInHour = requestTimestamps.first(where: { $0 >= lastHour }) ?? now
                let retryAfter = 3600 - now.timeIntervalSince(oldestInHour)
                throw RateLimitError.hourLimitExceeded(retryAfter: max(0, retryAfter))
            }

            // Check day limit
            let lastDay = now.addingTimeInterval(-86400)
            let dayCount = requestTimestamps.filter { $0 >= lastDay }.count
            if dayCount >= config.maxRequestsPerDay {
                let oldestInDay = requestTimestamps.first(where: { $0 >= lastDay }) ?? now
                let retryAfter = 86400 - now.timeIntervalSince(oldestInDay)
                throw RateLimitError.dayLimitExceeded(retryAfter: max(0, retryAfter))
            }
        }
    }

    /// Record a successful request
    func recordRequest() {
        queue.async(flags: .barrier) {
            self.requestTimestamps.append(Date())
        }
    }

    /// Get current usage statistics
    func getUsageStats() -> (minute: Int, hour: Int, day: Int) {
        queue.sync {
            let now = Date()
            cleanOldTimestamps(before: now)

            let minuteCount = requestTimestamps.filter { $0 >= now.addingTimeInterval(-60) }.count
            let hourCount = requestTimestamps.filter { $0 >= now.addingTimeInterval(-3600) }.count
            let dayCount = requestTimestamps.filter { $0 >= now.addingTimeInterval(-86400) }.count

            return (minuteCount, hourCount, dayCount)
        }
    }

    /// Reset all rate limits (use with caution)
    func reset() {
        queue.async(flags: .barrier) {
            self.requestTimestamps.removeAll()
        }
    }

    // MARK: - Private Helpers

    /// Remove timestamps older than 24 hours to prevent memory growth
    private func cleanOldTimestamps(before date: Date) {
        let cutoff = date.addingTimeInterval(-86400) // 24 hours ago
        requestTimestamps.removeAll { $0 < cutoff }
    }

    // MARK: - Convenience Methods

    /// Execute a block with rate limiting
    /// - Parameter block: The block to execute if rate limit allows
    /// - Throws: RateLimitError if rate limit exceeded
    func execute<T>(_ block: () throws -> T) throws -> T {
        try checkRateLimit()
        let result = try block()
        recordRequest()
        return result
    }

    /// Execute an async block with rate limiting
    /// - Parameter block: The async block to execute if rate limit allows
    /// - Throws: RateLimitError if rate limit exceeded
    func execute<T>(_ block: () async throws -> T) async throws -> T {
        try checkRateLimit()
        let result = try await block()
        recordRequest()
        return result
    }
}

// MARK: - UserDefaults Persistence (Optional)

extension APIRateLimiter {
    /// Save request timestamps to UserDefaults for persistence across app launches
    func saveToUserDefaults() {
        queue.async {
            let timestamps = self.requestTimestamps.map { $0.timeIntervalSince1970 }
            UserDefaults.standard.set(timestamps, forKey: "APIRateLimiter.timestamps")
        }
    }

    /// Load request timestamps from UserDefaults
    func loadFromUserDefaults() {
        queue.async(flags: .barrier) {
            if let timestamps = UserDefaults.standard.array(forKey: "APIRateLimiter.timestamps") as? [TimeInterval] {
                self.requestTimestamps = timestamps.map { Date(timeIntervalSince1970: $0) }
                // Clean old timestamps after loading
                self.cleanOldTimestamps(before: Date())
            }
        }
    }
}

// MARK: - Usage Example

/*

 USAGE:

 1. Check and execute a request:
 ```swift
 do {
     try APIRateLimiter.shared.checkRateLimit()
     // Make your API call
     let response = await makeAPICall()
     APIRateLimiter.shared.recordRequest()
 } catch let error as RateLimitError {
     print(error.localizedDescription)
     // Show user-friendly message
 }
 ```

 2. Use convenience method:
 ```swift
 do {
     let response = try await APIRateLimiter.shared.execute {
         await makeAPICall()
     }
 } catch let error as RateLimitError {
     print("Rate limit exceeded: \(error.localizedDescription)")
 }
 ```

 3. Check usage statistics:
 ```swift
 let stats = APIRateLimiter.shared.getUsageStats()
 print("Usage: \(stats.minute)/min, \(stats.hour)/hour, \(stats.day)/day")
 ```

 4. Persist across app launches:
 ```swift
 // In AppDelegate or App initialization
 APIRateLimiter.shared.loadFromUserDefaults()

 // When app goes to background
 APIRateLimiter.shared.saveToUserDefaults()
 ```

 */
