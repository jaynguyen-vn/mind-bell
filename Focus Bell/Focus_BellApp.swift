import SwiftUI
import AVFoundation
import Cocoa
import UniformTypeIdentifiers
import ServiceManagement

enum TimerMode {
    case once
    case `repeat`
}

enum SoundSource {
    case preset
    case custom
}

enum AlertSound: String, CaseIterable {
    case singingBowl = "singing-bowl"
    case zenBell = "zen-bell"
    case windChime = "wind-chime"
    case chime = "chime"
    case bikeBell = "bike-bell-ring"
    case schoolBell = "school-bell"
    case airportAnnouncementBell = "airport-announcement-ding"
    case templeBell = "temple-bell"
    case xylophone = "xylophone"

    var displayName: String {
        switch self {
        case .singingBowl: return "Singing Bowl"
        case .zenBell: return "Zen Bell"
        case .windChime: return "Wind Chime"
        case .chime: return "Chime"
        case .bikeBell: return "Bike Bell"
        case .schoolBell: return "School Bell"
        case .airportAnnouncementBell: return "Airport"
        case .templeBell: return "Temple Bell"
        case .xylophone: return "Xylophone"
        }
    }

    var icon: String {
        switch self {
        case .singingBowl: return "circle.circle"
        case .zenBell: return "bell"
        case .windChime: return "wind"
        case .chime: return "bell.fill"
        case .bikeBell: return "bicycle"
        case .schoolBell: return "bell.badge"
        case .airportAnnouncementBell: return "airplane"
        case .templeBell: return "building.columns"
        case .xylophone: return "pianokeys"
        }
    }
}

class TimerViewModel: ObservableObject {
    @Published var timeLeft: Int = 0
    @Published var initialTime: Int = 8 {
        didSet { UserDefaults.standard.set(initialTime, forKey: "initialTime") }
    }
    @Published var isRunning = false
    @Published var mode: TimerMode = .once
    @Published var taskName: String = ""
    @Published var selectedSound: AlertSound = .singingBowl {
        didSet { UserDefaults.standard.set(selectedSound.rawValue, forKey: "selectedSound") }
    }
    @Published var soundSource: SoundSource = .preset {
        didSet { UserDefaults.standard.set(soundSource == .custom, forKey: "isCustomSound") }
    }
    @Published var customSoundURL: URL? {
        didSet {
            // Save bookmark data so the app can re-access the file after restart
            guard let url = customSoundURL else {
                UserDefaults.standard.removeObject(forKey: "customSoundBookmark")
                return
            }
            if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                UserDefaults.standard.set(bookmark, forKey: "customSoundBookmark")
            }
        }
    }
    @Published var customSoundName: String = "" {
        didSet { UserDefaults.standard.set(customSoundName, forKey: "customSoundName") }
    }

    @Published var launchAtLogin: Bool = false

    weak var delegate: TimerUpdateDelegate?
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?

    var progress: Double {
        guard initialTime > 0 else { return 0 }
        let total = Double(initialTime * 60)
        return total > 0 ? Double(timeLeft) / total : 0
    }

    init() {
        restoreSavedSettings()
        loadCurrentSound()
        if #available(macOS 13.0, *) {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    private func restoreSavedSettings() {
        // Restore duration (default 8 if never saved)
        let savedTime = UserDefaults.standard.integer(forKey: "initialTime")
        if savedTime > 0 { initialTime = savedTime }

        // Restore preset sound
        if let savedSound = UserDefaults.standard.string(forKey: "selectedSound"),
           let sound = AlertSound(rawValue: savedSound) {
            selectedSound = sound
        }

        // Restore custom sound
        let isCustom = UserDefaults.standard.bool(forKey: "isCustomSound")
        customSoundName = UserDefaults.standard.string(forKey: "customSoundName") ?? ""

        if isCustom, let bookmarkData = UserDefaults.standard.data(forKey: "customSoundBookmark") {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale),
               url.startAccessingSecurityScopedResource(),
               FileManager.default.fileExists(atPath: url.path) {
                customSoundURL = url
                soundSource = .custom
                if isStale {
                    // Re-save bookmark if stale
                    self.customSoundURL = url
                }
            } else {
                // File deleted or inaccessible — fallback to preset
                soundSource = .preset
                customSoundName = ""
                UserDefaults.standard.removeObject(forKey: "customSoundBookmark")
            }
        }
    }

    private func loadCurrentSound() {
        switch soundSource {
        case .preset:
            loadPresetSound(selectedSound)
        case .custom:
            if let url = customSoundURL, FileManager.default.fileExists(atPath: url.path) {
                loadCustomSound(from: url)
            } else {
                // File gone — fallback to preset
                soundSource = .preset
                customSoundURL = nil
                customSoundName = ""
                loadPresetSound(selectedSound)
            }
        }
    }

    private func loadPresetSound(_ sound: AlertSound) {
        guard let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else { return }
        loadCustomSound(from: soundURL)
    }

    private func loadCustomSound(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error loading sound file: \(error)")
        }
    }

    func selectCustomSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.mp3, UTType.wav]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        panel.begin { [weak self] response in
            guard let self = self else { return }
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    self.customSoundURL = url
                    self.customSoundName = url.lastPathComponent
                    self.soundSource = .custom
                    self.loadCustomSound(from: url)
                }
            }
        }
    }

    func previewSound() {
        loadCurrentSound()
        playSound()
    }

    func updateSelectedSound(_ sound: AlertSound) {
        selectedSound = sound
        soundSource = .preset
        loadPresetSound(sound)
    }

    func startTimer() {
        isRunning = true
        timeLeft = initialTime * 60
        updateMenuBarTitle()

        loadCurrentSound()
        playSound()

        if !taskName.isEmpty {
            delegate?.showAlert(taskName)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeLeft > 0 {
                self.timeLeft -= 1
                self.updateMenuBarTitle()
            } else {
                self.loadCurrentSound()
                self.playSound()

                if !self.taskName.isEmpty {
                    self.delegate?.showAlert(self.taskName)
                }

                if self.mode == .repeat {
                    self.timeLeft = self.initialTime * 60
                    self.updateMenuBarTitle()
                } else {
                    self.stopTimer()
                }
            }
        }
    }

    private func playSound() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        updateMenuBarTitle()
    }

    func resetTimer() {
        timeLeft = initialTime * 60
        updateMenuBarTitle()
    }

    func formatTime() -> String {
        let minutes = timeLeft / 60
        let seconds = timeLeft % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateMenuBarTitle() {
        if isRunning {
            delegate?.updateMenuBarTitle(formatTime())
        } else {
            delegate?.updateMenuBarTitle("")
        }
    }
}

