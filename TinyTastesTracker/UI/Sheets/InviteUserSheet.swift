//
//  InviteUserSheet.swift
//  TinyTastesTracker
//
//  Invite a user to share a child profile
//

import SwiftUI

struct InviteUserSheet: View {
    @Bindable var appState: AppState
    let profile: ChildProfile
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isGenerating = false
    @State private var error: String?
    @State private var invitation: ProfileInvitation?
    @State private var showCopiedConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                if let invitation = invitation {
                    // Success state - show code with share options
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 60))
                                .foregroundStyle(appState.themeColor)

                            Text("Invitation Created")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Share this code to grant access to \(profile.name)'s profile")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Invitation Code")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Text(invitation.inviteCode)
                                        .font(.system(.largeTitle, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundStyle(appState.themeColor)

                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }

                            Text("Code expires in 7 days")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }

                    Section {
                        ShareLink(item: shareMessage) {
                            Label("Share via iMessage, WhatsApp, etc.", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appState.themeColor)

                        Button {
                            copyToClipboard()
                        } label: {
                            HStack {
                                if showCopiedConfirmation {
                                    Label("Copied!", systemImage: "checkmark")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Label("Copy Code", systemImage: "doc.on.doc")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    } footer: {
                        Text("They can enter this code in Settings → Family → Accept Invitation")
                    }
                } else {
                    // Initial state - generate invitation
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .foregroundStyle(appState.themeColor)
                                Text("Share \(profile.name)'s Profile")
                                    .fontWeight(.semibold)
                            }

                            Text("Enter the email address of the person you want to invite. They'll receive an invitation code.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        TextField("Email address", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    } header: {
                        Text("Invite")
                    } footer: {
                        Text("They'll need to create an account with this email to accept the invitation.")
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
            .navigationTitle("Invite User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(invitation == nil ? "Cancel" : "Done") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }

                if invitation == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send Invite") {
                            generateInvitation()
                        }
                        .disabled(isGenerating || email.isEmpty || !isValidEmail(email))
                        .fontWeight(.semibold)
                    }
                }
            }
            .overlay {
                if isGenerating {
                    ProgressView("Creating invitation...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private var shareMessage: String {
        guard let invitation = invitation else { return "" }

        return """
        You're invited to view and edit \(profile.name)'s profile in Tiny Tastes Tracker!

        Invitation Code: \(invitation.inviteCode)

        To accept:
        1. Download Tiny Tastes Tracker (if you haven't already)
        2. Create an account with \(invitation.invitedEmail)
        3. The invitation will appear automatically, or go to Settings → Family → Accept Invitation
        4. Enter the code above

        This invitation expires in 7 days.
        """
    }

    @MainActor
    private func generateInvitation() {
        isGenerating = true
        error = nil

        Task {
            do {
                let newInvitation = try await appState.inviteUser(toProfile: profile.id ?? "", email: email)

                await MainActor.run {
                    invitation = newInvitation
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }

    private func copyToClipboard() {
        guard let invitation = invitation else { return }
        UIPasteboard.general.string = invitation.inviteCode

        // Show confirmation
        withAnimation {
            showCopiedConfirmation = true
        }

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedConfirmation = false
            }
        }
    }
}
