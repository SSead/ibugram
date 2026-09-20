import SwiftUI
import IBUgramKit

struct IBUTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var message: String?
    var validationState: ValidationState = .neutral
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never
    var isSubmitLabelDone = false

    enum ValidationState: Equatable {
        case neutral
        case valid
        case invalid
    }

    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(title)
                .font(theme.typography.captionEmphasis)
                .foregroundStyle(theme.colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.6)

            field

            if let message {
                Text(message)
                    .font(theme.typography.footnote)
                    .foregroundStyle(messageColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .animation(theme.motion.quick, value: message)
    }

    private var field: some View {
        HStack(spacing: theme.spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(theme.colors.textTertiary)
            }
            TextField(placeholder, text: $text)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .submitLabel(isSubmitLabelDone ? .done : .next)
                .focused($isFocused)
            if validationState == .valid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.colors.success)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.surfaceSunken, in: .rect(cornerRadius: theme.radii.sm))
        .overlay {
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .strokeBorder(borderColor, lineWidth: isFocused ? 1.6 : 1)
        }
        .animation(theme.motion.quick, value: isFocused)
        .animation(theme.motion.quick, value: validationState)
        .accessibilityLabel(title)
    }

    private var borderColor: Color {
        switch validationState {
        case .invalid: theme.colors.destructive
        case .valid: theme.colors.success.opacity(0.6)
        case .neutral: isFocused ? theme.colors.brand : theme.colors.separator
        }
    }

    private var messageColor: Color {
        validationState == .invalid ? theme.colors.destructive : theme.colors.textSecondary
    }
}

private struct TextFieldGallery: View {
    @State private var valid = "amina.hodzic@stu.ibu.edu.ba"
    @State private var invalid = "amina@gmail.com"
    @State private var empty = ""

    var body: some View {
        VStack(spacing: 24) {
            IBUTextField(
                title: "University email",
                placeholder: "name@stu.ibu.edu.ba",
                text: $valid,
                icon: "envelope",
                message: "We will send a 6-digit code.",
                validationState: .valid,
                keyboardType: .emailAddress
            )
            IBUTextField(
                title: "University email",
                placeholder: "name@stu.ibu.edu.ba",
                text: $invalid,
                icon: "envelope",
                message: "gmail.com is not a Burch address.",
                validationState: .invalid
            )
            IBUTextField(title: "Username", placeholder: "amina.h", text: $empty, icon: "at")
        }
        .padding(20)
    }
}

#Preview("Text field") {
    TextFieldGallery()
}

#Preview("Text field · dark") {
    TextFieldGallery()
        .preferredColorScheme(.dark)
}
