//
//  ShareManagementView.swift
//  TinyTastesTracker
//
//  UI Components for managing Family Sharing (Firebase).
//

import SwiftUI

struct ShareManagementView: View {
    @Bindable var appState: AppState

    @State private var sentInvitations: [ProfileInvitation] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        List {
            if !sentInvitations.isEmpty {
                Section("Invitations Sent") {
                    ForEach(sentInvitations) { invitation in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(invitation.childName)
                                    .font(.headline)
                                Text("Invitation Code: \(invitation.inviteCode)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                StatusBadge(status: invitation.status)
                                Text(invitation.invitedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if sentInvitations.isEmpty && !isLoading {
                Section {
                    ContentUnavailableView(
                        "No Invitations",
                        systemImage: "envelope.open",
                        description: Text("You haven't sent any profile sharing invitations yet")
                    )
                }
            }

            Section {
                Text("To share a profile, go to Settings → Manage Children and select 'Manage Sharing' from the profile menu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("To accept an invitation, use the 'Accept Invitation' button above and enter the 6-digit code you received")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = error {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Family Sharing")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await loadInvitations()
        }
        .refreshable {
            await loadInvitations()
        }
    }

    private func loadInvitations() async {
        isLoading = true
        error = nil

        do {
            let sentList = try await appState.loadSentInvitations()

            await MainActor.run {
                sentInvitations = sentList
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: InvitationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
            Text(statusText)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .foregroundStyle(statusColor)
        .cornerRadius(8)
    }

    private var statusIcon: String {
        switch status {
        case .pending: return "clock"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .expired: return "hourglass.bottomhalf.filled"
        }
    }

    private var statusText: String {
        status.rawValue.capitalized
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }
}
