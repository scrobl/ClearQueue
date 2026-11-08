import MediaPlayer

enum QueueClearError: LocalizedError {
    case accessDenied
    case nothingPlaying
    case prepareFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Media library access denied. Open ClearQueue once and allow access, or enable it in Settings > ClearQueue."
        case .nothingPlaying: return "Nothing is playing."
        case .prepareFailed(let m): return "prepareToPlay failed: \(m)"
        }
    }
}

/// Shared by the app UI and the App Intent.
@MainActor
enum QueueClearing {
    /// Resets the queue to just the current song and resumes near the same position.
    static func clearKeepingCurrent() async throws -> String {
        var auth = MPMediaLibrary.authorizationStatus()
        if auth == .notDetermined {
            auth = await withCheckedContinuation { c in
                MPMediaLibrary.requestAuthorization { c.resume(returning: $0) }
            }
        }
        guard auth == .authorized else { throw QueueClearError.accessDenied }

        let player = MPMusicPlayerController.systemMusicPlayer
        guard let now = player.nowPlayingItem else { throw QueueClearError.nothingPlaying }
        let t = player.currentPlaybackTime
        let wasPlaying = player.playbackState == .playing

        // Apple Music catalog items have a store ID; local/uploaded items report "0".
        if now.playbackStoreID != "0", !now.playbackStoreID.isEmpty {
            player.setQueue(with: [now.playbackStoreID])
        } else {
            player.setQueue(with: MPMediaItemCollection(items: [now]))
        }

        let err: Error? = await withCheckedContinuation { c in
            player.prepareToPlay { c.resume(returning: $0) }
        }
        if let err { throw QueueClearError.prepareFailed(err.localizedDescription) }

        player.currentPlaybackTime = t
        if wasPlaying { player.play() }
        return "Queue cleared."
    }
}
