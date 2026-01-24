//
//  BottleFeedSheet.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct BottleFeedSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState
    
    @State private var amount: Double = 4.0
    @State private var feedType: FeedingType = .formula
    @State private var notes: String = ""
    @State private var customAmount: String = ""
    @State private var useCustomAmount = false
    
    let presetAmounts: [Double] = [2, 3, 4, 5, 6, 7, 8]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount (oz)") {
                    if !useCustomAmount {
                        Picker("Amount", selection: $amount) {
                            ForEach(presetAmounts, id: \.self) { amt in
                                Text("\(Int(amt)) oz").tag(amt)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Button {
                            useCustomAmount = true
                            customAmount = String(format: "%.1f", amount)
                        } label: {
                            Text("Enter custom amount")
                                .frame(maxWidth: .infinity)
                        }
                        .accessibilityHint("Double tap to enter a specific amount manually")
                    } else {
                        HStack {
                            TextField("Amount", text: $customAmount)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Custom Amount")
                                .accessibilityValue("\(customAmount) ounces")
                            Text("oz")
                        }
                        
                        Button {
                            useCustomAmount = false
                        } label: {
                            Text("Use preset amounts")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                Section("Type") {
                    Picker("Feed Type", selection: $feedType) {
                        Text("Breast Milk").tag(FeedingType.breastMilk)
                        Text("Formula").tag(FeedingType.formula)
                        Text("Mixed").tag(FeedingType.mixed)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Feed Type")
                }
                
                Section("Notes (Optional)") {
                    TextField("Add any observations...", text: $notes, axis: .vertical)
                        .accessibilityLabel("Notes")
                        .accessibilityHint("Enter any observations about the feeding")
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Bottle Feed")
            .navigationBarTitleDisplayMode(.inline)
            .withSage(context: "User is logging a bottle feeding. Type: \(feedType == .formula ? "Formula" : feedType == .breastMilk ? "Breast Milk" : "Mixed").", appState: appState)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.selection()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBottleFeed()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveBottleFeed() {
        let finalAmount = useCustomAmount ? (Double(customAmount) ?? amount) : amount
        appState.saveBottleFeedLog(
            amount: finalAmount,
            feedType: feedType,
            notes: notes.isEmpty ? nil : notes,
            context: modelContext
        )
        HapticManager.success()
        dismiss()
    }
}
