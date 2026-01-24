//
//  DataExportService.swift
//  TinyTastesTracker
//
//  Service for exporting user data to JSON and CSV formats
//

import Foundation
import SwiftData

// MARK: - Export Metadata

struct DataExportMetadata: Codable {
    let appVersion: String
    let exportDate: Date
    let profileName: String
    let profileID: UUID
    let dataTypes: [String]
    
    init(profileName: String, profileID: UUID, dataTypes: [String]) {
        self.appVersion = "1.0"
        self.exportDate = Date()
        self.profileName = profileName
        self.profileID = profileID
        self.dataTypes = dataTypes
    }
}

// MARK: - Complete Data Export

struct CompleteDataExport: Codable {
    let metadata: DataExportMetadata
    let profile: UserProfile
    let mealLogs: [MealLog]
    let triedFoods: [TriedFoodLog]
    let recipes: [Recipe]
    let customFoods: [CustomFood]
    let nursingLogs: [NursingLog]
    let sleepLogs: [SleepLog]
    let diaperLogs: [DiaperLog]
    let bottleLogs: [BottleFeedLog]
    let growthMeasurements: [GrowthMeasurement]
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case noDataToExport
    case fileCreationFailed
    case encodingFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noDataToExport:
            return "No data available to export"
        case .fileCreationFailed:
            return "Failed to create export file"
        case .encodingFailed(let detail):
            return "Failed to encode data: \(detail)"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

// MARK: - Data Export Service

@MainActor
class DataExportService {
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case json = "Complete Backup (JSON)"
        case csvMeals = "Meal Logs (CSV)"
        case csvSleep = "Sleep Logs (CSV)"
        case csvGrowth = "Growth Data (CSV)"
        case csvNursing = "Nursing Logs (CSV)"
        case csvBottle = "Bottle Logs (CSV)"
        case photoTimeline = "Photo Timeline (PDF)"
        case photosZIP = "All Photos (ZIP)"
        
        var id: String { rawValue }
    }
    
    // MARK: - JSON Export
    
    /// Export all user data as a complete JSON file
    static func exportAllDataAsJSON(
        profile: UserProfile,
        mealLogs: [MealLog],
        triedFoods: [TriedFoodLog],
        recipes: [Recipe],
        customFoods: [CustomFood],
        nursingLogs: [NursingLog],
        sleepLogs: [SleepLog],
        diaperLogs: [DiaperLog],
        bottleLogs: [BottleFeedLog],
        growthMeasurements: [GrowthMeasurement]
    ) throws -> URL {
        
        let dataTypes = [
            "UserProfile",
            "MealLogs (\(mealLogs.count))",
            "TriedFoods (\(triedFoods.count))",
            "Recipes (\(recipes.count))",
            "CustomFoods (\(customFoods.count))",
            "NursingLogs (\(nursingLogs.count))",
            "SleepLogs (\(sleepLogs.count))",
            "DiaperLogs (\(diaperLogs.count))",
            "BottleLogs (\(bottleLogs.count))",
            "GrowthMeasurements (\(growthMeasurements.count))"
        ]
        
        let metadata = DataExportMetadata(
            profileName: profile.babyName,
            profileID: profile.id,
            dataTypes: dataTypes
        )
        
        let completeExport = CompleteDataExport(
            metadata: metadata,
            profile: profile,
            mealLogs: mealLogs,
            triedFoods: triedFoods,
            recipes: recipes,
            customFoods: customFoods,
            nursingLogs: nursingLogs,
            sleepLogs: sleepLogs,
            diaperLogs: diaperLogs,
            bottleLogs: bottleLogs,
            growthMeasurements: growthMeasurements
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(completeExport)
            return try saveToTemporaryFile(
                data: jsonData,
                filename: generateFilename(for: profile, extension: "json")
            )
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - CSV Export
    
    /// Export meal logs as CSV
    static func exportMealLogsAsCSV(logs: [MealLog], profileName: String) throws -> URL {
        guard !logs.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var csv = "Date,Time,Meal Type,Foods,Feeding Strategy,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for log in logs.sorted(by: { $0.timestamp > $1.timestamp }) {
            let date = dateFormatter.string(from: log.timestamp)
            let time = timeFormatter.string(from: log.timestamp)
            let mealType = log.mealType.rawValue
            let foods = log.foods.joined(separator: "; ")
            let strategy = log.feedingStrategy.rawValue
            let notes = log.notes.replacingOccurrences(of: ",", with: ";")
            
            csv += "\"\(date)\",\"\(time)\",\"\(mealType)\",\"\(foods)\",\"\(strategy)\",\"\(notes)\"\n"
        }
        
        guard let csvData = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed("Failed to encode CSV")
        }
        
        return try saveToTemporaryFile(
            data: csvData,
            filename: "\(profileName)_MealLogs_\(formattedDate()).csv"
        )
    }
    
    /// Export sleep logs as CSV
    static func exportSleepLogsAsCSV(logs: [SleepLog], profileName: String) throws -> URL {
        guard !logs.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var csv = "Date,Start Time,End Time,Duration (hours),Quality\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for log in logs.sorted(by: { $0.startTime > $1.startTime }) {
            let date = dateFormatter.string(from: log.startTime)
            let startTime = timeFormatter.string(from: log.startTime)
            let endTime = timeFormatter.string(from: log.endTime)
            let durationHours = String(format: "%.2f", log.duration / 3600)
            let quality = log.quality.rawValue
            
            csv += "\"\(date)\",\"\(startTime)\",\"\(endTime)\",\"\(durationHours)\",\"\(quality)\"\n"
        }
        
