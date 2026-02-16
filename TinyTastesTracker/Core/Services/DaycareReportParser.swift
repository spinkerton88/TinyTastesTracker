//
//  DaycareReportParser.swift
//  TinyTastesTracker
//
//  Service to parse daily reports (images or text) into structured logs
//

import Vision
import UIKit
import Foundation

// MARK: - Models

public enum SuggestedLogType: String, CaseIterable, Codable {
    case sleep = "sleep"
    case feed = "feed"     // Bottle, Nursing, or Solid
    case diaper = "diaper"
    case activity = "activity"
    case other = "other"
}

public struct SuggestedLog: Identifiable, Equatable {
    public let id = UUID()
    public let type: SuggestedLogType
    public let startTime: Date
    public let endTime: Date?
    public let quantity: String?
    public let details: String
    public var isConfirmed: Bool
    
    public let isWet: Bool?
    public let isDirty: Bool?
    
    // Duplicate detection
    public var isDuplicate: Bool
    public var duplicateReason: String?
    
    public init(
        type: SuggestedLogType,
        startTime: Date,
        endTime: Date? = nil,
        quantity: String? = nil,
        details: String,
        isConfirmed: Bool = true,
        isWet: Bool? = nil,
        isDirty: Bool? = nil,
        isDuplicate: Bool = false,
        duplicateReason: String? = nil
    ) {
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.quantity = quantity
        self.details = details
        self.isConfirmed = isConfirmed
        self.isWet = isWet
        self.isDirty = isDirty
        self.isDuplicate = isDuplicate
        self.duplicateReason = duplicateReason
    }
}

// Internal structure for AI JSON response
struct AIExtractedEvent: Codable {
    let type: String          // sleep, feed, diaper, etc.
    let startTime: String     // HH:mm
    let endTime: String?      // HH:mm
    let quantity: String?     // e.g. "5oz"
    let details: String       // description
    let isWet: Bool?
    let isDirty: Bool?
}

// MARK: - Parser Service

@MainActor
class DaycareReportParser {
    static let shared = DaycareReportParser()
    
    private init() {}
    