// MARK: - Sound Grid Item

struct SoundGridItem: View {
    let sound: AlertSound
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: sound.icon)
                        .font(.system(size: 16))
                        .frame(width: 36, height: 28)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.accentColor)
                            .offset(x: 4, y: -2)
                    }
                }

                Text(sound.displayName)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sound Selection View

struct SoundSelectionView: View {
    @ObservedObject var viewModel: TimerViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Preset sound grid
            if viewModel.soundSource == .preset {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(AlertSound.allCases, id: \.self) { sound in
                        SoundGridItem(
                            sound: sound,
                            isSelected: viewModel.selectedSound == sound,
                            onSelect: {
                                viewModel.updateSelectedSound(sound)
                                viewModel.previewSound()
                            }
                        )
                    }
                }
            } else {
                // Custom sound file picker
                HStack(spacing: 8) {
                    Button {
                        viewModel.selectCustomSound()
                    } label: {
                        Label("Choose File", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if !viewModel.customSoundName.isEmpty {
                        Text(viewModel.customSoundName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            // Source toggle
            Button {
                viewModel.soundSource = viewModel.soundSource == .preset ? .custom : .preset
            } label: {
                Label(
                    viewModel.soundSource == .preset ? "Use Custom" : "Use Presets",
                    systemImage: viewModel.soundSource == .preset ? "folder" : "music.note.list"
                )
                .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Timer Display (running state)

struct TimerRunningView: View {
    @ObservedObject var viewModel: TimerViewModel
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Task name header
            if !viewModel.taskName.isEmpty {
                Text(viewModel.taskName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            // Circular progress + time
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 6)

                // Progress ring
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.progress)

                // Time text
                VStack(spacing: 2) {
                    Text(viewModel.formatTime())
                        .font(.system(size: 36, weight: .light, design: .monospaced))

                    if viewModel.mode == .repeat {
                        Label("Repeating", systemImage: "repeat")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 160, height: 160)
            .padding(.vertical, 8)

            // Stop button
            Button(action: onStop) {
                Text("Stop")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [])
        }
    }
}

// MARK: - Setup View (idle state)

struct TimerSetupView: View {
    @ObservedObject var viewModel: TimerViewModel
    let onStart: () -> Void

    private var isStartDisabled: Bool {
        viewModel.initialTime <= 0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Task name
            VStack(alignment: .leading, spacing: 4) {
                Text("Task")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("What are you focusing on?", text: $viewModel.taskName)
                    .textFieldStyle(.roundedBorder)
            }

            // Duration + Mode row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("", value: $viewModel.initialTime, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $viewModel.mode) {
                        Label("Once", systemImage: "1.circle").tag(TimerMode.once)
                        Label("Repeat", systemImage: "repeat").tag(TimerMode.repeat)
                    }
                    .pickerStyle(.segmented)
                }
            }

            if viewModel.initialTime <= 0 {
                Text("Duration must be greater than 0")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Sound selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Sound")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SoundSelectionView(viewModel: viewModel)
            }

            // Start button
            Button(action: onStart) {
                Text("Start Focus")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [])
            .disabled(isStartDisabled)
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @ObservedObject var viewModel: TimerViewModel
    let quitAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            if viewModel.isRunning {
                TimerRunningView(viewModel: viewModel) {
                    viewModel.stopTimer()
                    viewModel.resetTimer()
                }
            } else {
                TimerSetupView(viewModel: viewModel) {
                    viewModel.startTimer()
                }
            }

            Spacer().frame(height: 12)

            // Footer: settings + credit
            VStack(spacing: 6) {
                HStack {
                    if #available(macOS 13.0, *) {
                        Toggle("Launch at Login", isOn: Binding(
                            get: { viewModel.launchAtLogin },
                            set: { viewModel.setLaunchAtLogin($0) }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Quit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onTapGesture { quitAction() }
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }

                HStack(spacing: 0) {
                    Text("MindBell by ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Jay")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            if let url = URL(string: "https://www.facebook.com/iductruong") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}

// MARK: - App Delegate

protocol TimerUpdateDelegate: AnyObject {
    func updateMenuBarTitle(_ title: String)
    func showAlert(_ message: String)
}

class AppDelegate: NSObject, NSApplicationDelegate, TimerUpdateDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timerViewModel: TimerViewModel!
    var alertPopover: NSPopover?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupTimerViewModel()
        setupPopover()
        setupStatusItem()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
                NSApplication.shared.terminate(nil)
            }
            return event
        }

        // Show greeting so user knows the app is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showAlert("MindBell is ready")
        }
    }

    private func setupTimerViewModel() {
        timerViewModel = TimerViewModel()
        timerViewModel.delegate = self
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView(viewModel: timerViewModel) {
                NSApplication.shared.terminate(nil)
            }
        )
        self.popover = popover
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "infinity", accessibilityDescription: "Infinity")
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.imagePosition = .imageLeft
        }
    }

    func showAlert(_ message: String) {
        alertPopover?.close()

        let alertPopover = NSPopover()
        alertPopover.behavior = .transient

        let alertView = NSHostingController(rootView:
            Text(message)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .lineLimit(1)
                .truncationMode(.tail)
                .fixedSize(horizontal: true, vertical: true)
                .frame(maxWidth: 484)
                .multilineTextAlignment(.center)
        )

        alertPopover.contentViewController = alertView
        let fittingSize = alertView.view.fittingSize
        alertPopover.contentSize = NSSize(
            width: min(fittingSize.width, 484),
            height: fittingSize.height
        )

        if let button = statusItem.button {
            alertPopover.show(
                relativeTo: NSRect(x: 0, y: -8, width: button.bounds.width, height: 0),
                of: button,
                preferredEdge: .minY
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                alertPopover.close()
            }
        }

        self.alertPopover = alertPopover
    }

    func updateMenuBarTitle(_ title: String) {
        if let button = statusItem.button {
            button.title = title.isEmpty ? "" : " " + title
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}

@main
struct TimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
