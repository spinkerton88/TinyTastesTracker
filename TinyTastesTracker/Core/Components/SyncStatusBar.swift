//
//  SyncStatusBar.swift
//  TinyTastesTracker
//
//  Global sync status indicator
//

import SwiftUI

struct SyncStatusBar: View {
    @State private var syncStatus = SyncStatusManager.shared
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showingErrorDetails = false
    
    var body: some View {
        if shouldShowBar {
            HStack(spacing: 8) {
                statusIcon
                
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                
                Spacer()
                
                if syncStatus.hasErrors {
                    Button {
                        showingErrorDetails = true
                    } label: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                
                if syncStatus.isSyncing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .sheet(isPresented: $showingErrorDetails) {
                SyncErrorDetailsView()
            }
        }
    }
    
    private var shouldShowBar: Bool {
        !networkMonitor.isConnected || 
        syncStatus.isSyncing || 
        syncStatus.hasPendingOperations || 
        syncStatus.hasErrors
    }
    
    private var statusMessage: String {
        if !networkMonitor.isConnected {
            return "Offline - Changes will sync when connected"
        } else if syncStatus.isSyncing {
            return "Syncing changes..."
        } else if syncStatus.hasPendingOperations {
            return "\(syncStatus.pendingOperations.count) change\(syncStatus.pendingOperations.count == 1 ? "" : "s") pending"
        } else if syncStatus.hasErrors {
            return "\(syncStatus.syncErrors.count) sync error\(syncStatus.syncErrors.count == 1 ? "" : "s")"
        } else {
            return "All changes saved"
        }
    }
    
    private var statusIcon: some View {
        Group {
            if !networkMonitor.isConnected {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.orange)
            } else if syncStatus.hasErrors {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if syncStatus.isSyncing {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
            } else if syncStatus.hasPendingOperations {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .font(.caption)
    }
    
    private var statusColor: Color {
        if !networkMonitor.isConnected || syncStatus.hasErrors {
            return .primary
        } else if syncStatus.isSyncing || syncStatus.hasPendingOperations {
            return .secondary
        } else {
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        if !networkMonitor.isConnected {
            return Color.orange.opacity(0.1)
        } else if syncStatus.hasErrors {
            return Color.red.opacity(0.1)
        } else if syncStatus.isSyncing || syncStatus.hasPendingOperations {
            return Color.blue.opacity(0.05)
        } else {
            return Color.green.opacity(0.05)
        }
    }
}

// MARK: - Sync Error Details View

struct SyncErrorDetailsView: View {
    @State private var syncStatus = SyncStatusManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if syncStatus.hasErrors {
                    Section("Sync Errors") {
                        ForEach(syncStatus.syncErrors) { error in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(error.error.errorDescription ?? "Unknown Error")
                                    .font(.headline)
                                
                                Text(error.operation.type.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if let suggestion = error.error.recoverySuggestion {
                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if error.error.isRetryable {
                                    Button("Retry") {
                                        Task {
                                            try? await OfflineQueue.shared.retryOperation(error.operation.id)
                                            syncStatus.clearSyncError(error.id)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .swipeActions {
                                Button("Dismiss", role: .destructive) {
                                    syncStatus.clearSyncError(error.id)
                                }
                            }
                        }
                    }
                }
                
                if syncStatus.hasPendingOperations {
                    Section("Pending Operations") {
                        ForEach(syncStatus.pendingOperations) { operation in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(operation.type.rawValue.capitalized)
                                        .font(.headline)
                                    Text("Retry \(operation.retryCount)/3")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if NetworkMonitor.shared.isConnected {
                                    ProgressView()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if syncStatus.hasErrors {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear All") {
                            syncStatus.clearAllSyncErrors()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        SyncStatusBar()
        Spacer()
    }
}
