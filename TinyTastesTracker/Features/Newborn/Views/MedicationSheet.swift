//
//  MedicationSheet.swift
//  TinyTastesTracker
//
//

import SwiftUI
import PhotosUI

struct MedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter
    @Bindable var appState: AppState

    @State private var medicineName: String = ""
    @State private var babyWeight: Double = 10.0
    @State private var dosage: String = ""
    @State private var notes: String = ""
    @State private var safetyInfo: MedicationSafetyInfo?
    @State private var isLoadingSafety = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false

    // Camera/Photo functionality
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var isAnalyzingImage = false
    @State private var capturedImage: UIImage?

    // Saved medications
    @State private var showingSavedMedsPicker = false
    @State private var showingSavePrompt = false

    var body: some View {
        NavigationStack {
            Form {
                // Saved Medications Section (if any exist)
                if !appState.savedMedications.isEmpty {
                    Section("Quick Select") {
                        Button {
                            showingSavedMedsPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(appState.themeColor)
                                Text("Use Saved Medication")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(appState.savedMedications.count)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section("Medication Details") {
                    TextField("Medicine Name (e.g., Tylenol)", text: $medicineName)
                        .autocorrectionDisabled()

                    HStack {
                        Text("Baby's Weight")
                        Spacer()
                        TextField("Weight", value: $babyWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }

                    TextField("Dosage (e.g., 2.5ml, 1 tablet)", text: $dosage)
                        .autocorrectionDisabled()
                }

                Section {
                    Button {
                        Task {
                            await fetchSafetyInfo()
                        }
                    } label: {
                        HStack {
                            if isLoadingSafety {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isLoadingSafety ? "Checking Safety..." : "Get Safety Info")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(medicineName.isEmpty || dosage.isEmpty || isLoadingSafety)
                }

                if let safety = safetyInfo {
                    Section("Safety Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Status Badge
                            HStack {
                                Text("Status:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(safety.status)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(statusColor(safety.status).opacity(0.2))
                                    .foregroundStyle(statusColor(safety.status))
                                    .clipShape(Capsule())
                                    .fontWeight(.semibold)
                            }

                            Divider()

                            // Summary
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Summary")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(safety.summary)
                                    .font(.body)
                            }

                            Divider()

                            // Dosage Guidance
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dosage Guidance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(safety.dosageGuidance)
                                    .font(.body)
                            }

                            // Warnings
                            if !safety.warnings.isEmpty {
                                Divider()

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Warnings")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    ForEach(safety.warnings, id: \.self) { warning in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.orange)
                                                .font(.caption)
                                            Text(warning)
                                                .font(.callout)
                                        }
                                    }
                                }
                            }

                            // Age Appropriate
                            Divider()

                            HStack {
                                Text("Age Appropriate:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: safety.ageAppropriate ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(safety.ageAppropriate ? .green : .red)
                                Text(safety.ageAppropriate ? "Yes" : "No")
                                    .foregroundStyle(safety.ageAppropriate ? .green : .red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Add any observations...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Save Medication Log") {
                        saveMedication()
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(appState.themeColor)
                    .disabled(medicineName.isEmpty || dosage.isEmpty || isSaving)

                    // Option to save as frequently-used medication
                    if !medicineName.isEmpty && !dosage.isEmpty {
                        Button {
                            showingSavePrompt = true
                        } label: {
                            HStack {
                                Image(systemName: "bookmark")
                                Text("Save as Frequently Used")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .navigationTitle("Log Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }

                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(appState.themeColor)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("Save Medication", isPresented: $showingSavePrompt) {
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    saveAsFavoriteMedication()
                }
            } message: {
                Text("Save '\(medicineName)' as a frequently-used medication for quick access?")
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(
                    title: "Capture Label",
                    subtitle: "Ensure medication name and dosage are visible",
                    iconName: "text.viewfinder"
                ) { image in
                    capturedImage = image
                    Task {
                        await analyzeMedicationImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                MedicationPhotoPicker(selectedImage: $capturedImage)
                    .onChange(of: capturedImage) { _, newImage in
                        if let image = newImage {
                            Task {
                                await analyzeMedicationImage(image)
                            }
                        }
                    }
            }
            .sheet(isPresented: $showingSavedMedsPicker) {
                SavedMedicationsPickerView(appState: appState) { medication in
                    loadSavedMedication(medication)
                    showingSavedMedsPicker = false
                }
            }
            .overlay {
                if isAnalyzingImage {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                            Text("Analyzing medication bottle...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Safe":
            return .green
        case "Caution":
            return .orange
        case "Consult Doctor":
            return .red
        default:
            return .gray
        }
    }

    private func fetchSafetyInfo() async {
        isLoadingSafety = true

        do {
            let ageInMonths = appState.userProfile?.ageInMonths ?? 6
            let info = try await appState.geminiService.getMedicationSafetyInfo(
                medicineName: medicineName,
                babyWeight: babyWeight,
                dosage: dosage,
                ageInMonths: ageInMonths
            )
            safetyInfo = info
            HapticManager.success()
        } catch {
            errorMessage = "Failed to get safety information: \(error.localizedDescription)"
            showError = true
            HapticManager.error()
        }

        isLoadingSafety = false
    }

    private func analyzeMedicationImage(_ image: UIImage) async {
        isAnalyzingImage = true

        do {
            let analysis = try await appState.analyzeMedicationBottle(image: image)

            // Populate fields with extracted data
            medicineName = analysis.medicineName

            // Build dosage string from available info
            if let concentration = analysis.concentration {
                dosage = concentration
            } else if let recommended = analysis.recommendedDosage {
                dosage = recommended
            }

            // Add extracted info to notes
            var extractedNotes = ""
            if let ingredient = analysis.activeIngredient {
                extractedNotes += "Active Ingredient: \(ingredient)\n"
            }
            if let form = analysis.dosageForm {
                extractedNotes += "Form: \(form)\n"
            }
            if !analysis.warnings.isEmpty {
                extractedNotes += "Label Warnings: \(analysis.warnings.joined(separator: ", "))"
            }
            notes = extractedNotes

            HapticManager.success()
        } catch {
            errorMessage = "Failed to analyze image: \(error.localizedDescription)"
            showError = true
            HapticManager.error()
        }

        isAnalyzingImage = false
    }

    private func loadSavedMedication(_ medication: SavedMedication) {
        medicineName = medication.medicineName
        dosage = medication.defaultDosage
        if let savedNotes = medication.notes {
            notes = savedNotes
        }

        // Update usage count
        appState.updateSavedMedicationUsage(medication)
    }

    private func saveAsFavoriteMedication() {
        Task {
            do {
                try await appState.saveSavedMedication(
                    medicineName: medicineName,
                    defaultDosage: dosage,
                    notes: notes.isEmpty ? nil : notes
                )
                errorPresenter.showSuccess("Medication saved for quick access")
            } catch {
                errorPresenter.present(error)
            }
        }
    }

    private func saveMedication() {
        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                try await appState.saveMedicationLog(
                    medicineName: medicineName,
                    babyWeight: babyWeight,
                    dosage: dosage,
                    safetyInfo: safetyInfo?.summary,
                    notes: notes.isEmpty ? nil : notes
                )
                errorPresenter.showSuccess("Medication logged")
                dismiss()
            } catch {
                errorPresenter.present(error)
            }
        }
    }
}

// MARK: - Saved Medications Picker

struct SavedMedicationsPickerView: View {
    @Bindable var appState: AppState
    let onSelect: (SavedMedication) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter

    var body: some View {
        NavigationStack {
            List {
                if appState.savedMedications.isEmpty {
                    ContentUnavailableView(
                        "No Saved Medications",
                        systemImage: "pills",
                        description: Text("Save frequently-used medications for quick access")
                    )
                } else {
                    ForEach(appState.savedMedications) { medication in
                        Button {
                            onSelect(medication)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(medication.medicineName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(medication.defaultDosage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let notes = medication.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(2)
                                }

                                HStack {
                                    Text("Used \(medication.usageCount) times")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                    Text("Last: \(medication.lastUsed.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                appState.deleteSavedMedication(medication)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Medications")
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
}

// MARK: - Camera View


// MARK: - Photo Picker

struct MedicationPhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.errorPresenter) private var errorPresenter

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MedicationPhotoPicker

        init(_ parent: MedicationPhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
