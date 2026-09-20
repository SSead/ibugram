import SwiftUI

struct ActivityPlaceholderView: View {
    var body: some View {
        TeamHandoffView(
            tab: .activity,
            owner: "Notifications & Realtime",
            brief: "Grouped activity feed fed by REST on cold start and by the WebSocket while connected.",
            entryPoint: "ibugram/Features/Activity/ActivityPlaceholderView.swift",
            sampleRoutes: [
                ("Open a conversation", .conversation(id: SampleData.amina.id)),
                ("Open an event", .event(id: SampleData.professorKovac.id))
            ]
        )
    }
}

#Preview("Activity tab") {
    TabNavigationStack { ActivityPlaceholderView() }
        .appContainer(.preview())
}

#Preview("Activity tab · dark") {
    TabNavigationStack { ActivityPlaceholderView() }
        .appContainer(.preview())
        .preferredColorScheme(.dark)
}
