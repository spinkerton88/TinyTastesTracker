//
//  ContentView.swift
//  TinyTastesTracker
//
//

import SwiftUI
import FirebaseAuth // For listener if needed, but we use AuthManager shared

struct ContentView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            SyncStatusBar()
            MainTabView(appState: appState)
        }
    }
}


struct MainTabView: View {
    @Bindable var appState: AppState
    @State private var showingSage = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Tab Content
            Group {
                if appState.currentMode == .newborn {
                    TabView {
                        NewbornDashboardPage(appState: appState)
                            .tabItem { 
                                Label("Tracking", systemImage: "list.bullet.clipboard.fill") 
                            }
                            .accessibilityLabel("Newborn Log Tab")
                        
                        SleepAndGrowthPage(appState: appState)
                            .tabItem { 
                                Label("Sleep & Growth", systemImage: "moon.fill") 
                            }
                            .accessibilityLabel("Sleep and Growth Tab")
                        
                        SafetyCheckView(appState: appState)
                            .tabItem { 
                                Label("Is It Normal?", systemImage: "checkmark.shield.fill") 
                            }
                            .accessibilityLabel("Safety Check Tab")
                        
                        SettingsPage(appState: appState)
                            .tabItem { 
                                Label("Profile", systemImage: "person.circle.fill") 
                            }
                            .accessibilityLabel("Profile and Settings Tab")
                    }
                    .tint(.pink)
                } else if appState.currentMode == .toddler {
                    TabView {
                        MealBuilderView(appState: appState)
                            .tabItem { Label("Meal Builder", systemImage: "fork.knife.circle.fill") }
                        
                        TrackingTab(mode: .toddler, appState: appState)
                            .tabItem { Label("Tracking", systemImage: "list.bullet.clipboard.fill") }
                        
                        BalancePage(appState: appState)
                            .tabItem { Label("Balance", systemImage: "chart.bar.fill") }
                        
                        RecipesPage(appState: appState)
                            .tabItem { Label("Recipes", systemImage: "book.fill") }
                        
                        SettingsPage(appState: appState)
                            .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                    }
                    .tint(appState.themeColor)
                } else {
                    // Explorer mode
                    TabView {
                        FoodTrackerPage(appState: appState)
                            .tabItem { Label("Foods", systemImage: "fork.knife.circle.fill") }
                        
                        TrackingTab(mode: .explorer, appState: appState)
                            .tabItem { Label("Tracking", systemImage: "list.bullet.clipboard.fill") }
                        
                        RecommendationsView(appState: appState)
                            .tabItem { Label("Recs", systemImage: "sparkles") }
                        
                        RecipesPage(appState: appState)
                            .tabItem { Label("Recipes", systemImage: "book.fill") }
                        
                        SettingsPage(appState: appState)
                            .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                    }
                    .tint(appState.themeColor)
                }
            }
            
            // Floating Sage Button Removed (Handled by SageOverlay)
        }
        .sheet(isPresented: $showingSage) {
            SageView(appState: appState)
        }
    }
}


