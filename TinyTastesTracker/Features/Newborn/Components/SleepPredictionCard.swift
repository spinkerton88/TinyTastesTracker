//
//  SleepPredictionCard.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct SleepPredictionCard: View {
    @Bindable var appState: AppState
    @State private var prediction: SleepPredictionResponse?
    @State private var isLoading = false
    @State private var error: String?
    
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(themeColor)
                Text("AI Sleep Prediction")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    Task {
                        await loadPrediction()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(themeColor)
                }
                .accessibilityLabel("Refresh Sleep Prediction")
                .accessibilityHint("Double tap to calculate new sleep prediction")
                .disabled(isLoading)
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(themeColor)
                    Text("Analyzing sleep patterns...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical)
            } else if let prediction = prediction {
                predictionContent(prediction)
            } else if let error = error {
                errorContent(error)
            } else {
                emptyContent
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            if prediction == nil && appState.sleepLogs.count >= 3 {
                await loadPrediction()
            }
        }
    }
    
    @ViewBuilder
    private func predictionContent(_ pred: SleepPredictionResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if pred.predictionStatus == "Ready", 
               let start = pred.nextSweetSpotStart,
               let end = pred.nextSweetSpotEnd {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Sweet Spot")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(start) - \(end)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    ConfidenceBadge(confidence: pred.confidence)
                }
                .padding()
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(pred.reasoning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Reasoning: \(pred.reasoning)")
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.orange)
                    Text(pred.reasoning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var emptyContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("Tap refresh to predict next sleep window")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func errorContent(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func loadPrediction() async {
        guard appState.sleepLogs.count >= 3 else {
            error = "Need at least 3 sleep logs for prediction"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            prediction = try await appState.predictNextSleepWindow()
            HapticManager.success()
        } catch {
            self.error = "Unable to predict: \(error.localizedDescription)"
            HapticManager.error()
        }
        
        isLoading = false
    }
}

struct ConfidenceBadge: View {
    let confidence: String
    
    var color: Color {
        switch confidence.lowercased() {
        case "high": return .green
        case "medium": return .yellow
        default: return .orange
        }
    }
    
    var body: some View {
        Text(confidence)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
