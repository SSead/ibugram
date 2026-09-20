import SwiftUI

struct SettingsPlaceholderView: View {
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session

    var body: some View {
        List {
            Section("Account") {
                LabeledContent("Signed in as", value: session.currentUser?.username ?? "—")
                Button("Active sessions") {}
                    .disabled(true)
            }
            Section {
                Button("Sign out", role: .destructive) {
                    Task { await session.signOut() }
                }
            } footer: {
                Text("Settings is owned by the Identity & Access team. Entry point: ibugram/Features/Settings/SettingsPlaceholderView.swift")
            }
        }
        .listStyle(.insetGrouped)
        .tint(theme.colors.brand)
        .navigationTitle("Settings")
    }
}

#Preview("Settings") {
    NavigationStack { SettingsPlaceholderView() }
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Settings · dark") {
    NavigationStack { SettingsPlaceholderView() }
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
