import SwiftUI

extension EnvironmentValues {
    @Entry var appContainer: AppContainer = .preview()
}

extension View {
    func appContainer(_ container: AppContainer) -> some View {
        environment(\.appContainer, container)
    }
}
