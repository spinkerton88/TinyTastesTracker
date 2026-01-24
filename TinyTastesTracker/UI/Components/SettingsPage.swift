//
//  SettingsPage.swift
//  TinyTastesTracker
//

import SwiftUI

struct SettingsPage: View {
    @Bindable var appState: AppState
    
    @AppStorage("isNightMode") private var isNightMode = false
    
    private var modeBinding: Binding<AppMode?> {
        Binding(
            get: { appState.userProfile?.preferredMode },
            set: { appState.userProfile?.preferredMode = $0 }
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let profile = appState.userProfile {
                    Section("Baby Profile") {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(profile.babyName)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Age")
                            Spacer()
                            Text("\(profile.ageInMonths) months")
                                .foregroundStyle(.secondary)
                        }

                        Picker("App Mode", selection: modeBinding) {
                            Text("Auto (Age-Based)").tag(Optional<AppMode>.none)
                            Text("Newborn (0-6m)").tag(Optional<AppMode>.some(.newborn))
                            Text("Explorer (6-12m)").tag(Optional<AppMode>.some(.explorer))
                            Text("Toddler (12m+)").tag(Optional<AppMode>.some(.toddler))
                        }
                        .tint(appState.themeColor)
                        .accessibilityLabel("Application Mode Selection")
                    }
                    
                    Section {
                        NavigationLink {
                            PediatricianSummaryListView(appState: appState)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundStyle(appState.themeColor)
                                    Text("Checkup Prep")
                                        .fontWeight(.medium)
                                }

                                Text("Generate a report to share during your next checkup")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        NavigationLink {
                            KnownAllergiesView(appState: appState)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Known Allergies")
                                        .fontWeight(.medium)
                                }

                                if let allergies = appState.userProfile?.knownAllergies, !allergies.isEmpty {
                                    Text(allergies.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                } else {
                                    Text("Tap to add any diagnosed allergies")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Health Information")
                    } footer: {
                        Text("Allergens will be flagged across the app to help you avoid them.")
                            .font(.caption)
                    }

                    Section("Family") {
                        NavigationLink {
                            ProfileSwitcherView(appState: appState)
                        } label: {
                            Label("Manage Children", systemImage: "person.2.fill")
                        }

                        if appState.profileManager.profiles.count >= 2 {
                            NavigationLink {
                                SiblingComparisonView(appState: appState)
                            } label: {
                                Label("Compare Siblings", systemImage: "chart.bar.xaxis")
                            }
                        }
                    }
                }
                
                Section("Development") {
                    NavigationLink {
                        MilestonesListView(appState: appState)
                    } label: {
                        Label("Milestones", systemImage: "flag.checkered")
                    }
                }
                
                Section("Achievements") {
                    NavigationLink {
                        BadgesListView(appState: appState)
                    } label: {
                        Label("Trophy Case", systemImage: "trophy.fill")
                    }
                }
                
                Section("Progress") {
                    HStack {
                        Text("Foods Tried")
                        Spacer()
                        Text("\(appState.triedFoodsCount)/100")
                            .foregroundStyle(appState.themeColor)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Recipes")
                        Spacer()
                        Text("\(appState.recipes.count)")
                            .foregroundStyle(appState.themeColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Section("Appearance") {
                    Toggle("Night Mode", isOn: $isNightMode)
                        .tint(appState.themeColor)
                        .accessibilityLabel("Night Mode Switch")
                }
                
                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notification Settings", systemImage: "bell.badge.fill")
                    }
                }
                
                Section("iCloud Sync") {
                    NavigationLink {
                        CloudKitSyncStatusView()
                    } label: {
                        Label("Sync Status", systemImage: "icloud.fill")
                    }
                }
                
                Section("Data Management") {
                    NavigationLink {
                        DataManagementView(appState: appState)
                    } label: {
                        Label("Backup & Export", systemImage: "arrow.down.doc.fill")
                    }
                }
                
                Section {
                    NavigationLink {
                        DemoModeView(appState: appState)
                    } label: {
                        HStack {
                            HStack {
                                SageIcon(size: .medium, style: .gradient)
                                Text("Load Sample Data")
                            }
                            
                            if UserDefaults.standard.bool(forKey: "isUsingSampleData") {
                                Spacer()
                                Text("Active")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Demo Mode")
                } footer: {
                    Text("Explore the app with realistic sample data. Great for testing features or taking screenshots.")
                }
                
                Section("Privacy & Data") {
                    NavigationLink {
                        PrivacySettingsView(appState: appState)
                    } label: {
                        Label("Privacy & Data", systemImage: "hand.raised.fill")
                    }
                }
                
                Section {
                    Text("Tiny Tastes Tracker AI v1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                #if DEBUG
                Section("Developer Tools") {
                    // TODO: Fix BatchImageGeneratorView target membership
                    // NavigationLink {
                    //     BatchImageGeneratorView()
                    // } label: {
                    //     Label("Batch Image Generator", systemImage: "photo.stack")
                    // }
                }
                #endif
            }
            .navigationTitle("Settings")
        }
    }
}
