//
//  DataManagementView.swift
//  TinyTastesTracker
//
//  User interface for data export, import, and iCloud sync
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct DataManagementView: View {
    @Bindable var appState: AppState
    
    @State private var selectedFormat: DataExportService.ExportFormat = .json
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingImportPreview = false
    @State private var showingDeleteConfirmation = false
    @State private var exportURL: URL?
    @State private var importPreview: ImportPreview?
    @State private var importURL: URL?
    @State private var importStrategy: ImportStrategy = .merge
    @State private var alertMessage: String?
    @State private var showingAlert = false
    
    var body: some View {
        List {
            // MARK: - Export Section
            Section {
                Picker("Export Format", selection: $selectedFormat) {
                    ForEach(DataExportService.ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                
                Button(action: exportData) {
                    HStack {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting || appState.userProfile == nil)
                
                if let estimatedSize = calculateEstimatedSize() {
                    HStack {
                        Text("Estimated Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(estimatedSize)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            } header: {
                Label("Export Data", systemImage: "arrow.down.doc")
            } footer: {
                Text("Export your data to share with healthcare providers or backup to another device.")
                    .font(.caption)
            }
            
            // MARK: - Import Section
            Section {
                Button(action: { showingImportPicker = true }) {
                    HStack {
                        Label("Import from File", systemImage: "square.and.arrow.down")
                        Spacer()
                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isImporting)
                
                if importPreview != nil {
                    Picker("Import Strategy", selection: $importStrategy) {
                        Text("Merge with existing").tag(ImportStrategy.merge)
                        Text("Replace all data").tag(ImportStrategy.replace)
                    }
                    .pickerStyle(.segmented)
                }
            } header: {
                Label("Import Data", systemImage: "arrow.up.doc")
            } footer: {
                Text("Import data from a TinyTastes backup file. Choose 'Merge' to keep existing data or 'Replace' to start fresh.")
                    .font(.caption)
            }
            

            // MARK: - Storage Section
            Section {
                HStack {
                    Text("Total Items")
                    Spacer()
                    Text("\(totalItemCount)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Estimated Size")
                    Spacer()
                    Text(totalDataSize)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Storage", systemImage: "internaldrive")
            }
            
            // MARK: - Danger Zone
            Section {
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Delete All Data", systemImage: "trash")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("This will permanently delete tracked data for the current child profile. This action cannot be undone.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .sheet(isPresented: $showingImportPreview) {
            if let preview = importPreview, let url = importURL {
                ImportPreviewSheet(
                    preview: preview,
                    strategy: $importStrategy,
                    onConfirm: {
                        showingImportPreview = false
                        performImport(from: url)
                    },
                    onCancel: {
                        showingImportPreview = false
                        importPreview = nil
                        importURL = nil
                    }
                )
            }
        }
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: deleteAllData)
        } message: {
            Text("This will permanently delete all tracking data for \(appState.userProfile?.name ?? "your child"). This action cannot be undone.")
        }
        .alert("Data Management", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = alertMessage {
                Text(message)
            }
        }
    }
    
    // MARK: - Export Functions
    
    private func exportData() {
        guard let profile = appState.userProfile else { return }
        
        isExporting = true
        
        Task {
            do {
                let url: URL
                
                switch selectedFormat {
                case .json:
                    url = try await exportCompleteBackup(profile: profile)
                case .csvMeals:
                    url = try DataExportService.exportMealLogsAsCSV(
                        logs: appState.mealLogs,
                        profileName: profile.name
                    )
                case .csvSleep:
                    url = try DataExportService.exportSleepLogsAsCSV(
                        logs: appState.sleepLogs,
                        profileName: profile.name
                    )
                case .csvGrowth:
                    url = try DataExportService.exportGrowthDataAsCSV(
                        measurements: appState.growthMeasurements,
                        profileName: profile.name
                    )
                case .csvNursing:
                    url = try DataExportService.exportNursingLogsAsCSV(
                        logs: appState.nursingLogs,
                        profileName: profile.name
                    )
                case .csvBottle:
                    url = try DataExportService.exportBottleLogsAsCSV(
                        logs: appState.bottleLogs,
                        profileName: profile.name
                    )
                case .photoTimeline:
                    url = try DataExportService.exportPhotosWithTimeline(
                        logs: appState.foodLogs,
                        profileName: profile.name
                    )
                case .photosZIP:
                    url = try DataExportService.exportPhotosAsZIP(
                        logs: appState.foodLogs,
                        profileName: profile.name
                    )
                }
                
                exportURL = url
                showingExportSheet = true
                
            } catch {
                alertMessage = "Export failed: \(error.localizedDescription)"
                showingAlert = true
            }
            
            isExporting = false
        }
    }
    
    private func exportCompleteBackup(profile: ChildProfile) async throws -> URL {
        return try DataExportService.exportAllDataAsJSON(
            profile: profile,
            mealLogs: appState.mealLogs,
            triedFoods: appState.foodLogs,
            recipes: appState.recipes,
            customFoods: appState.customFoods,
            nursingLogs: appState.nursingLogs,
            sleepLogs: appState.sleepLogs,
            diaperLogs: appState.diaperLogs,
            bottleLogs: appState.bottleLogs,
            growthMeasurements: appState.growthMeasurements,
            pumpingLogs: appState.pumpingLogs,
            medicationLogs: appState.medicationLogs
        )
    }
    
    // MARK: - Import Functions
    
    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            isImporting = true
            importURL = url
            
            Task {
                do {
                    let preview = try await DataImportService.previewImport(from: url)
                    importPreview = preview
                    showingImportPreview = true
                } catch {
                    alertMessage = "Failed to read import file: \(error.localizedDescription)"
                    showingAlert = true
                }
                isImporting = false
            }
            
        case .failure(let error):
            alertMessage = "Import failed: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func performImport(from url: URL) {
        guard let ownerId = appState.currentOwnerId else {
            alertMessage = "You must be signed in to import data."
            showingAlert = true
            return
        }
        
        isImporting = true
        
        Task {
            do {
                let result = try await DataImportService.importFromJSON(
                    fileURL: url,
                    strategy: importStrategy,
                    ownerId: ownerId
                )
                
                if result.success {
                    alertMessage = result.summary
                    showingAlert = true
                } else {
                    alertMessage = "Import failed: \(result.errors.first?.localizedDescription ?? "Unknown error")"
                    showingAlert = true
                }
                
                importPreview = nil
                importURL = nil
                
            } catch {
                alertMessage = "Import failed: \(error.localizedDescription)"
                showingAlert = true
            }
            
            isImporting = false
        }
    }
    
    // MARK: - Delete Function
    
    private func deleteAllData() {
        guard appState.userProfile != nil else { return }
        
        Task {
            // Delete logs using managers
            // This is client-side iteration, might be slow for huge datasets but safe.
            
            // Toddler Data
            for log in appState.mealLogs {
                appState.toddlerManager.deleteMealLog(log)
            }
            for log in appState.foodLogs {
                appState.toddlerManager.deleteFoodLog(log)
            }
            
            // Newborn Data
            for log in appState.nursingLogs {
                appState.newbornManager.deleteNursingLog(log)
            }
            for log in appState.sleepLogs {
                appState.newbornManager.deleteSleepLog(log)
            }
            for log in appState.diaperLogs {
                appState.newbornManager.deleteDiaperLog(log)
            }
            for log in appState.bottleLogs {
                appState.newbornManager.deleteBottleFeedLog(log)
            }
            for log in appState.growthMeasurements {
                appState.newbornManager.deleteGrowthMeasurement(log)
            }
            for log in appState.pumpingLogs {
                appState.newbornManager.deletePumpingLog(log)
            }
            for log in appState.medicationLogs {
                appState.newbornManager.deleteMedicationLog(log)
            }
            
            // Wait a bit for propagation?
            // Deletions are async in managers (Task { ... }).
            
            alertMessage = "Deletion requests sent. Data will vanish shortly."
            showingAlert = true
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateEstimatedSize() -> String? {
        guard appState.userProfile != nil else { return nil }
        
        return DataExportService.estimateExportSize(
            mealLogs: appState.mealLogs,
            triedFoods: appState.foodLogs,
            recipes: appState.recipes,
            customFoods: appState.customFoods,
            nursingLogs: appState.nursingLogs,
            sleepLogs: appState.sleepLogs,
            diaperLogs: appState.diaperLogs,
            bottleLogs: appState.bottleLogs,
            growthMeasurements: appState.growthMeasurements
        )
    }
    
    private var totalItemCount: Int {
        appState.mealLogs.count +
        appState.foodLogs.count +
        appState.recipes.count +
        appState.customFoods.count +
        appState.nursingLogs.count +
        appState.sleepLogs.count +
        appState.diaperLogs.count +
        appState.bottleLogs.count +
        appState.growthMeasurements.count
    }
    
    private var totalDataSize: String {
        calculateEstimatedSize() ?? "0 KB"
    }
}

// MARK: - Import Preview Sheet

struct ImportPreviewSheet: View {
    let preview: ImportPreview
    @Binding var strategy: ImportStrategy
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section("Import Summary") {
                    HStack {
                        Text("Total Items")
                        Spacer()
                        Text("\(preview.totalItems)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Estimated Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(preview.estimatedSize)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Data Breakdown") {
                    if preview.mealLogCount > 0 {
                        LabeledContent("Meal Logs", value: "\(preview.mealLogCount)")
                    }
                    if preview.triedFoodCount > 0 {
                        LabeledContent("Tried Foods", value: "\(preview.triedFoodCount)")
                    }
                    if preview.recipeCount > 0 {
                        LabeledContent("Recipes", value: "\(preview.recipeCount)")
                    }
                    if preview.customFoodCount > 0 {
                        LabeledContent("Custom Foods", value: "\(preview.customFoodCount)")
                    }
                    if preview.nursingLogCount > 0 {
                        LabeledContent("Nursing Logs", value: "\(preview.nursingLogCount)")
                    }
                    if preview.sleepLogCount > 0 {
                        LabeledContent("Sleep Logs", value: "\(preview.sleepLogCount)")
                    }
                    if preview.diaperLogCount > 0 {
                        LabeledContent("Diaper Logs", value: "\(preview.diaperLogCount)")
                    }
                    if preview.bottleLogCount > 0 {
                        LabeledContent("Bottle Logs", value: "\(preview.bottleLogCount)")
                    }
                    if preview.growthMeasurementCount > 0 {
                        LabeledContent("Growth Measurements", value: "\(preview.growthMeasurementCount)")
                    }
                }
                
                Section {
                    Picker("Import Strategy", selection: $strategy) {
                        Text("Merge with existing").tag(ImportStrategy.merge)
                        Text("Replace all data").tag(ImportStrategy.replace)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    if strategy == .replace {
                        Text("⚠️ This will attempt to overwrite existing items if IDs match.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Items with matching IDs will be skipped or updated.")
                    }
                }
            }
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import", action: onConfirm)
                }
            }
        }
    }
}
