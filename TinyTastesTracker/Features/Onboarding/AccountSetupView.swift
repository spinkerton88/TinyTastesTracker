//
//  AccountSetupView.swift
//  TinyTastesTracker
//
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountSetupView: View {
    @Bindable var appState: AppState

    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var authMode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Service for creating parent profile
    private let profileService = FirestoreService<ParentProfile>(collectionName: "parent_profiles")

    enum AuthMode {
        case signIn
        case createAccount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 40)

                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 80))
                            .foregroundStyle(Constants.explorerColor)
                            .symbolEffect(.bounce, value: isSigningIn)

                        Text("Welcome to Tiny Tastes")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Your intelligent companion for tracking your baby's nutrition, growth, and development.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    // Auth Mode Picker
                    Picker("Auth Mode", selection: $authMode) {
                        Text("Sign In").tag(AuthMode.signIn)
                        Text("Create Account").tag(AuthMode.createAccount)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Auth Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("email@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            SecureField("Password", text: $password)
                                .textContentType(authMode == .createAccount ? .newPassword : .password)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Confirm Password (only for create account)
                        if authMode == .createAccount {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        // Email/Password Button
                        Button(action: handleEmailAuth) {
                            HStack {
                                if isSigningIn {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(authMode == .signIn ? "Sign In" : "Create Account")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Constants.explorerColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSigningIn || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                    }
                    .padding(.horizontal)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Continue as Guest
                    Button(action: handleAnonymousSignIn) {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isSigningIn)

                    Text("By continuing, you verify that you are a parent or guardian.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private var isFormValid: Bool {
        if authMode == .signIn {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
        }
    }

    private func handleEmailAuth() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                if authMode == .signIn {
                    try await appState.authenticationManager.signInWithEmail(email: email, password: password)
                } else {
                    try await appState.authenticationManager.createAccount(email: email, password: password)
                }

                // Create Parent Profile if needed
                if let uid = appState.authenticationManager.userSession?.uid {
                    await createParentProfileIfNeeded(uid: uid)
                }
                isSigningIn = false
            } catch {
                errorMessage = error.localizedDescription
                isSigningIn = false
            }
        }
    }

    private func handleAnonymousSignIn() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                try await appState.authenticationManager.signInAnonymously()

                // Create Parent Profile if needed
                if let uid = appState.authenticationManager.userSession?.uid {
                    await createParentProfileIfNeeded(uid: uid)
                }
                isSigningIn = false
            } catch {
                errorMessage = error.localizedDescription
                isSigningIn = false
            }
        }
    }

    private func createParentProfileIfNeeded(uid: String) async {
        let newProfile = ParentProfile(
            ownerId: uid,
            name: "Parent", // Default name
            icloudStatus: "Firebase"
        )

        do {
            try await profileService.add(newProfile)
        } catch {
            print("Error creating parent profile: \(error)")
        }
    }
}

#Preview {
    AccountSetupView(appState: AppState())
}
