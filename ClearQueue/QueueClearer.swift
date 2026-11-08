import MediaPlayer
import UIKit

enum ReturnMode: String, CaseIterable, Identifiable {
    case stay, music, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .stay: return "Stay in ClearQueue"
        case .music: return "Open Apple Music"
        case .custom: return "Open another app"
        }
    }
}

@MainActor
final class QueueClearer: ObservableObject {
    @Published var title = ""
    @Published var artist = ""
    @Published var album = ""
    @Published var artwork: UIImage?
    @Published var hasSong = false
    @Published var status: String?
    @Published var statusIsError = false
    private var statusTask: Task<Void, Never>?
    @Published var isWorking = false
    /// When on, the queue is cleared once each time the app is opened. Never while it stays open.
    @Published var autoClear = UserDefaults.standard.bool(forKey: "autoClear") {
        didSet { UserDefaults.standard.set(autoClear, forKey: "autoClear") }
    }

    @Published var returnMode = ReturnMode(rawValue: UserDefaults.standard.string(forKey: "returnMode") ?? "") ?? .stay {
        didSet { UserDefaults.standard.set(returnMode.rawValue, forKey: "returnMode") }
    }
    /// URL scheme of another music app, e.g. "marvis" or "marvis://".
    @Published var customScheme = UserDefaults.standard.string(forKey: "customScheme") ?? "" {
        didSet { UserDefaults.standard.set(customScheme, forKey: "customScheme") }
    }

    private var handledThisOpen = false
    private let player = MPMusicPlayerController.systemMusicPlayer
    private var observer: NSObjectProtocol?

    init() {
        player.beginGeneratingPlaybackNotifications()
        observer = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player, queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        refresh()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        player.endGeneratingPlaybackNotifications()
    }

    func refresh() {
        guard let item = player.nowPlayingItem else {
            hasSong = false; title = ""; artist = ""; album = ""; artwork = nil
            return
        }
        hasSong = true
        title = item.title ?? "Unknown Song"
        artist = item.artist ?? "Unknown Artist"
        album = item.albumTitle ?? ""
        artwork = item.artwork?.image(at: CGSize(width: 600, height: 600))
    }

    /// Called when the app becomes active. Auto-clears at most once per open.
    func appDidBecomeActive() {
        refresh()
        guard !handledThisOpen else { return }
        handledThisOpen = true
        if autoClear { clearQueue() }
    }

    /// The next time the app is opened counts as a new open.
    func appDidEnterBackground() { handledThisOpen = false }

    private func show(_ message: String, isError: Bool) {
        statusTask?.cancel()
        statusIsError = isError
        status = message
        guard !isError else { return }
        statusTask = Task {
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { status = nil }
        }
    }

    /// iOS apps can't close themselves, but they can open another app.
    private func returnToMusicApp() async {
        let url: URL?
        switch returnMode {
        case .stay: return
        case .music: url = URL(string: "music://")
        case .custom:
            let t = customScheme.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return }
            url = URL(string: t.contains("://") ? t : "\(t)://")
        }
        guard let url else { return }
        try? await Task.sleep(for: .milliseconds(700)) // let the confirmation show briefly
        if !(await UIApplication.shared.open(url)) {
            show("Couldn't open \(url.absoluteString). Check the app link in Settings.", isError: true)
        }
    }

    func clearQueue() {
        guard !isWorking else { return }
        isWorking = true
        status = nil
        Task {
            do {
                show(try await QueueClearing.clearKeepingCurrent(), isError: false)
                await returnToMusicApp()
            }
            catch { show(error.localizedDescription, isError: true) }
            isWorking = false
            refresh()
        }
    }
}
