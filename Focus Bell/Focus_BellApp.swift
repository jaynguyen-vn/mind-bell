import SwiftUI
import AVFoundation
import Cocoa
import UniformTypeIdentifiers
import ServiceManagement
import UserNotifications

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
    case templeBell = "temple-bell"
    case tingsha = "tingsha"
    case windChime = "wind-chime"
    case kalimba = "kalimba"
    case marimba = "marimba"
    case airport = "airport-announcement-ding"
    case softDing = "soft-ding"

    /// Resolves a saved raw value, mapping sounds removed from the preset set to their closest replacement
    init?(savedValue: String) {
        let replacements = [
            "zen-bell": "temple-bell",
            "chime": "soft-ding",
            "xylophone": "marimba",
            "school-bell": "airport-announcement-ding",
            "bike-bell-ring": "soft-ding"
        ]
        self.init(rawValue: replacements[savedValue] ?? savedValue)
    }

    var displayName: String {
        switch self {
        case .singingBowl: return "Singing Bowl"
        case .templeBell: return "Temple Bell"
        case .tingsha: return "Tingsha"
        case .windChime: return "Wind Chime"
        case .kalimba: return "Kalimba"
        case .marimba: return "Marimba"
        case .airport: return "Airport"
        case .softDing: return "Soft Ding"
        }
    }

    var icon: String {
        switch self {
        case .singingBowl: return "circle.bottomhalf.filled"
        case .templeBell: return "bell"
        case .tingsha: return "sparkles"
        case .windChime: return "wind"
        case .kalimba: return "music.note"
        case .marimba: return "music.quarternote.3"
        case .airport: return "airplane"
        case .softDing: return "tuningfork"
        }
    }
}

