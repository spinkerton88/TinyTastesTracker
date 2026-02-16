//
//  MilestonesListView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/3/26.
//

import SwiftUI

struct MilestonesListView: View {
    @Bindable var appState: AppState
    
    // Default to the user's current mode, but allow switching
    @State private var selectedMode: AppMode
    
    init(appState: AppState) {
        self.appState = appState
        // Initialize selectedMode with the user's current mode or fallback to newborn
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
            
            // Milestones List
            List {
                if let milestones = filteredMilestones {
                    if milestones.isEmpty {
                        ContentUnavailableView(
                            "No Milestones Found",
                            systemImage: "checklist",
                            description: Text("No milestones available for this stage.")
                        )
                    } else {
                        ForEach(milestones) { milestone in
                            MilestoneRow(milestone: milestone) {
                                toggleMilestone(milestone)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Profile Not Found",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("Please set up a profile to track milestones.")
                    )
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            seedMilestonesIfNeeded()
        }
    }
    
    private func seedMilestonesIfNeeded() {
        guard let profile = appState.userProfile else { return }
        
        if profile.milestones == nil || profile.milestones?.isEmpty == true {
            var updatedProfile = profile
            let defaults = Milestone.defaults()
            updatedProfile.milestones = defaults
            appState.profileManager.updateProfile(updatedProfile)
        }
    }
    
    private var filteredMilestones: [Milestone]? {
        guard let allMilestones = appState.userProfile?.milestones else { return nil }
        
        return allMilestones
            .filter { $0.category == selectedMode }
            .sorted { $0.isCompleted && !$1.isCompleted } // Sort completed to bottom? Or keep default order?
            // Actually, usually users want list in logic order. Let's keep original order for now.
    }
    
    private func toggleMilestone(_ milestone: Milestone) {
        guard let profile = appState.userProfile,
              var milestones = profile.milestones,
              let index = milestones.firstIndex(where: { $0.id == milestone.id }) else { return }
        
        var updatedMilestone = milestones[index]
        updatedMilestone.isCompleted.toggle()
        updatedMilestone.dateCompleted = updatedMilestone.isCompleted ? Date() : nil
        
        var updatedProfile = profile
        var newMilestones = milestones
        newMilestones[index] = updatedMilestone
        updatedProfile.milestones = newMilestones
        
        withAnimation {
            appState.profileManager.updateProfile(updatedProfile)
        }
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    let toggleAction: () -> Void
    
    var body: some View {
        Button(action: toggleAction) {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(milestone.isCompleted ? .green : .secondary)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .strikethrough(milestone.isCompleted)
                    
                    if let date = milestone.dateCompleted, milestone.isCompleted {
                        Text("Completed \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Icon
                Image(systemName: milestone.icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
            }
            .contentShape(Rectangle()) // Make full row tappable
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
