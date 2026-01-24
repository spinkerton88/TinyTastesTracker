//
//  PhotoTimelineExportService.swift
//  TinyTastesTracker
//
//  Service for exporting photos with timeline as PDF or ZIP
//

import UIKit
import PDFKit
import UniformTypeIdentifiers

// MARK: - Export Formats

enum TimelineExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF Document"
    case zip = "ZIP Archive"
    case both = "PDF + ZIP"
    
    var id: String { rawValue }
}

// MARK: - Timeline Options

struct TimelineOptions {
    var dateRange: DateInterval?
    var includePhotos: Bool
    var includeReactions: Bool
    var includeNotes: Bool
    var includeStatistics: Bool
    var filterMealType: MealType?
    var filterMinReaction: Int?
    var title: String
    var subtitle: String?
    
    static var `default`: TimelineOptions {
        TimelineOptions(
            dateRange: nil,
            includePhotos: true,
            includeReactions: true,
            includeNotes: false,
            includeStatistics: true,
            filterMealType: nil,
            filterMinReaction: nil,
            title: "Food Journey Timeline",
            subtitle: nil
        )
    }
}

// MARK: - Export Errors

enum TimelineExportError: LocalizedError {
    case noPhotos
    case pdfGenerationFailed
    case zipCreationFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noPhotos:
            return "No photos available to export"
        case .pdfGenerationFailed:
            return "Failed to generate PDF"
        case .zipCreationFailed:
            return "Failed to create ZIP archive"
        case .invalidData:
            return "Invalid photo data"
        }
    }
}

// MARK: - Photo Timeline Export Service

@MainActor
class PhotoTimelineExportService {
    static let shared = PhotoTimelineExportService()
    
    private init() {}
    
    // MARK: - Public Export Methods
    
    /// Export timeline in specified format
    func exportTimeline(
        logs: [TriedFoodLog],
        format: TimelineExportFormat,
        options: TimelineOptions = .default,
        profileName: String
    ) throws -> URL {
        let filteredLogs = filterLogs(logs, with: options)
        
        guard !filteredLogs.isEmpty else {
            throw TimelineExportError.noPhotos
        }
        
        switch format {
        case .pdf:
            return try generateTimelinePDF(logs: filteredLogs, options: options, profileName: profileName)
        case .zip:
            return try exportPhotosAsZIP(logs: filteredLogs, profileName: profileName)
        case .both:
            let pdfURL = try generateTimelinePDF(logs: filteredLogs, options: options, profileName: profileName)
            let zipURL = try exportPhotosAsZIP(logs: filteredLogs, profileName: profileName)
            return try combinePDFAndZIP(pdfURL: pdfURL, zipURL: zipURL, profileName: profileName)
        }
    }
    
    // MARK: - PDF Generation
    
