//
//  FoodImageStorageService.swift
//  TinyTastesTracker
//
//  Service for uploading and downloading custom food images to/from Firebase Storage
//

import UIKit
import FirebaseStorage

class FoodImageStorageService {
    static let shared = FoodImageStorageService()

    private let storage = Storage.storage()
    private let imageCache = NSCache<NSString, UIImage>()

    private init() {
        // Configure cache limits
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    // MARK: - Upload Image

    /// Upload a custom food image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - foodId: The unique ID of the food
    ///   - ownerId: The owner's user ID
    /// - Returns: The Firebase Storage path (e.g., "food_images/user123/food456.jpg")
    func uploadFoodImage(_ image: UIImage, foodId: String, ownerId: String) async throws -> String {
        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw FoodImageError.compressionFailed
        }

        // Create storage path
        let filename = "\(foodId).jpg"
        let storagePath = "food_images/\(ownerId)/\(filename)"
        let storageRef = storage.reference().child(storagePath)

        // Upload with metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Also save locally for offline access
        saveImageLocally(image, filename: filename)

        return storagePath
    }

    // MARK: - Download Image

    /// Download a custom food image from Firebase Storage
    /// - Parameter storagePath: The Firebase Storage path
    /// - Returns: The downloaded UIImage
    func downloadFoodImage(storagePath: String) async throws -> UIImage {
        // Check cache first
        if let cachedImage = imageCache.object(forKey: storagePath as NSString) {
            return cachedImage
        }

        // Check local storage
        let filename = (storagePath as NSString).lastPathComponent
        if let localImage = loadImageLocally(filename: filename) {
            imageCache.setObject(localImage, forKey: storagePath as NSString)
            return localImage
        }

        // Download from Firebase Storage
        let storageRef = storage.reference().child(storagePath)
        let maxSize: Int64 = 10 * 1024 * 1024 // 10 MB

        let data = try await storageRef.data(maxSize: maxSize)

        guard let image = UIImage(data: data) else {
            throw FoodImageError.invalidImageData
        }

        // Cache the image
        imageCache.setObject(image, forKey: storagePath as NSString)

        // Save locally for offline access
        saveImageLocally(image, filename: filename)

        return image
    }

    // MARK: - Delete Image

    /// Delete a custom food image from Firebase Storage
    /// - Parameter storagePath: The Firebase Storage path
    func deleteFoodImage(storagePath: String) async throws {
        let storageRef = storage.reference().child(storagePath)
        try await storageRef.delete()

        // Remove from cache
        imageCache.removeObject(forKey: storagePath as NSString)

        // Remove from local storage
        let filename = (storagePath as NSString).lastPathComponent
        deleteImageLocally(filename: filename)
    }

    // MARK: - Local Storage Helpers

    private func saveImageLocally(_ image: UIImage, filename: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        try? data.write(to: fileURL)
    }

    private func loadImageLocally(filename: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func deleteImageLocally(filename: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Get Cached Image

    /// Get image from cache if available
    func getCachedImage(storagePath: String) -> UIImage? {
        return imageCache.object(forKey: storagePath as NSString)
    }

    /// Clear all cached images
    func clearCache() {
        imageCache.removeAllObjects()
    }
}

// MARK: - Errors

enum FoodImageError: LocalizedError {
    case compressionFailed
    case invalidImageData
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidImageData:
            return "Invalid image data"
        case .uploadFailed:
            return "Failed to upload image"
        case .downloadFailed:
            return "Failed to download image"
        }
    }
}
