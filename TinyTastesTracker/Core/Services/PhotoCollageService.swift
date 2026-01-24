//
//  PhotoCollageService.swift
//  TinyTastesTracker
//
//  Service for creating photo collages and memories from messy face photos
//

import UIKit
import SwiftUI

// MARK: - Collage Templates

enum CollageTemplate: String, CaseIterable, Identifiable {
    case grid2x2 = "2×2 Grid"
    case grid3x3 = "3×3 Grid"
    case timeline = "Timeline"
    case scrapbook = "Scrapbook"
    case mosaic = "Mosaic"
    case milestone = "Milestone"
    
    var id: String { rawValue }
    
    var minPhotos: Int {
        switch self {
        case .grid2x2: return 4
        case .grid3x3: return 9
        case .timeline: return 3
        case .scrapbook: return 2
        case .mosaic: return 4
        case .milestone: return 5
        }
    }
    
    var maxPhotos: Int {
        switch self {
        case .grid2x2: return 4
        case .grid3x3: return 9
        case .timeline: return 12
        case .scrapbook: return 6
        case .mosaic: return 9
        case .milestone: return 10
        }
    }
}

// MARK: - Memory Types

enum MemoryType: String, CaseIterable, Identifiable {
    case firstFoods = "First Foods"
    case rainbowComplete = "Rainbow Complete"
    case monthly = "Monthly Summary"
    case weekly = "Weekly Summary"
    case themed = "Themed Collection"
    case milestone = "Milestone"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .firstFoods:
            return "Celebrate your baby's first food adventures"
        case .rainbowComplete:
            return "All the colors of the rainbow!"
        case .monthly:
            return "A month of delicious discoveries"
        case .weekly:
            return "This week's tasty journey"
        case .themed:
            return "Fruits, veggies, or proteins"
        case .milestone:
            return "50 foods, 100 foods, and beyond!"
        }
    }
}

// MARK: - Collage Options

struct CollageOptions {
    var backgroundColor: UIColor
    var showFoodNames: Bool
    var showDates: Bool
    var showReactions: Bool
    var borderWidth: CGFloat
    var spacing: CGFloat
    var fontName: String
    var fontSize: CGFloat
    var textColor: UIColor
    
    static var `default`: CollageOptions {
        CollageOptions(
            backgroundColor: .systemBackground,
            showFoodNames: true,
            showDates: true,
            showReactions: false,
            borderWidth: 2.0,
            spacing: 8.0,
            fontName: "Avenir-Heavy",
            fontSize: 16.0,
            textColor: .label
        )
    }
}

/// Sendable DTO for photo assets to ensure thread safety
struct PhotoAssetData: Sendable, Identifiable {
    let id: String // Food name
    let date: Date
    let imageData: Data
}

// MARK: - Collage Memory

struct CollageMemory {
    let title: String
    let subtitle: String?
    let photos: [PhotoAssetData]
    let template: CollageTemplate
    let generatedDate: Date
}

// MARK: - Photo Collage Service

class PhotoCollageService {
    static let shared = PhotoCollageService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Create a collage from selected photos
    func createCollage(
        from assets: [PhotoAssetData],
        template: CollageTemplate,
        options: CollageOptions = .default
    ) -> UIImage? {
        guard assets.count >= template.minPhotos else { return nil }
        
        let photosToUse = Array(assets.prefix(template.maxPhotos))
        let images = photosToUse.compactMap { asset -> UIImage? in
            return UIImage(data: asset.imageData)
        }
        
        guard images.count == photosToUse.count else { return nil }
        
        switch template {
        case .grid2x2:
            return createGridCollage(images: images, assets: photosToUse, columns: 2, options: options)
        case .grid3x3:
            return createGridCollage(images: images, assets: photosToUse, columns: 3, options: options)
        case .timeline:
            return createTimelineCollage(images: images, assets: photosToUse, options: options)
        case .scrapbook:
            return createScrapbookCollage(images: images, assets: photosToUse, options: options)
        case .mosaic:
            return createMosaicCollage(images: images, assets: photosToUse, options: options)
        case .milestone:
            return createMilestoneCollage(images: images, assets: photosToUse, options: options)
        }
    }
    
