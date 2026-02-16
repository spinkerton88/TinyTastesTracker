//
//  FeatureTourView.swift
//  TinyTastesTracker
//
//  Interactive feature tour with swipeable cards
//

import SwiftUI

struct FeatureTourView: View {
    @Binding var isPresented: Bool
    var appState: AppState
    @State private var currentPage = 0
    @State private var showWelcomeView = false
    
    private let features: [FeaturePage] = [
        FeaturePage(
            icon: "sage.leaf.sprig",
            iconColor: .purple,
            title: "Meet Sage",
            description: "Your personal feeding assistant. Get instant answers to feeding questions, analyze food photos, and receive personalized recommendations.",
            gradient: [.purple, .pink],
            isSystemImage: false
        ),
        FeaturePage(
            icon: "fork.knife.circle.fill",
            iconColor: .orange,
            title: "Track Every Meal",
            description: "Log meals with our visual food selector. Track colors, nutrients, and feeding strategies. See your baby's nutrition balance at a glance.",
            gradient: [.orange, .yellow]
        ),
        FeaturePage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .green,
            title: "Monitor Growth",
            description: "Track weight, height, and head circumference. Compare against WHO percentiles. Visualize your baby's growth journey over time.",
            gradient: [.green, .teal]
        ),
        FeaturePage(
            icon: "book.fill",
            iconColor: .blue,
            title: "Discover Recipes",
            description: "Scan recipes with your camera or create your own. Get personalized meal suggestions. Build a curated recipe collection.",
            gradient: [.blue, .cyan]
        ),
        FeaturePage(
            icon: "person.2.fill",
            iconColor: .pink,
            title: "Compare Siblings",
            description: "Track multiple children in one app. Compare growth, nutrition, and milestones. Perfect for families with multiple little ones.",
            gradient: [.pink, .red]
        ),
        FeaturePage(
            icon: "hand.raised.fill",
            iconColor: .indigo,
            title: "Your Privacy Matters",
            description: "Your data stays on your device. Export anytime. Delete whenever you want. We never sell your information.",
            gradient: [.indigo, .purple]
        )
    ]
    
    var body: some View {
        ZStack {
            // Clean background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        AnalyticsService.shared.trackFeatureTourSkipped(
                            atPage: currentPage,
                            totalPages: features.count
                        )
                        showWelcomeView = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color(UIColor.darkGray))
                    .padding()
                }
                
                // Tab view with pages
                TabView(selection: $currentPage) {
                    ForEach(0..<features.count, id: \.self) { index in
                        FeaturePageView(feature: features[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .onChange(of: currentPage) { oldValue, newValue in
                    AnalyticsService.shared.trackFeatureTourPageViewed(
                        page: newValue,
                        featureName: features[newValue].title
                    )
                }
                
                // Bottom action button
                Button {
                    if currentPage < features.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        AnalyticsService.shared.trackFeatureTourCompleted()
                        showWelcomeView = true
                    }
                } label: {
                    Text(currentPage < features.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(features[currentPage].iconColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: features[currentPage].iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .fullScreenCover(isPresented: $showWelcomeView) {
            WelcomeView(isPresented: $isPresented, appState: appState)
        }
        .onAppear {
            AnalyticsService.shared.trackFeatureTourStarted()
        }
    }
}

// MARK: - Feature Page View

struct FeaturePageView: View {
    let feature: FeaturePage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(feature.iconColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(feature.iconColor.opacity(0.2))
                    .frame(width: 110, height: 110)
                
                if feature.isSystemImage {
                    Image(systemName: feature.icon)
                        .font(.system(size: 50)) // Keep for decorative emoji/icon
                        .foregroundStyle(feature.iconColor)
                } else {
                    Image(feature.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(feature.iconColor)
                }
            }
            
            // Title
            Text(feature.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.black) // Force black on white background
                .multilineTextAlignment(.center)
            
            // Description
            Text(feature.description)
                .font(.body)
                .foregroundStyle(Color(UIColor.darkGray))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Supporting Types

struct FeaturePage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let gradient: [Color]
    var isSystemImage: Bool = true
}

#Preview {
    FeatureTourView(isPresented: .constant(true), appState: AppState())
}