class TimerViewModel: ObservableObject {
    @Published var timeLeft: Int = 0
    @Published var initialTime: Int = 8 {
        didSet { UserDefaults.standard.set(initialTime, forKey: "initialTime") }
    }
    @Published var isRunning = false
    @Published var isPaused = false
    @Published private(set) var endDate: Date?
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
    @Published var volume: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "volume")
            audioPlayer?.volume = Float(volume)
        }
    }

    @Published var launchAtLogin: Bool = false

    /// Upper bound for a session; also keeps `minutes * 60` far from integer overflow
    static let maxMinutes = 999

    weak var delegate: TimerUpdateDelegate?
    private var timer: Timer?
    private var pausedRemaining: TimeInterval = 0
    private var activity: NSObjectProtocol?
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
        if savedTime > 0 { initialTime = min(savedTime, TimerViewModel.maxMinutes) }

        // Restore volume (default full volume, like before the slider existed)
        if UserDefaults.standard.object(forKey: "volume") != nil {
            volume = UserDefaults.standard.double(forKey: "volume")
        }

        // Restore preset sound
        if let savedSound = UserDefaults.standard.string(forKey: "selectedSound"),
           let sound = AlertSound(savedValue: savedSound) {
            selectedSound = sound
        }

        // Restore custom sound; keep the file even while a preset is selected so the Custom tile can switch back to it
        let isCustom = UserDefaults.standard.bool(forKey: "isCustomSound")
        customSoundName = UserDefaults.standard.string(forKey: "customSoundName") ?? ""

        if let bookmarkData = UserDefaults.standard.data(forKey: "customSoundBookmark") {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale),
               url.startAccessingSecurityScopedResource(),
               FileManager.default.fileExists(atPath: url.path) {
                // Assigning re-saves the bookmark, which also refreshes a stale one
                customSoundURL = url
                if isCustom { soundSource = .custom }
            } else if isCustom {
                // File deleted or inaccessible — fallback to preset
                soundSource = .preset
                customSoundName = ""
                UserDefaults.standard.removeObject(forKey: "customSoundBookmark")
            }
            // With a preset selected, keep the bookmark: the file may just be on a drive that isn't mounted yet
        } else if isCustom {
            soundSource = .preset
        }
    }

    private func loadCurrentSound() {
        switch soundSource {
        case .preset:
            loadPresetSound(selectedSound)
        case .custom:
            if let url = customSoundURL, FileManager.default.fileExists(atPath: url.path) {
                loadSound(from: url)
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
        guard let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") else {
            assertionFailure("Missing bundled sound \(sound.rawValue).m4a")
            return
        }
        loadSound(from: soundURL)
    }

    private func loadSound(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = Float(volume)
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
                    self.loadSound(from: url)
                }
            }
        }
    }

    /// Custom tile: switch back to the saved file, or pick one when there is none, it went missing,
    /// or Custom is already selected
    func selectCustomTile() {
        let savedFileExists = customSoundURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        if soundSource == .custom || !savedFileExists {
            selectCustomSound()
        } else {
            soundSource = .custom
            previewSound()
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
        // A second start (e.g. Enter pressed twice) would orphan the first timer, which Stop could no longer cancel
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        startCycle()
        startTicking()

        loadCurrentSound()
        playStartCue()

        delegate?.sessionDidStart(taskName: taskName)
    }

    func togglePause() {
        if isPaused {
            resumeTimer()
        } else {
            pauseTimer()
        }
    }

    func pauseTimer() {
        guard isRunning, !isPaused, let endDate = endDate else { return }
        pausedRemaining = endDate.timeIntervalSinceNow
        timeLeft = max(0, Int(pausedRemaining.rounded()))
        self.endDate = nil
        isPaused = true
        stopTicking()
        updateMenuBarTitle()
    }

    func resumeTimer() {
        guard isRunning, isPaused else { return }
        endDate = Date().addingTimeInterval(pausedRemaining)
        isPaused = false
        startTicking()
        updateMenuBarTitle()
    }

    private func startCycle() {
        timeLeft = initialTime * 60
        endDate = Date().addingTimeInterval(TimeInterval(timeLeft))
        updateMenuBarTitle()
    }

    private func startTicking() {
        // Keep App Nap from throttling the ticks while a session runs; the Mac may still sleep
        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Focus timer running"
        )
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
        if let activity = activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
    }

    private func tick() {
        guard let endDate = endDate else { return }

        // Read the remaining time off the clock so sleep or late ticks can't push the bell back
        let remaining = Int(endDate.timeIntervalSinceNow.rounded())
        if remaining > 0 {
            timeLeft = remaining
            updateMenuBarTitle()
            return
        }

        loadCurrentSound()
        playSound()

        delegate?.sessionDidFinish(taskName: taskName, nextBellMinutes: mode == .repeat ? initialTime : nil)

        if mode == .repeat {
            startCycle()
        } else {
            // Let the final bell ring out; only a manual stop cuts the sound
            stopTimer(stopSound: false)
        }
    }

    private func playSound(volumeScale: Float = 1) {
        audioPlayer?.volume = Float(volume) * volumeScale
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    /// A softer, shortened strike at the start so it can't be mistaken for the full end-of-session bell
    private func playStartCue() {
        playSound(volumeScale: 0.5)
        guard let player = audioPlayer else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard player.isPlaying else { return }
            player.setVolume(0, fadeDuration: 0.8)
            // Stop once silent: a muted player still holds the audio device and keeps the Mac from idle sleep
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                if player.isPlaying && player.volume == 0 { player.stop() }
            }
        }
    }

    func stopTimer(stopSound: Bool = true) {
        isRunning = false
        isPaused = false
        stopTicking()
        endDate = nil
        if stopSound {
            audioPlayer?.stop()
        }
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
        delegate?.updateMenuBarTitle(isRunning ? formatTime() : "", isPaused: isPaused)
    }
}

// MARK: - Sound Grid Item

struct SoundGridItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .frame(width: 36, height: 28)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                            .offset(x: 6, y: -3)
                    }
                }

                Text(title)
                    .font(.system(size: 11))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Sound Selection View

struct SoundSelectionView: View {
    @ObservedObject var viewModel: TimerViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(AlertSound.allCases, id: \.self) { sound in
                    SoundGridItem(
                        icon: sound.icon,
                        title: sound.displayName,
                        isSelected: viewModel.soundSource == .preset && viewModel.selectedSound == sound,
                        onSelect: {
                            viewModel.updateSelectedSound(sound)
                            viewModel.previewSound()
                        }
                    )
                }

