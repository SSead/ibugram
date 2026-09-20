import SwiftUI
import IBUgramKit

struct VerifyCodeView: View {
    let verification: PendingVerification

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @State private var viewModel: VerifyCodeViewModel?

    var body: some View {
        ZStack {
            BrandBackdrop()
            if let viewModel {
                content(viewModel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prepareViewModel)
        .onDisappear { viewModel?.stopResendCountdown() }
    }

    private func content(_ viewModel: VerifyCodeViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: theme.spacing.xl) {
            header
            OneTimeCodeField(
                code: bound.code,
                length: VerifyCodeViewModel.codeLength,
                isErrored: viewModel.hasFailedAttempt
            )
            actions(viewModel)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.top, theme.spacing.xl)
        .errorAlert(bound.presentedError)
        .onChange(of: viewModel.code) { _, newValue in
            guard newValue.count == VerifyCodeViewModel.codeLength else { return }
            Task { await submit(viewModel) }
        }
    }

    private var header: some View {
        VStack(spacing: theme.spacing.xs) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(theme.colors.brand)
            Text("Check your inbox")
                .font(theme.typography.displaySmall)
                .foregroundStyle(theme.colors.textPrimary)
            Text("We sent a 6-digit code to \(verification.email).")
                .font(theme.typography.subheadline)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func actions(_ viewModel: VerifyCodeViewModel) -> some View {
        VStack(spacing: theme.spacing.sm) {
            Button("Verify and continue") {
                Task { await submit(viewModel) }
            }
            .buttonStyle(.ibuPrimary(isLoading: viewModel.isVerifying))
            .disabled(!viewModel.canSubmit)

            Button(viewModel.resendTitle) {
                Task { await viewModel.resendCode() }
            }
            .buttonStyle(.ibuSecondary(isLoading: viewModel.isResending))
            .disabled(!viewModel.canResend)

            if let debugCode = verification.debugCode {
                Button("Use development code \(debugCode)") { viewModel.code = debugCode }
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textTertiary)
            }
        }
    }

    private func prepareViewModel() {
        guard viewModel == nil else { return }
        let model = VerifyCodeViewModel(verification: verification, api: container.api)
        model.startResendCountdown()
        viewModel = model
    }

    private func submit(_ viewModel: VerifyCodeViewModel) async {
        guard let authSession = await viewModel.verify() else { return }
        await session.begin(authSession)
    }
}

#Preview("Verify code") {
    NavigationStack {
        VerifyCodeView(verification: PendingVerification(
            email: "amina.hodzic@stu.ibu.edu.ba",
            challenge: SampleData.codeChallenge
        ))
    }
    .appContainer(.preview())
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Verify code · dark") {
    NavigationStack {
        VerifyCodeView(verification: PendingVerification(
            email: "amina.hodzic@stu.ibu.edu.ba",
            challenge: SampleData.codeChallenge
        ))
    }
    .appContainer(.preview())
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
