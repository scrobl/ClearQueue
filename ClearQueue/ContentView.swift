import SwiftUI

struct ContentView: View {
    @StateObject private var clearer = QueueClearer()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 20) {
                Spacer(minLength: 0)
                Text("NOW PLAYING")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                    .opacity(clearer.hasSong ? 1 : 0)
                artwork
                    .layoutPriority(-1)
                VStack(spacing: 6) {
                    Text(clearer.hasSong ? clearer.title : "Nothing Playing")
                        .font(.title2.weight(.semibold))
                    if clearer.hasSong {
                        Text(clearer.artist).font(.headline).foregroundStyle(.secondary)
                        if !clearer.album.isEmpty {
                            Text(clearer.album).font(.subheadline).foregroundStyle(.tertiary)
                        }
                    } else {
                        Text("Start a song in the Music app first, then come back and tap Clear Queue.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                .multilineTextAlignment(.center)
                .lineLimit(clearer.hasSong ? 2 : 4)
                .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .background { background }
        .safeAreaInset(edge: .bottom) { controls }
        .overlay(alignment: .topTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.title3).padding(16)
            }
            .tint(.secondary)
        }
        .sheet(isPresented: $showSettings) { settings }
        .onAppear { clearer.appDidBecomeActive() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: clearer.appDidBecomeActive()
            case .background: clearer.appDidEnterBackground()
            default: break
            }
        }
    }

    private var settings: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("After clearing", selection: $clearer.returnMode) {
                        ForEach(ReturnMode.allCases) { Text($0.label).tag($0) }
                    }
                    if clearer.returnMode == .custom {
                        TextField("App link, e.g. marvis://", text: $clearer.customScheme)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                    if clearer.returnMode != .stay {
                        Picker("Switch after", selection: $clearer.returnDelay) {
                            ForEach([1, 2, 3, 5, 8], id: \.self) { Text("\($0) seconds").tag($0) }
                        }
                    }
                } footer: {
                    Text("iOS doesn't let an app close itself, so ClearQueue can open another app instead. A countdown appears after clearing, with a Stay here button to cancel. Another app needs its URL scheme, which you can usually find in its documentation.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSettings = false } } }
        }
        .presentationDetents([.medium, .large])
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: clearer.clearQueue) {
                Label("Clear Queue", systemImage: "text.badge.xmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.pink)
            .disabled(!clearer.hasSong || clearer.isWorking)

            Toggle("Clear automatically when opened", isOn: $clearer.autoClear)
                .tint(.pink)

            ZStack {
                if let status = clearer.status {
                    VStack(spacing: 8) {
                        Label(status, systemImage: clearer.statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(clearer.statusIsError ? Color.orange : Color.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                (clearer.statusIsError ? Color.orange : Color.green).opacity(0.15),
                                in: Capsule()
                            )
                        if let seconds = clearer.returnCountdown {
                            HStack(spacing: 12) {
                                Text("Opening \(clearer.returnTargetName) in \(seconds)…")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                Button("Stay here") { clearer.cancelReturn() }
                                    .buttonStyle(.bordered)
                                    .tint(.pink)
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text(clearer.autoClear
                         ? "Clears once each time you open the app. Use the button to clear again."
                         : "Off. Use the button to clear manually.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(minHeight: clearer.returnMode == .stay ? 48 : 96)
            .animation(.spring(duration: 0.35), value: clearer.status)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var artwork: some View {
        Group {
            if let image = clearer.artwork {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ZStack {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "music.note").font(.system(size: 64)).foregroundStyle(.secondary)
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .frame(maxWidth: 320, maxHeight: 320)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }

    private var background: some View {
        ZStack {
            Color(.systemBackground)
            if let image = clearer.artwork {
                Image(uiImage: image).resizable().scaledToFill()
                    .blur(radius: 60).opacity(0.35)
            }
        }
        .clipped()
        .ignoresSafeArea()
        .animation(.easeInOut, value: clearer.artwork)
    }
}
