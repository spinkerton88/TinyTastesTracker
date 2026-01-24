//
//  WelcomeView.swift
//  TinyTastesTracker
//
//  First-launch welcome screen with sample data option
//

import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @Bindable var appState: AppState
    
    @State private var isLoadingSampleData = false
    
    var body: some View {
        ZStack {
            // Clean background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Icon/Logo
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80)) // Keep large for icon
                        .foregroundStyle(.purple)
                        .background(
                            Circle()
                                .fill(.purple.opacity(0.1))
                                .frame(width: 140, height: 140)
                        )
                        .accessibilityHidden(true) // Decorative
                    
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("Tiny Tastes Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AccessibilityIdentifiers.Onboarding.welcomeTitle)
                .accessibilityAddTraits(.isHeader)
                
                Text("Track your little one's feeding journey with AI-powered guidance")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Options
                VStack(spacing: 16) {
                    // Sample Data Option
                    Button {
                        loadSampleData()
                    } label: {
                        VStack(spacing: 12) {
                            HStack {
                                Image("sage.leaf.sprig")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(.purple)
                                Text("Explore with Sample Data")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("See how the app works with realistic data")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Explore with Sample Data")
                    .accessibilityHint("Loads realistic sample data to explore app features")
                    
                    // Fresh Start Option
                    Button {
                        startFresh()
                    } label: {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "pencil.circle")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                Text("Start Fresh")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("Add your own data from scratch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start Fresh")
                    .accessibilityHint("Begin with empty data and add your own information")
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding()
            
            // Loading overlay
            if isLoadingSampleData {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Loading sample data...")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.trackOnboardingStarted()
        }
    }
    
    // MARK: - Actions
    
    private func loadSampleData() {
        isLoadingSampleData = true
        
        // Generate sample data on main actor
        Task { @MainActor in
            // Generate sample data
            SampleDataGenerator.generateSampleData(context: modelContext)
            
            // Wait a moment for visual feedback
            try? await Task.sleep(for: .seconds(1))
            
            // Reload app state
            appState.loadData(context: modelContext)
            
            // Mark as using sample data
            UserDefaults.standard.set(true, forKey: "isUsingSampleData")
            
            // Mark as launched
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            
            isLoadingSampleData = false
            isPresented = false
            
            // Track completion and dismiss
            AnalyticsService.shared.trackOnboardingCompleted(usedSampleData: true)
            AnalyticsService.shared.trackSampleDataLoaded(source: "welcome_screen")
        }
    }
    
    private func startFresh() {
        // Track analytics
        AnalyticsService.shared.trackOnboardingCompleted(usedSampleData: false)
        
        // Just mark as launched, no data generation
        UserDefaults.standard.set(false, forKey: "isUsingSampleData")
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        isPresented = false
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true), appState: AppState())
}
