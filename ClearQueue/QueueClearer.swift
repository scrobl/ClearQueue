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

    /// Seconds to wait (with a visible countdown and a "Stay here" button) before opening the other app.
    @Published var returnDelay = UserDefaults.standard.object(forKey: "returnDelay") as? Int ?? 3 {
        didSet { UserDefaults.standard.set(returnDelay, forKey: "returnDelay") }
    }
    /// Seconds left before switching apps; nil when no switch is pending.
    @Published var returnCountdown: Int?
    private var returnTask: Task<Void, Never>?

    var returnTargetName: String {
        switch returnMode {
        case .stay: return ""
        case .music: return "Music"
        case .custom:
            let t = customScheme.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.replacingOccurrences(of: "://", with: "").capitalized
        }
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
    func appDidEnterBackground() {
        handledThisOpen = false
        cancelReturn() // never switch apps later on the user's behalf
    }

    private func show(_ message: String, isError: Bool, autoDismiss: Bool = true) {
        statusTask?.cancel()
        statusIsError = isError
        status = message
        guard !isError, autoDismiss else { return }
        scheduleDismiss()
    }

    private func scheduleDismiss(after seconds: Double = 4) {
        statusTask?.cancel()
        statusTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled { status = nil }
        }
    }

    private func returnURL() -> URL? {
        switch returnMode {
        case .stay: return nil
        case .music: return URL(string: "music://")
        case .custom:
            let t = customScheme.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return nil }
            return URL(string: t.contains("://") ? t : "\(t)://")
        }
    }

    /// iOS apps can't close themselves, but they can open another app. Counts down first so the
    /// user can cancel with "Stay here".
    private func startReturn(to url: URL) {
        returnTask?.cancel()
        returnTask = Task {
            var remaining = max(returnDelay, 1)
            while remaining > 0 {
                returnCountdown = remaining
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                remaining -= 1
            }
            returnCountdown = nil
            returnTask = nil
            if await UIApplication.shared.open(url) {
                status = nil
            } else {
                show("Couldn't open \(url.absoluteString). Check the app link in Settings.", isError: true)
            }
        }
    }

    /// The "Stay here" button.
    func cancelReturn() {
        guard returnTask != nil || returnCountdown != nil else { return }
        returnTask?.cancel()
        returnTask = nil
        returnCountdown = nil
        scheduleDismiss(after: 3)
    }

    func clearQueue() {
        guard !isWorking else { return }
        isWorking = true
        returnTask?.cancel(); returnTask = nil; returnCountdown = nil
        status = nil
        Task {
            do {
                let message = try await QueueClearing.clearKeepingCurrent()
                if let url = returnURL() {
                    show(message, isError: false, autoDismiss: false)
                    startReturn(to: url)
                } else {
                    show(message, isError: false)
                }
            }
            catch { show(error.localizedDescription, isError: true) }
            isWorking = false
            refresh()
        }
    }
}
