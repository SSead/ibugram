import SwiftUI

/// Wraps a tab's root screen in its own `NavigationStack` and `Router`. Any screen inside can
/// push any `Route` by reading `@Environment(Router.self)`.
struct TabNavigationStack<Root: View>: View {
    @State private var router = Router()
    private let root: () -> Root

    init(@ViewBuilder root: @escaping () -> Root) {
        self.root = root
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            root()
                .navigationDestination(for: Route.self) { RouteDestinationView(route: $0) }
        }
        .environment(router)
    }
}
