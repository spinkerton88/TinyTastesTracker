//
//  DataAggregationService.swift
//  TinyTastesTracker
//
//  Service for aggregating tracking data into pediatrician summaries
//

import Foundation

@MainActor
class DataAggregationService {
    static let shared = DataAggregationService()

    private init() {}

    func generateSummary(
        for childID: String,
        from startDate: Date,
        to endDate: Date,
        appState: AppState
    ) async throws -> PediatricianSummary {
        print("📊 DataAggregationService: Starting data aggregation")

        // Calculate date range in days
        let dayCount = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        print("📅 Date range: \(dayCount) days")

        // Fetch all relevant data (filtering from AppState)
        print("🔍 Fetching sleep logs...")
        let sleepLogs = appState.sleepLogs.filter { log in
            log.startTime >= startDate && log.startTime <= endDate
        }
        print("  Found \(sleepLogs.count) sleep logs")

        print("🔍 Fetching bottle logs...")
        let bottleLogs = appState.bottleFeedLogs.filter { log in
            log.timestamp >= startDate && log.timestamp <= endDate
        }
        print("  Found \(bottleLogs.count) bottle logs")

        print("🔍 Fetching nursing logs...")
        let nursingLogs = appState.nursingLogs.filter { log in
            log.timestamp >= startDate && log.timestamp <= endDate
        }
        print("  Found \(nursingLogs.count) nursing logs")

        print("🔍 Fetching food logs...")
        let triedFoodLogs = appState.foodLogs.filter { log in
            log.date >= startDate && log.date <= endDate && log.isMarkedAsTried
        }
        print("  Found \(triedFoodLogs.count) food logs")

        print("🔍 Fetching diaper logs...")
        let diaperLogs = appState.diaperLogs.filter { log in
            log.timestamp >= startDate && log.timestamp <= endDate
        }
        print("  Found \(diaperLogs.count) diaper logs")

        print("🔍 Fetching growth logs...")
        let growthLogs = appState.growthMeasurements.filter { log in
            log.date >= startDate && log.date <= endDate
        }
        print("  Found \(growthLogs.count) growth logs")

        // Calculate metrics
        print("📈 Calculating metrics...")
        let sleepMetrics = calculateSleepMetrics(from: sleepLogs, dayCount: dayCount)
        let feedingMetrics = calculateFeedingMetrics(
            bottleLogs: bottleLogs,
            nursingLogs: nursingLogs,
            dayCount: dayCount
        )
        let explorerMetrics = calculateExplorerMetrics(from: triedFoodLogs)
        let diaperMetrics = calculateDiaperMetrics(from: diaperLogs, dayCount: dayCount)
        let growthMetrics = calculateGrowthMetrics(from: growthLogs)

        // Only include growth metrics if there's actual data
        let finalGrowthMetrics: GrowthSummaryMetrics? = {
            if growthMetrics.weightChange != nil || growthMetrics.heightChange != nil {
                return growthMetrics
            }
            return nil
        }()

        // Generate AI summary
        print("🤖 Generating AI summary...")
        let aiResponse = try await generateAISummary(
            sleepMetrics: sleepMetrics,
            feedingMetrics: feedingMetrics,
            explorerMetrics: explorerMetrics,
            diaperMetrics: diaperMetrics,
            growthMetrics: finalGrowthMetrics,
            dayCount: dayCount
        )
        print("✅ AI summary generated")

        // Create summary object
        // Assuming ownerId is available in appState
        guard let ownerId = appState.currentOwnerId else {
            throw AppError.unknown(NSError(domain: "DataAggregation", code: 1, userInfo: [NSLocalizedDescriptionKey: "No owner ID found"]))
        }

        let summary = PediatricianSummary(
            ownerId: ownerId,
            childId: childID,
            startDate: startDate,
            endDate: endDate,
            sleepMetrics: sleepMetrics,
            feedingMetrics: feedingMetrics,
            explorerMetrics: explorerMetrics,
            medicationMetrics: nil, // TODO: Add medication tracking
            diaperMetrics: diaperMetrics,
            growthMetrics: finalGrowthMetrics,
            aiSummary: aiResponse.summary,
            highlights: aiResponse.highlights,
            concerns: aiResponse.concerns,
            suggestedQuestions: aiResponse.questions
        )

        print("✅ Summary object created successfully")
        return summary
    }

    // MARK: - Metrics Calculation