                SoundGridItem(
                    icon: "folder.badge.plus",
                    title: "Custom",
                    isSelected: viewModel.soundSource == .custom,
                    onSelect: { viewModel.selectCustomTile() }
                )
            }

            if viewModel.soundSource == .custom && !viewModel.customSoundName.isEmpty {
                HStack(spacing: 6) {
                    Text(viewModel.customSoundName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Change…") { viewModel.selectCustomSound() }
                        .buttonStyle(.link)
                        .font(.caption)
                }
            }

            // Volume; releasing the slider plays the sound at the new level
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $viewModel.volume, in: 0...1, onEditingChanged: { isEditing in
                    if !isEditing { viewModel.previewSound() }
                })
                .controlSize(.small)
                .accessibilityLabel("Volume")
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Timer Display (running state)

struct TimerRunningView: View {
    @ObservedObject var viewModel: TimerViewModel
    let onStop: () -> Void

    private var statusLabel: (text: String, icon: String) {
        if viewModel.isPaused { return ("Paused", "pause.fill") }
        let time = viewModel.endDate?.formatted(date: .omitted, time: .shortened) ?? ""
        return viewModel.mode == .repeat ? ("Next bell \(time)", "repeat") : ("Ends at \(time)", "clock")
    }

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
                    .opacity(viewModel.isPaused ? 0.4 : 1)

