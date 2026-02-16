//
//  FoodImageView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/16/26.
//

import SwiftUI

struct FoodImageView: View {
    let food: FoodItem
    let size: CGFloat

    @State private var downloadedImage: UIImage?
    @State private var isLoadingImage = false

    // Derived asset name for built-in foods
    private var assetName: String {
        "food_\(food.id.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    var body: some View {
        ZStack {
            // Subtle background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.15),
                            Color.gray.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Food image with circular mask
            Group {
                // Priority 1: Downloaded image from Firebase Storage
                if let downloadedImage = downloadedImage {
                    Image(uiImage: downloadedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                // Priority 2: Custom Food Image (from file property - legacy)
                else if let imageFileName = food.imageFileName,
                   let uiImage = loadLocalImage(named: imageFileName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                // Priority 3: Generated Override for Built-in Food (local file: food_{id}.png)
                else if let uiImage = loadLocalImage(named: "food_\(food.id.lowercased().replacingOccurrences(of: " ", with: "_")).png") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                // Priority 4: Built-in Asset
                else if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                // Priority 5: Fallback to Emoji
                else {
                    if isLoadingImage {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(food.emoji)
                            .font(.system(size: size * 0.5))
                    }
                }
            }
            .frame(width: size * 0.85, height: size * 0.85)
            .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .task {
            // Download image from Firebase Storage if available
            if let storagePath = food.imageStoragePath {
                await downloadImageFromStorage(storagePath: storagePath)
            }
        }
    }

    private func downloadImageFromStorage(storagePath: String) async {
        // Check if already loaded
        guard downloadedImage == nil else { return }

        isLoadingImage = true

        do {
            let image = try await FoodImageStorageService.shared.downloadFoodImage(storagePath: storagePath)
            await MainActor.run {
                downloadedImage = image
                isLoadingImage = false
            }
        } catch {
            print("Error downloading image from storage: \(error)")
            await MainActor.run {
                isLoadingImage = false
            }
        }
    }

    private func loadLocalImage(named fileName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

#Preview {
    FoodImageView(
        food: FoodItem(id: "BANANA", name: "Banana", emoji: "🍌", category: .fruits),
        size: 100
    )
}
