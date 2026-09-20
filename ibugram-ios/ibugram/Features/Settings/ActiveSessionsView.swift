import SwiftUI
import IBUgramKit

struct ActiveSessionsView: View {
    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @State private var viewModel: ActiveSessionsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Active sessions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let model = viewModel ?? ActiveSessionsViewModel(api: container.api)
            viewModel = model
            await model.load()
        }
    }

    private func content(_ viewModel: ActiveSessionsViewModel) -> some View {
        let bound = Bindable(viewModel)
        return Group {
            switch viewModel.phase {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.load() }
            case .loaded where viewModel.sessions.isEmpty:
                EmptyStateView(
                    systemImage: "laptopcomputer.and.iphone",
                    title: "No sessions",
                    message: "Devices signed in to this account will appear here."
                )
            case .loaded:
                List {
                    ForEach(viewModel.sessions) { session in
                        sessionRow(session, viewModel: viewModel)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .errorAlert(bound.presentedError)
    }

    private func sessionRow(_ session: Session, viewModel: ActiveSessionsViewModel) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            HStack {
                Text(session.title)
                    .font(theme.typography.bodyEmphasis)
                    .foregroundStyle(theme.colors.textPrimary)
                Spacer()
                if session.isCurrent {
                    TagChip(title: "This device", style: .brand)
                } else {
                    Button("Revoke", role: .destructive) {
                        Task { await viewModel.revoke(session) }
                    }
                    .accessibilityLabel("Revoke session \(session.title)")
                }
            }
            if let ip = session.ipAddress {
                Text(ip)
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            Text("Last used \(RelativeTimestamp.abbreviated(from: session.lastUsedAt))")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textTertiary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Sessions") {
    NavigationStack { ActiveSessionsView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
}

#Preview("Sessions · dark") {
    NavigationStack { ActiveSessionsView() }
        .appContainer(.preview(api: MockAPIClient(stubs: SettingsFixtures.stubs)))
        .preferredColorScheme(.dark)
}
