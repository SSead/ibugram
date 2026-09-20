import SwiftUI

extension View {
    /// The app's single error-presentation affordance for failed actions. Use `ErrorStateView`
    /// instead when an entire screen failed to load.
    func errorAlert(_ error: Binding<PresentedError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

private struct ErrorAlertModifier: ViewModifier {
    @Binding var error: PresentedError?

    func body(content: Content) -> some View {
        content.alert(
            error?.title ?? "",
            isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } }),
            presenting: error
        ) { presented in
            if let retry = presented.retry {
                Button("Try again") { Task { await retry() } }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: { presented in
            Text(presented.message)
        }
    }
}
