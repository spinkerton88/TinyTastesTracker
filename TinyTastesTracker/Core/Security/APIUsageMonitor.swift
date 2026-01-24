//
//  APIUsageMonitor.swift
//  TinyTastesTracker
//
//  Monitors API usage patterns and detects potential abuse or anomalies
//

import Foundation

/// API call types for tracking
enum APICallType: String, Codable {
    case textGeneration = "text_generation"
    case imageAnalysis = "image_analysis"
    case voiceChat = "voice_chat"
    case recipeGeneration = "recipe_generation"
    case nutritionAnalysis = "nutrition_analysis"
    case general = "general"
}

/// Represents a single API call record
struct APICallRecord: Codable {
    let id: UUID
    let timestamp: Date
    let callType: APICallType
    let success: Bool
    let responseTime: TimeInterval?
    let errorMessage: String?
    let tokensUsed: Int?

    init(
        callType: APICallType,
        success: Bool,
        responseTime: TimeInterval? = nil,
        errorMessage: String? = nil,
        tokensUsed: Int? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.callType = callType
        self.success = success
        self.responseTime = responseTime
        self.errorMessage = errorMessage
        self.tokensUsed = tokensUsed
    }
}

/// Anomaly detection result
struct UsageAnomaly {
    enum AnomalyType {
        case suspiciousFrequency
        case unusualFailureRate
        case unexpectedCallPattern
        case excessiveTokenUsage
    }

    let type: AnomalyType
    let description: String
    let severity: Int // 1-10
    let detectedAt: Date
}

/// Usage statistics for reporting
struct UsageStatistics {
    let totalCalls: Int
    let successfulCalls: Int
    let failedCalls: Int
    let averageResponseTime: TimeInterval
    let totalTokensUsed: Int
    let callsByType: [APICallType: Int]
    let timeRange: (start: Date, end: Date)

    var successRate: Double {
        guard totalCalls > 0 else { return 0 }
        return Double(successfulCalls) / Double(totalCalls)
    }

    var failureRate: Double {
        guard totalCalls > 0 else { return 0 }
        return Double(failedCalls) / Double(totalCalls)
    }
}

/// Monitors and logs API usage patterns
class APIUsageMonitor {

    static let shared = APIUsageMonitor()

    private let queue = DispatchQueue(label: "com.tinytastes.apimonitor", attributes: .concurrent)
    private let maxRecordsInMemory = 1000
    private let persistenceKey = "APIUsageMonitor.records"

    // In-memory cache of recent calls
    private var recentRecords: [APICallRecord] = []

    // Anomaly detection thresholds
    private let anomalyThresholds = (
        callsPerMinute: 15,
        failureRateThreshold: 0.3, // 30% failure rate
        avgResponseTimeThreshold: 10.0 // 10 seconds
    )

    // MARK: - Initialization

    private init() {
        loadRecordsFromDisk()
    }

    // MARK: - Recording API Calls

    /// Record an API call
    /// - Parameters:
    ///   - callType: Type of API call
    ///   - success: Whether the call succeeded
    ///   - responseTime: Time taken for the response
    ///   - errorMessage: Error message if failed
    ///   - tokensUsed: Number of tokens consumed
    func recordCall(
        type callType: APICallType,
        success: Bool,
        responseTime: TimeInterval? = nil,
        errorMessage: String? = nil,
        tokensUsed: Int? = nil
    ) {
        let record = APICallRecord(
            callType: callType,
            success: success,
            responseTime: responseTime,
            errorMessage: errorMessage,
            tokensUsed: tokensUsed
        )

        queue.async(flags: .barrier) {
            self.recentRecords.append(record)

            // Trim old records if we exceed the limit
            if self.recentRecords.count > self.maxRecordsInMemory {
                self.recentRecords.removeFirst(self.recentRecords.count - self.maxRecordsInMemory)
            }

            // Persist to disk periodically (every 10 calls)
            if self.recentRecords.count % 10 == 0 {
                self.saveRecordsToDisk()
            }
        }

        // Check for anomalies after recording
        _ = checkForAnomalies()
    }

