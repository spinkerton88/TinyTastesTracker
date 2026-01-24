//
//  ImageCompression.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import UIKit
import SwiftUI

struct ImageCompression {
    /// Compresses and resizes a UIImage to stay within storage limits
    /// - Parameters:
    ///   - image: The original UIImage to compress
    ///   - maxWidth: Maximum width in pixels (default 300px)
    ///   - quality: JPEG compression quality 0.0-1.0 (default 0.7)
    /// - Returns: Compressed image data, or nil if compression fails
    static func compressImage(_ image: UIImage, maxWidth: CGFloat = 300, quality: CGFloat = 0.7) -> Data? {
        let size = image.size
        
        // Calculate new size maintaining aspect ratio
        var newSize: CGSize
        if size.width > maxWidth {
            let aspectRatio = size.height / size.width
            newSize = CGSize(width: maxWidth, height: maxWidth * aspectRatio)
        } else {
            newSize = size
        }
        
        // Resize image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // Convert to JPEG with specified quality
        return resizedImage.jpegData(compressionQuality: quality)
    }
    
    /// Converts compressed Data back to UIImage for display
    /// - Parameter data: Compressed image data
    /// - Returns: UIImage, or nil if conversion fails
    static func dataToImage(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}
