//
//  CloudKitSyncStatusView.swift
//  TinyTastesTracker
//
//  View for displaying CloudKit sync status in Settings
//

import SwiftUI

struct CloudKitSyncStatusView: View {
    @StateObject private var syncManager = CloudKitSyncManager.shared
    @State private var isRefreshing = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: syncManager.syncStatus.iconName)
                        .foregroundStyle(statusColor)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Sync")
                            .font(.headline)
                        
                        Text(syncManager.syncStatus.displayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if isRefreshing {
                        ProgressView()
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Sync Status")
            } footer: {
                Text("Your data is automatically synced to iCloud when you're signed in and online. All changes are saved locally first, then synced in the background.")
            }
            
            Section {
                Button {
                    Task {
                        isRefreshing = true
                        await syncManager.refreshStatus()
                        try? await Task.sleep(nanoseconds: 500_000_000) // Brief delay for UX
                        isRefreshing = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Check Status")
                    }
                }
                .disabled(isRefreshing)
            } header: {
                Text("Actions")
            }
            
            if !syncManager.isAccountAvailable {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("iCloud Not Available")
                                .fontWeight(.semibold)
                        }
                        
                        Text("To enable iCloud sync:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Open Settings app", systemImage: "1.circle.fill")
                            Label("Tap your name at the top", systemImage: "2.circle.fill")
                            Label("Sign in to iCloud", systemImage: "3.circle.fill")
                            Label("Enable iCloud Drive", systemImage: "4.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Setup Required")
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How Sync Works")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SyncInfoRow(icon: "checkmark.circle.fill", text: "All data is saved locally first")
                        SyncInfoRow(icon: "icloud.fill", text: "Changes sync automatically to iCloud")
                        SyncInfoRow(icon: "arrow.triangle.2.circlepath", text: "Works across all your devices")
                        SyncInfoRow(icon: "lock.fill", text: "End-to-end encrypted")
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("About iCloud Sync")
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await syncManager.checkAccountStatus()
        }
    }
    
    private var statusColor: Color {
        switch syncManager.syncStatus {
        case .active:
            return .green
        case .idle:
            return .blue
        case .syncing:
            return .orange
        case .error, .accountNotAvailable:
            return .red
        }
    }
}

private struct SyncInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.caption)
        }
    }
}