    private func calculateSleepMetrics(from logs: [SleepLog], dayCount: Int) -> SleepSummaryMetrics {
        guard !logs.isEmpty else {
            return SleepSummaryMetrics(
                avgNapsPerDay: 0,
                avgNapDuration: 0,
                avgTotalSleepTime: 0,
                longestSleepStretch: 0,
                totalNaps: 0
            )
        }

        let totalNaps = logs.count
        let avgNapsPerDay = Double(totalNaps) / Double(max(dayCount, 1))

        let durations = logs.map { $0.endTime.timeIntervalSince($0.startTime) }
        let totalSleepTime = durations.reduce(0, +)
        let avgNapDuration = totalSleepTime / Double(totalNaps)
        let avgTotalSleepTime = totalSleepTime / Double(max(dayCount, 1))
        let longestSleepStretch = durations.max() ?? 0

        return SleepSummaryMetrics(
            avgNapsPerDay: avgNapsPerDay,
            avgNapDuration: avgNapDuration,
            avgTotalSleepTime: avgTotalSleepTime,
            longestSleepStretch: longestSleepStretch,
            totalNaps: totalNaps
        )
    }

    private func calculateFeedingMetrics(
        bottleLogs: [BottleFeedLog],
        nursingLogs: [NursingLog],
        dayCount: Int
    ) -> FeedingSummaryMetrics {
        let totalFeeds = bottleLogs.count + nursingLogs.count
        let avgFeedsPerDay = Double(totalFeeds) / Double(max(dayCount, 1))

        // Calculate average interval between feeds
        var allFeedTimes: [Date] = []
        allFeedTimes.append(contentsOf: bottleLogs.map { $0.timestamp })
        allFeedTimes.append(contentsOf: nursingLogs.map { $0.timestamp })
        allFeedTimes.sort()

        var intervals: [TimeInterval] = []
        if allFeedTimes.count >= 2 {
            for i in 1..<allFeedTimes.count {
                intervals.append(allFeedTimes[i].timeIntervalSince(allFeedTimes[i-1]))
            }
        }
        let avgFeedingInterval = intervals.isEmpty ? 0 : intervals.reduce(0, +) / Double(intervals.count)

        // Bottle-specific metrics
        let avgBottleVolume: Double? = bottleLogs.isEmpty ? nil :
            bottleLogs.map { $0.amount }.reduce(0, +) / Double(bottleLogs.count)

        // Nursing-specific metrics
        let avgNursingDuration: TimeInterval? = nursingLogs.isEmpty ? nil :
            nursingLogs.map { $0.duration }.reduce(0, +) / Double(nursingLogs.count)

        return FeedingSummaryMetrics(
            avgFeedsPerDay: avgFeedsPerDay,
            avgFeedingInterval: avgFeedingInterval,
            totalFeeds: totalFeeds,
            avgBottleVolume: avgBottleVolume,
            avgNursingDuration: avgNursingDuration
        )
    }

    private func calculateExplorerMetrics(from logs: [TriedFoodLog]) -> ExplorerSummaryMetrics? {
        guard !logs.isEmpty else { return nil }

        // Count unique foods tried (id is the food name or ID)
        let uniqueFoods = Set(logs.map { $0.foodName }) // Should be foodName or ID depending on duplication logic
        let newFoodsTried = uniqueFoods.count

        // Count allergen reactions
        let allergenReactions = logs.filter { $0.allergyReaction != .none }.count

        // Get unique reaction signs
        let reactionSigns = Set(logs.flatMap { $0.reactionSigns }).sorted()

        // For food colors, we'd need to look up each food in the food database
        // For now, return a simple count
        let foodsByColor: [String: Int] = [:] // TODO: Implement color categorization with food database

        return ExplorerSummaryMetrics(
            newFoodsTried: newFoodsTried,
            foodsByColor: foodsByColor,
            allergenReactions: allergenReactions,
            allergenExposures: reactionSigns
        )
    }

    private func calculateDiaperMetrics(from logs: [DiaperLog], dayCount: Int) -> DiaperSummaryMetrics {
        guard !logs.isEmpty else {
            return DiaperSummaryMetrics(
                avgChangesPerDay: 0,
                totalChanges: 0,
                wetDiapers: 0,
                dirtyDiapers: 0
            )
        }

        let totalChanges = logs.count
        let avgChangesPerDay = Double(totalChanges) / Double(max(dayCount, 1))
        let wetDiapers = logs.filter { $0.type == .wet || $0.type == .both }.count
        let dirtyDiapers = logs.filter { $0.type == .dirty || $0.type == .both }.count

        return DiaperSummaryMetrics(
            avgChangesPerDay: avgChangesPerDay,
            totalChanges: totalChanges,
            wetDiapers: wetDiapers,
            dirtyDiapers: dirtyDiapers
        )
    }

    private func calculateGrowthMetrics(from logs: [GrowthMeasurement]) -> GrowthSummaryMetrics {
        let sortedLogs = logs.sorted { $0.date < $1.date }

        guard let firstLog = sortedLogs.first, let lastLog = sortedLogs.last else {
            return GrowthSummaryMetrics(
                startWeight: nil,
                endWeight: nil,
                weightChange: nil,
                startHeight: nil,
                endHeight: nil,
                heightChange: nil
            )
        }

        let weightChange = (lastLog.weight ?? 0) - (firstLog.weight ?? 0)
        let heightChange = (lastLog.height ?? 0) - (firstLog.height ?? 0)

        return GrowthSummaryMetrics(
            startWeight: firstLog.weight,
            endWeight: lastLog.weight,
            weightChange: weightChange,
            startHeight: firstLog.height,
            endHeight: lastLog.height,
            heightChange: heightChange
        )
    }

