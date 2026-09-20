import SwiftUI
import IBUgramKit

struct ChangeUsernameView: View {
    let currentUsername: String
    var onSaved: (User) -> Void

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChangeUsernameViewModel?

    var body: some View {
        Group {
            if let viewModel {
                form(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Username")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = viewModel ?? ChangeUsernameViewModel(
                api: container.api,
                currentUsername: currentUsername
            )
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func form(_ viewModel: ChangeUsernameViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: theme.spacing.lg) {
            IBUTextField(
                title: "Username",
                placeholder: "amina.h",
                text: bound.username,
                icon: "at",
                message: viewModel.message,
                validationState: viewModel.validationState
            )
            .onChange(of: viewModel.username) { _, _ in
                viewModel.usernameDidChange()
            }
            Button("Save") {
                Task { await save(viewModel) }
            }
            .buttonStyle(.ibuPrimary(isLoading: viewModel.isSubmitting))
            .disabled(!viewModel.canSubmit)
            Spacer()
        }
        .padding(theme.spacing.screenMargin)
        .errorAlert(bound.presentedError)
    }

    private func save(_ viewModel: ChangeUsernameViewModel) async {
        guard let updated = await viewModel.submit() else { return }
        onSaved(updated)
    }
}

#Preview("Change username") {
    NavigationStack {
        ChangeUsernameView(currentUsername: "amina.h", onSaved: { _ in })
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
}
