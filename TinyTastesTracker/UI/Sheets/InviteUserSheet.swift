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

    @State private var selectedRole = ProfileRole.coparent
    @State private var expirationOption = ExpirationOption.never
    @State private var isGenerating = false
    @State private var error: String?
    @State private var invitation: ProfileInvitation?
    @State private var showCopiedConfirmation = false
    @State private var showShareSheet = false

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

                            if let expiresAt = invitation.accessExpiresAt {
                                Text("Access expires on \(expiresAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }

                    Section {
                        Button {
                            showShareSheet = true
                        } label: {
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
                        Text("When they tap the link, the app will automatically open and prompt them to accept.")
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

                            Text("Generate an invitation code or link to share with the person you want to invite.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }



                    Section {
                        Picker("Access Level", selection: $selectedRole) {
                            Text("Co-Parent (Full Access)")
                                .tag(ProfileRole.coparent)
                            Text("Caregiver (View & Log)")
                                .tag(ProfileRole.caregiver)
                        }
                        
                        if selectedRole == .caregiver {
                            Picker("Expires", selection: $expirationOption) {
                                Text("Never")
                                    .tag(ExpirationOption.never)
                                Text("In 24 Hours")
                                    .tag(ExpirationOption.oneDay)
                                Text("In 1 Week")
                                    .tag(ExpirationOption.oneWeek)
                                Text("In 1 Month")
                                    .tag(ExpirationOption.oneMonth)
                            }
                        }
                    } header: {
                        Text("Permissions")
                    } footer: {
                         if selectedRole == .coparent {
                             Text("Co-Parents have full access to view, edit, and add all data, including tracking history.")
                         } else {
                             Text("Caregivers can view the dashboard and add logs, but their access can automatically expire.")
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
                        Button("Generate Link") {
                            generateInvitation()
                        }
                        .disabled(isGenerating)
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
            .sheet(isPresented: $showShareSheet) {
                if let invitation = invitation, let url = URL(string: "https://spinkerton88.github.io/TinyTastesTracker/accept-invite?code=\(invitation.inviteCode)") {
                    ShareSheet(items: [
                        LinkMetadataProvider(
                            url: url,
                            title: "Join \(profile.name) on Tiny Tastes Tracker!",
                            fallbackText: shareMessage
                        ),
                        shareMessage
                    ])
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    private var shareMessage: String {
        guard let invitation = invitation else { return "" }

        let link = "https://spinkerton88.github.io/TinyTastesTracker/accept-invite?code=\(invitation.inviteCode)"
        
        var message = """
        You're invited to view \(profile.name)'s profile in Tiny Tastes Tracker!
        
        Tap this link to accept your invitation:
        \(link)
        
        If the link doesn't work:
        1. Download Tiny Tastes Tracker
        2. Create an account
        3. Go to Settings → Family sharing and enter code: \(invitation.inviteCode)
        """
        
        if let expiresAt = invitation.accessExpiresAt {
            message += "\n\nThis invitation and your access will expire on \(expiresAt.formatted(date: .abbreviated, time: .shortened))."
        }
        
        return message
    }

    @MainActor
    private func generateInvitation() {
        isGenerating = true
        error = nil

        Task {
            do {
                let expiresAt = selectedRole == .caregiver ? expirationOption.date : nil
                
                let newInvitation = try await appState.inviteUser(
                    toProfile: profile.id ?? "",
                    role: selectedRole,
                    accessExpiresAt: expiresAt
                )

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

enum ExpirationOption {
    case never
    case oneDay
    case oneWeek
    case oneMonth
    
    var date: Date? {
        switch self {
        case .never: return nil
        case .oneDay: return Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .oneWeek: return Calendar.current.date(byAdding: .day, value: 7, to: Date())
        case .oneMonth: return Calendar.current.date(byAdding: .month, value: 1, to: Date())
        }
    }
}
