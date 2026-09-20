import PhotosUI
import SwiftUI

struct OnboardingFlowView: View {
    let user: User

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(AuthSessionStore.self) private var session
    @State private var viewModel: OnboardingViewModel?
    @State private var pickedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            BrandBackdrop()
            if let viewModel {
                content(viewModel)
            }
        }
        .onAppear { viewModel = viewModel ?? OnboardingViewModel(api: container.api, user: user) }
    }

    private func content(_ viewModel: OnboardingViewModel) -> some View {
        let bound = Bindable(viewModel)
        return ScrollView {
            VStack(spacing: theme.spacing.xl) {
                header
                avatarPicker(viewModel)
                identityFields(viewModel)
                studyFields(viewModel)
                Button("Join IBUgram") {
                    Task { await finish(viewModel) }
                }
                .buttonStyle(.ibuPrimary(isLoading: viewModel.isSubmitting))
                .disabled(!viewModel.canSubmit)
            }
            .padding(.horizontal, theme.spacing.screenMargin)
            .padding(.vertical, theme.spacing.xl)
        }
        .errorAlert(bound.presentedError)
        .task(id: pickedPhoto) { await loadPickedPhoto(into: viewModel) }
    }

    private var header: some View {
        VStack(spacing: theme.spacing.xs) {
            Text("Set up your profile")
                .font(theme.typography.displaySmall)
                .foregroundStyle(theme.colors.textPrimary)
            Text("This is how the Burch community will find you.")
                .font(theme.typography.subheadline)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func avatarPicker(_ viewModel: OnboardingViewModel) -> some View {
        let preview = OnboardingAvatarPreview(
            imageData: viewModel.avatarImageData,
            displayName: viewModel.trimmedDisplayName
        )
        return VStack(spacing: theme.spacing.xs) {
            PhotosPicker(selection: $pickedPhoto, matching: .images) { preview }
                .accessibilityLabel("Choose a profile photo")

            Text("Add a photo")
                .font(theme.typography.footnote)
                .foregroundStyle(theme.colors.textSecondary)
        }
    }

    private func identityFields(_ viewModel: OnboardingViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: theme.spacing.md) {
            IBUTextField(
                title: "Username",
                placeholder: "amina.h",
                text: bound.username,
                icon: "at",
                message: viewModel.usernameMessage,
                validationState: viewModel.usernameValidationState
            )
            IBUTextField(
                title: "Display name",
                placeholder: "Amina Hodžić",
                text: bound.displayName,
                icon: "person",
                autocapitalization: .words
            )
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.lg))
        .shadow(theme.shadows.card)
    }

    private func studyFields(_ viewModel: OnboardingViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(spacing: theme.spacing.sm) {
            pickerRow(title: "Department") {
                Picker("Department", selection: bound.department) {
                    Text("Not set").tag("")
                    ForEach(OnboardingViewModel.departments, id: \.self) { Text($0).tag($0) }
                }
            }
            Divider().overlay(theme.colors.separator)
            pickerRow(title: "Year of study") {
                Picker("Year of study", selection: bound.yearOfStudy) {
                    Text("Not set").tag(Int?.none)
                    ForEach(1...5, id: \.self) { Text("Year \($0)").tag(Int?.some($0)) }
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.lg))
        .shadow(theme.shadows.card)
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.6)
            Spacer(minLength: theme.spacing.xs)
            content()
                .labelsHidden()
                .tint(theme.colors.brand)
        }
    }

    private func loadPickedPhoto(into viewModel: OnboardingViewModel) async {
        guard let pickedPhoto,
              let data = try? await pickedPhoto.loadTransferable(type: Data.self) else { return }
        viewModel.avatarImageData = data
    }

    private func finish(_ viewModel: OnboardingViewModel) async {
        guard let updated = await viewModel.submit() else { return }
        session.completeOnboarding(with: updated)
    }
}

#Preview("Onboarding") {
    OnboardingFlowView(user: SampleData.newcomer)
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
}

#Preview("Onboarding · dark") {
    OnboardingFlowView(user: SampleData.newcomer)
        .appContainer(.preview())
        .environment(AuthSessionStore(container: .preview()))
        .preferredColorScheme(.dark)
}
