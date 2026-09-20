import SwiftUI
import IBUgramKit

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @Environment(Router.self) private var router
    @Environment(AppearanceSettingsStore.self) private var appearance
    @Environment(AppLockSettingsStore.self) private var appLock
    @State private var confirmSignOut = false

    var body: some View {
        let appearance = Bindable(appearance)
        let appLock = Bindable(appLock)
        return List {
            accountSection
            securitySection(appLock: appLock)
            appearanceSection(appearance: appearance)
            privacySection
            aboutSection
            signOutSection
        }
        .listStyle(.insetGrouped)
        .tint(theme.colors.brand)
        .navigationTitle("Settings")
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
                router.push(.editProfile)
            } label: {
                Label("Edit Profile", systemImage: "person.crop.circle")
            }
            .accessibilityHint("Change your display name, bio and photo")

            Button {
                router.push(.changeUsername)
            } label: {
                LabeledContent("Username", value: session.currentUser.map { "@\($0.username)" } ?? "—")
            }
            .accessibilityLabel("Username, \(session.currentUser?.username ?? "not set")")
        }
    }

    private func securitySection(appLock: Bindable<AppLockSettingsStore>) -> some View {
        Section("Security") {
            Button {
                router.push(.activeSessions)
            } label: {
                Label("Active sessions", systemImage: "laptopcomputer.and.iphone")
            }

            Toggle(isOn: appLock.isEnabled) {
                Label("Lock with \(self.appLock.biometryTitle)", systemImage: "lock.fill")
            }
            .disabled(!self.appLock.isBiometryAvailable)
            .accessibilityHint("Require biometrics when opening IBUgram")
        }
    }

    private func appearanceSection(appearance: Bindable<AppearanceSettingsStore>) -> some View {
        Section("Appearance") {
            Picker("Appearance", selection: appearance.preference) {
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
            Button {
                router.push(.blockedAccounts)
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
}

#Preview("Settings") {
    TabNavigationStack { SettingsView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
        .environment(AppearanceSettingsStore())
        .environment(AppLockSettingsStore())
}

#Preview("Settings · dark") {
    TabNavigationStack { SettingsView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
        .environment(AuthSessionStore(container: .preview()))
        .environment(AppearanceSettingsStore())
        .environment(AppLockSettingsStore())
        .preferredColorScheme(.dark)
}
