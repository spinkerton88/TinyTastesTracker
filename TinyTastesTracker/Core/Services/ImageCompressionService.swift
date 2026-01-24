//
//  ImageCompressionService.swift
//  TinyTastesTracker
//
//  Performance optimization: Compress and resize images before storage
//

import UIKit
import SwiftUI

/// Compression quality levels for images
enum CompressionQuality {
    case high       // 0.9 quality, 1024x1024 max
    case balanced   // 0.7 quality, 1024x1024 max (default)
    case aggressive // 0.5 quality, 800x800 max
    
    var jpegQuality: CGFloat {
        switch self {
        case .high: return 0.9
        case .balanced: return 0.7
        case .aggressive: return 0.5
        }
    }
    
    var maxDimension: CGFloat {
        switch self {
        case .high, .balanced: return 1024
        case .aggressive: return 800
        }
    }
}

/// Service for compressing and resizing images to optimize storage
class ImageCompressionService {
    
    // MARK: - Constants
    
    static let thumbnailSize: CGFloat = 200
    static let defaultQuality: CompressionQuality = .balanced
    
    // MARK: - Public Methods
    
    /// Compress an image to the specified quality level
    /// - Parameters:
    ///   - image: The original UIImage to compress
    ///   - quality: Compression quality level (default: .balanced)
    /// - Returns: Compressed image data, or nil if compression fails
    static func compressImage(_ image: UIImage, quality: CompressionQuality = .balanced) -> Data? {
        // Resize to max dimensions first
        guard let resizedImage = resizeImage(image, maxDimension: quality.maxDimension) else {
            return nil
        }
        
        // Convert to JPEG with specified quality
        return resizedImage.jpegData(compressionQuality: quality.jpegQuality)
    }
    
    /// Generate a thumbnail from an image
    /// - Parameters:
    ///   - image: The original UIImage
    ///   - maxSize: Maximum dimension for the thumbnail (default: 200)
    /// - Returns: Thumbnail image data, or nil if generation fails
    static func generateThumbnail(_ image: UIImage, maxSize: CGFloat = thumbnailSize) -> Data? {
        guard let resizedImage = resizeImage(image, maxDimension: maxSize) else {
            return nil
        }
        
        // Use higher quality for thumbnails to maintain clarity at small size
        return resizedImage.jpegData(compressionQuality: 0.8)
    }
    
    /// Process a recipe image: generate both full-size and thumbnail versions
    /// - Parameters:
    ///   - image: The original UIImage
    ///   - quality: Compression quality for full-size image (default: .balanced)
    /// - Returns: Tuple containing full-size and thumbnail data
    static func processRecipeImage(_ image: UIImage, quality: CompressionQuality = .balanced) -> (full: Data?, thumbnail: Data?) {
        let fullData = compressImage(image, quality: quality)
        let thumbnailData = generateThumbnail(image)
        
        return (fullData, thumbnailData)
    }
    
    /// Estimate storage savings from compression
    /// - Parameters:
    ///   - originalData: Original image data
    ///   - compressedData: Compressed image data
    /// - Returns: Tuple containing original size, compressed size, and percentage saved
    static func estimateSavings(originalData: Data, compressedData: Data) -> (originalMB: Double, compressedMB: Double, percentSaved: Double) {
        let originalMB = Double(originalData.count) / 1_048_576 // Convert bytes to MB
        let compressedMB = Double(compressedData.count) / 1_048_576
        let percentSaved = ((originalMB - compressedMB) / originalMB) * 100
        
        return (originalMB, compressedMB, percentSaved)
    }
    
    // MARK: - Private Helpers
    
    /// Resize an image to fit within max dimensions while maintaining aspect ratio
    /// - Parameters:
    ///   - image: The original UIImage
    ///   - maxDimension: Maximum width or height
    /// - Returns: Resized UIImage, or nil if resize fails
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        
        // If image is already smaller than max, return original
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            // Landscape or square
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // Portrait
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Perform the resize
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    /// Convert image data to UIImage
    /// - Parameter data: Image data
    /// - Returns: UIImage, or nil if conversion fails
    static func dataToImage(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    /// Get formatted file size string
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string (e.g., "2.5 MB")
    static func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - SwiftUI Extensions

extension Image {
    /// Create an Image from compressed data
    /// - Parameter data: Compressed image data
    /// - Returns: SwiftUI Image, or nil if data is invalid
    static func fromCompressedData(_ data: Data?) -> Image? {
        guard let data = data,
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}