    /// Parse an image (e.g. photo of a paper report)
    func parseReportImage(_ image: UIImage, forDate date: Date = Date()) async throws -> [SuggestedLog] {
        let recognizedText = try await performOCR(on: image)
        
        guard !recognizedText.isEmpty else {
            throw AppError.unknown(NSError(domain: "DaycareParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "No text text detected in image"]))
        }
        
        return try await parseTextContent(recognizedText, forDate: date, context: "daycare report image")
    }
    
    /// Parse raw text content (e.g. from a file or pasted text)
    func parseReportFile(content: String, fileType: String, forDate date: Date = Date()) async throws -> [SuggestedLog] {
        return try await parseTextContent(content, forDate: date, context: "daycare report \(fileType)")
    }
    
    /// Check for duplicate logs in existing data
    func detectDuplicates(in suggestedLogs: [SuggestedLog], appState: AppState) -> [SuggestedLog] {
        var updatedLogs: [SuggestedLog] = []
        
        for log in suggestedLogs {
            var isDuplicate = false
            var duplicateReason: String? = nil
            
            // Define time tolerance based on log type
            let timeTolerance: TimeInterval
            switch log.type {
            case .sleep:
                timeTolerance = 30 * 60 // 30 minutes for sleep
            case .feed:
                timeTolerance = 5 * 60 // 5 minutes for feeds
            case .diaper:
                timeTolerance = 5 * 60 // 5 minutes for diapers
            case .activity, .other:
                timeTolerance = 10 * 60 // 10 minutes for activities
            }
            
            // Start/End Range
            let startRange = log.startTime.addingTimeInterval(-timeTolerance)
            let endRange = log.startTime.addingTimeInterval(timeTolerance)

            // Check for duplicates based on log type
            switch log.type {
            case .sleep:
                let overlaps = appState.sleepLogs.filter { sleepLog in
                    sleepLog.startTime >= startRange && sleepLog.startTime <= endRange
                }
                if !overlaps.isEmpty {
                    isDuplicate = true
                    duplicateReason = "Similar sleep log found within 30 minutes"
                }
                
            case .feed:
                // Check bottle feeds
                let bottleOverlaps = appState.bottleFeedLogs.filter { feedLog in
                    feedLog.timestamp >= startRange && feedLog.timestamp <= endRange
                }
                
                // Check nursing logs
                let nursingOverlaps = appState.nursingLogs.filter { feedLog in
                    feedLog.timestamp >= startRange && feedLog.timestamp <= endRange
                }
                
                if !bottleOverlaps.isEmpty {
                    isDuplicate = true
                    duplicateReason = "Similar bottle feed found within 5 minutes"
                } else if !nursingOverlaps.isEmpty {
                    isDuplicate = true
                    duplicateReason = "Similar nursing session found within 5 minutes"
                }
                
            case .diaper:
                let overlaps = appState.diaperLogs.filter { diaperLog in
                    diaperLog.timestamp >= startRange && diaperLog.timestamp <= endRange
                }
                if !overlaps.isEmpty {
                    isDuplicate = true
                    duplicateReason = "Similar diaper change found within 5 minutes"
                }
                
            case .activity, .other:
                // No duplicate detection for activities yet
                break
            }
            
            // Create updated log with duplicate info
            var updatedLog = log
            updatedLog.isDuplicate = isDuplicate
            updatedLog.duplicateReason = duplicateReason
            updatedLogs.append(updatedLog)
        }
        
        return updatedLogs
    }
    
    // MARK: - Private Helpers
    
    private func parseTextContent(_ text: String, forDate date: Date, context: String) async throws -> [SuggestedLog] {
        // AI Parsing Logic
        let prompt = """
        You are an AI assistant parsing a daycare daily report.
        Extract structured events from the following text derived from a \(context).
        
        CURRENT DATE: \(date.formatted(date: .numeric, time: .omitted))
        (Assume all times in the text refer to this date unless specified otherwise)
        
        TEXT TO PARSE:
        \(text)
        
        TASK:
        Return a JSON ARRAY of events.
        
        FORMAT GUIDELINES:
        - "type": 
            - "sleep" (naps)
            - "bottle" (formula/milk quantites)
            - "nursing" (breastfeeding, usually duration)
            - "solid" (food/meals)
            - "diaper"
            - "activity" (play/mood)
            - "other"
            - "feed" (generic)
        - "startTime": "HH:mm" (24-hour format). Best guess if implied.
        - "endTime": "HH:mm" (24-hour format) or null.
        - "quantity": String or null (e.g. "5 oz", "1 jar", "15 mins").
        - "details": Brief description (e.g. "Ate all chicken", "Fussy").
        - "isWet": true/false (for diapers ONLY, else null).
        - "isDirty": true/false (for diapers ONLY, else null).
        
        Return ONLY valid JSON:
        [
          {
            "type": "diaper",
            "startTime": "10:30",
            "endTime": null,
            "quantity": null,
            "details": "Mixed",
            "isWet": true,
            "isDirty": true
          }
        ]
        """
        
        let jsonString = try await GeminiService().generateText(prompt: prompt)
        return try extractAndMapEvents(from: jsonString, referenceDate: date)
    }
    
    private func extractAndMapEvents(from jsonString: String, referenceDate: Date) throws -> [SuggestedLog] {
        var cleanJSON = jsonString
        
        // Handle markdown code blocks
        if cleanJSON.contains("```json") {
            let components = cleanJSON.components(separatedBy: "```json")
            if components.count > 1 {
                cleanJSON = components[1].components(separatedBy: "```")[0]
            }
        } else if cleanJSON.contains("```") {
             let components = cleanJSON.components(separatedBy: "```")
             if components.count > 1 {
                 cleanJSON = components[1]
             }
        }
        
        cleanJSON = cleanJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanJSON.data(using: .utf8) else {
            throw AppError.invalidResponse
        }
        
        let extractedEvents = try JSONDecoder().decode([AIExtractedEvent].self, from: data)
        
        // Map to SuggestedLog
        return extractedEvents.compactMap { aiEvent in
            guard let type = SuggestedLogType(rawValue: aiEvent.type) ?? SuggestedLogType(rawValue: "other") else { return nil }
            guard let startDate = combineDateAndTime(date: referenceDate, timeString: aiEvent.startTime) else { return nil }
            
            var endDate: Date? = nil
            if let endStr = aiEvent.endTime {
                endDate = combineDateAndTime(date: referenceDate, timeString: endStr)
            }
            
            return SuggestedLog(
                type: type,
                startTime: startDate,
                endTime: endDate,
                quantity: aiEvent.quantity,
                details: aiEvent.details,
                isConfirmed: true,
                isWet: aiEvent.isWet,
                isDirty: aiEvent.isDirty
            )
        }
    }
    
    private func combineDateAndTime(date: Date, timeString: String) -> Date? {
        let calendar = Calendar.current
        let timeComponents = timeString.split(separator: ":").compactMap { Int($0) }
        
        guard timeComponents.count == 2 else { return nil }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = timeComponents[0]
        dateComponents.minute = timeComponents[1]
        
        return calendar.date(from: dateComponents)
    }
    
    private func performOCR(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw AppError.unknown(NSError(domain: "DaycareParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image format"]))
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Extract text with high confidence
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
