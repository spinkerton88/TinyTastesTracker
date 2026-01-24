//
//  RainbowProgressChart.swift
//  TinyTastesTracker
//
//  Bar chart showing "Eat the Rainbow" progress by color category
//

import SwiftUI
import Charts

struct RainbowProgressChart: View {
    let colorProgress: [ColorProgress]
    let themeColor: Color
    

    
    private var weeklyGoal: Int {
        7 // One serving per day
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Rainbow Progress")
                .font(.headline)
            
            if colorProgress.isEmpty {
                ContentUnavailableView(
                    "No Rainbow Data",
                    systemImage: "rainbow",
                    description: Text("Start logging colorful foods")
                )
                .frame(height: 250)
            } else {
                // Horizontal Bar Chart
                Chart {
                    ForEach(colorProgress) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Color", item.color.rawValue.capitalized)
                        )
                        .foregroundStyle(item.color.displayColor)
                        .annotation(position: .trailing) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    
                    // Goal line
                    RuleMark(x: .value("Goal", weeklyGoal))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                        .annotation(position: .top) {
                            Text("Goal: \(weeklyGoal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: 300)
                
                // Progress summary
                HStack {
                    let achievedColors = colorProgress.filter { $0.metGoal }.count
                    let totalColors = colorProgress.count
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Colors Achieved")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(achievedColors)/\(totalColors)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Rainbow emoji if all achieved
                    if achievedColors == totalColors && totalColors > 0 {
                        VStack {
                            Text("🌈")
                                .font(.system(size: 40))
                            Text("Rainbow Complete!")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(themeColor)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rainbow progress chart showing variety of food colors eaten")
    }
}
