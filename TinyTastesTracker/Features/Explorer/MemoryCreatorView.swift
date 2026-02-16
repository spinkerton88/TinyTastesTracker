//
//  MemoryCreatorView.swift
//  TinyTastesTracker
//
//  Automatic memory generation UI
//

import SwiftUI

struct MemoryCreatorView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // All available photos
    let availablePhotos: [TriedFoodLog]
    
    // State
    @State private var selectedMemoryType: MemoryType = .firstFoods
    @State private var generatedMemory: CollageMemory?
    @State private var previewImage: UIImage?
    @State private var isGenerating = false
    @State private var customTitle: String = ""
    @State private var customSubtitle: String = ""
    @State private var dateRange: DateInterval?
    
    @State private var showGenerationError = false
    @State private var generationErrorMessage = ""
    
    // Actions
    @State private var showShareSheet = false
    @State private var showSaveConfirmation = false
    @State private var saveError: Error?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Memory type selector
                    memoryTypeSection
                    
                    // Date range (for time-based memories)
                    if selectedMemoryType == .monthly || selectedMemoryType == .weekly {
                        dateRangeSection
                    }
                    
                    // Generate button
                    generateButton
                    
                    // Generated memory preview
                    if let memory = generatedMemory {
                        memoryPreviewSection(memory)
                    }
                    
                    // Action buttons
                    if previewImage != nil {
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("Create Memory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = previewImage {
                    PhotoShareSheet(items: [image, customTitle.isEmpty ? generatedMemory?.title ?? "" : customTitle])
                }
            }
            .alert("Memory Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your memory has been saved to Photos.")
            }
            .alert("Save Failed", isPresented: .constant(saveError != nil)) {
                Button("OK", role: .cancel) {
                    saveError = nil
                }
            } message: {
                if let error = saveError {
                    Text(error.localizedDescription)
                }
            }
            .alert("Could Not Generate Memory", isPresented: $showGenerationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(generationErrorMessage)
            }
        }
    }
    
    // MARK: - Memory Type Section
    
    private var memoryTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Memory Type")
                .font(.headline)
            
            ForEach(MemoryType.allCases) { type in
                MemoryTypeCard(
                    type: type,
                    isSelected: selectedMemoryType == type,
                    themeColor: appState.themeColor
                ) {
                    selectedMemoryType = type
                    generatedMemory = nil
                    previewImage = nil
                }
            }
        }
    }
    
    // MARK: - Date Range Section
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.headline)
            
            Text("Leave empty to use the most recent period")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Simple date range picker would go here
            // For now, we'll auto-select based on memory type
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Generate Button
    
    private var generateButton: some View {
        Button {
            generateMemory()
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    SageIcon(size: .medium, style: .monochrome(.white))
                }
                Text("Generate Memory")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(appState.themeColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isGenerating)
    }
    
    // MARK: - Memory Preview
    
    private func memoryPreviewSection(_ memory: CollageMemory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Memory Preview")
                .font(.headline)
            
            // Title and subtitle editing
            VStack(alignment: .leading, spacing: 8) {
                TextField("Title", text: $customTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Subtitle (optional)", text: $customSubtitle)
                    .font(.subheadline)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Memory details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundStyle(appState.themeColor)
                    Text("\(memory.photos.count) photos")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(appState.themeColor)
                    Text("Generated \(memory.generatedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(appState.themeColor)
                    Text("Template: \(memory.template.rawValue)")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Image preview
            if let preview = previewImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            } else {
                Button {
                    generatePreviewImage()
                } label: {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("Generate Preview")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appState.themeColor.opacity(0.2))
                    .foregroundStyle(appState.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                saveMemory()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(appState.themeColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(appState.themeColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Actions
    
    private func generateMemory() {
        isGenerating = true
        
        // Prepare Sendable data on MainActor
        let assets = availablePhotos.compactMap { log -> PhotoAssetData? in
            guard let data = log.messyFaceImage, let id = log.id else { return nil }
            return PhotoAssetData(id: id, date: log.date, imageData: data)
        }
        let type = selectedMemoryType
        let range = dateRange
        
        Task {
            let memory = await Task.detached {
                PhotoManager.shared.generateMemory(
                    type: type,
                    from: assets,
                    dateRange: range
                )
            }.value
            
            await MainActor.run {
                if let memory = memory {
                    generatedMemory = memory
                    customTitle = memory.title
                    customSubtitle = memory.subtitle ?? ""
                } else {
                    generatedMemory = nil
                    switch type {
                    case .firstFoods:
                        generationErrorMessage = "Need at least 5 tried foods with photos."
                    case .rainbowComplete:
                        generationErrorMessage = "Need foods of all rainbow colors with photos."
                    case .monthly:
                        generationErrorMessage = "Need at least 4 photos from the last month."
                    case .weekly:
                        generationErrorMessage = "Need at least 3 photos from the last 7 days."
                    case .themed:
                        generationErrorMessage = "Need at least 4 photos for a themed collection."
                    case .milestone:
                        generationErrorMessage = "Need at least 10 photos to reach a milestone."
                    }
                    showGenerationError = true
                }
                isGenerating = false
            }
        }
    }
    
    private func generatePreviewImage() {
        guard let memory = generatedMemory else { return }
        
        Task {
            let image = await Task.detached {
                PhotoManager.shared.createImageFromMemory(memory)
            }.value
            
            await MainActor.run {
                previewImage = image
            }
        }
    }
    
    private func saveMemory() {
        guard let image = previewImage else { return }
        
        PhotoManager.shared.saveCollageToPhotosLibrary(collage: image) { success, error in
            if success {
                showSaveConfirmation = true
            } else {
                saveError = error
            }
        }
    }
}

// MARK: - Memory Type Card

struct MemoryTypeCard: View {
    let type: MemoryType
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                memoryIcon
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? themeColor : .secondary)
                    .frame(width: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundStyle(isSelected ? themeColor : .primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeColor)
                }
            }
            .padding()
            .background(isSelected ? themeColor.opacity(0.1) : Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeColor : Color.clear, lineWidth: 2)
            }
        }
    }
    
    @ViewBuilder
    private var memoryIcon: some View {
        switch type {
        case .firstFoods:
            Image(systemName: "fork.knife.circle.fill")
        case .rainbowComplete:
            Image(systemName: "rainbow")
        case .monthly:
            Image(systemName: "calendar.circle.fill")
        case .weekly:
            Image(systemName: "calendar.badge.clock")
        case .themed:
            Image(systemName: "square.stack.3d.up.fill")
        case .milestone:
            Image(systemName: "star.circle.fill")
        }
    }
}
