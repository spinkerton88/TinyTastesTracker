import SwiftUI

// MARK: - Nursing Timer Card

struct NursingTimerCard: View {
    let side: NursingSide
    let startTime: Date?
    let currentTime: Date
    let themeColor: Color
    let onStart: () -> Void
    let onStop: () -> Void
    
    var isRunning: Bool {
        startTime != nil
    }
    
    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }
        return currentTime.timeIntervalSince(start)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(side.rawValue.capitalized)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(formatTime(elapsedTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced)) // Consider switching to scaled font in future
                .minimumScaleFactor(0.5)
                .foregroundStyle(isRunning ? themeColor : .primary)
            
            Button(action: isRunning ? onStop : onStart) {
                Text(isRunning ? "Stop" : "Start")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.red : themeColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(isRunning ? "Stop \(side.rawValue) side nursing" : "Start \(side.rawValue) side nursing")
            .accessibilityHint(isRunning ? "Double tap to stop the timer" : "Double tap to start the timer")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to log \(label)")
    }
}

// MARK: - Recent Activity List

// RecentActivityList moved to Shared/Components/RecentActivityList.swift

// MARK: - Shared Chart Components

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
