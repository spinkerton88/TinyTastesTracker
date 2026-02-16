//
//  RootView.swift
//  TinyTastesTracker
//
//  Root authentication gate for the app
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var authenticationManager = AuthenticationManager()
    @State private var appState: AppState?
    @AppStorage("isNightMode") private var isNightMode = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showFeatureTour = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

    @State private var hasCheckedInvitations = false

    @ViewBuilder
    private var contentView: some View {
        if let appState = appState {
            if authenticationManager.userSession == nil {
                // Not logged in -> Auth Screen
                AccountSetupView(appState: appState)
            } else if appState.userProfile == nil {
                // Logged in but no child profile
                if !hasCheckedInvitations {
                    // First, check for pending invitations
                    PendingInvitationsCheckView(appState: appState) {
                        // User skipped invitations, proceed to onboarding
                        hasCheckedInvitations = true
                    }
                } else {
                    // Already checked invitations, show normal onboarding
                    OnboardingView(appState: appState)
                }
            } else if !hasLaunchedBefore {
                // Has profile but hasn't completed onboarding -> Show sample data step
                OnboardingView(appState: appState)
            } else {
                // Logged in, has profile, and completed onboarding -> Main App
                ContentView(appState: appState)
            }
        } else {
            // Loading state while initializing
            ProgressView()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline indicator at top
            OfflineIndicatorView()

            contentView
        }
        .environment(\.errorPresenter, appState?.errorPresenter ?? ErrorPresenter())
        .preferredColorScheme(isNightMode ? .dark : nil)
        .withErrorPresentation() // Global error handling
        .onChange(of: appState?.userProfile) { oldValue, newValue in
            // When active profile changes, reload child-specific data
            if let childId = newValue?.id {
                appState?.updateActiveChildData(childId: childId)
            }
        }
        .onAppear {
            // Initialize AppState with AuthenticationManager on first appearance
            if appState == nil {
                appState = AppState(authenticationManager: authenticationManager)
            }

            if let uid = authenticationManager.userSession?.uid {
                appState?.loadData(forUser: uid)
            }
            checkForWidgetLogRequests()
        }
        .onChange(of: authenticationManager.userSession) { oldValue, newValue in
            if let uid = newValue?.uid {
                appState?.loadData(forUser: uid)
            } else {
                // Handle logout cleanup if needed
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkForWidgetLogRequests()
        }
        .fullScreenCover(isPresented: $showFeatureTour) {
            if let appState = appState {
                FeatureTourView(isPresented: $showFeatureTour, appState: appState)
            }
        }
    }

    // MARK: - Widget Intent Handling

    private func checkForWidgetLogRequests() {
        // Check for nursing log request
        if let nursingRequest = WidgetDataManager.consumeLogRequest(type: .nursing) {
            handleNursingLogRequest(requestTime: nursingRequest)
        }

        // Check for diaper log request
        if let diaperRequest = WidgetDataManager.consumeLogRequest(type: .diaper) {
            handleDiaperLogRequest(requestTime: diaperRequest)
        }

        // Check for sleep log request
        if let sleepRequest = WidgetDataManager.consumeLogRequest(type: .sleep) {
            handleSleepLogRequest(requestTime: sleepRequest)
        }

        // Existing bottle log request (if implemented elsewhere, keep it)
        if let defaults = UserDefaults(suiteName: "group.com.tinytastes.tracker"),
           let bottleRequest = defaults.object(forKey: "widgetBottleLogRequest") as? Date {
            defaults.removeObject(forKey: "widgetBottleLogRequest")
            handleBottleLogRequest(requestTime: bottleRequest)
        }
    }

    private func handleNursingLogRequest(requestTime: Date) {
        // Create a default nursing log
        let duration: TimeInterval = 600 // 10 minutes default
        Task {
            try? await appState?.saveNursingLog(
                startTime: requestTime,
                duration: duration,
                side: .left
            )
        }
    }

    private func handleDiaperLogRequest(requestTime: Date) {
        // Create a default diaper log
        Task {
            try? await appState?.saveDiaperLog(
                type: .wet
            )
        }
    }

    private func handleSleepLogRequest(requestTime: Date) {
        // Start sleep tracking or create a completed log
        // For now, create a 2-hour completed sleep log
        let startTime = requestTime.addingTimeInterval(-7200) // 2 hours ago
        Task {
            try? await appState?.saveSleepLog(
                start: startTime,
                end: requestTime,
                quality: .good
            )
        }
    }

    private func handleBottleLogRequest(requestTime: Date) {
        // Create a default bottle log
        Task {
            try? await appState?.saveBottleFeedLog(
                amount: 4.0,
                feedType: .formula,
                notes: nil
            )
        }
    }
}