    // MARK: - AI Summary Generation

    private func generateAISummary(
        sleepMetrics: SleepSummaryMetrics,
        feedingMetrics: FeedingSummaryMetrics,
        explorerMetrics: ExplorerSummaryMetrics?,
        diaperMetrics: DiaperSummaryMetrics,
        growthMetrics: GrowthSummaryMetrics?,
        dayCount: Int
    ) async throws -> (summary: String, highlights: [String], concerns: [String], questions: [String]) {
        let prompt = """
        Generate a professional pediatric summary for a healthcare provider based on the following tracking data over \(dayCount) days:

        SLEEP PATTERNS:
        - Average naps per day: \(String(format: "%.1f", sleepMetrics.avgNapsPerDay))
        - Average nap duration: \(formatDuration(sleepMetrics.avgNapDuration))
        - Average total sleep time: \(formatDuration(sleepMetrics.avgTotalSleepTime))
        - Longest sleep stretch: \(formatDuration(sleepMetrics.longestSleepStretch))

        FEEDING:
        - Average feeds per day: \(String(format: "%.1f", feedingMetrics.avgFeedsPerDay))
        - Average feeding interval: \(formatDuration(feedingMetrics.avgFeedingInterval))
        \(feedingMetrics.avgBottleVolume.map { "- Average bottle volume: \(String(format: "%.1f", $0)) oz" } ?? "")
        \(feedingMetrics.avgNursingDuration.map { "- Average nursing duration: \(formatDuration($0))" } ?? "")

        \(explorerMetrics.map { metrics in
            """
            FOOD EXPLORATION:
            - New foods tried: \(metrics.newFoodsTried)
            - Rainbow variety: \(metrics.foodsByColor.values.reduce(0, +)) foods across \(metrics.foodsByColor.count) color categories
            - Allergen exposures: \(metrics.allergenExposures.joined(separator: ", "))
            - Allergen reactions: \(metrics.allergenReactions)
            """
        } ?? "")

        DIAPER CHANGES:
        - Average changes per day: \(String(format: "%.1f", diaperMetrics.avgChangesPerDay))
        - Wet diapers: \(diaperMetrics.wetDiapers)
        - Dirty diapers: \(diaperMetrics.dirtyDiapers)

        \(growthMetrics != nil && (growthMetrics!.weightChange != nil || growthMetrics!.heightChange != nil) ? """
        GROWTH:
        \(growthMetrics!.weightChange.map { "- Weight change: \(String(format: "%.2f", $0)) kg" } ?? "")
        \(growthMetrics!.heightChange.map { "- Height change: \(String(format: "%.1f", $0)) cm" } ?? "")
        """ : "")

        Please provide:
        1. A concise professional summary (2-3 paragraphs) suitable for a pediatrician
        2. Key highlights (3-5 bullet points of positive developments)
        3. Any concerns or unusual patterns (if any, otherwise empty list)
        4. Suggested questions for the pediatrician (5-7 specific questions the parent should ask based on the data, age-appropriate milestones, and any concerns)

        Format your response as JSON:
        {
          "summary": "...",
          "highlights": ["...", "...", "..."],
          "concerns": ["...", "..."],
          "questions": ["...", "...", "...", "...", "..."]
        }
        """

        let response = try await GeminiService().generateText(prompt: prompt)
        return try parseAIResponse(response)
    }

    private func parseAIResponse(_ response: String) throws -> (summary: String, highlights: [String], concerns: [String], questions: [String]) {
        // Extract JSON from response (may be wrapped in markdown code blocks)
        let jsonString = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = json["summary"] as? String else {
            // Fallback if parsing fails
            return (
                summary: response,
                highlights: ["Data successfully aggregated"],
                concerns: [],
                questions: [
                    "Are my baby's growth measurements on track?",
                    "Is the feeding schedule appropriate for their age?",
                    "Are there any developmental milestones I should be watching for?",
                    "Should I be concerned about any patterns in the data?"
                ]
            )
        }

        let highlights = json["highlights"] as? [String] ?? []
        let concerns = json["concerns"] as? [String] ?? []
        let questions = json["questions"] as? [String] ?? [
            "Are my baby's growth measurements on track?",
            "Is the feeding schedule appropriate for their age?",
            "Are there any developmental milestones I should be watching for?"
        ]

        return (summary: summary, highlights: highlights, concerns: concerns, questions: questions)
    }

    // MARK: - Helper Methods

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
