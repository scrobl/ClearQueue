# Clear Queue Support

**Nothing happens when I tap Clear Queue.** A song must be playing in the Music app (or another app that uses the system Music player). Check that access is allowed in Settings > Clear Queue > Media & Apple Music.

**There is a short pause in the audio.** iOS has no way for an app to edit the queue in place, so Clear Queue rebuilds it, which restarts the current song at the same position. A brief gap is expected.

**Auto-clear.** With "Clear automatically when opened" on, the queue is cleared once each time you open the app, not while it stays open.

**Opening another app afterwards.** iOS apps can't close themselves, but Clear Queue can open Apple Music or another app. Open the gear icon in the app to set it. For another app you need its URL scheme, such as `appname://`.

**Siri and Shortcuts.** Say "Clear queue in Clear Queue", or add the "Clear Music Queue" action in the Shortcuts app.

**Something else?** Open an issue at https://github.com/scrobl/ClearQueue/issues.
