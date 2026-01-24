//
//  NutrientIntakeChart.swift
//  TinyTastesTracker
//
//  Horizontal bar chart showing weekly nutrient intake vs. goals
//

import SwiftUI
import Charts

struct NutrientIntakeChart: View {
    let nutrientProgress: [NutrientProgress]
    let themeColor: Color
    

    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Nutrient Intake")
                .font(.headline)
            
            if nutrientProgress.isEmpty {
                ContentUnavailableView(
                    "No Nutrition Data",
                    systemImage: "leaf",
                    description: Text("Start logging meals to track nutrients")
                )
                .frame(height: 250)
            } else {
                // Horizontal Bar Chart
                Chart {
                    ForEach(nutrientProgress) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Nutrient", item.name)
                        )
                        .foregroundStyle(item.metGoal ? Color.green : Color.orange)
                        .foregroundStyle(item.metGoal ? Color.green : Color.orange)
                        .annotation(position: .trailing, alignment: .leading) {
                            HStack(spacing: 4) {
                                Text("\(item.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                if item.metGoal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.leading, 4)
                        }
                        
                        // Goal marker
                        RuleMark(x: .value("Goal", item.weeklyGoal))
                            .foregroundStyle(.gray.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let servings = value.as(Int.self) {
                                Text("\(servings)")
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(nutrientProgress.count * 50 + 50))
                
                chartSummary
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Nutrient intake chart showing weekly progress towards goals")
    }
    
    private var chartSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                let achieved = nutrientProgress.filter { $0.metGoal }.count
                let total = nutrientProgress.count
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrients on Track")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(achieved)/\(total)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Met Goal")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                        Text("Below Goal")
                            .font(.caption)
                    }
                }
            }
            
            // Gaps identified
            let gaps = nutrientProgress.filter { !$0.metGoal }
            if !gaps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus Areas")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(gaps.prefix(3)) { gap in
                        HStack {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(gap.name)
                                .font(.caption)
                            Spacer()
                            Text("\(gap.count)/\(gap.weeklyGoal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
