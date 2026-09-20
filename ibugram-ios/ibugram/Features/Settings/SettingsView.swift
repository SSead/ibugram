import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @State private var appearance = AppearanceSettingsStore()
    @State private var appLock = AppLockSettingsStore()
    @State private var isEditingProfile = false
    @State private var isChangingUsername = false
    @State private var confirmSignOut = false

    var body: some View {
        List {
            accountSection
            securitySection
            appearanceSection
            privacySection
            aboutSection
            signOutSection
        }
        .listStyle(.insetGrouped)
        .tint(theme.colors.brand)
        .navigationTitle("Settings")
        .sheet(isPresented: $isEditingProfile) { editProfileSheet }
        .sheet(isPresented: $isChangingUsername) { usernameSheet }
        .confirmationDialog("Sign out of IBUgram?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                Task { await session.signOut() }
            }
        } message: {
            Text("You can sign back in with your university email.")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button {
                isEditingProfile = true
            } label: {
                Label("Edit Profile", systemImage: "person.crop.circle")
            }
            .accessibilityHint("Change your display name, bio and photo")

            Button {
                isChangingUsername = true
            } label: {
                LabeledContent("Username", value: session.currentUser.map { "@\($0.username)" } ?? "—")
            }
            .accessibilityLabel("Username, \(session.currentUser?.username ?? "not set")")
        }
    }

    private var securitySection: some View {
        Section("Security") {
            NavigationLink {
                ActiveSessionsView()
            } label: {
                Label("Active sessions", systemImage: "laptopcomputer.and.iphone")
            }

            Toggle(isOn: $appLock.isEnabled) {
                Label("Lock with \(appLock.biometryTitle)", systemImage: "lock.fill")
            }
            .disabled(!appLock.isBiometryAvailable)
            .accessibilityHint("Require biometrics when opening IBUgram")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Appearance", selection: $appearance.preference) {
                ForEach(AppearancePreference.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Appearance")
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            NavigationLink {
                BlockedAccountsView()
            } label: {
                Label("Blocked accounts", systemImage: "nosign")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: versionString)
            NavigationLink("On-device processing") {
                OnDevicePrivacyView()
            }
            NavigationLink("Licences") {
                LicencesView()
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button("Sign out", role: .destructive) {
                confirmSignOut = true
            }
            .accessibilityHint("Sign out through your session, not by clearing local storage")
        }
    }

    private var versionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    @ViewBuilder
    private var editProfileSheet: some View {
        if let user = session.currentUser {
            NavigationStack {
                EditProfileView(user: user) { updated in
                    session.update(user: updated)
                    isEditingProfile = false
                }
            }
        }
    }

    @ViewBuilder
    private var usernameSheet: some View {
        if let user = session.currentUser {
            NavigationStack {
                ChangeUsernameView(currentUsername: user.username) { updated in
                    session.update(user: updated)
                    isChangingUsername = false
                }
            }
        }
    }
}

#Preview("Settings") {
    TabNavigationStack { SettingsView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Settings · dark") {
    TabNavigationStack { SettingsView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
