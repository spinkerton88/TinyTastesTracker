//
//  ReportImportView.swift
//  TinyTastesTracker
//
//  UI for scanning/uploading daycare reports and reviewing parsed events
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PendingReport: Identifiable, Codable {
    let id: UUID
    let dateCreated: Date
    let imageFilename: String
    
    var imageUrl: URL? {
        PendingReportManager.shared.documentsDirectory?.appendingPathComponent(imageFilename)
    }
}

struct ReportImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Config
    var themeColor: Color = .blue
    
    // State
    @State private var scannedImage: UIImage?
    @State private var parsedEvents: [SuggestedLog] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showScanner = false
    @State private var showFileImporter = false
    @State private var showConfirmation = false
    
    // Offline / Retry
    @State private var pendingReports: [PendingReport] = []
    @State private var failedImage: UIImage?
    
    // For Photo Picker
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            List {
                if parsedEvents.isEmpty {
                    if !pendingReports.isEmpty {
                        pendingReportsSection
                    }
                    uploadSection
                } else {
                    reviewSection
                }
            }
            .navigationTitle("Care Provider Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                if !parsedEvents.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        HStack(spacing: 16) {
                            Button {
                                confirmAllEvents()
                            } label: {
                                Label("Confirm All", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                            
                            Button {
                                rejectAllEvents()
                            } label: {
                                Label("Reject All", systemImage: "xmark.circle.fill")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save All") {
                            saveEvents()
                        }
                        .bold()
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScannerView(scannedImage: $scannedImage)
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.image, .pdf, .plainText, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        if url.pathExtension.lowercased() == "pdf" || ["png", "jpg", "jpeg", "heic"].contains(url.pathExtension.lowercased()) {
                            // If it's an image file, load and process as image
                            if let data = try? Data(contentsOf: url),
                               let image = UIImage(data: data) {
                                processImage(image)
                            }
                        } else {
                            // Otherwise process as file (CSV, TXT, etc.)
                            processFile(url: url)
                        }
                    }
                case .failure(let error):
                    errorMessage = "Failed to import file: \(error.localizedDescription)"
                }
            }
            .onChange(of: scannedImage) { _, newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    guard let item = newItem else { return }
                    
                    // Start processing immediately upon valid selection
                    await MainActor.run { isProcessing = true }
                    
                    do {
                        // Try loading as Data first
                        if let data = try await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                processImage(image)
                            }
                        } else {
                            // If Data loading fails, show error
                            await MainActor.run {
                                errorMessage = "Unable to load the selected image. Please try again or use a different photo."
                                isProcessing = false
                            }
                        }
                    } catch {
                        // Handle any errors during loading
                        await MainActor.run {
                            errorMessage = "Failed to load image: \(error.localizedDescription)"
                            isProcessing = false
                        }
                    }
                    
                    // Reset selection to ensure clean state for next time
                    await MainActor.run { selectedItem = nil }
                }
            }
            .overlay {
                if isProcessing {
                    LoadingView(message: "Analyzing Report...")
                }
            }
            .onAppear {
                refreshPendingReports()
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                if let image = failedImage {
                    Button("Save for Later") {
                        try? PendingReportManager.shared.savePendingReport(image: image)
                        refreshPendingReports()
                        errorMessage = nil
                        failedImage = nil
                    }
                }
                Button("OK") {
                    errorMessage = nil
                    failedImage = nil
                }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private var pendingReportsSection: some View {
        Section(header: Text("Pending Uploads")) {
            ForEach(pendingReports) { report in
                Button {
                    retryReport(report)
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.icloud.fill")
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading) {
                            Text("Unsent Report")
                                .font(.headline)
                            Text(report.dateCreated.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Retry")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    PendingReportManager.shared.deleteReport(pendingReports[index])
                }
                refreshPendingReports()
            }
        }
    }
    
    private var uploadSection: some View {
        Section {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(themeColor)
                    .padding()
                
                Text("Scan or Upload Report")
                    .font(.headline)
                
                Text("Take a photo of your daycare's daily sheet or upload a screenshot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    // Scan button (camera)
                    Button {
                        showScanner = true
                    } label: {
                        ImportOptionCard(icon: "camera.fill", label: "Scan", color: themeColor)
                    }

                    // Photo picker (photo - Photos app)
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ImportOptionCard(icon: "photo.fill", label: "Photo", color: themeColor)
                    }

                    // File picker button (folder - Files app)
                    Button {
                        showFileImporter = true
                    } label: {
                        ImportOptionCard(icon: "folder.fill", label: "File", color: themeColor)
                    }
                }
                .buttonStyle(.borderless)
                .padding(.top)
            }
            .padding()
        }
    }
    
    private var reviewSection: some View {
        Section(header: Text("Review Detected Events")) {
            ForEach($parsedEvents) { $event in
                EditableEventRow(event: $event)
            }
            .onDelete { indexSet in
                parsedEvents.remove(atOffsets: indexSet)
            }
        }
    }
    
    // MARK: - Logic
    
    private func refreshPendingReports() {
        pendingReports = PendingReportManager.shared.getPendingReports()
    }
    
    private func retryReport(_ report: PendingReport) {
        guard let url = report.imageUrl,
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            // If image is missing, just delete the report
            PendingReportManager.shared.deleteReport(report)
            refreshPendingReports()
            return
        }
        
        processImage(image, fromReport: report)
    }
    
    private func processImage(_ image: UIImage, fromReport: PendingReport? = nil) {
        isProcessing = true
        
        Task {
            do {
                let events = try await DaycareReportParser.shared.parseReportImage(image)
                await MainActor.run {
                    // Run duplicate detection
                    self.parsedEvents = DaycareReportParser.shared.detectDuplicates(in: events, modelContext: modelContext)
                    self.isProcessing = false
                    
                    // If successful and was from a pending report, delete it
                    if let report = fromReport {
                        PendingReportManager.shared.deleteReport(report)
                        self.refreshPendingReports()
                    }
                    
                    // Clear failed image state on success
                    self.failedImage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isProcessing = false
                    
                    // Store image so user can save it
                    self.failedImage = image
                }
            }
        }
    }
    
    private func confirmAllEvents() {
        for index in parsedEvents.indices {
            parsedEvents[index] = SuggestedLog(
                type: parsedEvents[index].type,
                startTime: parsedEvents[index].startTime,
                endTime: parsedEvents[index].endTime,
                quantity: parsedEvents[index].quantity,
                details: parsedEvents[index].details,
                isConfirmed: true,
                isWet: parsedEvents[index].isWet,
                isDirty: parsedEvents[index].isDirty,
                isDuplicate: parsedEvents[index].isDuplicate,
                duplicateReason: parsedEvents[index].duplicateReason
            )
        }
    }
    
    private func rejectAllEvents() {
        for index in parsedEvents.indices {
            parsedEvents[index] = SuggestedLog(
                type: parsedEvents[index].type,
                startTime: parsedEvents[index].startTime,
                endTime: parsedEvents[index].endTime,
                quantity: parsedEvents[index].quantity,
                details: parsedEvents[index].details,
                isConfirmed: false,
                isWet: parsedEvents[index].isWet,
                isDirty: parsedEvents[index].isDirty,
                isDuplicate: parsedEvents[index].isDuplicate,
                duplicateReason: parsedEvents[index].duplicateReason
            )
        }
    }
    
    private func processFile(url: URL) {
        isProcessing = true
        Task {
            do {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                if let content = String(data: data, encoding: .utf8) {
                    let events = try await DaycareReportParser.shared.parseReportFile(content: content, fileType: url.pathExtension)
                     await MainActor.run {
                        // Run duplicate detection
                        self.parsedEvents = DaycareReportParser.shared.detectDuplicates(in: events, modelContext: modelContext)
                        self.isProcessing = false
                    }
                } else {
                    throw URLError(.cannotDecodeContentData)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func saveEvents() {
        for event in parsedEvents where event.isConfirmed {
            switch event.type {
            case .sleep:
                saveSleepLog(event)
            case .feed:
                // Determine if it's bottle or nursing based on quantity
                if let quantity = event.quantity, quantity.lowercased().contains("oz") || quantity.lowercased().contains("ml") {
                    saveBottleLog(event)
                } else {
                    saveNursingLog(event)
                }
            case .diaper:
                saveDiaperLog(event)
            case .activity, .other:
                saveActivityLog(event)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    // MARK: - Saving Helpers
    
    private func saveSleepLog(_ event: SuggestedLog) {
        // Default to 1 hour if end time missing, or skip? 
        // Better: require end time for sleep logs in UI? 
        // For now, use 1 hour default if null
        let endTime = event.endTime ?? event.startTime.addingTimeInterval(3600)
        
        let log = SleepLog(
            startTime: event.startTime,
            endTime: endTime,
            quality: .fair // Default
        )
        modelContext.insert(log)
    }
    
    private func saveBottleLog(_ event: SuggestedLog) {
        // Parse quantity "5 oz" -> 5.0
        let amount = parseAmount(event.quantity)
        
        let log = BottleFeedLog(
            timestamp: event.startTime,
            amount: amount,
            feedType: .formula, // Default, user can edit later
            notes: event.details
        )
        modelContext.insert(log)
    }
    
    private func saveNursingLog(_ event: SuggestedLog) {
        // Parse duration "15 mins" -> seconds
        let duration = parseDuration(event.quantity)
        
        let log = NursingLog(
            timestamp: event.startTime,
            duration: duration,
            side: .left // Default, unknown
        )
        modelContext.insert(log)
    }
    
    private func saveDiaperLog(_ event: SuggestedLog) {
        let type: DiaperType
        if event.isWet == true && event.isDirty == true {
            type = .both
        } else if event.isDirty == true {
            type = .dirty
        } else {
            type = .wet
        }
        
        let log = DiaperLog(
            timestamp: event.startTime,
            type: type
        )
        modelContext.insert(log)
    }
    
    private func saveActivityLog(_ event: SuggestedLog) {
        let log = ActivityLog(
            timestamp: event.startTime,
            activityType: event.type.rawValue,
            description: event.details,
            notes: event.quantity // Use quantity field for additional notes if present
        )
        modelContext.insert(log)
    }
    
    private func parseAmount(_ string: String?) -> Double {
        guard let string = string else { return 0 }
        // Extract number from string like "5 oz" or "5.5oz"
        let digits = string.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        return Double(digits) ?? 0
    }
    
    private func parseDuration(_ string: String?) -> TimeInterval {
        guard let string = string else { return 0 }
        // Extract number
        let digits = string.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        let value = Double(digits) ?? 0
        
        // Simple heuristic: if string contains "h" or "hour", treat as hours, else minutes
        if string.lowercased().contains("h") {
            return value * 3600
        } else {
            return value * 60
        }
    }
}

// MARK: - Subviews

struct ParsedEventRow: View {
    @Binding var event: SuggestedLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Type Icon
                Image(systemName: iconForType(event.type))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(colorForType(event.type))
                    .clipShape(Circle())
                
                Text(event.type.rawValue.capitalized)
                    .font(.headline)
                
                Spacer()
                
                // Duplicate warning badge
                if event.isDuplicate {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
                
                Text(event.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Duplicate warning message
            if event.isDuplicate, let reason = event.duplicateReason {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(reason)
                        .font(.caption)
                }
                .foregroundStyle(.yellow)
                .padding(6)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(6)
            }
            
            if !event.details.isEmpty {
                Text(event.details)
                    .font(.body)
            }
            
            if let quantity = event.quantity {
                Text("Amt: \(quantity)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: SuggestedLogType) -> String {
        switch type {
        case .sleep: return "bed.double.fill"
        case .feed: return "fork.knife"
        case .diaper: return "toilet.fill" // Or appropriate icon
        case .activity: return "figure.play"
        case .other: return "doc.text"
        }
    }
    
    private func colorForType(_ type: SuggestedLogType) -> Color {
        switch type {
        case .sleep: return .indigo
        case .feed: return .orange
        case .diaper: return .blue
        case .activity: return .green
        case .other: return .gray
        }
    }
}

// Simple Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text(message)
                    .foregroundStyle(.white)
                    .bold()
            }
            .padding(40)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

// Reusable Import Option Card
struct ImportOptionCard: View {
    let icon: String
    let label: String
    var color: Color = .blue
    var isProminent: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(isProminent ? .white : color)
                .frame(width: 80, height: 80)
                .background(isProminent ? color : Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(label)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - PendingReportManager (Moved here due to file visibility issues)
class PendingReportManager {
    static let shared = PendingReportManager()
    
    private let persistenceKey = "PendingReportManager.reports"
    var documentsDirectory: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private init() {}
    
    // MARK: - Public API
    
    func savePendingReport(image: UIImage) throws {
        let id = UUID()
        let filename = "pending_report_\(id.uuidString).jpg"
        
        // 1. Save Image to Disk
        guard let data = image.jpegData(compressionQuality: 0.8),
              let url = documentsDirectory?.appendingPathComponent(filename) else {
            throw AppError.unknown(NSError(domain: "PendingReportManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create file path"]))
        }
        
        try data.write(to: url)
        
        // 2. Save Metadata
        let report = PendingReport(id: id, dateCreated: Date(), imageFilename: filename)
        var reports = getPendingReports()
        reports.append(report)
        saveReportsMetadata(reports)
    }
    
    func getPendingReports() -> [PendingReport] {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return [] }
        do {
            let reports = try JSONDecoder().decode([PendingReport].self, from: data)
            return reports.sorted(by: { $0.dateCreated > $1.dateCreated })
        } catch {
            print("Failed to decode pending reports: \(error)")
            return []
        }
    }
    
    func deleteReport(_ report: PendingReport) {
        // 1. Remove from Metadata
        var reports = getPendingReports()
        reports.removeAll { $0.id == report.id }
        saveReportsMetadata(reports)
        
        // 2. Delete Image File
        if let url = report.imageUrl {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveReportsMetadata(_ reports: [PendingReport]) {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }
}
