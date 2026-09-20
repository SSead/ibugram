import SwiftUI

/// Six boxed digits backed by one hidden field, so paste, autofill and the keyboard all behave
/// like a normal text field while the presentation stays custom.
struct OneTimeCodeField: View {
    @Binding var code: String
    let length: Int
    var isErrored = false

    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            hiddenField
            HStack(spacing: theme.spacing.xs) {
                ForEach(0..<length, id: \.self) { index in
                    digitBox(at: index)
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(.rect)
        .onTapGesture { isFocused = true }
        .onAppear { isFocused = true }
        .accessibilityElement()
        .accessibilityLabel("Six digit verification code")
        .accessibilityValue(code.isEmpty ? "empty" : code.map(String.init).joined(separator: " "))
    }

    private var hiddenField: some View {
        TextField("", text: $code)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isFocused)
            .opacity(0.01)
            .frame(height: 1)
    }

    private func digitBox(at index: Int) -> some View {
        let digit = character(at: index)
        let isActive = isFocused && code.count == index
        return Text(digit.map(String.init) ?? "")
            .font(theme.typography.monospacedCode)
            .foregroundStyle(theme.colors.textPrimary)
            .frame(width: 46, height: 58)
            .background(theme.colors.surface, in: .rect(cornerRadius: theme.radii.sm))
            .overlay {
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .strokeBorder(borderColor(isActive: isActive, isFilled: digit != nil), lineWidth: isActive ? 2 : 1)
            }
            .shadow(theme.shadows.subtle)
            .animation(theme.motion.quick, value: isActive)
            .animation(theme.motion.quick, value: digit)
    }

    private func borderColor(isActive: Bool, isFilled: Bool) -> Color {
        if isErrored { return theme.colors.destructive }
        if isActive { return theme.colors.brand }
        return isFilled ? theme.colors.brand.opacity(0.45) : theme.colors.separator
    }

    private func character(at index: Int) -> Character? {
        guard index < code.count else { return nil }
        return code[code.index(code.startIndex, offsetBy: index)]
    }
}

private struct CodeFieldGallery: View {
    @State private var partial = "4829"
    @State private var errored = "12"

    var body: some View {
        VStack(spacing: 32) {
            OneTimeCodeField(code: $partial, length: 6)
            OneTimeCodeField(code: $errored, length: 6, isErrored: true)
        }
        .padding(20)
    }
}

#Preview("Code field") {
    CodeFieldGallery()
}

#Preview("Code field · dark") {
    CodeFieldGallery()
        .preferredColorScheme(.dark)
}