                // Time text
                VStack(spacing: 4) {
                    Text(viewModel.formatTime())
                        .font(.system(size: 36, weight: .light, design: .rounded).monospacedDigit())

                    Label(statusLabel.text, systemImage: statusLabel.icon)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 160, height: 160)
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)

            HStack(spacing: 8) {
                Button(action: viewModel.togglePause) {
                    Text(viewModel.isPaused ? "Resume" : "Pause")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])

                // No keyboard shortcut: Stop ends the session, so it should never fire by accident
                Button(action: onStop) {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Setup View (idle state)

struct TimerSetupView: View {
    @ObservedObject var viewModel: TimerViewModel
    let onStart: () -> Void

    // Text-backed so each keystroke updates the duration; a formatter-backed field only
    // commits on Return or blur, so clicking Start right after typing used the old value
    @State private var minutesText = ""

    private let minutePresets = [5, 15, 25, 50]

    private var isStartDisabled: Bool {
        viewModel.initialTime <= 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Task name
            VStack(alignment: .leading, spacing: 4) {
                Text("Task")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("What are you focusing on?", text: $viewModel.taskName)
                    .textFieldStyle(.roundedBorder)
            }

            // Duration: free entry plus quick presets
            VStack(alignment: .leading, spacing: 4) {
                Text("Minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    TextField("", text: $minutesText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 48)
                        .accessibilityLabel("Minutes")
                        .onAppear { minutesText = String(viewModel.initialTime) }
                        .onChange(of: minutesText) { text in
                            let minutes = Int(text.trimmingCharacters(in: .whitespaces)) ?? 0
                            if minutes > TimerViewModel.maxMinutes {
                                minutesText = String(TimerViewModel.maxMinutes)
                                return
                            }
                            viewModel.initialTime = minutes
                        }

                    ForEach(minutePresets, id: \.self) { minutes in
                        MinutePresetChip(minutes: minutes, isSelected: viewModel.initialTime == minutes) {
                            minutesText = String(minutes)
                        }
                    }
                }

                if viewModel.initialTime <= 0 {
                    Text("Enter at least 1 minute")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // Mode
            VStack(alignment: .leading, spacing: 4) {
                Text("Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $viewModel.mode) {
                    Label("Once", systemImage: "1.circle").tag(TimerMode.once)
                    Label("Repeat", systemImage: "repeat").tag(TimerMode.repeat)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
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
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [])
            .disabled(isStartDisabled)
        }
    }
}

// MARK: - Minute Preset Chip

struct MinutePresetChip: View {
    let minutes: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text("\(minutes)")
                .font(.system(size: 12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) minutes")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Pointing Hand Cursor

/// Shows the pointing-hand cursor on hover. Tracks its own push so the cursor stack stays
/// balanced when the view goes away mid-hover (e.g. the popover closes after opening a link).
struct PointingHandCursor: ViewModifier {
    @State private var isPushed = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering && !isPushed {
                    NSCursor.pointingHand.push()
                    isPushed = true
                } else if !hovering && isPushed {
                    NSCursor.pop()
                    isPushed = false
                }
            }
            .onDisappear {
                if isPushed {
                    NSCursor.pop()
                    isPushed = false
                }
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

                    Button("Quit", action: quitAction)
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .modifier(PointingHandCursor())
                }

                HStack(spacing: 0) {
                    Text("MindBell by ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("Jay", destination: URL(string: "https://www.facebook.com/iductruong")!)
                        .font(.caption)
                        .modifier(PointingHandCursor())
                }
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}

// MARK: - App Delegate

protocol TimerUpdateDelegate: AnyObject {
    func updateMenuBarTitle(_ title: String, isPaused: Bool)
    func sessionDidStart(taskName: String)
    /// `nextBellMinutes` is set in repeat mode, nil when the session is over
    func sessionDidFinish(taskName: String, nextBellMinutes: Int?)
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, TimerUpdateDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var timerViewModel: TimerViewModel!
    var alertPopover: NSPopover?

    private let bellImage = NSImage(systemSymbolName: "bell", accessibilityDescription: "MindBell")
    private let pausedImage = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "MindBell, paused")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupTimerViewModel()
        setupPopover()
        setupStatusItem()
        UNUserNotificationCenter.current().delegate = self

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
                NSApplication.shared.terminate(nil)
            }
            return event
        }

        // Greet only on first launch; with Launch at Login a toast on every login gets noisy
        if !UserDefaults.standard.bool(forKey: "hasShownReadyToast") {
            UserDefaults.standard.set(true, forKey: "hasShownReadyToast")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showAlert("MindBell is ready")
            }
        }
    }

    private func setupTimerViewModel() {
        timerViewModel = TimerViewModel()
        timerViewModel.delegate = self
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        let controller = NSHostingController(
            rootView: ContentView(viewModel: timerViewModel) {
                NSApplication.shared.terminate(nil)
            }
        )
        if #available(macOS 13.0, *) {
            // Let the popover follow the content height as it switches between setup and running
            controller.sizingOptions = .preferredContentSize
        } else {
            popover.contentSize = controller.view.fittingSize
        }
        popover.contentViewController = controller
        self.popover = popover
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = bellImage
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

    func sessionDidStart(taskName: String) {
        // Ask when a session starts rather than at launch, when the reason is clear; the system prompts only once
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
            if let error = error {
                print("Notification authorization failed: \(error)")
            } else if !granted {
                print("Notifications not allowed; only the toast will show")
            }
        }

        if !taskName.isEmpty {
            showAlert("Focus started · \(taskName)")
        }
    }

    func sessionDidFinish(taskName: String, nextBellMinutes: Int?) {
        showAlert(taskName.isEmpty ? "Time's up" : "Time's up · \(taskName)")

        let content = UNMutableNotificationContent()
        content.title = "Time's up"
        if !taskName.isEmpty {
            content.body = taskName
        } else if let minutes = nextBellMinutes {
            content.body = "Next bell in \(minutes) min"
        } else {
            content.body = "Focus session complete"
        }
        // The app plays its own bell, so the notification stays silent. A fixed identifier
        // replaces the previous banner, so repeat mode doesn't pile up notifications.
        let request = UNNotificationRequest(identifier: "mindbell.time-up", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to post notification: \(error)")
            }
        }
    }

    func updateMenuBarTitle(_ title: String, isPaused: Bool) {
        guard let button = statusItem.button else { return }
        button.title = title.isEmpty ? "" : " " + title
        let image = isPaused ? pausedImage : bellImage
        if button.image !== image {
            button.image = image
        }
    }

    // Opening the popover activates MindBell; when it closes via Esc or the menu bar icon, hand keyboard
    // focus back to the previous app. Skip it while one of our windows (e.g. the sound file picker) is key.
    func popoverDidClose(_ notification: Notification) {
        if NSApp.keyWindow == nil {
            NSApp.deactivate()
        }
    }

    // Show banners even while MindBell is the active app (e.g. the popover is open)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                // Activate so Return works right away and the primary button draws in its active color
                if #available(macOS 14.0, *) {
                    NSApp.activate()
                } else {
                    NSApp.activate(ignoringOtherApps: true)
                }
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
