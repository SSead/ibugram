import MapKit
import SwiftUI
import IBUgramKit

struct CampusMapView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @Environment(Router.self) private var router
    @State private var viewModel: CampusMapViewModel?
    @State private var position: MapCameraPosition = .region(MapBoundingBox.campusRegion)

    var body: some View {
        Group {
            if let viewModel {
                map(viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Campus map")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? CampusMapViewModel(api: container.api)
            viewModel = model
            await model.load(region: MapBoundingBox.campusRegion)
        }
    }

    private func map(_ viewModel: CampusMapViewModel) -> some View {
        let bound = Bindable(viewModel)
        return ZStack {
            Map(position: $position) {
                ForEach(viewModel.pins) { pin in
                    Annotation(pin.title, coordinate: pin.coordinate, anchor: .bottom) {
                        Button {
                            router.push(pin.route)
                        } label: {
                            CampusMapPinMarker(systemImage: pin.systemImage)
                        }
                        .accessibilityLabel(pin.accessibilityLabel)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onMapCameraChange(frequency: .onEnd) { context in
                Task { await viewModel.load(region: context.region) }
            }

            if viewModel.phase == .loading && viewModel.pins.isEmpty {
                ProgressView()
            }

            if case .failed(let error) = viewModel.phase, viewModel.pins.isEmpty {
                ErrorStateView(error: error) {
                    await viewModel.load(region: MapBoundingBox.campusRegion)
                }
                .padding(theme.spacing.lg)
                .background(theme.colors.background.opacity(0.92), in: .rect(cornerRadius: theme.radii.md))
                .padding(theme.spacing.screenMargin)
            }
        }
        .errorAlert(bound.presentedError)
    }
}

#Preview("Campus map") {
    TabNavigationStack {
        CampusMapView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: MapFixtures.stubs)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Campus map · empty") {
    TabNavigationStack {
        CampusMapView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: ["GET /events/map": MapContents()])))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Campus map · error") {
    TabNavigationStack {
        CampusMapView()
    }
    .appContainer(.preview(api: MockAPIClient.failing(.offline)))
    .environment(AuthSessionStore(container: .preview()))
}

#Preview("Campus map · dark") {
    TabNavigationStack {
        CampusMapView()
    }
    .appContainer(.preview(api: MockAPIClient(stubs: MapFixtures.stubs)))
    .environment(AuthSessionStore(container: .preview()))
    .preferredColorScheme(.dark)
}
