//
//  AccountSetupView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/23/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct AccountSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    
    @State private var cloudKitStatus: String = "Checking iCloud status..."
    @State private var isChecking = true
    @State private var accountName: String = ""
    @State private var isCreatingAccount = false
    @State private var errorMessage: String?
    
    // CloudKit container
    private let container = CKContainer(identifier: "iCloud.tinytastestracker")
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "icloud.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Constants.explorerColor) // Teal color
                        .symbolEffect(.bounce, value: isChecking)
                    
                    Text("Welcome Parents")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Tiny Tastes Tracker syncs across your devices using iCloud. Let's get you set up.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                // Status Card
                VStack(spacing: 16) {
                    if isChecking {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Constants.explorerColor)
                    } else {
                        HStack {
                            Image(systemName: cloudKitStatus == "Available" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(cloudKitStatus == "Available" ? .green : .orange)
                            
                            Text(cloudKitStatus == "Available" ? "iCloud Active" : "iCloud Issue Detected")
                                .font(.headline)
                        }
                        
                        if !accountName.isEmpty {
                            Text("Signed in as \(accountName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if cloudKitStatus == "Available" {
                            Text("Signed in (Name Hidden)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(cloudKitStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: createAccount) {
                        HStack {
                            if isCreatingAccount {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(cloudKitStatus == "Available" ? Constants.explorerColor : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isChecking || isCreatingAccount)
                    
                    if cloudKitStatus != "Available" && !isChecking {
                        Button("Open iCloud Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .onAppear {
                checkCloudKitStatus()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func checkCloudKitStatus() {
        isChecking = true
        
        Task {
            do {
                let status = try await container.accountStatus()
                
                switch status {
                case .available:
                    cloudKitStatus = "Available"
                    // Try to fetch user name
                    do {
                        let status = try await container.requestApplicationPermission(.userDiscoverability)
                        if status == .granted {
                            if let userID = try? await container.userRecordID() {
                                // discoverUserIdentity might not have async overload in this context or SDK
                                // using completion handler with continuation
                                let identity: CKUserIdentity? = try await withCheckedThrowingContinuation { continuation in
                                    container.discoverUserIdentity(withUserRecordID: userID) { identity, error in
                                        if let error = error {
                                            continuation.resume(throwing: error)
                                        } else {
                                            continuation.resume(returning: identity)
                                        }
                                    }
                                }
                                
                                if let components = identity?.nameComponents {
                                    accountName = PersonNameComponentsFormatter().string(from: components)
                                }
                            }
                        }
                    } catch {
                        print("Permission error: \(error)")
                    }
                case .noAccount:
                    cloudKitStatus = "No iCloud account found"
                case .restricted:
                    cloudKitStatus = "iCloud access restricted"
                case .couldNotDetermine:
                    cloudKitStatus = "Could not verify iCloud status"
                case .temporarilyUnavailable:
                    cloudKitStatus = "iCloud temporarily unavailable"
                @unknown default:
                    cloudKitStatus = "Unknown status"
                }
            } catch {
                cloudKitStatus = "Error checking status"
                print("CloudKit error: \(error)")
            }
            
            isChecking = false
        }
    }
    
    private func createAccount() {
        isCreatingAccount = true
        
        // Create ParentProfile
        let newAccount = ParentProfile(
            parentName: accountName.isEmpty ? nil : accountName,
            icloudStatus: cloudKitStatus
        )
        
        modelContext.insert(newAccount)
        
        do {
            try modelContext.save()
            // Update AppState
            withAnimation {
                appState.userAccount = newAccount
            }
        } catch {
            errorMessage = "Failed to create account: \(error.localizedDescription)"
            isCreatingAccount = false
        }
    }
}

#Preview {
    AccountSetupView(appState: AppState())
}
