//
//  PhotoViewerSheet.swift
//  TinyTastesTracker
//
//  Full-screen photo viewer with sharing, metadata, and navigation
//

import SwiftUI
import PhotosUI

struct PhotoViewerSheet: View {
    let log: TriedFoodLog
    @Bindable var appState: AppState
    let allLogs: [TriedFoodLog]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showDeleteConfirmation = false
    @State private var showFoodDetail = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var showShareSheet = false
    @State private var imageToShare: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Photo with pinch-to-zoom
                    if let imageData = log.messyFaceImage,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        // Reset if zoomed out too far
                                        if scale < 1.0 {
                                            withAnimation(.spring()) {
                                                scale = 1.0
                                                lastScale = 1.0
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                // Double tap to reset zoom
                                withAnimation(.spring()) {
                                    scale = 1.0
                                    lastScale = 1.0
                                }
                            }
                        
                        // Metadata overlay
                        photoMetadataOverlay
                            .padding()
                    } else {
                        Text("Photo not available")
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            sharePhoto()
                        } label: {
                            Label("Share Photo", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            saveToPhotosLibrary()
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                        }
                        
                        Divider()
                        
                        Button {
                            showFoodDetail = true
                        } label: {
                            Label("View Food Details", systemImage: "info.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Photo", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .confirmationDialog(
                "Delete Photo?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deletePhoto()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove the photo from this food log.")
            }
            .sheet(isPresented: $showFoodDetail) {
                if let food = appState.allKnownFoods.first(where: { $0.id == log.id }) {
                    FoodDetailModal(food: food, appState: appState)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = imageToShare {
                    PhotoShareSheet(items: [image, createPhotoCaption()])
                }
            }
        }
    }
    
    // MARK: - Photo Metadata Overlay
    
    private var photoMetadataOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.id)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                HStack {
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("•")
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(log.meal.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                // Reaction
                HStack(spacing: 4) {
                    ForEach(1...7, id: \.self) { index in
                        Circle()
                            .fill(index <= log.reaction ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(reactionText(log.reaction))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.leading, 4)
                }
            }
            .padding()
            .background(.ultraThinMaterial.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helper Functions
    
    private func reactionText(_ reaction: Int) -> String {
        switch reaction {
        case 1: return "Hated it"
        case 2: return "Didn't like"
        case 3: return "Not sure"
        case 4: return "Neutral"
        case 5: return "Liked it"
        case 6: return "Loved it"
        case 7: return "Absolutely loved!"
        default: return "Neutral"
        }
    }
    
    private func createPhotoCaption() -> String {
        let dateStr = log.date.formatted(date: .abbreviated, time: .omitted)
        let reaction = reactionText(log.reaction)
        return "\(log.id) - \(dateStr) - \(reaction)"
    }
    
    private func sharePhoto() {
        if let imageData = log.messyFaceImage,
           let uiImage = UIImage(data: imageData) {
            imageToShare = uiImage
            showShareSheet = true
        }
    }
    
    private func saveToPhotosLibrary() {
        guard let imageData = log.messyFaceImage,
              let uiImage = UIImage(data: imageData) else { return }
        
        PhotoManager.shared.saveToPhotosLibrary(image: uiImage) { success, error in
            // Could show a toast notification here
            if success {
                print("Photo saved successfully")
            } else if let error = error {
                print("Failed to save photo: \(error.localizedDescription)")
            }
        }
    }
    
    private func deletePhoto() {
        // Remove photo from log
        log.messyFaceImage = nil
        
        // Save context
        try? modelContext.save()
        
        // Dismiss viewer
        dismiss()
    }
}

// MARK: - PhotoShareSheet (UIKit wrapper)

struct PhotoShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