    /// Generate a memory automatically based on type
    func generateMemory(
        type: MemoryType,
        from allAssets: [PhotoAssetData],
        dateRange: DateInterval? = nil
    ) -> CollageMemory? {
        var filteredAssets = allAssets // All inputs should already be valid photos
        
        // Apply date range filter if provided
        if let range = dateRange {
            filteredAssets = filteredAssets.filter { range.contains($0.date) }
        }
        
        switch type {
        case .firstFoods:
            return generateFirstFoodsMemory(from: filteredAssets)
        case .rainbowComplete:
            return generateRainbowMemory(from: filteredAssets)
        case .monthly:
            return generateMonthlyMemory(from: filteredAssets)
        case .weekly:
            return generateWeeklyMemory(from: filteredAssets)
        case .themed:
            return generateThemedMemory(from: filteredAssets)
        case .milestone:
            return generateMilestoneMemory(from: filteredAssets)
        }
    }
    
    // MARK: - Grid Collage
    
    private func createGridCollage(
        images: [UIImage],
        assets: [PhotoAssetData],
        columns: Int,
        options: CollageOptions
    ) -> UIImage? {
        let rows = Int(ceil(Double(images.count) / Double(columns)))
        let cellSize: CGFloat = 400
        let totalWidth = CGFloat(columns) * cellSize + CGFloat(columns + 1) * options.spacing
        let totalHeight = CGFloat(rows) * cellSize + CGFloat(rows + 1) * options.spacing
        
        let size = CGSize(width: totalWidth, height: totalHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            options.backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw images in grid
            for (index, image) in images.enumerated() {
                let row = index / columns
                let col = index % columns
                
                let x = options.spacing + CGFloat(col) * (cellSize + options.spacing)
                let y = options.spacing + CGFloat(row) * (cellSize + options.spacing)
                
                let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                
                // Draw image
                drawImage(image, in: rect, with: options)
                
                // Draw text overlay if enabled
                if options.showFoodNames || options.showDates {
                    drawTextOverlay(for: assets[index], in: rect, with: options)
                }
            }
        }
    }
    
    // MARK: - Timeline Collage
    
    private func createTimelineCollage(
        images: [UIImage],
        assets: [PhotoAssetData],
        options: CollageOptions
    ) -> UIImage? {
        let imageWidth: CGFloat = 300
        let imageHeight: CGFloat = 300
        let spacing = options.spacing
        let padding: CGFloat = 40
        
        let totalWidth: CGFloat = 1200
        let itemsPerRow = 3
        let rows = Int(ceil(Double(images.count) / Double(itemsPerRow)))
        let totalHeight = padding * 2 + CGFloat(rows) * (imageHeight + spacing + 60) + 100
        
        let size = CGSize(width: totalWidth, height: totalHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            options.backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Title
            let titleFont = UIFont(name: options.fontName, size: 48) ?? UIFont.boldSystemFont(ofSize: 48)
            let title = "Food Journey Timeline"
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: options.textColor
            ]
            let titleSize = title.size(withAttributes: titleAttrs)
            title.draw(at: CGPoint(x: (totalWidth - titleSize.width) / 2, y: padding), withAttributes: titleAttrs)
            
            // Draw timeline items
            var currentY = padding + 100
            
            for (index, image) in images.enumerated() {
                let row = index / itemsPerRow
                let col = index % itemsPerRow
                
                if col == 0 && index > 0 {
                    currentY += imageHeight + spacing + 60
                }
                
                let x = padding + CGFloat(col) * (imageWidth + spacing)
                let y = currentY
                
                let imageRect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)
                
                // Draw image with border
                drawImage(image, in: imageRect, with: options)
                
                // Draw food name and date below
                let asset = assets[index]
                let textY = y + imageHeight + 10
                
                let font = UIFont(name: options.fontName, size: options.fontSize) ?? UIFont.systemFont(ofSize: options.fontSize)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: options.textColor
                ]
                
