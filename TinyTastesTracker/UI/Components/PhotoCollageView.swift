//
//  PhotoCollageView.swift
//  TinyTastesTracker
//
//  Interactive UI for creating photo collages
//

import SwiftUI

struct PhotoCollageView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // Available photos
    let availablePhotos: [TriedFoodLog]
    
    // Selection state
    @State private var selectedPhotos: Set<String> = []
    @State private var selectedTemplate: CollageTemplate = .grid2x2
    @State private var collageOptions = CollageOptions.default
    
    // Preview state
    @State private var previewImage: UIImage?
    @State private var isGeneratingPreview = false
    
    // Actions
    @State private var showShareSheet = false
    @State private var showColorPicker = false
    @State private var showSaveConfirmation = false
    @State private var saveError: Error?
    
    var selectedLogs: [TriedFoodLog] {
        availablePhotos.filter { 
            guard let id = $0.id else { return false }
            return selectedPhotos.contains(id) 
        }
    }
    
    var canCreateCollage: Bool {
        selectedPhotos.count >= selectedTemplate.minPhotos &&
        selectedPhotos.count <= selectedTemplate.maxPhotos
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    instructionSection
                    
                    // Template picker
                    templatePickerSection
                    
                    // Photo selection grid
                    photoSelectionSection
                    
                    // Customization options
                    customizationSection
                    
                    // Preview
                    if let preview = previewImage {
                        previewSection(preview)
                    }
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Create Collage")
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
                    PhotoShareSheet(items: [image])
                }
            }
            .alert("Collage Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your collage has been saved to Photos.")
            }
            .alert("Error", isPresented: .constant(saveError != nil)) {
                Button("OK", role: .cancel) {
                    saveError = nil
                }
            } message: {
                if let error = saveError {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Instruction Section
    
    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(appState.themeColor)
                Text("How to Create a Collage")
                    .font(.headline)
            }
            
            Text("1. Choose a template\n2. Select \(selectedTemplate.minPhotos)-\(selectedTemplate.maxPhotos) photos\n3. Customize colors and text\n4. Preview and save")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Template Picker
    
    private var templatePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Template")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CollageTemplate.allCases) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate == template,
                            themeColor: appState.themeColor
                        ) {
                            selectedTemplate = template
                            selectedPhotos.removeAll()
                            previewImage = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Photo Selection
    
    private var photoSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Photos")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedPhotos.count)/\(selectedTemplate.maxPhotos)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if selectedPhotos.count < selectedTemplate.minPhotos {
                Text("Select at least \(selectedTemplate.minPhotos) photos")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(availablePhotos) { log in
                    if let id = log.id {
                        SelectablePhotoCard(
                            log: log,
                            isSelected: selectedPhotos.contains(id),
                            isDisabled: !selectedPhotos.contains(id) && selectedPhotos.count >= selectedTemplate.maxPhotos
                        ) {
                            togglePhotoSelection(log)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Customization
    
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customize")
                .font(.headline)
            
            // Background color
            HStack {
                Text("Background Color")
                    .font(.subheadline)
                
                Spacer()
                
                ColorPicker("", selection: Binding(
                    get: { Color(collageOptions.backgroundColor) },
                    set: { collageOptions.backgroundColor = UIColor($0) }
                ))
                .labelsHidden()
            }
            
            // Text options
            Toggle("Show Food Names", isOn: $collageOptions.showFoodNames)
            Toggle("Show Dates", isOn: $collageOptions.showDates)
            Toggle("Show Reactions", isOn: $collageOptions.showReactions)
            
            // Spacing
            VStack(alignment: .leading, spacing: 4) {
                Text("Spacing: \(Int(collageOptions.spacing))px")
                    .font(.subheadline)
                Slider(value: $collageOptions.spacing, in: 0...40, step: 4)
            }
            
            // Border width
            VStack(alignment: .leading, spacing: 4) {
                Text("Border: \(Int(collageOptions.borderWidth))px")
                    .font(.subheadline)
                Slider(value: $collageOptions.borderWidth, in: 0...10, step: 1)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Preview
    
    private func previewSection(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                generatePreview()
            } label: {
                HStack {
                    if isGeneratingPreview {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "eye.fill")
                    }
                    Text("Generate Preview")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreateCollage ? appState.themeColor : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canCreateCollage || isGeneratingPreview)
            
            if previewImage != nil {
                HStack(spacing: 12) {
                    Button {
                        saveCollage()
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
        }
    }
    
    // MARK: - Actions
    
    private func togglePhotoSelection(_ log: TriedFoodLog) {
        guard let id = log.id else { return }
        
        if selectedPhotos.contains(id) {
            selectedPhotos.remove(id)
        } else if selectedPhotos.count < selectedTemplate.maxPhotos {
            selectedPhotos.insert(id)
        }
        
        // Clear preview when selection changes
        previewImage = nil
    }
    
    private func generatePreview() {
        isGeneratingPreview = true
        
        // Prepare Sendable data on MainActor
        let assets = selectedLogs.compactMap { log -> PhotoAssetData? in
            guard let data = log.messyFaceImage, let id = log.id else { return nil }
            return PhotoAssetData(id: id, date: log.date, imageData: data)
        }
        let template = selectedTemplate
        let options = collageOptions
        
        Task {
            let image = await Task.detached {
                await PhotoManager.shared.createShareableCollage(
                    from: assets,
                    template: template,
                    options: options
                )
            }.value
            
            await MainActor.run {
                if let generatedImage = image {
                    previewImage = generatedImage
                } else {
                    saveError = NSError(domain: "CollageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not generate collage from selected photos."])
                }
                isGeneratingPreview = false
            }
        }
    }
    
    private func saveCollage() {
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

// MARK: - Template Card

struct TemplateCard: View {
    let template: CollageTemplate
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Template icon
                templateIcon
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? themeColor : .secondary)
                
                Text(template.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? themeColor : .primary)
                
                Text("\(template.minPhotos)-\(template.maxPhotos) photos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, height: 120)
            .background(isSelected ? themeColor.opacity(0.1) : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeColor : Color.clear, lineWidth: 2)
            }
        }
    }
    
    @ViewBuilder
    private var templateIcon: some View {
        switch template {
        case .grid2x2:
            Image(systemName: "square.grid.2x2")
        case .grid3x3:
            Image(systemName: "square.grid.3x3")
        case .timeline:
            Image(systemName: "timeline.selection")
        case .scrapbook:
            Image(systemName: "photo.on.rectangle.angled")
        case .mosaic:
            Image(systemName: "square.split.2x2")
        case .milestone:
            Image(systemName: "star.circle")
        }
    }
}

// MARK: - Selectable Photo Card

struct SelectablePhotoCard: View {
    let log: TriedFoodLog
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                if let imageData = log.messyFaceImage,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .opacity(isDisabled ? 0.4 : 1.0)
                } else {
                    Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 100)
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.green))
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
            }
        }
        .disabled(isDisabled)
    }
}
