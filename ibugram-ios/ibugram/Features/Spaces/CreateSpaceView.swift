import SwiftUI
import IBUgramKit

struct CreateSpaceView: View {
    var currentUser: User?
    var onCreated: (Space) -> Void

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateSpaceViewModel?

    var body: some View {
        Group {
            if let viewModel {
                form(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("New Space")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = viewModel ?? CreateSpaceViewModel(api: container.api, currentUser: currentUser)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func form(_ viewModel: CreateSpaceViewModel) -> some View {
        let bound = Bindable(viewModel)
        return ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                IBUTextField(
                    title: "Name",
                    placeholder: "IBU Robotics",
                    text: bound.name,
                    icon: "person.3"
                )
                .onChange(of: viewModel.name) { _, _ in viewModel.nameDidChange() }

                IBUTextField(
                    title: "Slug",
                    placeholder: "ibu-robotics",
                    text: bound.slug,
                    icon: "link",
                    message: SpaceSlug.isValid(viewModel.slug) || viewModel.slug.isEmpty
                        ? nil
                        : "Use 3–40 lowercase letters, numbers and hyphens.",
                    validationState: slugState(viewModel)
                )
                .onChange(of: viewModel.slug) { _, _ in viewModel.slugDidChange() }

                IBUTextField(
                    title: "Description",
                    placeholder: "What is this Space about?",
                    text: bound.description
                )

                kindPicker(viewModel)
                visibilityPicker(viewModel)

                if viewModel.canMarkOfficial {
                    Toggle("Official Space", isOn: bound.isOfficial)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textPrimary)
                        .tint(theme.colors.brand)
                        .accessibilityHint("Only faculty can create official Spaces")
                }

                Button("Create Space") {
                    Task { await submit(viewModel) }
                }
                .buttonStyle(.ibuPrimary(isLoading: viewModel.isSubmitting))
                .disabled(!viewModel.canSubmit)
            }
            .padding(theme.spacing.screenMargin)
        }
        .errorAlert(bound.presentedError)
    }

    private func kindPicker(_ viewModel: CreateSpaceViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text("Kind")
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.textSecondary)
            Picker("Kind", selection: bound.kind) {
                ForEach(SpaceKind.allCases, id: \.self) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Space kind")
        }
    }

    private func visibilityPicker(_ viewModel: CreateSpaceViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text("Visibility")
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.textSecondary)
            Picker("Visibility", selection: bound.visibility) {
                ForEach(SpaceVisibility.allCases, id: \.self) { visibility in
                    Text(visibility.title).tag(visibility)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Space visibility")
        }
    }

    private func slugState(_ viewModel: CreateSpaceViewModel) -> IBUTextField.ValidationState {
        if viewModel.slug.isEmpty { return .neutral }
        return SpaceSlug.isValid(viewModel.slug) ? .valid : .invalid
    }

    private func submit(_ viewModel: CreateSpaceViewModel) async {
        guard let space = await viewModel.submit() else { return }
        onCreated(space)
    }
}

#Preview("Create · student") {
    NavigationStack {
        CreateSpaceView(currentUser: SampleData.amina, onCreated: { _ in })
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.browseStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Create · faculty") {
    NavigationStack {
        CreateSpaceView(currentUser: SampleData.professorKovac, onCreated: { _ in })
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.browseStubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Create · dark") {
    NavigationStack {
        CreateSpaceView(currentUser: SampleData.professorKovac, onCreated: { _ in })
    }
    .appContainer(.preview(api: MockAPIClient(stubs: SpaceFixtures.browseStubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