    /// Convenience method to track an API call execution
    /// - Parameters:
    ///   - callType: Type of API call
    ///   - block: The async block to execute and track
    /// - Returns: Result of the block execution
    func track<T>(
        _ callType: APICallType,
        _ block: () async throws -> T
    ) async throws -> T {
        let startTime = Date()

        do {
            let result = try await block()
            let responseTime = Date().timeIntervalSince(startTime)

            recordCall(
                type: callType,
                success: true,
                responseTime: responseTime
            )

            return result
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)

            recordCall(
                type: callType,
                success: false,
                responseTime: responseTime,
                errorMessage: error.localizedDescription
            )

            throw error
        }
    }

    // MARK: - Statistics

    /// Get usage statistics for a time period
    /// - Parameters:
    ///   - from: Start date (defaults to 24 hours ago)
    ///   - to: End date (defaults to now)
    /// - Returns: Usage statistics for the period
    func getStatistics(from: Date? = nil, to: Date? = nil) -> UsageStatistics {
        queue.sync {
            let startDate = from ?? Date().addingTimeInterval(-86400) // 24 hours ago
            let endDate = to ?? Date()

            let filteredRecords = recentRecords.filter { record in
                record.timestamp >= startDate && record.timestamp <= endDate
            }

            let totalCalls = filteredRecords.count
            let successfulCalls = filteredRecords.filter { $0.success }.count
            let failedCalls = totalCalls - successfulCalls

            let responseTimes = filteredRecords.compactMap { $0.responseTime }
            let averageResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)

            let totalTokens = filteredRecords.compactMap { $0.tokensUsed }.reduce(0, +)

            var callsByType: [APICallType: Int] = [:]
            for record in filteredRecords {
                callsByType[record.callType, default: 0] += 1
            }

            return UsageStatistics(
                totalCalls: totalCalls,
                successfulCalls: successfulCalls,
                failedCalls: failedCalls,
                averageResponseTime: averageResponseTime,
                totalTokensUsed: totalTokens,
                callsByType: callsByType,
                timeRange: (startDate, endDate)
            )
        }
    }

    /// Get statistics for the last hour
    func getHourlyStatistics() -> UsageStatistics {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return getStatistics(from: oneHourAgo)
    }

    /// Get statistics for the last day
    func getDailyStatistics() -> UsageStatistics {
        let oneDayAgo = Date().addingTimeInterval(-86400)
        return getStatistics(from: oneDayAgo)
    }

    /// Get statistics for the last week
    func getWeeklyStatistics() -> UsageStatistics {
        let oneWeekAgo = Date().addingTimeInterval(-604800)
        return getStatistics(from: oneWeekAgo)
    }

    // MARK: - Anomaly Detection

    /// Check for usage anomalies
    /// - Returns: Array of detected anomalies
    func checkForAnomalies() -> [UsageAnomaly] {
        var anomalies: [UsageAnomaly] = []
        let now = Date()

        queue.sync {
            // Check for suspicious frequency (too many calls in short time)
            let lastMinute = now.addingTimeInterval(-60)
            let recentCalls = recentRecords.filter { $0.timestamp >= lastMinute }

            if recentCalls.count > anomalyThresholds.callsPerMinute {
                anomalies.append(UsageAnomaly(
                    type: .suspiciousFrequency,
                    description: "Detected \(recentCalls.count) calls in the last minute (threshold: \(anomalyThresholds.callsPerMinute))",
                    severity: 7,
                    detectedAt: now
                ))
            }

            // Check for unusual failure rate
            let stats = getDailyStatistics()
            if stats.totalCalls > 10 && stats.failureRate > anomalyThresholds.failureRateThreshold {
                anomalies.append(UsageAnomaly(
                    type: .unusualFailureRate,
                    description: "High failure rate detected: \(Int(stats.failureRate * 100))%",
                    severity: 8,
                    detectedAt: now
                ))
            }

            // Check for slow response times
            if stats.averageResponseTime > anomalyThresholds.avgResponseTimeThreshold {
                anomalies.append(UsageAnomaly(
                    type: .unexpectedCallPattern,
                    description: "Slow average response time: \(String(format: "%.2f", stats.averageResponseTime))s",
                    severity: 5,
                    detectedAt: now
                ))
            }
        }

        // Log anomalies if detected
        if !anomalies.isEmpty {
            logAnomalies(anomalies)
        }

        return anomalies
    }

    /// Log detected anomalies
    private func logAnomalies(_ anomalies: [UsageAnomaly]) {
        for anomaly in anomalies {
            print("⚠️ API Usage Anomaly Detected:")
            print("   Type: \(anomaly.type)")
            print("   Severity: \(anomaly.severity)/10")
            print("   Description: \(anomaly.description)")
            print("   Detected at: \(anomaly.detectedAt)")
        }
    }

    // MARK: - Persistence

    /// Save records to UserDefaults
    private func saveRecordsToDisk() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentRecords)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("⚠️ Failed to save API usage records: \(error)")
        }
    }

    /// Load records from UserDefaults
    private func loadRecordsFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            recentRecords = try decoder.decode([APICallRecord].self, from: data)

            // Clean old records (keep only last 7 days)
            let sevenDaysAgo = Date().addingTimeInterval(-604800)
            recentRecords.removeAll { $0.timestamp < sevenDaysAgo }
        } catch {
            print("⚠️ Failed to load API usage records: \(error)")
        }
    }

    /// Clear all stored records
    func clearAllRecords() {
        queue.async(flags: .barrier) {
            self.recentRecords.removeAll()
            UserDefaults.standard.removeObject(forKey: self.persistenceKey)
        }
    }

    // MARK: - Export

    /// Export usage data as JSON
    /// - Returns: JSON string of all records
    func exportAsJSON() -> String? {
        queue.sync {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(recentRecords)
                return String(data: data, encoding: .utf8)
            } catch {
                print("⚠️ Failed to export usage data: \(error)")
                return nil
            }
        }
    }

    /// Get a formatted report for display
    func getFormattedReport() -> String {
        let stats = getDailyStatistics()

        var report = """
        📊 API Usage Report (Last 24 Hours)
        ═══════════════════════════════════════

        Total Calls: \(stats.totalCalls)
        Successful: \(stats.successfulCalls) (\(Int(stats.successRate * 100))%)
        Failed: \(stats.failedCalls) (\(Int(stats.failureRate * 100))%)
        Avg Response Time: \(String(format: "%.2f", stats.averageResponseTime))s
        Total Tokens Used: \(stats.totalTokensUsed)

        Calls by Type:
        """

        for (type, count) in stats.callsByType.sorted(by: { $0.value > $1.value }) {
            report += "\n  • \(type.rawValue): \(count)"
        }

        let anomalies = checkForAnomalies()
        if !anomalies.isEmpty {
            report += "\n\n⚠️ Anomalies Detected: \(anomalies.count)"
            for anomaly in anomalies {
                report += "\n  • [\(anomaly.severity)/10] \(anomaly.description)"
            }
        }

        return report
    }
}

// MARK: - Usage Examples

/*

 USAGE:

 1. Track an API call automatically:
 ```swift
 let result = try await APIUsageMonitor.shared.track(.textGeneration) {
     await geminiService.generateContent(prompt: prompt)
 }
 ```

 2. Record a call manually:
 ```swift
 APIUsageMonitor.shared.recordCall(
     type: .imageAnalysis,
     success: true,
     responseTime: 2.5,
     tokensUsed: 150
 )
 ```

 3. Get usage statistics:
 ```swift
 let stats = APIUsageMonitor.shared.getDailyStatistics()
 print("Success rate: \(Int(stats.successRate * 100))%")
 print("Total tokens: \(stats.totalTokensUsed)")
 ```

 4. Check for anomalies:
 ```swift
 let anomalies = APIUsageMonitor.shared.checkForAnomalies()
 if !anomalies.isEmpty {
     print("⚠️ \(anomalies.count) anomalies detected")
 }
 ```

 5. Generate a report:
 ```swift
 let report = APIUsageMonitor.shared.getFormattedReport()
 print(report)
 ```

 6. Export data:
 ```swift
 if let json = APIUsageMonitor.shared.exportAsJSON() {
     // Save to file or send to analytics service
 }
 ```

 */
