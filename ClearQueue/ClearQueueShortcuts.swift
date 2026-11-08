import AppIntents

struct ClearQueueShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ClearQueueIntent(),
            phrases: [
                "Clear queue in \(.applicationName)",
                "Clear my Music queue with \(.applicationName)"
            ],
            shortTitle: "Clear Queue",
            systemImageName: "text.line.first.and.arrowtriangle.forward"
        )
    }
}