                asset.id.draw(at: CGPoint(x: x, y: textY), withAttributes: attrs)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                let dateStr = dateFormatter.string(from: asset.date)
                let smallFont = UIFont(name: options.fontName, size: options.fontSize - 4) ?? UIFont.systemFont(ofSize: options.fontSize - 4)
                let dateAttrs: [NSAttributedString.Key: Any] = [
                    .font: smallFont,
                    .foregroundColor: options.textColor.withAlphaComponent(0.7)
                ]
                dateStr.draw(at: CGPoint(x: x, y: textY + 25), withAttributes: dateAttrs)
            }
        }
    }
    
    // MARK: - Scrapbook Collage
    
    private func createScrapbookCollage(
        images: [UIImage],
        assets: [PhotoAssetData],
        options: CollageOptions
    ) -> UIImage? {
        let canvasSize = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { context in
            // Background with texture
            options.backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            
            // Randomly place photos at slight angles for scrapbook effect
            let photoSize: CGFloat = 350
            let positions: [(CGPoint, CGFloat)] = [
                (CGPoint(x: 100, y: 150), -5),
                (CGPoint(x: 650, y: 100), 3),
                (CGPoint(x: 100, y: 700), 4),
                (CGPoint(x: 650, y: 650), -3),
                (CGPoint(x: 350, y: 1100), 2),
                (CGPoint(x: 100, y: 1200), -4)
            ]
            
            for (index, image) in images.enumerated() {
                guard index < positions.count else { break }
                
                let (position, angle) = positions[index]
                let rect = CGRect(x: position.x, y: position.y, width: photoSize, height: photoSize)
                
                context.cgContext.saveGState()
                
                // Rotate
                let centerX = rect.midX
                let centerY = rect.midY
                context.cgContext.translateBy(x: centerX, y: centerY)
                context.cgContext.rotate(by: angle * .pi / 180)
                context.cgContext.translateBy(x: -centerX, y: -centerY)
                
                // White border (polaroid effect)
                let borderRect = rect.insetBy(dx: -15, dy: -15)
                UIColor.white.setFill()
                context.fill(borderRect)
                
                // Draw image
                drawImage(image, in: rect, with: options)
                
                // Draw caption below (polaroid style)
                if options.showFoodNames {
                    let captionY = rect.maxY + 5
                    let font = UIFont(name: "Bradley Hand", size: 18) ?? UIFont.systemFont(ofSize: 18)
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: UIColor.darkGray
                    ]
                    let caption = assets[index].id
                    let captionSize = caption.size(withAttributes: attrs)
                    caption.draw(at: CGPoint(x: rect.midX - captionSize.width / 2, y: captionY), withAttributes: attrs)
                }
                
                context.cgContext.restoreGState()
            }
        }
    }
    
    // MARK: - Mosaic Collage
    
    private func createMosaicCollage(
        images: [UIImage],
        assets: [PhotoAssetData],
        options: CollageOptions
    ) -> UIImage? {
        // Mosaic with varying sizes
        let canvasSize = CGSize(width: 1200, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { context in
            options.backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            
            // Define mosaic layout (varying sizes)
            let layouts: [CGRect] = [
                CGRect(x: 0, y: 0, width: 600, height: 600),           // Large top-left
                CGRect(x: 600, y: 0, width: 600, height: 400),         // Medium top-right
                CGRect(x: 600, y: 400, width: 300, height: 400),       // Small middle-right
                CGRect(x: 900, y: 400, width: 300, height: 400),       // Small middle-right
                CGRect(x: 0, y: 600, width: 400, height: 600),         // Medium bottom-left
                CGRect(x: 400, y: 600, width: 400, height: 300),       // Small bottom-middle
                CGRect(x: 400, y: 900, width: 400, height: 300),       // Small bottom-middle
                CGRect(x: 800, y: 800, width: 400, height: 400),       // Medium bottom-right
                CGRect(x: 600, y: 800, width: 200, height: 200)        // Tiny
            ]
            
            for (index, image) in images.enumerated() {
                guard index < layouts.count else { break }
                
                let rect = layouts[index].insetBy(dx: options.spacing / 2, dy: options.spacing / 2)
                drawImage(image, in: rect, with: options)
                
                if options.showFoodNames {
                    drawTextOverlay(for: assets[index], in: rect, with: options)
                }
            }
        }
    }
    
    // MARK: - Milestone Collage
    
    private func createMilestoneCollage(
        images: [UIImage],
        assets: [PhotoAssetData],
        options: CollageOptions
    ) -> UIImage? {
        let canvasSize = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { context in
            // Gradient background
            let colors = [options.backgroundColor, options.backgroundColor.withAlphaComponent(0.7)]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors.map { $0.cgColor } as CFArray, locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: canvasSize.height), options: [])
            
            // Title
            let titleFont = UIFont(name: options.fontName, size: 60) ?? UIFont.boldSystemFont(ofSize: 60)
            let title = "🎉 Milestone Achieved! 🎉"
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: options.textColor
            ]
            let titleSize = title.size(withAttributes: titleAttrs)
            title.draw(at: CGPoint(x: (canvasSize.width - titleSize.width) / 2, y: 50), withAttributes: titleAttrs)
            
            // Subtitle
            let subtitleFont = UIFont(name: options.fontName, size: 30) ?? UIFont.systemFont(ofSize: 30)
            let subtitle = "\(assets.count) Foods Tried!"
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: options.textColor.withAlphaComponent(0.8)
            ]
            let subtitleSize = subtitle.size(withAttributes: subtitleAttrs)
            subtitle.draw(at: CGPoint(x: (canvasSize.width - subtitleSize.width) / 2, y: 130), withAttributes: subtitleAttrs)
            
            // Photos in circular arrangement
            let photoSize: CGFloat = 200
            let centerX = canvasSize.width / 2
            let centerY: CGFloat = 600
            let radius: CGFloat = 350
            
            for (index, image) in images.enumerated() {
                let angle = (2 * .pi / CGFloat(images.count)) * CGFloat(index) - .pi / 2
                let x = centerX + radius * cos(angle) - photoSize / 2
                let y = centerY + radius * sin(angle) - photoSize / 2
                
                let rect = CGRect(x: x, y: y, width: photoSize, height: photoSize)
                
                // Draw circular mask
                context.cgContext.saveGState()
                let path = UIBezierPath(ovalIn: rect)
                path.addClip()
                drawImage(image, in: rect, with: options)
                context.cgContext.restoreGState()
                
                // Border
                UIColor.white.setStroke()
                let borderPath = UIBezierPath(ovalIn: rect)
                borderPath.lineWidth = options.borderWidth * 2
                borderPath.stroke()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func drawImage(_ image: UIImage, in rect: CGRect, with options: CollageOptions) {
        // Draw border
        if options.borderWidth > 0 {
            options.textColor.setStroke()
            let borderPath = UIBezierPath(rect: rect)
            borderPath.lineWidth = options.borderWidth
            borderPath.stroke()
        }
        
        // Draw image (aspect fill)
        let imageRect = rect.insetBy(dx: options.borderWidth, dy: options.borderWidth)
        image.draw(in: imageRect)
    }
    
    private func drawTextOverlay(for asset: PhotoAssetData, in rect: CGRect, with options: CollageOptions) {
        let overlayHeight: CGFloat = 60
        let overlayRect = CGRect(x: rect.minX, y: rect.maxY - overlayHeight, width: rect.width, height: overlayHeight)
        
        // Semi-transparent background
        UIColor.black.withAlphaComponent(0.6).setFill()
        UIBezierPath(rect: overlayRect).fill()
        
        // Text
        let font = UIFont(name: options.fontName, size: options.fontSize) ?? UIFont.boldSystemFont(ofSize: options.fontSize)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        var text = ""
        if options.showFoodNames {
            text = asset.id
        }
        if options.showDates {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let dateStr = dateFormatter.string(from: asset.date)
            text += text.isEmpty ? dateStr : " • \(dateStr)"
        }
        
        let textSize = text.size(withAttributes: attrs)
        let textPoint = CGPoint(
            x: overlayRect.midX - textSize.width / 2,
            y: overlayRect.midY - textSize.height / 2
        )
        text.draw(at: textPoint, withAttributes: attrs)
    }
    
    // MARK: - Memory Generation
    
    private func generateFirstFoodsMemory(from assets: [PhotoAssetData]) -> CollageMemory? {
        let sortedAssets = assets.sorted { $0.date < $1.date }
        let firstTen = Array(sortedAssets.prefix(10))
        
        guard firstTen.count >= 5 else { return nil }
        
        return CollageMemory(
            title: "First Foods Journey",
            subtitle: "The beginning of a delicious adventure!",
            photos: firstTen,
            template: .milestone,
            generatedDate: Date()
        )
    }
    
    private func generateRainbowMemory(from assets: [PhotoAssetData]) -> CollageMemory? {
        // This would need food color data
        // For now, return a simple memory
        guard assets.count >= 7 else { return nil }
        
        return CollageMemory(
            title: "Rainbow Complete! 🌈",
            subtitle: "All the colors of nutrition",
            photos: Array(assets.prefix(9)),
            template: .grid3x3,
            generatedDate: Date()
        )
    }
    
    private func generateMonthlyMemory(from assets: [PhotoAssetData]) -> CollageMemory? {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        
        let monthAssets = assets.filter { asset in
            calendar.isDate(asset.date, equalTo: lastMonth, toGranularity: .month)
        }
        
        guard monthAssets.count >= 4 else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let monthName = dateFormatter.string(from: lastMonth)
        
        return CollageMemory(
            title: "This Month in Food",
            subtitle: monthName,
            photos: Array(monthAssets.prefix(9)),
            template: .grid3x3,
            generatedDate: Date()
        )
    }
    
    private func generateWeeklyMemory(from assets: [PhotoAssetData]) -> CollageMemory? {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let weekAssets = assets.filter { $0.date >= weekAgo }
        
        guard weekAssets.count >= 3 else { return nil }
        
        return CollageMemory(
            title: "This Week's Adventures",
            subtitle: "7 days of tasty discoveries",
            photos: Array(weekAssets.prefix(6)),
            template: .scrapbook,
            generatedDate: Date()
        )
    }
    
    private func generateThemedMemory(from assets: [PhotoAssetData]) -> CollageMemory? {
        // Would need food category data
        guard assets.count >= 4 else { return nil }
        
        return CollageMemory(
            title: "Themed Collection",
            subtitle: "Similar foods, different reactions",
            photos: Array(assets.prefix(6)),
            template: .mosaic,
            generatedDate: Date()
        )
    }
    
    private func generateMilestoneMemory(from assets: [PhotoAssetData]) -> CollageMemory? {
        let count = assets.count
        let milestone = (count / 10) * 10
        
        guard milestone >= 10 else { return nil }
        
        return CollageMemory(
            title: "\(milestone) Foods Milestone! 🎉",
            subtitle: "What an amazing journey!",
            photos: Array(assets.prefix(10)),
            template: .milestone,
            generatedDate: Date()
        )
    }
}
