//
//  DataImportService.swift
//  TinyTastesTracker
//
//  Service for importing user data from JSON and CSV formats
//

import Foundation
import SwiftData

// MARK: - Import Result

struct ImportResult {
    let success: Bool
    let itemsImported: Int
    let itemsSkipped: Int
    let errors: [ImportError]
    
    var summary: String {
        if success {
            return "Successfully imported \(itemsImported) items" + 
                   (itemsSkipped > 0 ? " (\(itemsSkipped) skipped)" : "")
        } else {
            return "Import failed: \(errors.first?.localizedDescription ?? "Unknown error")"
        }
    }
}

struct ImportPreview {
    let profileCount: Int
    let mealLogCount: Int
    let triedFoodCount: Int
    let recipeCount: Int
    let customFoodCount: Int
    let nursingLogCount: Int
    let sleepLogCount: Int
    let diaperLogCount: Int
    let bottleLogCount: Int
    let growthMeasurementCount: Int
    
    var totalItems: Int {
        profileCount + mealLogCount + triedFoodCount + recipeCount + customFoodCount +
        nursingLogCount + sleepLogCount + diaperLogCount + bottleLogCount + growthMeasurementCount
    }
    
    var estimatedSize: String {
        let kb = totalItems / 2
        if kb < 1024 {
            return "\(kb) KB"
        } else {
            return String(format: "%.2f MB", Double(kb) / 1024.0)
        }
    }
}

// MARK: - Import Errors

enum ImportError: LocalizedError {
    case invalidFileFormat
    case decodingFailed(String)
    case unsupportedVersion
    case missingRequiredData
    case duplicateData
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "Invalid file format. Please select a valid TinyTastes backup file."
        case .decodingFailed(let detail):
            return "Failed to read file: \(detail)"
        case .unsupportedVersion:
            return "This backup file was created with an incompatible version of TinyTastes."
        case .missingRequiredData:
            return "The backup file is missing required data."
        case .duplicateData:
            return "This data has already been imported."
        case .validationFailed(let detail):
            return "Data validation failed: \(detail)"
        }
    }
}

// MARK: - Import Strategy

enum ImportStrategy {
    case merge      // Keep existing data, add new items
    case replace    // Delete existing data, import all
}

// MARK: - Data Import Service

@MainActor
class DataImportService {
    
    // MARK: - JSON Import
    
