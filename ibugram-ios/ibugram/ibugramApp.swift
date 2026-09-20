import SwiftUI

@main
struct IBUgramApp: App {
    @State private var container = LaunchConfiguration.current.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .appContainer(container)
        }
    }
}
