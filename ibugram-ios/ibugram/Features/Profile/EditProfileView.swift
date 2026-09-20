import PhotosUI
import SwiftUI

struct EditProfileView: View {
    let user: User
    var onSaved: (User) -> Void

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditProfileViewModel?
    @State private var pickedPhoto: PhotosPickerItem?

    var body: some View {
        Group {
            if let viewModel {
                form(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = viewModel ?? EditProfileViewModel(api: container.api, user: user)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func form(_ viewModel: EditProfileViewModel) -> some View {
        let bound = Bindable(viewModel)
        return ScrollView {
            VStack(spacing: theme.spacing.lg) {
                avatarPicker(viewModel)
                IBUTextField(
                    title: "Display name",
                    placeholder: "Amina Hodžić",
                    text: bound.displayName,
                    icon: "person",
                    autocapitalization: .words
                )
                bioEditor(viewModel)
                departmentRow(viewModel)
                yearRow(viewModel)
                Button("Save") {
                    Task { await save(viewModel) }
                }
                .buttonStyle(.ibuPrimary(isLoading: viewModel.isSubmitting))
                .disabled(!viewModel.canSubmit)
            }
            .padding(theme.spacing.screenMargin)
        }
        .errorAlert(bound.presentedError)
        .task(id: pickedPhoto) { await loadPhoto(into: viewModel) }
    }

    private func avatarPicker(_ viewModel: EditProfileViewModel) -> some View {
        PhotosPicker(selection: $pickedPhoto, matching: .images) {
            OnboardingAvatarPreview(
                imageData: viewModel.avatarImageData,
                displayName: viewModel.trimmedDisplayName
            )
        }
        .accessibilityLabel("Change profile photo")
        .frame(maxWidth: .infinity)
    }

    private func bioEditor(_ viewModel: EditProfileViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text("Bio")
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.6)
            TextField("A short introduction", text: bound.bio, axis: .vertical)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(3...6)
                .padding(theme.spacing.md)
                .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.sm))
                .accessibilityLabel("Bio")
        }
    }

    private func departmentRow(_ viewModel: EditProfileViewModel) -> some View {
        let bound = Bindable(viewModel)
        return pickerRow("Department") {
            Picker("Department", selection: bound.department) {
                Text("Not set").tag("")
                ForEach(OnboardingViewModel.departments, id: \.self) { Text($0).tag($0) }
            }
        }
    }

    private func yearRow(_ viewModel: EditProfileViewModel) -> some View {
        let bound = Bindable(viewModel)
        return pickerRow("Year of study") {
            Picker("Year of study", selection: bound.yearOfStudy) {
                Text("Not set").tag(Int?.none)
                ForEach(1...5, id: \.self) { Text("Year \($0)").tag(Int?.some($0)) }
            }
        }
    }

    private func pickerRow<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
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
        .padding(theme.spacing.md)
        .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.sm))
    }

    private func loadPhoto(into viewModel: EditProfileViewModel) async {
        guard let pickedPhoto,
              let data = try? await pickedPhoto.loadTransferable(type: Data.self) else { return }
        viewModel.avatarImageData = data
    }

    private func save(_ viewModel: EditProfileViewModel) async {
        guard let updated = await viewModel.submit() else { return }
        onSaved(updated)
    }
}

#Preview("Edit profile") {
    NavigationStack {
        EditProfileView(user: ProfileFixtures.currentUser, onSaved: { _ in })
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ProfileFixtures.ownProfileStubs)))
}