    /// Preview import from JSON file
    static func previewImport(from fileURL: URL) async throws -> ImportPreview {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ImportError.invalidFileFormat
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let data = try Data(contentsOf: fileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let export = try decoder.decode(CompleteDataExport.self, from: data)
            
            return ImportPreview(
                profileCount: 1,
                mealLogCount: export.mealLogs.count,
                triedFoodCount: export.triedFoods.count,
                recipeCount: export.recipes.count,
                customFoodCount: export.customFoods.count,
                nursingLogCount: export.nursingLogs.count,
                sleepLogCount: export.sleepLogs.count,
                diaperLogCount: export.diaperLogs.count,
                bottleLogCount: export.bottleLogs.count,
                growthMeasurementCount: export.growthMeasurements.count
            )
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
    }
    
    /// Import data from JSON file
    static func importFromJSON(
        fileURL: URL,
        strategy: ImportStrategy,
        modelContext: ModelContext
    ) async throws -> ImportResult {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ImportError.invalidFileFormat
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let data = try Data(contentsOf: fileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var itemsImported = 0
        var itemsSkipped = 0
        let errors: [ImportError] = []
        
        do {
            let export = try decoder.decode(CompleteDataExport.self, from: data)
            
            // Validate metadata
            guard export.metadata.appVersion == "1.0" else {
                throw ImportError.unsupportedVersion
            }
            
            // Handle replace strategy
            if strategy == .replace {
                try clearExistingData(modelContext: modelContext)
            }
            
            // Import profile (always replace if exists)
            let existingProfiles = try modelContext.fetch(FetchDescriptor<UserProfile>())
            if let existing = existingProfiles.first(where: { $0.id == export.profile.id }) {
                // Update existing profile
                existing.babyName = export.profile.babyName
                existing.birthDate = export.profile.birthDate
                existing.gender = export.profile.gender
                existing.knownAllergies = export.profile.knownAllergies
                existing.preferredMode = export.profile.preferredMode
                existing.substitutedFoods = export.profile.substitutedFoods
                itemsImported += 1
            } else {
                modelContext.insert(export.profile)
                itemsImported += 1
            }
            
            // Import meal logs
            let (mealImported, mealSkipped) = try importItems(
                export.mealLogs,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += mealImported
            itemsSkipped += mealSkipped
            
            // Import tried foods
            let (foodImported, foodSkipped) = try importItems(
                export.triedFoods,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += foodImported
            itemsSkipped += foodSkipped
            
            // Import recipes
            let (recipeImported, recipeSkipped) = try importItems(
                export.recipes,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += recipeImported
            itemsSkipped += recipeSkipped
            
            // Import custom foods
            let (customImported, customSkipped) = try importItems(
                export.customFoods,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += customImported
            itemsSkipped += customSkipped
            
            // Import nursing logs
            let (nursingImported, nursingSkipped) = try importItems(
                export.nursingLogs,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += nursingImported
            itemsSkipped += nursingSkipped
            
            // Import sleep logs
            let (sleepImported, sleepSkipped) = try importItems(
                export.sleepLogs,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += sleepImported
            itemsSkipped += sleepSkipped
            
            // Import diaper logs
            let (diaperImported, diaperSkipped) = try importItems(
                export.diaperLogs,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += diaperImported
            itemsSkipped += diaperSkipped
            
            // Import bottle logs
            let (bottleImported, bottleSkipped) = try importItems(
                export.bottleLogs,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += bottleImported
            itemsSkipped += bottleSkipped
            
            // Import growth measurements
            let (growthImported, growthSkipped) = try importItems(
                export.growthMeasurements,
                strategy: strategy,
                modelContext: modelContext
            )
            itemsImported += growthImported
            itemsSkipped += growthSkipped
            
            // Save all changes
            try modelContext.save()
            
            return ImportResult(
                success: true,
                itemsImported: itemsImported,
                itemsSkipped: itemsSkipped,
                errors: errors
            )
            
        } catch let error as ImportError {
            return ImportResult(
                success: false,
                itemsImported: itemsImported,
                itemsSkipped: itemsSkipped,
                errors: [error]
            )
        } catch {
            return ImportResult(
                success: false,
                itemsImported: itemsImported,
                itemsSkipped: itemsSkipped,
                errors: [.decodingFailed(error.localizedDescription)]
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private static func importItems<T: PersistentModel & Identifiable>(
        _ items: [T],
        strategy: ImportStrategy,
        modelContext: ModelContext
    ) throws -> (imported: Int, skipped: Int) where T.ID == UUID {
        var imported = 0
        var skipped = 0
        
        for item in items {
            if strategy == .merge {
                // Check if item already exists
                let targetID = item.id
                let descriptor = FetchDescriptor<T>(
                    predicate: #Predicate<T> { $0.id == targetID }
                )
                let existing = try modelContext.fetch(descriptor)
                
                if existing.isEmpty {
                    modelContext.insert(item)
                    imported += 1
                } else {
                    skipped += 1
                }
            } else {
                // Replace strategy - insert all
                modelContext.insert(item)
                imported += 1
            }
        }
        
        return (imported, skipped)
    }
    
    private static func importItems<T: PersistentModel & Identifiable>(
        _ items: [T],
        strategy: ImportStrategy,
        modelContext: ModelContext
    ) throws -> (imported: Int, skipped: Int) where T.ID == String {
        var imported = 0
        var skipped = 0
        
        for item in items {
            if strategy == .merge {
                // Check if item already exists
                let targetID = item.id
                let descriptor = FetchDescriptor<T>(
                    predicate: #Predicate<T> { $0.id == targetID }
                )
                let existing = try modelContext.fetch(descriptor)
                
                if existing.isEmpty {
                    modelContext.insert(item)
                    imported += 1
                } else {
                    skipped += 1
                }
            } else {
                // Replace strategy - insert all
                modelContext.insert(item)
                imported += 1
            }
        }
        
        return (imported, skipped)
    }
    
    private static func clearExistingData(modelContext: ModelContext) throws {
        // Delete all existing data
        try modelContext.delete(model: MealLog.self)
        try modelContext.delete(model: TriedFoodLog.self)
        try modelContext.delete(model: Recipe.self)
        try modelContext.delete(model: CustomFood.self)
        try modelContext.delete(model: NursingLog.self)
        try modelContext.delete(model: SleepLog.self)
        try modelContext.delete(model: DiaperLog.self)
        try modelContext.delete(model: BottleFeedLog.self)
        try modelContext.delete(model: GrowthMeasurement.self)
    }
    
    // MARK: - Validation
    
    static func validateImportFile(at fileURL: URL) async throws -> Bool {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ImportError.invalidFileFormat
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let data = try Data(contentsOf: fileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let export = try decoder.decode(CompleteDataExport.self, from: data)
            
            // Validate metadata exists
            guard !export.metadata.profileName.isEmpty else {
                throw ImportError.missingRequiredData
            }
            
            // Validate version compatibility
            guard export.metadata.appVersion == "1.0" else {
                throw ImportError.unsupportedVersion
            }
            
            return true
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
    }
}
