//
//  SleepPatternsChart.swift
//  TinyTastesTracker
//
//  Bar chart showing sleep duration per day with quality indicators
//

import SwiftUI
import Charts

struct SleepPatternsChart: View {
    let sleepData: [DailySleepData]
    let themeColor: Color
    
    @State private var timeRange: TimeRange = .week
    @State private var selectedDate: Date?
    @State private var selectedDay: DailySleepData?
    
    private var filteredData: [DailySleepData] {
        guard let days = timeRange.days else { return sleepData }
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        return sleepData.filter { $0.date >= cutoffDate }
    }
    
    private var averageSleep: Double {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(0.0) { $0 + $1.totalHours }
        return total / Double(filteredData.count)
    }
    
    private var recommendedSleep: Double {
       12.0 // Recommended hours for infants
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time range selector
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            if filteredData.isEmpty {
                ContentUnavailableView(
                    "No Sleep Data",
                    systemImage: "bed.double",
                    description: Text("Start logging sleep to see patterns")
                )
                .frame(height: 250)
            } else {
                // Bar Chart
                Chart {
                    ForEach(filteredData) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Hours", day.totalHours)
                        )
                        .foregroundStyle(getQualityColor(day.averageQuality))
                        .opacity(selectedDay == nil || selectedDay?.id == day.id ? 1.0 : 0.5)
                    }
                    
                    // Recommended sleep line
                    RuleMark(y: .value("Recommended", recommendedSleep))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Recommended")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    
                    // Average sleep line
                    RuleMark(y: .value("Average", averageSleep))
                        .foregroundStyle(.gray)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .annotation(position: .bottom, alignment: .trailing) {
                            Text("Avg: \(String(format: "%.1f", averageSleep))h")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                            }
                        }
                    }
                }
                .frame(height: 250)
                .chartXSelection(value: $selectedDate)
                .onChange(of: selectedDate) { _, newDate in
                    if let date = newDate {
                        // Find closest day
                        selectedDay = filteredData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
                    } else {
                        selectedDay = nil
                    }
                }
                
                // Quality legend
                HStack(spacing: 16) {
                    ForEach([SleepQuality.excellent, .good, .fair, .poor], id: \.self) { quality in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(getQualityColor(qualityToDouble(quality)))
                                .frame(width: 12, height: 12)
                            Text(quality.rawValue.capitalized)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Summary stats
                HStack(spacing: 16) {
                    StatBox(
                        title: "Average Sleep",
                        value: "\(String(format: "%.1f", averageSleep))h",
                        color: themeColor
                    )
                    
                    StatBox(
                        title: "Total Sessions",
                        value: "\(filteredData.reduce(0) { $0 + $1.sessionCount })",
                        color: .indigo
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sleep patterns chart showing daily sleep duration and quality")
    }
    
    private func getQualityColor(_ quality: Double) -> Color {
        // Map 1-4 scale to colors
        if quality >= 3.5 { return .green }
        if quality >= 2.5 { return .blue }
        if quality >= 1.5 { return .orange }
        return .red
    }
    
    private func qualityToDouble(_ quality: SleepQuality) -> Double {
        switch quality {
        case .poor: return 1.0
        case .fair: return 2.0
        case .good: return 3.0
        case .excellent: return 4.0
        }
    }
}
