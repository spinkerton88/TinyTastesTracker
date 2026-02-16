//
//  GrowthChart.swift
//  TinyTastesTracker
//
//  Growth tracking chart showing weight, height, and head circumference over time
//

import SwiftUI
import Charts

struct GrowthChart: View {
    let measurements: [GrowthMeasurement]
    let themeColor: Color
    let appState: AppState
    
    @State private var selectedDate: Date?
    @State private var selectedMeasurement: GrowthMeasurement?
    @State private var selectedMetric: GrowthMetric = .weight
    @State private var showingExportSheet = false
    @State private var exportedImage: UIImage?
    @State private var showPercentiles = false
    @State private var showPredictions = false
    @State private var predictions: [TrendPrediction] = []
    @State private var aiInsight: TrendInsight?
    @State private var isLoadingPredictions = false
    
    enum GrowthMetric: String, CaseIterable {
        case weight = "Weight"
        case height = "Height"
        case headCirc = "Head Circ."
        
        var unit: String {
            switch self {
            case .weight: return "lbs"
            case .height, .headCirc: return "in"
            }
        }
        
        var color: Color {
            switch self {
            case .weight: return .blue
            case .height: return .green
            case .headCirc: return .purple
            }
        }
    }
    
    init(measurements: [GrowthMeasurement], themeColor: Color, appState: AppState) {
        self.measurements = measurements
        self.themeColor = themeColor
        self.appState = appState
    }
    
    private var sortedMeasurements: [GrowthMeasurement] {
        measurements.sorted { $0.date < $1.date }
    }
    
