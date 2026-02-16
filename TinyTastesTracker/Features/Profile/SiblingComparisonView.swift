//
//  SiblingComparisonView.swift
//  TinyTastesTracker
//
//  Compare growth and nutrition across multiple children
//

import SwiftUI
import Charts

struct SiblingComparisonView: View {
    @Bindable var appState: AppState

    @State private var selectedComparison: ComparisonType = .rainbow

    enum ComparisonType: String, CaseIterable {
        case rainbow = "Rainbow Progress"
        case nutrients = "Nutrients"
        case growth = "Growth"

        var icon: String {
            switch self {
            case .rainbow: return "rainbow"
            case .nutrients: return "leaf.fill"
            case .growth: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Comparison Type Picker
            Picker("Comparison Type", selection: $selectedComparison) {
                ForEach(ComparisonType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Comparison Content
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedComparison {
                    case .rainbow:
                        RainbowComparisonView(appState: appState)
                    case .nutrients:
                        NutrientComparisonView(appState: appState)
                    case .growth:
                        GrowthComparisonView(appState: appState)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Compare Siblings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Rainbow Comparison

struct RainbowComparisonView: View {
    @Bindable var appState: AppState
    
    private var nutritionData: [ProfileNutritionData] {
        // TODO: Pass ALL children's meal logs here. Currently only passing active child's logs.
        appState.profileManager.getNutritionComparison(
            measurements: appState.mealLogs,
            allKnownFoods: appState.recipeManager.allKnownFoods
        )
    }

    var body: some View {
        if appState.profileManager.profiles.count < 1 {
            EmptyComparisonView(message: "Add children to compare rainbow progress", appState: appState)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rainbow Progress (This Week)")
                    .font(.headline)

                if appState.mealLogs.isEmpty {
                   Text("No meal data available for the active child.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(nutritionData) { data in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(data.profile.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            ForEach(FoodColor.allCases, id: \.self) { color in
                                RainbowBarSegment(
                                    color: color,
                                    count: data.rainbowProgress[color] ?? 0
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }

                Text("Note: Currently comparing active child data only")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}

struct RainbowBarSegment: View {
    let color: FoodColor
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.secondary)

            RoundedRectangle(cornerRadius: 4)
                .fill(color.displayColor)
                .frame(height: max(20, CGFloat(count) * 10))
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Nutrient Comparison

struct NutrientComparisonView: View {
    @Bindable var appState: AppState
    
    private var nutritionData: [ProfileNutritionData] {
        // TODO: Pass ALL children's meal logs here.
        appState.profileManager.getNutritionComparison(
            measurements: appState.mealLogs,
            allKnownFoods: appState.recipeManager.allKnownFoods
        )
    }

    var body: some View {
        if appState.profileManager.profiles.isEmpty {
            EmptyComparisonView(message: "Add children to compare nutrition", appState: appState)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("Key Nutrients (This Week)")
                    .font(.headline)

                ForEach(Array(Nutrient.allCases), id: \.self) { nutrient in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(nutrient.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Image(systemName: nutrient.icon)
                                .foregroundColor(nutrient.color)
                        }

                        ForEach(nutritionData) { data in
                            let count = data.nutrientCounts[nutrient] ?? 0
                            let maxCount = nutritionData.compactMap { $0.nutrientCounts[nutrient] }.max() ?? 1
                            let widthRatio = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                            
                            HStack {
                                Text(data.profile.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(nutrient.color)
                                            .frame(width: geometry.size.width * widthRatio)
                                    }
                                }
                                .frame(height: 8)

                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
            }
        }
    }
}

// MARK: - Growth Comparison

struct GrowthComparisonView: View {
    @Bindable var appState: AppState

    @State private var selectedMetric: GrowthMetric = .weight
    
    private var growthData: [ProfileGrowthData] {
        // TODO: Pass ALL children's growth logs here.
        appState.profileManager.getGrowthComparison(
            for: selectedMetric,
            growthStore: appState.growthMeasurements
        )
    }

    var body: some View {
        if appState.profileManager.profiles.isEmpty {
            EmptyComparisonView(message: "Add children to compare growth", appState: appState)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Metric", selection: $selectedMetric) {
                    Text("Weight").tag(GrowthMetric.weight)
                    Text("Height").tag(GrowthMetric.height)
                    Text("Head Circumference").tag(GrowthMetric.headCircumference)
                }
                .pickerStyle(.segmented)

                Text("Growth Comparison")
                    .font(.headline)

                Chart {
                    ForEach(growthData, id: \.profile.id) { data in
                        ForEach(data.dataPoints, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(by: .value("Child", data.profile.name))
                            .symbol(by: .value("Child", data.profile.name))
                        }
                    }
                }
                .frame(height: 300)
                .chartYAxisLabel(selectedMetric == .weight ? "Weight (lbs)" : selectedMetric == .height ? "Height (in)" : "Head Circumference (in)")
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                Text("Note: Growth data will be displayed when growth logs are available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyComparisonView: View {
    let message: String
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            NavigationLink(destination: ProfileSwitcherView(appState: appState)) {
                Text("Manage Profiles")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
