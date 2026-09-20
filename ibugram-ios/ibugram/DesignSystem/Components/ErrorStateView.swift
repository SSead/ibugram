import SwiftUI

/// Full-screen failure state for content that could not load. Use `.errorAlert` instead when a
/// discrete user action failed.
struct ErrorStateView: View {
    let error: APIError
    var retry: (@MainActor () async -> Void)?

    @Environment(\.theme) private var theme
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: error == .offline ? "wifi.slash" : "exclamationmark.triangle")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(theme.colors.warning)

            Text(error == .offline ? "You are offline" : "Could not load")
                .font(theme.typography.titleSmall)
                .foregroundStyle(theme.colors.textPrimary)

            Text(error.userFacingDescription)
                .font(theme.typography.subheadline)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let retry {
                Button("Try again") {
                    Task {
                        isRetrying = true
                        await retry()
                        isRetrying = false
                    }
                }
                .buttonStyle(.ibuPrimary(isLoading: isRetrying))
                .padding(.top, theme.spacing.xs)
                .frame(maxWidth: 260)
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Error state") {
    ErrorStateView(error: .server(status: 500, code: "internal_error", message: ""), retry: {})
}

#Preview("Error state · dark") {
    ErrorStateView(error: .offline, retry: {})
        .preferredColorScheme(.dark)
}
