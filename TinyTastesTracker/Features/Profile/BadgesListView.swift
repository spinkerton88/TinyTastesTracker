//
//  BadgesListView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/3/26.
//

import SwiftUI

struct BadgesListView: View {
    @Bindable var appState: AppState
    
    @State private var selectedMode: AppMode
    
    // Grid layout for 2 columns
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    init(appState: AppState) {
        self.appState = appState
        _selectedMode = State(initialValue: appState.userProfile?.currentMode ?? .newborn)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode Selector
            Picker("Mode", selection: $selectedMode) {
                Text("Newborn").tag(AppMode.newborn)
                Text("Explorer").tag(AppMode.explorer)
                Text("Toddler").tag(AppMode.toddler)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            
            ScrollView {
                // Summary Header
                if let badges = filteredBadges, !badges.isEmpty {
                    let unlockedCount = badges.filter { $0.isUnlocked }.count
                    let totalCount = badges.count
                    
                    VStack(spacing: 8) {
                        Text("\(unlockedCount) / \(totalCount) Unlocked")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                            .progressViewStyle(.linear)
                            .tint(appState.themeColor)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical)
                }
                
                LazyVGrid(columns: columns, spacing: 16) {
                    if let badges = filteredBadges {
                        if badges.isEmpty {
                            ContentUnavailableView(
                                "No Badges",
                                systemImage: "trophy",
                                description: Text("No badges available for this stage.")
                            )
                        } else {
                            ForEach(badges) { badge in
                                BadgeCard(badge: badge, themeColor: appState.themeColor)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "Profile Not Found",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text("Please set up a profile to see badges.")
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Trophy Case")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            seedBadgesIfNeeded()
            checkBadgeProgress()
        }
    }
    
    private var filteredBadges: [Badge]? {
        guard let allBadges = appState.userProfile?.badges else { return nil }
        return allBadges.filter { $0.category == selectedMode }
    }
    
    private func seedBadgesIfNeeded() {
        guard let profile = appState.userProfile else { return }
        
        let defaults = Badge.defaults()
        let existingBadges = profile.badges ?? []
        
        // If we have fewer badges than defaults, run a merge.
        if existingBadges.count < defaults.count {
            print("Detected missing badges. Running merge...")
            
            var updatedProfile = profile
            var currentBadges = updatedProfile.badges ?? []
            
            let existingTypes = Set(currentBadges.map { $0.type })
            
            for defaultBadge in defaults {
                if !existingTypes.contains(defaultBadge.type) {
                    currentBadges.append(defaultBadge)
                }
            }
            
            updatedProfile.badges = currentBadges
            appState.profileManager.updateProfile(updatedProfile)
        }
    }
    
    private func checkBadgeProgress() {
        guard let profile = appState.userProfile else { return }
        
        // Use BadgeManager to check for updates
        if let updatedBadges = BadgeManager.shared.checkBadges(for: profile, appState: appState) {
            print("Badges updated! Saving changes...")
            var updatedProfile = profile
            updatedProfile.badges = updatedBadges
            
            appState.profileManager.updateProfile(updatedProfile)
        }
    }
}

struct BadgeCard: View {
    let badge: Badge
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? themeColor.opacity(0.15) : Color(UIColor.systemGray5))
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.icon)
                    .font(.largeTitle)
                    .foregroundStyle(badge.isUnlocked ? themeColor : .gray)
                    .opacity(badge.isUnlocked ? 1.0 : 0.5)
            }
            
            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(badge.isUnlocked ? .primary : .secondary)
                
                Text(badge.userDescription)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Progress Bar or Lock status
            if !badge.isUnlocked {
                VStack(spacing: 4) {
                    ProgressView(value: Double(badge.progress), total: Double(badge.target))
                        .tint(themeColor)
                        .scaleEffect(x: 1, y: 0.8, anchor: .center)
                        .opacity(0.7) // Faded progress bar
                    
                    Text("\(badge.progress) / \(badge.target)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            } else {
                Text("Unlocked!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeColor)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(badge.isUnlocked ? themeColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        // Global opacity for locked state to "fade" it
        .opacity(badge.isUnlocked ? 1.0 : 0.6)
        // Add a saturation filter to grayscale locked badges
        .saturation(badge.isUnlocked ? 1.0 : 0.0)
    }
}
