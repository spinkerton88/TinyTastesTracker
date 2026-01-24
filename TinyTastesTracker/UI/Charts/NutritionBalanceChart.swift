//
//  NutritionBalanceChart.swift
//  TinyTastesTracker
//
//  Donut chart showing distribution of food categories
//

import SwiftUI
import Charts

struct NutritionBalanceChart: View {
    let categoryData: [CategoryDistribution]
    let themeColor: Color
    

    
    private var totalFoods: Int {
        categoryData.reduce(0) { $0 + $1.count }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if categoryData.isEmpty {
                ContentUnavailableView(
                    "No Food Data",
                    systemImage: "chart.pie",
                    description: Text("Start logging foods to see your nutrition balance")
                )
                .frame(height: 300)
            } else {
                // Donut Chart
                Chart(categoryData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.618),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                }
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 250)
                .overlay {
                    // Center text
                    VStack(spacing: 4) {
                        Text("Total Foods")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(totalFoods)")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                
                // Category breakdown list
                VStack(spacing: 8) {
                    ForEach(categoryData.sorted { $0.count > $1.count }.prefix(5)) { item in
                        HStack {
                            Circle()
                                .fill(item.color.displayColor)
                                .frame(width: 12, height: 12)
                            
                            Text(item.category)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("(\(Int(item.percentage))%)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Nutrition balance showing food categories distribution")
    }
    

}
