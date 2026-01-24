//
//  ProfileSwitcherView.swift
//  TinyTastesTracker
//
//  Profile management UI for switching between multiple children
//

import SwiftUI
import SwiftData

struct ProfileSwitcherView: View {
    @Environment(\.modelContext) private var context
    @Bindable var appState: AppState

    @State private var showingAddProfile = false
    @State private var showingEditProfile: UserProfile?
    @State private var showingDeleteConfirm: UserProfile?

    var body: some View {
        List {
            Section {
                ForEach(appState.profileManager.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isActive: profile.id == appState.profileManager.activeProfileId,
                        onSelect: {
                            appState.profileManager.setActiveProfile(profile)
                        },
                        onEdit: {
                            showingEditProfile = profile
                        },
                        onDelete: {
                            showingDeleteConfirm = profile
                        }
                    )
                }
            } header: {
                Text("Children")
            }

            Section {
                Button(action: { showingAddProfile = true }) {
                    Label("Add Child", systemImage: "plus.circle.fill")
                        .foregroundColor(appState.themeColor)
                }
            }
        }
        .navigationTitle("Manage Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddProfile) {
            AddProfileSheet(appState: appState)
        }
        .sheet(item: $showingEditProfile) { profile in
            EditProfileSheet(profile: profile, appState: appState)
        }
        .alert("Delete Profile?", isPresented: Binding(
            get: { showingDeleteConfirm != nil },
            set: { if !$0 { showingDeleteConfirm = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                showingDeleteConfirm = nil
            }
            Button("Delete", role: .destructive) {
                if let profile = showingDeleteConfirm {
                    appState.profileManager.deleteProfile(profile, context: context)
                    showingDeleteConfirm = nil
                }
            }
        } message: {
            if let profile = showingDeleteConfirm {
                Text("Are you sure you want to delete \(profile.babyName)'s profile? This will delete all their data and cannot be undone.")
            }
        }
        .onAppear {
            appState.profileManager.loadProfiles(context: context)
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: UserProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.babyName)
                        .font(.headline)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Text("\(profile.ageInMonths) months • \(profile.currentMode.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(profile.birthDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                if !isActive {
                    Button(action: onSelect) {
                        Label("Switch to \(profile.babyName)", systemImage: "arrow.left.arrow.right")
                    }
                }

                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isActive {
                onSelect()
            }
        }
    }
}

// MARK: - Add Profile Sheet

struct AddProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var appState: AppState

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender: Gender = .other
    @State private var allergies = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Child Information") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Child Name")

                    DatePicker("Birth Date",
                             selection: $birthDate,
                             in: ...Date(),
                             displayedComponents: .date)
                    .accessibilityLabel("Child's Birth Date")

                    Picker("Gender", selection: $gender) {
                        Text("Boy").tag(Gender.boy)
                        Text("Girl").tag(Gender.girl)
                        Text("Other").tag(Gender.other)
                    }
                    .accessibilityLabel("Gender Selection")
                }

                Section("Known Allergies (Optional)") {
                    TextField("Separate with commas", text: $allergies)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveProfile() {
        let allergyList = allergies.isEmpty ? nil : allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        appState.profileManager.createProfile(
            name: name,
            birthDate: birthDate,
            gender: gender,
            allergies: allergyList,
            context: context
        )

        dismiss()
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let profile: UserProfile
    @Bindable var appState: AppState

    @State private var name: String
    @State private var birthDate: Date
    @State private var gender: Gender
    @State private var allergies: String
    @State private var preferredMode: AppMode?

    init(profile: UserProfile, appState: AppState) {
        self.profile = profile
        self.appState = appState
        _name = State(initialValue: profile.babyName)
        _birthDate = State(initialValue: profile.birthDate)
        _gender = State(initialValue: profile.gender)
        _allergies = State(initialValue: profile.knownAllergies?.joined(separator: ", ") ?? "")
        _preferredMode = State(initialValue: profile.preferredMode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Child Information") {
                    TextField("Name", text: $name)

                    DatePicker("Birth Date",
                             selection: $birthDate,
                             in: ...Date(),
                             displayedComponents: .date)

                    Picker("Gender", selection: $gender) {
                        Text("Boy").tag(Gender.boy)
                        Text("Girl").tag(Gender.girl)
                        Text("Other").tag(Gender.other)
                    }
                }

                Section("Preferred Mode (Optional)") {
                    Picker("Mode", selection: $preferredMode) {
                        Text("Auto (Based on Age)").tag(nil as AppMode?)
                        Text("Newborn").tag(AppMode.newborn as AppMode?)
                        Text("Explorer").tag(AppMode.explorer as AppMode?)
                        Text("Toddler").tag(AppMode.toddler as AppMode?)
                    }
                }

                Section("Known Allergies") {
                    TextField("Separate with commas", text: $allergies)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let allergyList = allergies.isEmpty ? nil : allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        appState.profileManager.updateProfile(
            profile,
            name: name,
            birthDate: birthDate,
            gender: gender,
            allergies: allergyList,
            preferredMode: preferredMode,
            context: context
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileSwitcherView(appState: AppState())
    }
    .modelContainer(for: [UserProfile.self])
}
