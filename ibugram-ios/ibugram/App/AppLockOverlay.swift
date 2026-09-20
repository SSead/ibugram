import LocalAuthentication
import SwiftUI

struct AppLockOverlay: View {
    @Environment(AppLockSettingsStore.self) private var settings
    @Environment(\.theme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLocked = false
    @State private var isAuthenticating = false
    @State private var statusMessage: String?

    var body: some View {
        Group {
            if isLocked {
                lockScreen
                    .transition(.opacity)
            }
        }
        .onAppear { lockIfRequired() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                lockIfRequired()
            case .active:
                if isLocked { Task { await authenticate() } }
            default:
                break
            }
        }
    }

    private var lockScreen: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: theme.spacing.lg) {
                AppMarkView(dimension: 72)
                Text("IBUgram is locked")
                    .font(theme.typography.titleSmall)
                    .foregroundStyle(theme.colors.textPrimary)
                if let statusMessage {
                    Text(statusMessage)
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Button(isAuthenticating ? "Unlocking…" : "Unlock") {
                    Task { await authenticate() }
                }
                .buttonStyle(.ibuPrimary(isLoading: isAuthenticating))
                .disabled(isAuthenticating)
                .accessibilityLabel("Unlock IBUgram")
            }
            .padding(.horizontal, theme.spacing.xxl)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func lockIfRequired() {
        guard settings.shouldLock else {
            isLocked = false
            return
        }
        isLocked = true
        statusMessage = nil
    }

    private func authenticate() async {
        guard settings.shouldLock else {
            isLocked = false
            return
        }
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isLocked = false
            return
        }

        do {
            let reason = "Unlock IBUgram"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                isLocked = false
                statusMessage = nil
            }
        } catch {
            statusMessage = "Authentication was cancelled. You can try again."
        }
    }
}

#Preview("Lock overlay") {
    AppLockOverlay()
        .environment(AppLockSettingsStore())
        .appContainer(.preview())
}
