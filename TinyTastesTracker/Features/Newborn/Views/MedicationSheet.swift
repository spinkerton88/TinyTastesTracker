import SwiftUI
import SwiftData

struct MedicationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState
    
    @State private var medicineName: String = ""
    @State private var babyWeight: Double = 10.0
    @State private var dosage: String = ""
    @State private var notes: String = ""
    @State private var safetyInfo: MedicationSafetyInfo?
    @State private var isLoadingSafety = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
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
                    Section("AI Safety Information") {
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
                    .disabled(medicineName.isEmpty || dosage.isEmpty)
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
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
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
    
    private func saveMedication() {
        appState.saveMedicationLog(
            medicineName: medicineName,
            babyWeight: babyWeight,
            dosage: dosage,
            safetyInfo: safetyInfo?.summary,
            notes: notes.isEmpty ? nil : notes,
            context: modelContext
        )
        HapticManager.success()
        dismiss()
    }
}
