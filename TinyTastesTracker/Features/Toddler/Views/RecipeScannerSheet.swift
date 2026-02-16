//
//  RecipeScannerSheet.swift
//  TinyTastesTracker
//
//  Recipe scanning with OCR and AI parsing
//

import SwiftUI

struct RecipeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Bindable var appState: AppState

    @State private var scanningState: ScanningState = .camera
    @State private var capturedImage: UIImage?
    @State private var extractedRecipe: ExtractedRecipe?
    @State private var errorMessage: String?

    @State private var editedTitle: String = ""
    @State private var editedIngredients: String = ""
    @State private var editedInstructions: String = ""

    private let ocrService = RecipeOCRService()

    enum ScanningState {
        case camera
        case processing
        case review
        case error
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch scanningState {
                case .camera:
                    cameraView
                case .processing:
                    processingView
                case .review:
                    reviewView
                case .error:
                    errorView
                }
            }
            .navigationTitle("Scan Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        CameraView(
            title: "Scan Recipe",
            subtitle: "Ensure title and ingredients are visible",
            iconName: "doc.text.viewfinder"
        ) { image in
            capturedImage = image
            processImage(image)
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Scanning Recipe...")
                    .font(.headline)
                Text("Extracting text and parsing ingredients")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(0.6)
            }
        }
        .padding()
    }

    // MARK: - Review View

    private var reviewView: some View {
        Form {
            Section {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Section("Recipe Title") {
                TextField("Enter recipe title", text: $editedTitle)
            }

            Section("Ingredients") {
                TextEditor(text: $editedIngredients)
                    .frame(minHeight: 150)
            }

            Section("Instructions") {
                TextEditor(text: $editedInstructions)
                    .frame(minHeight: 200)
            }

            Section {
                Button("Save Recipe") {
                    saveRecipe()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(appState.themeColor)

                Button("Rescan") {
                    resetToCamera()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Scanning Failed")
                    .font(.headline)
                Text(errorMessage ?? "An error occurred while scanning the recipe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button("Try Again") {
                    resetToCamera()
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    // MARK: - Processing Logic

    private func processImage(_ image: UIImage) {
        scanningState = .processing

        Task {
            do {
                // Scan recipe using OCR service
                let recipe = try await ocrService.scanRecipe(from: image, using: appState.geminiService)
                extractedRecipe = recipe

                // Populate edit fields
                await MainActor.run {
                    editedTitle = recipe.title
                    editedIngredients = recipe.ingredients
                    editedInstructions = recipe.instructions
                    scanningState = .review
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    scanningState = .error
                }
            }
        }
    }

    private func saveRecipe() {
        guard !editedTitle.isEmpty else { return }
        
        Task {
            do {
                // Process image with compression service
                var imageData: Data?
                var thumbnailData: Data?
                
                if let image = capturedImage {
                    let processed = ImageCompressionService.processRecipeImage(image)
                    imageData = processed.full
                    thumbnailData = processed.thumbnail
                }

                let recipe = Recipe(
                    ownerId: appState.currentOwnerId ?? "",
                    title: editedTitle,
                    ingredients: editedIngredients,
                    instructions: editedInstructions,
                    imageData: imageData,
                    thumbnailData: thumbnailData
                )

                try await appState.saveRecipe(recipe)

                // Create custom food from recipe
                _ = appState.createCustomFoodFromRecipe(recipe)

                errorPresenter.showSuccess("Recipe saved")
                dismiss()
            } catch {
                errorPresenter.present(error)
            }
        }
    }

    private func resetToCamera() {
        scanningState = .camera
        capturedImage = nil
        extractedRecipe = nil
        errorMessage = nil
        editedTitle = ""
        editedIngredients = ""
        editedInstructions = ""
    }
}
