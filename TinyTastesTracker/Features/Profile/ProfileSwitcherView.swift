//
//  ProfileSwitcherView.swift
//  TinyTastesTracker
//
//  Profile management UI for switching between multiple children
//

import SwiftUI

struct ProfileSwitcherView: View {
    @Bindable var appState: AppState

    @State private var showingAddProfile = false
    @State private var showingEditProfile: ChildProfile?
    @State private var showingDeleteConfirm: ChildProfile?
    @State private var showingManageSharing: ChildProfile?

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
                        },
                        onManageSharing: {
                            showingManageSharing = profile
                        }
                    )
                }
            } header: {
                Text(NSLocalizedString("profile.section.children", comment: "Children section header"))
            }

            Section {
                Button(action: { showingAddProfile = true }) {
                    Label(NSLocalizedString("profile.action.add", comment: "Add child button"), systemImage: "plus.circle.fill")
                        .foregroundColor(appState.themeColor)
                }
            }
        }
        .navigationTitle(NSLocalizedString("profile.navigation.title", comment: "Navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddProfile) {
            AddProfileSheet(appState: appState)
        }
        .sheet(item: $showingEditProfile) { profile in
            EditProfileSheet(profile: profile, appState: appState)
        }
        .sheet(item: $showingManageSharing) { profile in
            NavigationStack {
                ManageSharedAccessView(appState: appState, profile: profile)
            }
        }
        .alert(NSLocalizedString("profile.alert.delete.title", comment: "Delete alert title"), isPresented: Binding(
            get: { showingDeleteConfirm != nil },
            set: { if !$0 { showingDeleteConfirm = nil } }
        )) {
            Button(NSLocalizedString("profile.alert.delete.cancel", comment: "Cancel button"), role: .cancel) {
                showingDeleteConfirm = nil
            }
            Button(NSLocalizedString("profile.alert.delete.confirm", comment: "Delete button"), role: .destructive) {
                if let profile = showingDeleteConfirm {
                    appState.profileManager.deleteProfile(profile)
                    showingDeleteConfirm = nil
                }
            }
        } message: {
            if let profile = showingDeleteConfirm {
                Text(String(format: NSLocalizedString("profile.alert.delete.message", comment: "Delete confirmation message"), profile.name))
            }
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: ChildProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onManageSharing: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.name)
                        .font(.headline)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }

                    // Shared profile indicator
                    if !profile.isOwner {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                    }
                }

                Text("\(profile.ageInMonths) \(NSLocalizedString("profile.row.months_suffix", comment: "Months suffix")) • \(profile.currentMode.rawValue)")
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
                        Label(String(format: NSLocalizedString("profile.row.switch_to", comment: "Switch profile"), profile.name), systemImage: "arrow.left.arrow.right")
                    }
                }

                Button(action: onEdit) {
                    Label(NSLocalizedString("profile.row.edit", comment: "Edit button"), systemImage: "pencil")
                }

                if profile.isOwner {
                    Button(action: onManageSharing) {
                        Label("Manage Sharing", systemImage: "person.2.badge.gearshape")
                    }
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label(NSLocalizedString("profile.row.delete", comment: "Delete button"), systemImage: "trash")
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
    @Bindable var appState: AppState

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender: Gender = .other
    @State private var allergies = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("profile.add.section.info", comment: "Section header")) {
                    TextField(NSLocalizedString("profile.add.field.name", comment: "Name field"), text: $name)
                        .accessibilityLabel(NSLocalizedString("profile.add.field.name.accessibility", comment: "Name accessibility"))

                    DatePicker(NSLocalizedString("profile.add.field.birthdate", comment: "Birth date field"),
                             selection: $birthDate,
                             in: ...Date(),
                             displayedComponents: .date)
                    .accessibilityLabel(NSLocalizedString("profile.add.field.birthdate.accessibility", comment: "Birth date accessibility"))

                    Picker(NSLocalizedString("profile.add.field.gender", comment: "Gender field"), selection: $gender) {
                        Text(NSLocalizedString("profile.add.field.gender.boy", comment: "Boy option")).tag(Gender.boy)
                        Text(NSLocalizedString("profile.add.field.gender.girl", comment: "Girl option")).tag(Gender.girl)
                        Text(NSLocalizedString("profile.add.field.gender.other", comment: "Other option")).tag(Gender.other)
                    }
                    .accessibilityLabel(NSLocalizedString("profile.add.field.gender.accessibility", comment: "Gender accessibility"))
                }

                Section(NSLocalizedString("profile.add.section.allergies", comment: "Allergies section")) {
                    TextField(NSLocalizedString("profile.add.field.allergies.placeholder", comment: "Allergies placeholder"), text: $allergies)
                }
            }
            .navigationTitle(NSLocalizedString("profile.add.title", comment: "Add child title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("profile.add.action.cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("profile.add.action.add", comment: "Add button")) {
                        saveProfile()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveProfile() {
        guard let ownerId = appState.currentOwnerId else { return }
        
        let allergyList = allergies.isEmpty ? nil : allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        appState.profileManager.createProfile(
            name: name,
            birthDate: birthDate,
            gender: gender,
            allergies: allergyList,
            ownerId: ownerId
        )

        dismiss()
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    let profile: ChildProfile
    @Bindable var appState: AppState

    @State private var name: String
    @State private var birthDate: Date
    @State private var gender: Gender
    @State private var allergies: String
    @State private var preferredMode: AppMode?

    init(profile: ChildProfile, appState: AppState) {
        self.profile = profile
        self.appState = appState
        _name = State(initialValue: profile.name)
        _birthDate = State(initialValue: profile.birthDate)
        _gender = State(initialValue: profile.gender)
        _allergies = State(initialValue: profile.knownAllergies?.joined(separator: ", ") ?? "")
        _preferredMode = State(initialValue: profile.preferredMode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("profile.add.section.info", comment: "Section header")) {
                    TextField(NSLocalizedString("profile.add.field.name", comment: "Name field"), text: $name)

                    DatePicker(NSLocalizedString("profile.add.field.birthdate", comment: "Birth date field"),
                             selection: $birthDate,
                             in: ...Date(),
                             displayedComponents: .date)

                    Picker(NSLocalizedString("profile.add.field.gender", comment: "Gender field"), selection: $gender) {
                        Text(NSLocalizedString("profile.add.field.gender.boy", comment: "Boy option")).tag(Gender.boy)
                        Text(NSLocalizedString("profile.add.field.gender.girl", comment: "Girl option")).tag(Gender.girl)
                        Text(NSLocalizedString("profile.add.field.gender.other", comment: "Other option")).tag(Gender.other)
                    }
                }

                Section(NSLocalizedString("profile.edit.section.mode", comment: "Mode section")) {
                    Picker(NSLocalizedString("profile.edit.field.mode", comment: "Mode field"), selection: $preferredMode) {
                        Text(NSLocalizedString("profile.edit.field.mode.auto", comment: "Auto mode")).tag(nil as AppMode?)
                        Text(NSLocalizedString("profile.edit.field.mode.newborn", comment: "Newborn mode")).tag(AppMode.newborn as AppMode?)
                        Text(NSLocalizedString("profile.edit.field.mode.explorer", comment: "Explorer mode")).tag(AppMode.explorer as AppMode?)
                        Text(NSLocalizedString("profile.edit.field.mode.toddler", comment: "Toddler mode")).tag(AppMode.toddler as AppMode?)
                    }
                }

                Section(NSLocalizedString("profile.edit.section.allergies", comment: "Allergies section")) {
                    TextField(NSLocalizedString("profile.add.field.allergies.placeholder", comment: "Allergies placeholder"), text: $allergies)
                }
            }
            .navigationTitle(NSLocalizedString("profile.edit.title", comment: "Edit profile title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("profile.add.action.cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("profile.edit.action.save", comment: "Save button")) {
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
            preferredMode: preferredMode
        )

        dismiss()
    }
}
