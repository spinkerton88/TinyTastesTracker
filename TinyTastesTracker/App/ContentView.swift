//
//  ContentView.swift
//  TinyTastesTracker
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()
    @AppStorage("isNightMode") private var isNightMode = false
    @State private var showFeatureTour = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline indicator at top
            OfflineIndicatorView()
            
            Group {
                if appState.userAccount == nil {
                    AccountSetupView(appState: appState)
                } else if appState.userProfile == nil {
                    OnboardingView(appState: appState)
                } else {
                    MainTabView(appState: appState)
                }
            }
        }
        .preferredColorScheme(isNightMode ? .dark : nil)
        .withErrorPresentation() // Global error handling
        .onAppear {
            appState.loadData(context: modelContext)
            checkForWidgetLogRequests()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkForWidgetLogRequests()
        }
        .fullScreenCover(isPresented: $showFeatureTour) {
            FeatureTourView(isPresented: $showFeatureTour, appState: appState)
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
        appState.saveNursingLog(
            startTime: requestTime,
            duration: duration,
            side: .left,
            context: modelContext
        )
    }

    private func handleDiaperLogRequest(requestTime: Date) {
        // Create a default diaper log
        appState.saveDiaperLog(
            type: .wet,
            context: modelContext
        )
    }

    private func handleSleepLogRequest(requestTime: Date) {
        // Start sleep tracking or create a completed log
        // For now, create a 2-hour completed sleep log
        let startTime = requestTime.addingTimeInterval(-7200) // 2 hours ago
        appState.saveSleepLog(
            start: startTime,
            end: requestTime,
            quality: .good,
            context: modelContext
        )
    }

    private func handleBottleLogRequest(requestTime: Date) {
        // Create a default bottle log
        appState.saveBottleFeedLog(
            amount: 4.0,
            feedType: .formula,
            notes: nil,
            context: modelContext
        )
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

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    
    @State private var selectedMode: AppMode?
    @State private var babyName = ""
    @State private var birthDate = Date()
    @State private var selectedGender: Gender = .other
    
    // Validation state
    @State private var validationError: String?
    @State private var showingModeMismatchAlert = false
    @State private var isCreatingProfile = false
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            if selectedMode == nil {
                // Step 1: Mode Selection
                modeSelectionView
            } else {
                // Step 2: Profile Setup
                profileSetupView
            }
        }
    }
    
    private var modeSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("Welcome to Tiny Tastes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Let's personalize your experience. Which stage is your little one in?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            .accessibilityElement(children: .combine)
            
            VStack(spacing: 16) {
                // Newborn Mode Card
                ModeCard(
                    title: "Newborn",
                    subtitle: "0-6 Months",
                    icon: "moon.stars.fill",
                    color: .pink,
                    action: { 
                        withAnimation {
                            selectedMode = .newborn
                            birthDate = Date() // Default to today
                        }
                    }
                )
                
                // Explorer Mode Card
                ModeCard(
                    title: "Explorer",
                    subtitle: "6-12 Months",
                    icon: "fork.knife.circle.fill",
                    color: Color(red: 13/255, green: 148/255, blue: 136/255),
                    action: { 
                        withAnimation {
                            selectedMode = .explorer
                            birthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date())! // Default to 8 months
                        }
                    }
                )
                
                // Toddler Mode Card
                ModeCard(
                    title: "Toddler",
                    subtitle: "12+ Months",
                    icon: "fork.knife",
                    color: .blue,
                    action: { 
                        withAnimation {
                            selectedMode = .toddler
                            birthDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())! // Default to 1 year
                        }
                    }
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var profileSetupView: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: modeIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(modeColor)
                    
                    Text("Tell us about your little one")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)
            
            Section {
                TextField("Baby's Name", text: $babyName)
                    .focused($isNameFieldFocused)
                    .accessibilityLabel(AccessibilityIdentifiers.Onboarding.babyNameField)
                    .accessibilityHint("Enter your baby's name")
                    .onChange(of: babyName) { oldValue, newValue in
                        // Clear validation error when user starts typing
                        if validationError != nil {
                            validationError = nil
                        }
                    }
                
                DatePicker(
                    "Birthdate",
                    selection: $birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .accessibilityLabel(AccessibilityIdentifiers.Onboarding.birthdateField)
                .accessibilityHint("Select your baby's birth date")
                .onChange(of: birthDate) { oldValue, newValue in
                    // Clear validation error when user changes date
                    if validationError != nil {
                        validationError = nil
                    }
                }
                
                Picker("Gender", selection: $selectedGender) {
                    Text("Boy").tag(Gender.boy)
                    Text("Girl").tag(Gender.girl)
                    Text("Other").tag(Gender.other)
                }
                .pickerStyle(.segmented)
                
                // Show validation error if present
                if let error = validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Error: \(error)")
                }
            }
            
            Section {
                Button(action: validateAndCreateProfile) {
                    HStack {
                        Spacer()
                        if isCreatingProfile {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Get Started")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(babyName.isEmpty || isCreatingProfile)
                .listRowBackground(babyName.isEmpty ? Color.gray.opacity(0.3) : appState.themeColor)
                .foregroundStyle(.white)
            }
        }
        .navigationTitle("Profile Setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    withAnimation {
                        selectedMode = nil
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
        .alert("Mode Mismatch", isPresented: $showingModeMismatchAlert) {
            Button("Continue Anyway") {
                createProfile()
            }
            Button("Go Back", role: .cancel) {
                // User can adjust birthdate or mode
            }
        } message: {
            let suggestedMode = OnboardingValidator.suggestedMode(for: birthDate)
            let age = OnboardingValidator.formatAge(from: birthDate)
            Text("Your baby is \(age). We recommend \(suggestedMode.rawValue.capitalized) mode for this age. Would you like to continue with \(selectedMode?.rawValue.capitalized ?? "the selected") mode anyway?")
        }
    }
    
    private var modeIcon: String {
        switch selectedMode {
        case .newborn: return "moon.stars.fill"
        case .explorer: return "fork.knife.circle.fill"
        case .toddler: return "fork.knife"
        case .none: return "person.fill"
        }
    }
    
    private var modeColor: Color {
        switch selectedMode {
        case .newborn: return .pink
        case .explorer: return Color(red: 13/255, green: 148/255, blue: 136/255)
        case .toddler: return .blue
        case .none: return .gray
        }
    }
    
    // MARK: - Validation and Profile Creation
    
    private func validateAndCreateProfile() {
        // Validate profile data
        let validation = OnboardingValidator.validateProfile(
            name: babyName,
            birthDate: birthDate,
            gender: selectedGender,
            mode: selectedMode ?? .newborn
        )
        
        // Check for hard errors
        if !validation.isValid {
            validationError = validation.errorMessage
            
            // Track validation failure
            if let error = validation.errors.first {
                OnboardingValidator.trackValidationFailure(error)
            }
            
            // Announce error to VoiceOver users
            if let error = validationError {
                AccessibilityManager.shared.announce("Error: \(error)")
            }
            
            return
        }
        
        // Check for mode mismatch warning
        let modeValidation = OnboardingValidator.validateModeForAge(
            mode: selectedMode ?? .newborn,
            birthDate: birthDate
        )
        
        if !modeValidation.errors.isEmpty {
            // Show alert for mode mismatch
            showingModeMismatchAlert = true
            return
        }
        
        // All validation passed, create profile
        createProfile()
    }
    
    private func createProfile() {
        isCreatingProfile = true
        validationError = nil
        
        // Track analytics
        let ageInMonths = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
        AnalyticsService.shared.trackProfileCreated(
            ageInMonths: ageInMonths,
            gender: selectedGender.rawValue
        )
        AnalyticsService.shared.trackModeSelected(mode: selectedMode?.rawValue ?? "auto")
        
        // Create profile with error handling
        appState.profileManager.createProfile(
            name: babyName,
            birthDate: birthDate,
            gender: selectedGender,
            allergies: nil,
            context: modelContext
        )
        
        isCreatingProfile = false
    }
}

struct ModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: icon)
                            .font(.largeTitle)
                            .foregroundStyle(color)
                    }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .accessibilityLabel("\(title) mode, for babies \(subtitle)")
        .accessibilityHint("Double tap to select \(title) mode")
    }
}
