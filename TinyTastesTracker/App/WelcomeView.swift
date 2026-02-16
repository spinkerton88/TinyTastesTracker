//
//  WelcomeView.swift
//  TinyTastesTracker
//
//  First-launch welcome screen with sample data option
//

import SwiftUI

struct WelcomeView: View {
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
                    
                Text(NSLocalizedString("onboarding.welcome.pretitle", comment: "Welcome pre-title"))
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text(NSLocalizedString("onboarding.welcome.title", comment: "App title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AccessibilityIdentifiers.Onboarding.welcomeTitle)
                .accessibilityAddTraits(.isHeader)
                
                Text(NSLocalizedString("onboarding.welcome.subtitle", comment: "Welcome subtitle"))
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
                                Text(NSLocalizedString("onboarding.action.sample_data.title", comment: "Sample data button title"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            
                            Text(NSLocalizedString("onboarding.action.sample_data.description", comment: "Sample data button description"))
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
                    .accessibilityLabel(Text(NSLocalizedString("onboarding.action.sample_data.title", comment: "Sample data button title")))
                    .accessibilityHint(Text(NSLocalizedString("onboarding.action.sample_data.accessibility_hint", comment: "Sample data button hint")))
                    
                    // Fresh Start Option
                    Button {
                        startFresh()
                    } label: {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "pencil.circle")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                Text(NSLocalizedString("onboarding.action.start_fresh.title", comment: "Start fresh button title"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            
                            Text(NSLocalizedString("onboarding.action.start_fresh.description", comment: "Start fresh button description"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(NSLocalizedString("onboarding.action.start_fresh.title", comment: "Start fresh button title")))
                    .accessibilityHint(Text(NSLocalizedString("onboarding.action.start_fresh.accessibility_hint", comment: "Start fresh button hint")))
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
                        
                        Text(NSLocalizedString("onboarding.loading.sample_data", comment: "Loading text"))
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
            if let ownerId = appState.currentOwnerId {
                await SampleDataGenerator.generateSampleData(ownerId: ownerId, appState: appState)
                
                // Wait a moment for visual feedback
                try? await Task.sleep(for: .seconds(1))
                
                // Reload app state
                appState.loadData(forUser: ownerId)
            }
            
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
