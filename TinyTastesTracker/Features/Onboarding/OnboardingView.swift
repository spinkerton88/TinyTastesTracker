//
//  OnboardingView.swift
//  TinyTastesTracker
//
//  Child profile creation flow
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState

    @State private var currentStep = 1 // 1: Mode, 2: Profile, 3: Sample Data
    @State private var selectedMode: AppMode?
    @State private var babyName = ""
    @State private var birthDate = Date()
    @State private var selectedGender: Gender = .other

    // Validation state
    @State private var validationError: String?
    @State private var showingModeMismatchAlert = false
    @State private var isCreatingProfile = false
    @State private var isLoadingSampleData = false
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            if currentStep == 1 {
                // Step 1: Mode Selection
                modeSelectionView
            } else if currentStep == 2 {
                // Step 2: Profile Setup
                profileSetupView
            } else {
                // Step 3: Sample Data
                sampleDataView
            }
        }
        .onAppear {
            // If profile already exists, skip to step 3
            if appState.userProfile != nil && !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
                currentStep = 3
            }
        }
    }
    
    private var modeSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(AccessibilityIdentifiers.Onboarding.welcomeTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.welcomeTitle)
                    .accessibilityAddTraits(.isHeader)
                
                Text(AccessibilityIdentifiers.Onboarding.welcomeSubtitle)
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
                            currentStep = 2
                        }
                    }
                )
                .accessibilityIdentifier("mode_newborn")

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
                            currentStep = 2
                        }
                    }
                )
                .accessibilityIdentifier("mode_explorer")

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
                            currentStep = 2
                        }
                    }
                )
                .accessibilityIdentifier("mode_toddler")
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
                    .accessibilityIdentifier("baby_name_field")
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
                .accessibilityIdentifier("Complete Profile")
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
                        currentStep = 1
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
        // Validation logic unchanged...
        let validation = OnboardingValidator.validateProfile(
            name: babyName,
            birthDate: birthDate,
            gender: selectedGender,
            mode: selectedMode ?? .newborn
        )
        
        if !validation.isValid {
            validationError = validation.errorMessage
            if let error = validation.errors.first {
                OnboardingValidator.trackValidationFailure(error)
            }
            if let error = validationError {
                AccessibilityManager.shared.announce("Error: \(error)")
            }
            return
        }
        
        let modeValidation = OnboardingValidator.validateModeForAge(
            mode: selectedMode ?? .newborn,
            birthDate: birthDate
        )
        
        if !modeValidation.errors.isEmpty {
            showingModeMismatchAlert = true
            return
        }
        
        createProfile()
    }
    
    private func createProfile() {
        isCreatingProfile = true
        validationError = nil

        guard let ownerId = appState.authenticationManager.userSession?.uid else {
             // Handle error - not logged in?
             isCreatingProfile = false
             validationError = "Not signed in"
             return
        }
        
        // Track analytics
        let ageInMonths = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
        AnalyticsService.shared.trackProfileCreated(
            ageInMonths: ageInMonths,
            gender: selectedGender.rawValue
        )
        AnalyticsService.shared.trackModeSelected(mode: selectedMode?.rawValue ?? "auto")
        
        // Create profile using ProfileManager
        appState.profileManager.createProfile(
            name: babyName,
            birthDate: birthDate,
            gender: selectedGender,
            allergies: nil,
            ownerId: ownerId
        )
        
        // ProfileManager listener will update appState.userProfile automatically
        // Wait a moment for the profile to be created and listener to fire
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCreatingProfile = false
            // Move to sample data step instead of auto-transitioning
            withAnimation {
                currentStep = 3
            }
        }
    }

    // MARK: - Sample Data View

    private var sampleDataView: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(appState.themeColor)
                        .symbolEffect(.bounce, value: isLoadingSampleData)

                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Would you like to start with sample data to explore the app?")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Options
                VStack(spacing: 16) {
                    // Sample Data Option
                    Button {
                        loadSampleData()
                    } label: {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundStyle(appState.themeColor)
                                Text("Load Sample Data")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            Text("Pre-populated with example meals, logs, and recipes to help you explore features")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(appState.themeColor.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)

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

                            Text("Begin with a clean slate and add your own data as you go")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
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
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Sample Data Actions

    private func loadSampleData() {
        isLoadingSampleData = true

        Task { @MainActor in
            // Generate sample data
            if let ownerId = appState.currentOwnerId {
                await SampleDataGenerator.generateSampleData(ownerId: ownerId, appState: appState)

                // Wait for visual feedback
                try? await Task.sleep(for: .seconds(1))

                // Reload app state
                appState.loadData(forUser: ownerId)
            }

            // Mark as using sample data
            UserDefaults.standard.set(true, forKey: "isUsingSampleData")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

            isLoadingSampleData = false

            // Track completion
            AnalyticsService.shared.trackOnboardingCompleted(usedSampleData: true)
            AnalyticsService.shared.trackSampleDataLoaded(source: "onboarding")

            // Profile is already created, so RootView will transition to ContentView
        }
    }

    private func startFresh() {
        // Track analytics
        AnalyticsService.shared.trackOnboardingCompleted(usedSampleData: false)

        // Mark as launched
        UserDefaults.standard.set(false, forKey: "isUsingSampleData")
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")

        // Profile is already created, so RootView will transition to ContentView
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