    func generateTimelinePDF(
        logs: [TriedFoodLog],
        options: TimelineOptions,
        profileName: String
    ) throws -> URL {
        let sortedLogs = logs.sorted { $0.date < $1.date }
        
        // Create PDF document
        let pdfMetadata = [
            kCGPDFContextCreator: "Tiny Tastes Tracker",
            kCGPDFContextAuthor: profileName,
            kCGPDFContextTitle: options.title
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            // Cover page
            context.beginPage()
            drawCoverPage(in: pageRect, options: options, totalPhotos: sortedLogs.count)
            
            // Statistics page (if enabled)
            if options.includeStatistics {
                context.beginPage()
                drawStatisticsPage(in: pageRect, logs: sortedLogs, options: options)
            }
            
            // Timeline pages
            let photosPerPage = 6
            let pageCount = Int(ceil(Double(sortedLogs.count) / Double(photosPerPage)))
            
            for pageIndex in 0..<pageCount {
                context.beginPage()
                
                let startIndex = pageIndex * photosPerPage
                let endIndex = min(startIndex + photosPerPage, sortedLogs.count)
                let pageLogs = Array(sortedLogs[startIndex..<endIndex])
                
                drawTimelinePage(
                    in: pageRect,
                    logs: pageLogs,
                    pageNumber: pageIndex + (options.includeStatistics ? 3 : 2),
                    totalPages: pageCount + (options.includeStatistics ? 2 : 1),
                    options: options
                )
            }
        }
        
        // Save to temporary file
        let filename = "\(profileName)_PhotoTimeline_\(formattedDate()).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            throw TimelineExportError.pdfGenerationFailed
        }
    }
    
    // MARK: - ZIP Export
    
    func exportPhotosAsZIP(
        logs: [TriedFoodLog],
        profileName: String
    ) throws -> URL {
        let sortedLogs = logs.sorted { $0.date < $1.date }
        
        // Create temporary directory for photos
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Export each photo
        var metadata: [[String: Any]] = []
        
        for (index, log) in sortedLogs.enumerated() {
            guard let imageData = log.messyFaceImage,
                  let image = UIImage(data: imageData),
                  let jpegData = image.jpegData(compressionQuality: 0.9) else {
                continue
            }
            
            let filename = String(format: "%03d_%@_%@.jpg",
                                index + 1,
                                log.id.replacingOccurrences(of: " ", with: "_"),
                                formattedDate(log.date))
            let fileURL = tempDir.appendingPathComponent(filename)
            try jpegData.write(to: fileURL)
            
            // Add metadata
            metadata.append([
                "filename": filename,
                "foodName": log.id,
                "date": ISO8601DateFormatter().string(from: log.date),
                "mealType": log.meal.rawValue,
                "reaction": log.reaction,
                "allergyReaction": log.allergyReaction.rawValue
            ])
        }
        
        // Write metadata JSON
        let metadataJSON = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        let metadataURL = tempDir.appendingPathComponent("metadata.json")
        try metadataJSON.write(to: metadataURL)
        
        // Note: iOS doesn't have native ZIP creation in Foundation
        // Return the directory URL - the share sheet will handle archiving
        // Alternatively, we could use a third-party library like ZIPFoundation
        
        // For now, return the temp directory
        // The system share sheet will automatically zip folders when sharing
        return tempDir
    }
    
    // MARK: - PDF Drawing Methods
    
    private func drawCoverPage(in rect: CGRect, options: TimelineOptions, totalPhotos: Int) {
        let margin: CGFloat = 50
        
        // Background gradient
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: rect.height), options: [])
        
        // Title
        let titleFont = UIFont.boldSystemFont(ofSize: 48)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleSize = options.title.size(withAttributes: titleAttrs)
        options.title.draw(at: CGPoint(x: (rect.width - titleSize.width) / 2, y: 200), withAttributes: titleAttrs)
        
        // Subtitle
        if let subtitle = options.subtitle {
            let subtitleFont = UIFont.systemFont(ofSize: 24)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let subtitleSize = subtitle.size(withAttributes: subtitleAttrs)
            subtitle.draw(at: CGPoint(x: (rect.width - subtitleSize.width) / 2, y: 270), withAttributes: subtitleAttrs)
        }
        
        // Photo count
        let countText = "\(totalPhotos) Photos"
        let countFont = UIFont.systemFont(ofSize: 36, weight: .medium)
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: countFont,
            .foregroundColor: UIColor.white
        ]
        let countSize = countText.size(withAttributes: countAttrs)
        countText.draw(at: CGPoint(x: (rect.width - countSize.width) / 2, y: 400), withAttributes: countAttrs)
        
        // Date range
        if let dateRange = options.dateRange {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let rangeText = "\(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))"
            let rangeFont = UIFont.systemFont(ofSize: 18)
            let rangeAttrs: [NSAttributedString.Key: Any] = [
                .font: rangeFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let rangeSize = rangeText.size(withAttributes: rangeAttrs)
            rangeText.draw(at: CGPoint(x: (rect.width - rangeSize.width) / 2, y: 460), withAttributes: rangeAttrs)
        }
        
        // Footer
        let footerText = "Generated by Tiny Tastes Tracker"
        let footerFont = UIFont.systemFont(ofSize: 14)
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        let footerSize = footerText.size(withAttributes: footerAttrs)
        footerText.draw(at: CGPoint(x: (rect.width - footerSize.width) / 2, y: rect.height - 100), withAttributes: footerAttrs)
    }
    
    private func drawStatisticsPage(in rect: CGRect, logs: [TriedFoodLog], options: TimelineOptions) {
        let margin: CGFloat = 50
        var yPosition: CGFloat = margin
        
        // Title
        let titleFont = UIFont.boldSystemFont(ofSize: 36)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        "Statistics Summary".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 60
        
        // Calculate statistics
        let totalFoods = logs.count
        let avgReaction = logs.map { $0.reaction }.reduce(0, +) / max(logs.count, 1)
        let mealBreakdown = Dictionary(grouping: logs, by: { $0.meal })
        let allergyCount = logs.filter { $0.allergyReaction != .none }.count
        
        // Draw stats
        let statFont = UIFont.systemFont(ofSize: 18)
        let statAttrs: [NSAttributedString.Key: Any] = [
            .font: statFont,
            .foregroundColor: UIColor.label
        ]
        
        let stats = [
            "Total Foods Tried: \(totalFoods)",
            "Average Reaction: \(avgReaction)/7",
            "Breakfast: \(mealBreakdown[.breakfast]?.count ?? 0)",
            "Lunch: \(mealBreakdown[.lunch]?.count ?? 0)",
            "Dinner: \(mealBreakdown[.dinner]?.count ?? 0)",
            "Snacks: \(mealBreakdown[.snack]?.count ?? 0)",
            "Allergy Reactions: \(allergyCount)"
        ]
        
        for stat in stats {
            stat.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: statAttrs)
            yPosition += 35
        }
        
        // Reaction distribution chart (simple bar chart)
        yPosition += 40
        "Reaction Distribution".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 50
        
        let reactionCounts = Dictionary(grouping: logs, by: { $0.reaction }).mapValues { $0.count }
        let maxCount = reactionCounts.values.max() ?? 1
        let barWidth: CGFloat = 60
        let barSpacing: CGFloat = 20
        
        for reaction in 1...7 {
            let count = reactionCounts[reaction] ?? 0
            let barHeight = CGFloat(count) / CGFloat(maxCount) * 150
            let x = margin + CGFloat(reaction - 1) * (barWidth + barSpacing)
            let y = yPosition + 150 - barHeight
            
            // Draw bar
            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            UIColor.systemBlue.setFill()
            UIBezierPath(rect: barRect).fill()
            
            // Draw count
            let countText = "\(count)"
            let countSize = countText.size(withAttributes: statAttrs)
            countText.draw(at: CGPoint(x: x + (barWidth - countSize.width) / 2, y: y - 25), withAttributes: statAttrs)
            
            // Draw label
            let labelText = "\(reaction)"
            let labelSize = labelText.size(withAttributes: statAttrs)
            labelText.draw(at: CGPoint(x: x + (barWidth - labelSize.width) / 2, y: yPosition + 160), withAttributes: statAttrs)
        }
    }
    
    private func drawTimelinePage(
        in rect: CGRect,
        logs: [TriedFoodLog],
        pageNumber: Int,
        totalPages: Int,
        options: TimelineOptions
    ) {
        let margin: CGFloat = 40
        let photoSize: CGFloat = 150
        let columns = 2
        let spacing: CGFloat = 20
        
        var yPosition: CGFloat = margin
        
        // Page header
        let headerFont = UIFont.systemFont(ofSize: 12)
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        "Page \(pageNumber) of \(totalPages)".draw(at: CGPoint(x: rect.width - 100, y: margin), withAttributes: headerAttrs)
        
        yPosition += 40
        
        // Draw photos in grid
        for (index, log) in logs.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let x = margin + CGFloat(col) * (photoSize + spacing + 200)
            let y = yPosition + CGFloat(row) * (photoSize + spacing + 40)
            
            // Draw photo
            if options.includePhotos, let imageData = log.messyFaceImage, let image = UIImage(data: imageData) {
                let photoRect = CGRect(x: x, y: y, width: photoSize, height: photoSize)
                image.draw(in: photoRect)
                
                // Border
                UIColor.systemGray4.setStroke()
                let borderPath = UIBezierPath(rect: photoRect)
                borderPath.lineWidth = 1
                borderPath.stroke()
            }
            
            // Draw info
            let infoX = x + photoSize + 15
            var infoY = y
            
            let foodFont = UIFont.boldSystemFont(ofSize: 14)
            let foodAttrs: [NSAttributedString.Key: Any] = [
                .font: foodFont,
                .foregroundColor: UIColor.label
            ]
            log.id.draw(at: CGPoint(x: infoX, y: infoY), withAttributes: foodAttrs)
            infoY += 20
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateText = dateFormatter.string(from: log.date)
            
            let detailFont = UIFont.systemFont(ofSize: 11)
            let detailAttrs: [NSAttributedString.Key: Any] = [
                .font: detailFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            dateText.draw(at: CGPoint(x: infoX, y: infoY), withAttributes: detailAttrs)
            infoY += 18
            
            log.meal.rawValue.capitalized.draw(at: CGPoint(x: infoX, y: infoY), withAttributes: detailAttrs)
            infoY += 18
            
            if options.includeReactions {
                let reactionText = "Reaction: \(log.reaction)/7"
                reactionText.draw(at: CGPoint(x: infoX, y: infoY), withAttributes: detailAttrs)
                infoY += 18
            }
            
            if log.allergyReaction != .none {
                let allergyText = "⚠️ \(log.allergyReaction.rawValue.capitalized)"
                let allergyAttrs: [NSAttributedString.Key: Any] = [
                    .font: detailFont,
                    .foregroundColor: UIColor.systemRed
                ]
                allergyText.draw(at: CGPoint(x: infoX, y: infoY), withAttributes: allergyAttrs)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func filterLogs(_ logs: [TriedFoodLog], with options: TimelineOptions) -> [TriedFoodLog] {
        var filtered = logs.filter { $0.messyFaceImage != nil && $0.isMarkedAsTried }
        
        if let dateRange = options.dateRange {
            filtered = filtered.filter { dateRange.contains($0.date) }
        }
        
        if let mealType = options.filterMealType {
            filtered = filtered.filter { $0.meal == mealType }
        }
        
        if let minReaction = options.filterMinReaction {
            filtered = filtered.filter { $0.reaction >= minReaction }
        }
        
        return filtered
    }
    
    private func combinePDFAndZIP(pdfURL: URL, zipURL: URL, profileName: String) throws -> URL {
        // Create a new directory containing both files
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let pdfDest = tempDir.appendingPathComponent(pdfURL.lastPathComponent)
        let zipDest = tempDir.appendingPathComponent("photos")
        
        try FileManager.default.copyItem(at: pdfURL, to: pdfDest)
        try FileManager.default.copyItem(at: zipURL, to: zipDest)
        
        // Return the directory - iOS share sheet will handle archiving
        return tempDir
    }
    
    private func formattedDate(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
