//
//  NewbornPage.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct NewbornPage: View {
    @Bindable var appState: AppState
    
    @State private var leftTimerStart: Date?
    @State private var rightTimerStart: Date?
    @State private var currentTime = Date()
    @State private var showingSleepSheet = false
    @State private var showingBottleFeedSheet = false
    @State private var showingGrowthSheet = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Statistics Card
                    StatisticsCard(stats: appState.last24HourStats, themeColor: appState.themeColor)
                    
                    // Sleep Prediction Card
                    SleepPredictionCard(appState: appState, themeColor: appState.themeColor)
                    
                    // Nursing Timers Section
                    nursingSection
                    
                    // Quick Actions Section
                    quickLogSection
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("Newborn Care")
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .sheet(isPresented: $showingSleepSheet) {
                SleepLogSheet(appState: appState)
            }
            .sheet(isPresented: $showingBottleFeedSheet) {
                BottleFeedSheet(appState: appState)
            }
            .sheet(isPresented: $showingGrowthSheet) {
                GrowthTrackingSheet(appState: appState)
            }
        }
    }
    
    // MARK: - Sub-Sections
    
    @ViewBuilder
    private var nursingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nursing")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                NursingTimerCard(
                    side: .left,
                    startTime: leftTimerStart,
                    currentTime: currentTime,
                    themeColor: appState.themeColor,
                    onStart: {
                        HapticManager.impact()
                        leftTimerStart = Date()
                    },
                    onStop: {
                        if let start = leftTimerStart {
                            let duration = Date().timeIntervalSince(start)
                            Task {
                                try? await appState.saveNursingLog(startTime: start, duration: duration, side: .left)
                            }
                            leftTimerStart = nil
                            HapticManager.success()
                        }
                    }
                )
                
                NursingTimerCard(
                    side: .right,
                    startTime: rightTimerStart,
                    currentTime: currentTime,
                    themeColor: appState.themeColor,
                    onStart: {
                        HapticManager.impact()
                        rightTimerStart = Date()
                    },
                    onStop: {
                        if let start = rightTimerStart {
                            let duration = Date().timeIntervalSince(start)
                            Task {
                                try? await appState.saveNursingLog(startTime: start, duration: duration, side: .right)
                            }
                            rightTimerStart = nil
                            HapticManager.success()
                        }
                    }
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Log")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionButton(
                    icon: "drop.fill",
                    label: "Wet",
                    color: .blue,
                    action: {
                        HapticManager.impact()
                        Task {
                            try? await appState.saveDiaperLog(type: .wet)
                        }
                        HapticManager.success()
                    }
                )
                
                QuickActionButton(
                    icon: "circle.fill",
                    label: "Dirty",
                    color: .brown,
                    action: {
                        HapticManager.impact()
                        Task {
                            try? await appState.saveDiaperLog(type: .dirty)
                        }
                        HapticManager.success()
                    }
                )
                
                QuickActionButton(
                    icon: "drop.circle.fill",
                    label: "Both",
                    color: .orange,
                    action: {
                        HapticManager.impact()
                        Task {
                            try? await appState.saveDiaperLog(type: .both)
                        }
                        HapticManager.success()
                    }
                )
                
                QuickActionButton(
                    icon: "moon.zzz.fill",
                    label: "Sleep",
                    color: appState.themeColor,
                    action: {
                        HapticManager.selection()
                        showingSleepSheet = true
                    }
                )
                
                QuickActionButton(
                    icon: "baby.bottle.fill",
                    label: "Bottle",
                    color: .cyan,
                    action: {
                        HapticManager.selection()
                        showingBottleFeedSheet = true
                    }
                )
                
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Growth",
                    color: .green,
                    action: {
                        HapticManager.selection()
                        showingGrowthSheet = true
                    }
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
            
            RecentActivityList(appState: appState)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Nursing Timer Card

// NursingTimerCard moved to Components/NewbornComponents.swift

// MARK: - Quick Action Button

// QuickActionButton moved to Components/NewbornComponents.swift

// MARK: - Recent Activity List

// RecentActivityList moved to Components/NewbornComponents.swift


