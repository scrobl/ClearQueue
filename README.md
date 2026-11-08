# Clear Queue

A small iPhone app that clears the Apple Music queue and keeps the song that is playing. One button, a widget, a Shortcuts/Siri action, and optional auto-clear when the app opens.

It uses only public APIs (`MediaPlayer`). iOS can't edit the system queue in place, so the current song is re-queued on its own and resumed at the same position, which causes a brief pause.

## Install

App Store link: coming soon.

## Build it yourself

Requires Xcode and an Apple ID (a free one works, but installs expire after 7 days).

```bash
cp Config/Local.example.xcconfig Config/Local.xcconfig   # then edit it: your Team ID and a bundle ID prefix you own
open ClearQueue.xcodeproj
```

Choose your iPhone and press Run. The project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`xcodegen generate`); the generated project is committed, so XcodeGen is only needed if you change `project.yml`.

## Privacy

No data is collected. See the [privacy policy](docs/privacy.md).

## License

MIT, see [LICENSE](LICENSE).
