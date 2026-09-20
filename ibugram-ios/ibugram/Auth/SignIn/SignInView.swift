import SwiftUI
import IBUgramKit

struct SignInView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @State private var viewModel: SignInViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackdrop()
                if let viewModel {
                    form(viewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { viewModel = viewModel ?? SignInViewModel(api: container.api) }
    }

    private func form(_ viewModel: SignInViewModel) -> some View {
        let bound = Bindable(viewModel)
        return ScrollView {
            VStack(spacing: theme.spacing.xl) {
                Spacer(minLength: theme.spacing.xl)
                header
                emailCard(viewModel)
                footnote
                Spacer(minLength: theme.spacing.md)
                capabilities
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.bottom, theme.spacing.xl)
            .containerRelativeFrame(.vertical)
        }
        .scrollBounceBehavior(.basedOnSize)
        .errorAlert(bound.presentedError)
        .navigationDestination(item: bound.pendingVerification) { VerifyCodeView(verification: $0) }
    }

    private var header: some View {
        VStack(spacing: theme.spacing.sm) {
            AppMarkView()
            Text("IBUgram")
                .font(theme.typography.displayLarge)
                .foregroundStyle(theme.colors.brand)
            Text("The Burch campus, in one place.")
                .font(theme.typography.titleSmall)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var capabilities: some View {
        VStack(spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.xs) {
                TagChip(title: "Spaces", icon: "person.3.fill")
                TagChip(title: "Campus events", icon: "calendar")
                TagChip(title: "Messages", icon: "bubble.left.and.bubble.right.fill")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("IBUgram includes Spaces, campus events and messages")

            BrandWordmark(height: 26)
                .opacity(0.65)
        }
    }

    private func emailCard(_ viewModel: SignInViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(alignment: .leading, spacing: theme.spacing.md) {
            IBUTextField(
                title: "University email",
                placeholder: "name@stu.ibu.edu.ba",
                text: bound.email,
                icon: "envelope",
                message: viewModel.inlineMessage,
                validationState: viewModel.validationState,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                isSubmitLabelDone: true
            )

            if let roleHint = viewModel.roleHint {
                TagChip(title: roleHint, icon: "person.badge.shield.checkmark", style: .brand)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            Button("Send me a code") {
                Task { await viewModel.requestCode() }
            }
            .buttonStyle(.ibuPrimary(isLoading: viewModel.isRequestingCode))
            .disabled(!viewModel.canRequestCode)
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.lg))
        .shadow(theme.shadows.card)
        .animation(theme.motion.standard, value: viewModel.roleHint)
    }

    private var footnote: some View {
        Text("No passwords. We email you a one-time code that expires in 10 minutes.")
            .font(theme.typography.footnote)
            .foregroundStyle(theme.colors.textTertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Sign in") {
    SignInView()
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Sign in · dark") {
    SignInView()
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