        guard let csvData = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed("Failed to encode CSV")
        }
        
        return try saveToTemporaryFile(
            data: csvData,
            filename: "\(profileName)_SleepLogs_\(formattedDate()).csv"
        )
    }
    
    /// Export growth measurements as CSV
    static func exportGrowthDataAsCSV(measurements: [GrowthMeasurement], profileName: String) throws -> URL {
        guard !measurements.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var csv = "Date,Weight (lbs),Height (inches),Head Circumference (inches),Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for measurement in measurements.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: measurement.date)
            let weight = measurement.weight.map { String(format: "%.2f", $0) } ?? ""
            let height = measurement.height.map { String(format: "%.2f", $0) } ?? ""
            let headCirc = measurement.headCircumference.map { String(format: "%.2f", $0) } ?? ""
            let notes = (measurement.notes ?? "").replacingOccurrences(of: ",", with: ";")
            
            csv += "\"\(date)\",\"\(weight)\",\"\(height)\",\"\(headCirc)\",\"\(notes)\"\n"
        }
        
        guard let csvData = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed("Failed to encode CSV")
        }
        
        return try saveToTemporaryFile(
            data: csvData,
            filename: "\(profileName)_GrowthData_\(formattedDate()).csv"
        )
    }
    
    /// Export nursing logs as CSV
    static func exportNursingLogsAsCSV(logs: [NursingLog], profileName: String) throws -> URL {
        guard !logs.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var csv = "Date,Time,Duration (minutes),Side\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for log in logs.sorted(by: { $0.timestamp > $1.timestamp }) {
            let date = dateFormatter.string(from: log.timestamp)
            let time = timeFormatter.string(from: log.timestamp)
            let durationMinutes = String(format: "%.1f", log.duration / 60)
            let side = log.side.rawValue
            
            csv += "\"\(date)\",\"\(time)\",\"\(durationMinutes)\",\"\(side)\"\n"
        }
        
        guard let csvData = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed("Failed to encode CSV")
        }
        
        return try saveToTemporaryFile(
            data: csvData,
            filename: "\(profileName)_NursingLogs_\(formattedDate()).csv"
        )
    }
    
    /// Export bottle feed logs as CSV
    static func exportBottleLogsAsCSV(logs: [BottleFeedLog], profileName: String) throws -> URL {
        guard !logs.isEmpty else {
            throw ExportError.noDataToExport
        }
        
        var csv = "Date,Time,Amount (oz),Feed Type,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for log in logs.sorted(by: { $0.timestamp > $1.timestamp }) {
            let date = dateFormatter.string(from: log.timestamp)
            let time = timeFormatter.string(from: log.timestamp)
            let amount = String(format: "%.1f", log.amount)
            let feedType = log.feedType.rawValue
            let notes = (log.notes ?? "").replacingOccurrences(of: ",", with: ";")
            
            csv += "\"\(date)\",\"\(time)\",\"\(amount)\",\"\(feedType)\",\"\(notes)\"\n"
        }
        
        guard let csvData = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed("Failed to encode CSV")
        }
        
        return try saveToTemporaryFile(
            data: csvData,
            filename: "\(profileName)_BottleLogs_\(formattedDate()).csv"
        )
    }
    
    // MARK: - Photo Export
    
    /// Export photos with timeline as PDF
    static func exportPhotosWithTimeline(
        logs: [TriedFoodLog],
        profileName: String,
        options: TimelineOptions = .default
    ) throws -> URL {
        return try PhotoTimelineExportService.shared.generateTimelinePDF(
            logs: logs,
            options: options,
            profileName: profileName
        )
    }
    
    /// Export all photos as ZIP archive
    static func exportPhotosAsZIP(
        logs: [TriedFoodLog],
        profileName: String
    ) throws -> URL {
        return try PhotoTimelineExportService.shared.exportPhotosAsZIP(
            logs: logs,
            profileName: profileName
        )
    }
    
    // MARK: - Helper Methods
    
    private static func saveToTemporaryFile(data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }
    
    private static func generateFilename(for profile: UserProfile, extension ext: String) -> String {
        let sanitizedName = profile.babyName.replacingOccurrences(of: " ", with: "_")
        return "\(sanitizedName)_TinyTastesBackup_\(formattedDate()).\(ext)"
    }
    
    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// Calculate total size of data to be exported
    static func estimateExportSize(
        mealLogs: [MealLog],
        triedFoods: [TriedFoodLog],
        recipes: [Recipe],
        customFoods: [CustomFood],
        nursingLogs: [NursingLog],
        sleepLogs: [SleepLog],
        diaperLogs: [DiaperLog],
        bottleLogs: [BottleFeedLog],
        growthMeasurements: [GrowthMeasurement]
    ) -> String {
        // Rough estimate: 1KB per meal log, 0.5KB per other logs
        let totalKB = mealLogs.count + 
                      (triedFoods.count / 2) +
                      (recipes.count * 2) +
                      customFoods.count +
                      (nursingLogs.count / 2) +
                      (sleepLogs.count / 2) +
                      (diaperLogs.count / 2) +
                      (bottleLogs.count / 2) +
                      (growthMeasurements.count / 2)
        
        if totalKB < 1024 {
            return "\(totalKB) KB"
        } else {
            let mb = Double(totalKB) / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
}
