import PhotosUI
import SwiftUI
import IBUgramKit

struct MessageComposerBar: View {
    @Binding var text: String
    var isSending: Bool
    var onSend: () -> Void
    var onPickImage: (Data) -> Void

    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool
    @State private var pickerItem: PhotosPickerItem?
    @State private var isPickingPhoto = false

    var body: some View {
        HStack(alignment: .bottom, spacing: theme.spacing.xs) {
            Button {
                isPickingPhoto = true
            } label: {
                Image(systemName: "photo")
                    .font(theme.typography.titleSmall)
                    .foregroundStyle(theme.colors.brand)
                    .frame(width: theme.spacing.xxl, height: theme.spacing.xxl)
            }
            .disabled(isSending)
            .accessibilityLabel("Send a photo")
            .photosPicker(isPresented: $isPickingPhoto, selection: $pickerItem, matching: .images)

            TextField("Message…", text: $text, axis: .vertical)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1...5)
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit(onSend)
                .accessibilityLabel("Message")

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(canSend ? theme.colors.brand : theme.colors.textTertiary)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, theme.spacing.screenMargin)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.colors.separator)
                .frame(height: theme.spacing.hairline / 2)
        }
        .onChange(of: pickerItem) {
            Task { await ingestPickedPhoto() }
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private func ingestPickedPhoto() async {
        guard let pickerItem,
              let raw = try? await pickerItem.loadTransferable(type: Data.self),
              let jpeg = UIImage(data: raw)?.jpegData(compressionQuality: 0.85)
        else { return }
        self.pickerItem = nil
        onPickImage(jpeg)
    }
}

#Preview("Composer") {
    MessageComposerBar(text: .constant("See you at demo night"), isSending: false, onSend: {}, onPickImage: { _ in })
        .appContainer(.preview())
}
