import AppIntents

struct ClearQueueIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear Music Queue"
    static var description = IntentDescription("Clears the Music queue, keeping only the song that is playing now.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await QueueClearing.clearKeepingCurrent()
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
