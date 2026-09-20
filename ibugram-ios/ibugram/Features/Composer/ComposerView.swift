import PhotosUI
import SwiftUI

struct ComposerView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ComposerViewModel?
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    editor(viewModel)
                }
            }
            .background(theme.colors.background)
            .navigationTitle("New post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .onAppear {
            viewModel = viewModel ?? ComposerViewModel(
                api: container.api,
                imageIntelligence: container.imageIntelligence
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .disabled(viewModel?.isPublishing == true)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Share") {
                Task { await publish() }
            }
            .font(theme.typography.bodyEmphasis)
            .disabled(!(viewModel?.canPublish ?? false))
            .accessibilityLabel("Share post")
        }
    }

    private func editor(_ viewModel: ComposerViewModel) -> some View {
        let bound = Bindable(viewModel)
        return ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                photos(viewModel)
                ComposerCaptionEditor(
                    caption: bound.caption,
                    characterCount: viewModel.characterCount,
                    isOverLimit: viewModel.isCaptionOverLimit
                )
                location(viewModel)
                spaces(viewModel)
                commentsToggle(viewModel)
                if let status = viewModel.publishStatus {
                    Text(status)
                        .font(theme.typography.footnote)
                        .foregroundStyle(theme.colors.textSecondary)
                        .accessibilityLabel(status)
                }
            }
            .padding(theme.spacing.screenMargin)
        }
        .scrollDismissesKeyboard(.interactively)
        .errorAlert(bound.presentedError)
        .onChange(of: pickerItems) {
            Task { await ingestPickedPhotos(into: viewModel) }
        }
    }

    private func photos(_ viewModel: ComposerViewModel) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            SectionHeader(
                title: "Photos",
                subtitle: "Up to \(ComposerLimits.maximumImageCount), in the order they will appear."
            )
            .padding(.horizontal, -theme.spacing.screenMargin)

            ForEach(Array(viewModel.images.enumerated()), id: \.element.id) { index, image in
                ComposerImageRow(
                    image: image,
                    canMoveUp: index > 0,
                    canMoveDown: index < viewModel.images.count - 1,
                    onAltTextChange: { viewModel.updateAltText(id: image.id, text: $0) },
                    onRemove: { viewModel.removeImage(id: image.id) },
                    onRetry: { viewModel.retryImage(id: image.id) },
                    onMoveUp: { viewModel.moveImage(id: image.id, by: -1) },
                    onMoveDown: { viewModel.moveImage(id: image.id, by: 1) }
                )
            }

            if viewModel.canAddMoreImages {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: viewModel.remainingImageSlots,
                    matching: .images
                ) {
                    Label("Add photos", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.ibuSecondary)
                .accessibilityLabel("Add photos")
            }
        }
    }

    private func location(_ viewModel: ComposerViewModel) -> some View {
        let bound = Bindable(viewModel)
        return VStack(alignment: .leading, spacing: theme.spacing.xs) {
            IBUTextField(
                title: "Location",
                placeholder: "Campus lawn",
                text: bound.locationName,
                icon: "mappin.and.ellipse",
                message: "Optional. Campus places can be picked below."
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(ComposerFixtures.campusPlaces, id: \.name) { place in
                        Button {
                            viewModel.locationName = place.name
                        } label: {
                            TagChip(
                                title: place.name,
                                icon: "mappin",
                                style: viewModel.locationName == place.name ? .brand : .neutral,
                                isSelected: viewModel.locationName == place.name
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(place.name)
                    }
                }
            }
        }
    }

    private func spaces(_ viewModel: ComposerViewModel) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Space")
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.6)
            HStack(spacing: theme.spacing.xs) {
                ForEach(ComposerFixtures.spaces) { space in
                    Button {
                        viewModel.selectedSpace = viewModel.selectedSpace?.id == space.id ? nil : space
                    } label: {
                        TagChip(
                            title: space.name,
                            icon: "person.3.fill",
                            style: viewModel.selectedSpace?.id == space.id ? .brand : .neutral,
                            isSelected: viewModel.selectedSpace?.id == space.id
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(space.name)
                    .accessibilityAddTraits(viewModel.selectedSpace?.id == space.id ? .isSelected : [])
                }
            }
        }
    }

    private func commentsToggle(_ viewModel: ComposerViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Toggle(isOn: bound.commentsEnabled) {
            VStack(alignment: .leading, spacing: theme.spacing.hairline) {
                Text("Allow comments")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                Text("People can reply on this post.")
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .tint(theme.colors.brand)
        .accessibilityLabel("Allow comments")
    }

    private func ingestPickedPhotos(into viewModel: ComposerViewModel) async {
        guard !pickerItems.isEmpty else { return }
        var data: [Data] = []
        for item in pickerItems {
            guard let raw = try? await item.loadTransferable(type: Data.self),
                  let jpeg = UIImage(data: raw)?.jpegData(compressionQuality: ComposerLimits.jpegQuality)
            else { continue }
            data.append(jpeg)
        }
        pickerItems = []
        await viewModel.addImages(data)
    }

    private func publish() async {
        guard let viewModel else { return }
        if await viewModel.publish() {
            dismiss()
        }
    }
}

#Preview("Composer") {
    ComposerView()
        .appContainer(.preview())
}

#Preview("Composer · dark") {
    ComposerView()
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
