//
//  PhotoManager.swift
//  TinyTastesTracker
//
//  Service for photo-related operations (save, share, delete)
//

import UIKit
import Photos

class PhotoManager {
    static let shared = PhotoManager()
    
    private init() {}
    
    /// Save an image to the user's Photos library
    func saveToPhotosLibrary(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        // Check authorization status
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            performSave(image: image, completion: completion)
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    self.performSave(image: image, completion: completion)
                } else {
                    completion(false, PhotoError.authorizationDenied)
                }
            }
            
        case .denied, .restricted:
            completion(false, PhotoError.authorizationDenied)
            
        @unknown default:
            completion(false, PhotoError.unknown)
        }
    }
    
    private func performSave(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    /// Create a shareable image with metadata overlay
    func createShareableImage(from log: TriedFoodLog) -> UIImage? {
        guard let imageData = log.messyFaceImage,
              let originalImage = UIImage(data: imageData) else {
            return nil
        }
        
        // For now, just return the original image
        // Future enhancement: overlay metadata on the image
        return originalImage
    }
    
    /// Create a collage from multiple food logs
    func createShareableCollage(
        from assets: [PhotoAssetData],
        template: CollageTemplate,
        options: CollageOptions = .default
    ) -> UIImage? {
        return PhotoCollageService.shared.createCollage(from: assets, template: template, options: options)
    }
    
    /// Save collage to Photos library
    func saveCollageToPhotosLibrary(collage: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        saveToPhotosLibrary(image: collage, completion: completion)
    }
    
    /// Generate a memory collage
    func generateMemory(
        type: MemoryType,
        from allAssets: [PhotoAssetData],
        dateRange: DateInterval? = nil
    ) -> CollageMemory? {
        return PhotoCollageService.shared.generateMemory(type: type, from: allAssets, dateRange: dateRange)
    }
    
    /// Create image from memory
    func createImageFromMemory(_ memory: CollageMemory, options: CollageOptions = .default) -> UIImage? {
        return PhotoCollageService.shared.createCollage(from: memory.photos, template: memory.template, options: options)
    }
}

// MARK: - Errors

enum PhotoError: LocalizedError {
    case authorizationDenied
    case saveFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Photo library access denied. Please enable access in Settings."
        case .saveFailed:
            return "Failed to save photo to library."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