    private var dataPoints: [(Date, Double)] {
        sortedMeasurements.compactMap { measurement in
            let value: Double?
            switch selectedMetric {
            case .weight:
                value = measurement.weight
            case .height:
                value = measurement.height
            case .headCirc:
                value = measurement.headCircumference
            }
            
            if let value = value {
                return (measurement.date, value)
            }
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Metric Selector
            Picker("Metric", selection: $selectedMetric) {
                ForEach(GrowthMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            
            // WHO Percentiles toggle (only for weight and height)
            if selectedMetric != .headCirc, appState.userProfile?.gender != nil {
                Toggle("Show WHO Percentiles", isOn: $showPercentiles)
                .toggleStyle(.switch)
                .font(.caption)
            }
            
            // Predictions toggle (needs at least 3 data points)
            if dataPoints.count >= 3 {
                Toggle(isOn: $showPredictions) {
                    HStack {
                        Text("Show Predictions")
                        if isLoadingPredictions {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                .toggleStyle(.switch)
                .font(.caption)
                .onChange(of: showPredictions) { _, newValue in
                    if newValue {
                        Task {
                            await generatePredictions()
                        }
                    }
                }
            }
            
            if dataPoints.isEmpty {
                ContentUnavailableView(
                    "No \(selectedMetric.rawValue) Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Start logging growth measurements to see your chart")
                )
                .frame(height: 250)
            } else {
                // Chart
                Chart {
                    ForEach(dataPoints, id: \.0) { date, value in
                        LineMark(
                            x: .value("Date", date),
                            y: .value(selectedMetric.rawValue, value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(selectedMetric.color)
                        
                        PointMark(
                            x: .value("Date", date),
                            y: .value(selectedMetric.rawValue, value)
                        )
                        .foregroundStyle(selectedMetric.color)
                        .symbolSize(120) // Increased for better legibility (HIG)
                    }
                    
                    // Selection indicator
                    if let selected = selectedMeasurement,
                       let value = getValue(from: selected) {
                        RuleMark(x: .value("Selected", selected.date))
                            .foregroundStyle(.gray.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        
                        PointMark(
                            x: .value("Date", selected.date),
                            y: .value(selectedMetric.rawValue, value)
                        )
                        .foregroundStyle(selectedMetric.color)
                        .symbolSize(100)
                    }
                    
                    // WHO Percentile curves
                    if showPercentiles, let profile = appState.userProfile {
                        percentileOverlays(for: profile)
                    }
                    
                    // Prediction overlays
                    if showPredictions, !predictions.isEmpty {
                        ForEach(Array(predictions.enumerated()), id: \.offset) { _, prediction in
                            // Prediction line
                            LineMark(
                                x: .value("Date", prediction.futurePoint.date),
                                y: .value(selectedMetric.rawValue, prediction.futurePoint.value)
                            )
                            .foregroundStyle(selectedMetric.color.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            
                            // Confidence interval (area)
                            let interval = TrendAnalyzer.calculateConfidenceInterval(prediction: prediction)
                            AreaMark(
                                x: .value("Date", prediction.futurePoint.date),
                                yStart: .value("Lower", interval.lower),
                                yEnd: .value("Upper", interval.upper)
                            )
                            .foregroundStyle(selectedMetric.color.opacity(0.1))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: getXAxisStride())) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue)) \(selectedMetric.unit)")
                            }
                        }
                    }
                }
                .frame(height: 250)
                .chartXSelection(value: $selectedDate)
                .onChange(of: selectedDate) { _, newDate in
                    if let date = newDate {
                        // Find closest measurement
                        selectedMeasurement = measurements.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
                    } else {
                        selectedMeasurement = nil
                    }
                }
                
                // Latest value display
                if let latest = dataPoints.last {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Measurement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Text("\(String(format: "%.1f", latest.1)) \(selectedMetric.unit)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(selectedMetric.color)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Text(latest.0.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // AI Insight Card
                if showPredictions, let insight = aiInsight {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image("sage.leaf.sprig")
                                .foregroundStyle(.purple)
                            Text("Growth Insights")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text(insight.summary)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        if !insight.recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recommendations:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                ForEach(insight.recommendations, id: \.self) { rec in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                        Text(rec)
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                        
                        if let alerts = insight.alerts, !alerts.isEmpty {
                            ForEach(alerts, id: \.self) { alert in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text(alert)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Export button
            if !dataPoints.isEmpty {
                Button {
                    exportChart()
                } label: {
                    Label("Export Chart", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(themeColor)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Growth chart showing \(selectedMetric.rawValue) over time")
        .sheet(isPresented: $showingExportSheet) {
            if let image = exportedImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    private func exportChart() {
        let metadata = ExportMetadata(
            babyName: appState.userProfile?.name ?? "Baby",
            ageMonths: appState.userProfile?.ageInMonths ?? 0,
            chartType: "Growth Chart - \(selectedMetric.rawValue)",
            dateRange: nil
        )
        
        let chartView = self
        
        Task { @MainActor in
            if let image = ChartExporter.exportChart(chartView, metadata: metadata) {
                exportedImage = image
                showingExportSheet = true
                HapticManager.success()
            }
        }
    }
    
    private func getValue(from measurement: GrowthMeasurement) -> Double? {
        switch selectedMetric {
        case .weight: return measurement.weight
        case .height: return measurement.height
        case .headCirc: return measurement.headCircumference
        }
    }
    
    private func getXAxisStride() -> Int {
        let count = dataPoints.count
        if count <= 5 { return 1 }
        if count <= 15 { return 3 }
        return 7
    }
    
    struct PercentilePoint: Identifiable {
        let id = UUID()
        let ageMonths: Int
        let value: Double
    }
    
    @ChartContentBuilder
    private func percentileOverlays(for profile: ChildProfile) -> some ChartContent {
        let whoMetric = mapToWHOMetric(selectedMetric)
        
        // Get birth date and calculate age range for percentile curves
        let birthDate = profile.birthDate
        
        // Show percentile curves for P3, P50, P97
        ForEach([3, 50, 97], id: \.self) { percentile in
            let curveData = WHOPercentiles.getPercentileCurve(
                metric: whoMetric,
                gender: profile.gender,
                percentile: percentile
            ).map { PercentilePoint(ageMonths: $0.ageMonths, value: $0.value) }
            
            ForEach(curveData) { point in
                let date = Calendar.current.date(byAdding: .month, value: point.ageMonths, to: birthDate) ?? Date()
                
                LineMark(
                    x: .value("Age", date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.gray.opacity(percentile == 50 ? 0.4 : 0.2))
                .lineStyle(StrokeStyle(lineWidth: percentile == 50 ? 1.5 : 1, dash: [4, 2]))
            }
        }
    }
    
    private func mapToWHOMetric(_ metric: GrowthMetric) -> WHOGrowthMetric {
        switch metric {
        case .weight: return .weightForAge
        case .height: return .lengthForAge
        case .headCirc: return .headCircForAge
        }
    }
    
    private func generatePredictions() async {
        isLoadingPredictions = true
        defer { isLoadingPredictions = false }
        
        // Statistical predictions
        let analysis = TrendAnalyzer.analyzeTrendDirection(dataPoints: dataPoints)
        predictions = analysis.predictions
        
        // AI insights (optional - only if API key available)
        if appState.geminiApiKey != nil, let currentValue = dataPoints.last?.1 {
            do {
                let insight = try await appState.geminiService.analyzeTrend(
                    dataType: selectedMetric.rawValue,
                    currentValue: currentValue,
                    historicalValues: dataPoints,
                    unit: selectedMetric.unit,
                    ageInMonths: appState.userProfile?.ageInMonths ?? 0
                )
                await MainActor.run {
                    aiInsight = insight
                }
            } catch {
                print("Failed to get AI insights: \(error)")
                // Still show statistical predictions even if AI fails
            }
        }
    }
}
