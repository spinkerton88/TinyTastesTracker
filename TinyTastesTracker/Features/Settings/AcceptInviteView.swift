//
//  AcceptInviteView.swift
//  TinyTastesTracker
//
//  Accept a profile sharing invitation via 6-digit code
//

import SwiftUI

struct AcceptInviteView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode = ""
    @State private var isAccepting = false
    @State private var error: String?
    @State private var invitationAccepted = false

    var body: some View {
        NavigationStack {
            Form {
                if invitationAccepted {
                    // Success state
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.green)

                            Text("Invitation Accepted!")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("The shared profile has been added to your account")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)

                            Text("You can now view and edit all data for this child")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                } else {
                    // Input form
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.badge")
                                    .foregroundStyle(appState.themeColor)
                                Text("Enter Invitation Code")
                                    .fontWeight(.semibold)
                            }

                            Text("Enter the 6-digit code you received via email")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        HStack {
                            Spacer()
                            TextField("000000", text: $inviteCode)
                                .font(.system(.largeTitle, design: .monospaced))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .onChange(of: inviteCode) { oldValue, newValue in
                                    // Limit to 6 digits
                                    if newValue.count > 6 {
                                        inviteCode = String(newValue.prefix(6))
                                    }
                                    // Auto-submit when 6 digits entered
                                    if newValue.count == 6 {
                                        acceptInvitation()
                                    }
                                }
                                .disabled(isAccepting)
                            Spacer()
                        }
                        .padding(.vertical, 24)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Full Access", systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                                .font(.caption)

                            Text("Once accepted, you'll have full access to view and edit all data for the shared child profile")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Divider()

                            Label("Real-time Sync", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.blue)
                                .font(.caption)

                            Text("Changes you make will sync instantly with all users who have access")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Divider()

                            Label("7-Day Expiration", systemImage: "clock")
                                .foregroundStyle(.orange)
                                .font(.caption)

                            Text("Invitation codes expire 7 days after being sent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("How Sharing Works")
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
            }
            .navigationTitle("Accept Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(invitationAccepted ? "Done" : "Cancel") {
                        dismiss()
                    }
                    .disabled(isAccepting)
                }

                if !invitationAccepted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Accept") {
                            acceptInvitation()
                        }
                        .disabled(inviteCode.count != 6 || isAccepting)
                        .fontWeight(.semibold)
                    }
                }
            }
            .overlay {
                if isAccepting {
                    ProgressView("Accepting invitation...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            .onAppear {
                checkForPendingInviteCode()
            }
            .onReceive(NotificationCenter.default.publisher(for: .handleInviteDeepLink)) { notification in
                if let code = notification.object as? String {
                    inviteCode = code
                    // Auto-submit if code is 6 digits
                    if code.count == 6 {
                        acceptInvitation()
                    }
                }
            }
        }
    }

    private func checkForPendingInviteCode() {
        // Check if there's a pending invite code from a deep link
        if let code = UserDefaults.standard.string(forKey: "pendingInviteCode") {
            inviteCode = code
            UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
            // Auto-submit if code is 6 digits
            if code.count == 6 {
                acceptInvitation()
            }
        }
    }

    private func acceptInvitation() {
        guard inviteCode.count == 6 else { return }

        isAccepting = true
        error = nil

        Task {
            do {
                try await appState.acceptInvite(code: inviteCode)

                await MainActor.run {
                    invitationAccepted = true
                    isAccepting = false

                    // Dismiss after a short delay to show success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isAccepting = false
                }
            }
        }
    }
}
