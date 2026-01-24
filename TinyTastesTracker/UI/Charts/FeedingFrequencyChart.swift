//
//  FeedingFrequencyChart.swift
//  TinyTastesTracker
//
//  Stacked bar chart showing nursing and bottle feeding patterns over time
//

import SwiftUI
import Charts

struct FeedingFrequencyChart: View {
    let feedingData: [DailyFeedingData]
    let themeColor: Color
    let appState: AppState
    
    @State private var timeRange: TimeRange = .week
    @State private var selectedDay: DailyFeedingData?
    
    private var filteredData: [DailyFeedingData] {
        guard let days = timeRange.days else { return feedingData }
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)
        return feedingData.filter { $0.date >= cutoffDate }
    }
    
    private var averageFeedings: Double {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(0) { $0 + $1.totalCount }
        return Double(total) / Double(filteredData.count)
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
                    "No Feeding Data",
                    systemImage: "chart.bar",
                    description: Text("Start logging feedings to see patterns")
                )
                .frame(height: 250)
            } else {
                // Stacked Bar Chart
                Chart {
                    ForEach(filteredData) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Count", day.nursingCount)
                        )
                        .foregroundStyle(by: .value("Type", "Nursing"))
                        .position(by: .value("Type", "Nursing"))
                        
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Count", day.bottleCount)
                        )
                        .foregroundStyle(by: .value("Type", "Bottle"))
                        .position(by: .value("Type", "Bottle"))
                    }
                    
                    // Average line
                    RuleMark(y: .value("Average", averageFeedings))
                        .foregroundStyle(.gray)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Avg: \(String(format: "%.1f", averageFeedings))")
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
                        AxisValueLabel()
                    }
                }
                .chartForegroundStyleScale([
                    "Nursing": themeColor,
                    "Bottle": Color.cyan
                ])
                .chartLegend(position: .top, alignment: .trailing)
                .frame(height: 250)
                
                // Summary stats
                HStack(spacing: 24) {
                    StatBox(
                        title: "Total Feedings",
                        value: "\(filteredData.reduce(0) { $0 + $1.totalCount })",
                        color: .primary
                    )
                    
                    StatBox(
                        title: "Nursing",
                        value: "\(filteredData.reduce(0) { $0 + $1.nursingCount })",
                        color: themeColor
                    )
                    
                    StatBox(
                        title: "Bottle",
                        value: "\(filteredData.reduce(0) { $0 + $1.bottleCount })",
                        color: .cyan
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Feeding frequency chart showing nursing and bottle feeding patterns")
    }
}


