//
//  PendingInvitationsCheckView.swift
//  TinyTastesTracker
//
//  Checks for pending invitations when user first creates account
//

import SwiftUI

struct PendingInvitationsCheckView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var pendingInvitations: [ProfileInvitation] = []
    @State private var isLoading = true
    @State private var selectedInvitation: ProfileInvitation?
    @State private var isAccepting = false
    @State private var errorMessage: String?

    var onSkip: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Checking for invitations...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if pendingInvitations.isEmpty {
                    // No invitations - proceed to normal onboarding
                    VStack(spacing: 20) {
                        Image(systemName: "envelope")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)

                        Text("No Pending Invitations")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("You can create your own child profile or wait for an invitation from another parent.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: onSkip) {
                            Text("Create Child Profile")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Show pending invitations
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Image(systemName: "envelope.badge.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.green)

                                Text("You've Been Invited!")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("You have pending invitations to join existing child profiles. Accept to get started!")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top)

                            VStack(spacing: 16) {
                                ForEach(pendingInvitations) { invitation in
                                    InvitationCard(invitation: invitation) {
                                        selectedInvitation = invitation
                                        acceptInvitation(invitation)
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Option to skip and create own profile
                            Button(action: onSkip) {
                                Text("Skip and Create My Own Profile")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                    }
                }

                if isAccepting {
                    LoadingOverlay(message: "Accepting invitation...")
                }
            }
            .navigationTitle("Welcome!")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                loadPendingInvitations()
            }
        }
    }

    private func loadPendingInvitations() {
        guard let email = appState.authenticationManager.userSession?.email else {
            isLoading = false
            return
        }

        Task {
            do {
                let invitations = try await appState.profileSharingManager.loadInvitations(forEmail: email)
                    .filter { $0.status == .pending && $0.isValid }

                await MainActor.run {
                    self.pendingInvitations = invitations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.pendingInvitations = []
                    self.isLoading = false
                }
            }
        }
    }

    private func acceptInvitation(_ invitation: ProfileInvitation) {
        guard let userId = appState.authenticationManager.userSession?.uid else { return }

        isAccepting = true
        errorMessage = nil

        Task {
            do {
                try await appState.profileSharingManager.acceptInvitation(
                    inviteCode: invitation.inviteCode,
                    userId: userId
                )

                await MainActor.run {
                    // Reload user data to get the newly shared profile
                    appState.loadData(forUser: userId)
                    isAccepting = false
                    // Invitation accepted successfully - app will automatically navigate to main view
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isAccepting = false
                }
            }
        }
    }
}

// MARK: - Invitation Card

struct InvitationCard: View {
    let invitation: ProfileInvitation
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.childName)
                        .font(.headline)

                    Text("from \(invitation.inviterName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Expires \(invitation.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onAccept) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accept Invitation")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text(message)
                    .foregroundStyle(.white)
                    .bold()
            }
            .padding(40)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(12)
        }
    }
}
