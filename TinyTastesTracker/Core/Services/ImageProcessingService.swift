//
//  ImageProcessingService.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import UIKit

struct ImageProcessingService {
    static func compressImage(_ image: UIImage, maxWidth: CGFloat = 300, quality: CGFloat = 0.7) -> Data {
        let size = image.size
        var newSize: CGSize
        
        if size.width > maxWidth {
            let aspectRatio = size.height / size.width
            newSize = CGSize(width: maxWidth, height: maxWidth * aspectRatio)
        } else {
            newSize = size
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: quality) ?? Data()
    }
}
