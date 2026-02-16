//
//  ManageSharedAccessView.swift
//  TinyTastesTracker
//
//  Manage who has access to a child profile
//

import SwiftUI

struct ManageSharedAccessView: View {
    @Bindable var appState: AppState
    let profile: ChildProfile

    @State private var sharedUsers: [SharedUser] = []
    @State private var pendingInvitations: [ProfileInvitation] = []
    @State private var isLoading = true
    @State private var showingInviteSheet = false
    @State private var error: String?

    var body: some View {
        List {
            Section("Owner") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(appState.themeColor)
                        .font(.title2)

                    VStack(alignment: .leading) {
                        Text("You")
                            .fontWeight(.semibold)
                        Text("Profile Owner")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                }
            }

            if !sharedUsers.isEmpty {
                Section("Shared With") {
                    ForEach(sharedUsers) { user in
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundStyle(.purple)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text(user.name ?? "User \(user.userId.prefix(6))")
                                    .fontWeight(.medium)
                                Text("Since \(user.sharedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if profile.isOwner {
                                Button(role: .destructive) {
                                    revokeAccess(for: user)
                                } label: {
                                    Text("Remove")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                        }
                    }
                }
            }

            if !pendingInvitations.isEmpty {
                Section("Pending Invitations") {
                    ForEach(pendingInvitations) { invitation in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.orange)

                                VStack(alignment: .leading) {
                                    Text("Invitation pending")
                                        .fontWeight(.medium)
                                    Text("Sent \(invitation.invitedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }

                            HStack {
                                Text("Code: \(invitation.inviteCode)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = invitation.inviteCode
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption2)
                                }

                                Text("·")
                                    .foregroundStyle(.tertiary)

                                Text("Expires \(invitation.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if profile.isOwner {
                Section {
                    Button {
                        showingInviteSheet = true
                    } label: {
                        Label("Invite Someone", systemImage: "person.badge.plus")
                            .foregroundStyle(appState.themeColor)
                    }
                } footer: {
                    Text("Shared users will have full access to view and edit all data for \(profile.name)")
                        .font(.caption)
                }
            } else {
                Section {
                    Button(role: .destructive) {
                        removeSelf()
                    } label: {
                        Label("Leave Profile", systemImage: "arrow.right.square")
                    }
                } footer: {
                    Text("You'll no longer have access to \(profile.name)'s data")
                        .font(.caption)
                }
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
        .navigationTitle("Manage Sharing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInviteSheet) {
            InviteUserSheet(appState: appState, profile: profile)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        error = nil

        do {
            async let users = appState.loadSharedUsers(forProfile: profile.id ?? "")
            async let invitations = appState.loadPendingInvitations(forProfile: profile.id ?? "")

            let (loadedUsers, loadedInvitations) = try await (users, invitations)

            await MainActor.run {
                sharedUsers = loadedUsers
                pendingInvitations = loadedInvitations
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func revokeAccess(for user: SharedUser) {
        guard let profileId = profile.id else { return }

        Task {
            do {
                try await appState.revokeAccess(fromProfile: profileId, userId: user.userId)
                await loadData()
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    private func removeSelf() {
        guard let profileId = profile.id else { return }

        Task {
            do {
                try await appState.removeSelfFromProfile(profileId)
                // Profile will automatically disappear from list via listener
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
