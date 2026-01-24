//
//  KnownAllergiesView.swift
//  TinyTastesTracker
//
//  View for managing known allergies
//

import SwiftUI

struct KnownAllergiesView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAllergies: Set<String> = []
    
    var body: some View {
        List {
            Section {
                Text("Select any allergens or intolerances your baby has been diagnosed with. These will be flagged across the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
            
            // MARK: - Allergens Section
            Section {
                FlowLayout(spacing: 12) {
                    ForEach(CommonAllergens.trueAllergies, id: \.self) { allergen in
                        AllergenChip(
                            allergen: allergen,
                            isSelected: selectedAllergies.contains(allergen),
                            themeColor: .red,
                            isTrueAllergy: true
                        ) {
                            toggleAllergen(allergen)
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } header: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Allergens")
                }
            } footer: {
                Text("Allergens involve the immune system and can be life-threatening. These will trigger monitoring prompts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // MARK: - Intolerances Section
            Section {
                FlowLayout(spacing: 12) {
                    ForEach(CommonAllergens.intolerances, id: \.self) { allergen in
                        AllergenChip(
                            allergen: allergen,
                            isSelected: selectedAllergies.contains(allergen),
                            themeColor: .orange,
                            isTrueAllergy: false
                        ) {
                            toggleAllergen(allergen)
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } header: {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Intolerances & Sensitivities")
                }
            } footer: {
                Text("Intolerances cause digestive discomfort but are not life-threatening. These will be tracked but won't trigger urgent alerts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Allergies & Intolerances")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveAllergies()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            loadCurrentAllergies()
        }
    }
    
    private func loadCurrentAllergies() {
        if let allergies = appState.userProfile?.knownAllergies {
            selectedAllergies = Set(allergies)
        }
    }
    
    private func toggleAllergen(_ allergen: String) {
        if selectedAllergies.contains(allergen) {
            selectedAllergies.remove(allergen)
        } else {
            selectedAllergies.insert(allergen)
        }
    }
    
    private func saveAllergies() {
        appState.userProfile?.knownAllergies = Array(selectedAllergies).sorted()
        dismiss()
    }
}

// MARK: - Allergen Chip Component

struct AllergenChip: View {
    let allergen: String
    let isSelected: Bool
    let themeColor: Color
    let isTrueAllergy: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: isTrueAllergy ? "exclamationmark.triangle.fill" : "checkmark")
                        .font(.caption.weight(.semibold))
                }
                
                Text(allergen)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? themeColor.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? themeColor : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? themeColor : .primary)
        }
        .buttonStyle(.plain)
    }
}
