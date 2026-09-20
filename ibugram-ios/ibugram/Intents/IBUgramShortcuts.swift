import AppIntents

struct IBUgramShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WhatsHappeningAtBurchIntent(),
            phrases: [
                "What's happening at Burch in \(.applicationName)",
                "What's happening at \(.applicationName)"
            ],
            shortTitle: "What's happening at Burch?",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: PostToIBUgramIntent(),
            phrases: [
                "Post to \(.applicationName)"
            ],
            shortTitle: "Post to IBUgram",
            systemImageName: "plus.square"
        )
    }
}
