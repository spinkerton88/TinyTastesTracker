//
//  StatisticsCard.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct StatisticsCard: View {
    let stats: (feedingCount: Int, diaperCount: Int, totalSleepHours: Double)
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 24 Hours")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                StatItem(
                    icon: "spoon.serving",
                    value: "\(stats.feedingCount)",
                    label: "Feedings",
                    color: themeColor,
                    status: feedingStatus
                )
                
                StatItem(
                    icon: "drop.fill",
                    value: "\(stats.diaperCount)",
                    label: "Diapers",
                    color: .blue,
                    status: diaperStatus
                )
                
                StatItem(
                    icon: "moon.zzz.fill",
                    value: String(format: "%.1f", stats.totalSleepHours),
                    label: "Sleep (hrs)",
                    color: .indigo,
                    status: sleepStatus
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var feedingStatus: StatStatus {
        // Expected 8-12 feedings for newborns
        if stats.feedingCount >= 8 { return .good }
        if stats.feedingCount >= 6 { return .caution }
        return .warning
    }
    
    private var diaperStatus: StatStatus {
        // Expected 6-8 diapers for newborns
        if stats.diaperCount >= 6 { return .good }
        if stats.diaperCount >= 4 { return .caution }
        return .warning
    }
    
    private var sleepStatus: StatStatus {
        // Expected 14-17 hours for newborns
        if stats.totalSleepHours >= 12 { return .good }
        if stats.totalSleepHours >= 8 { return .caution }
        return .warning
    }
}

enum StatStatus {
    case good
    case caution
    case warning
    
    var color: Color {
        switch self {
        case .good: return .green
        case .caution: return .yellow
        case .warning: return .orange
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let status: StatStatus
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(color)
            
            Text(value)
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            
            Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            
            Circle()
            .fill(status.color)
            .frame(width: 8, height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value), status: \(status == .good ? "Good" : (status == .caution ? "Caution" : "Warning"))")
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
