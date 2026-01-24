//
//  TimelineExportView.swift
//  TinyTastesTracker
//
//  Timeline export configuration and preview UI
//

import SwiftUI
import SwiftData

struct TimelineExportView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // Available photos
    let availablePhotos: [TriedFoodLog]
    let profileName: String
    
    // Configuration state
    @State private var selectedFormat: TimelineExportFormat = .pdf
    @State private var timelineOptions = TimelineOptions.default
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var useDateRange = false
    
    // Export state
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: Error?
    
    var filteredPhotosCount: Int {
        let logs = useDateRange ? availablePhotos.filter { $0.date >= startDate && $0.date <= endDate } : availablePhotos
        return logs.filter { $0.messyFaceImage != nil && $0.isMarkedAsTried }.count
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Format selection
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(TimelineExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(formatDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Date range
                Section("Date Range") {
                    Toggle("Use Date Range", isOn: $useDateRange)
                    
                    if useDateRange {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                    
                    HStack {
                        Text("Photos to export:")
                        Spacer()
                        Text("\(filteredPhotosCount)")
                            .foregroundStyle(filteredPhotosCount > 0 ? appState.themeColor : .red)
                            .fontWeight(.semibold)
                    }
                }
                
                // Content options
                Section("Include in Export") {
                    Toggle("Photos", isOn: $timelineOptions.includePhotos)
                    Toggle("Reactions", isOn: $timelineOptions.includeReactions)
                    Toggle("Notes", isOn: $timelineOptions.includeNotes)
                    Toggle("Statistics Summary", isOn: $timelineOptions.includeStatistics)
                }
                
                // Filters
                Section("Filters") {
                    Picker("Meal Type", selection: Binding(
                        get: { timelineOptions.filterMealType ?? .breakfast },
                        set: { timelineOptions.filterMealType = $0 }
                    )) {
                        Text("All Meals").tag(nil as MealType?)
                        ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { meal in
                            Text(meal.rawValue.capitalized).tag(meal as MealType?)
                        }
                    }
                    
                    Stepper("Min Reaction: \(timelineOptions.filterMinReaction ?? 1)", value: Binding(
                        get: { timelineOptions.filterMinReaction ?? 1 },
                        set: { timelineOptions.filterMinReaction = $0 }
                    ), in: 1...7)
                }
                
                // Customization
                Section("Customization") {
                    TextField("Title", text: $timelineOptions.title)
                    TextField("Subtitle (optional)", text: Binding(
                        get: { timelineOptions.subtitle ?? "" },
                        set: { timelineOptions.subtitle = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                // Export button
                Section {
                    Button {
                        exportTimeline()
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text("Export Timeline")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(filteredPhotosCount > 0 ? appState.themeColor : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(filteredPhotosCount == 0 || isExporting)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Export Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ActivityShareSheet(items: [url])
                }
            }
            .alert("Export Failed", isPresented: .constant(exportError != nil)) {
                Button("OK", role: .cancel) {
                    exportError = nil
                }
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private var formatDescription: String {
        switch selectedFormat {
        case .pdf:
            return "Multi-page PDF document with photos and timeline"
        case .zip:
            return "ZIP archive with all photos and metadata JSON"
        case .both:
            return "Combined ZIP containing both PDF and photo archive"
        }
    }
    
    // MARK: - Export Action
    
    private func exportTimeline() {
        isExporting = true
        
        // Update date range if enabled
        if useDateRange {
            timelineOptions.dateRange = DateInterval(start: startDate, end: endDate)
        } else {
            timelineOptions.dateRange = nil
        }
        
        Task {
            do {
                let url = try await Task.detached {
                    try PhotoTimelineExportService.shared.exportTimeline(
                        logs: availablePhotos,
                        format: selectedFormat,
                        options: timelineOptions,
                        profileName: profileName
                    )
                }.value
                
                await MainActor.run {
                    exportedURL = url
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Activity Share Sheet (UIKit wrapper)

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
