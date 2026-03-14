# MindBell: System Architecture

## High-Level Overview

MindBell is a **menu bar–first macOS application** with minimal system footprint. All functionality—UI, timer logic, sound playback, settings—runs in a single process tied to `NSApplication`.

```
┌─────────────────────────────────────────────────────┐
│                  macOS Menu Bar                     │
│  [∞ 08:30] ← Click to show/hide main popover       │
└──────────────────┬──────────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │  NSStatusItem       │
        │  + Button + Menu    │
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────────────┐
        │  AppDelegate                │
        │ ┌──────────────────────────┐│
        │ │ setupStatusItem()        ││
        │ │ togglePopover()          ││
        │ │ showAlert()              ││
        │ │ updateMenuBarTitle()     ││
        │ └──────────────────────────┘│
        └──────────┬──────────────────┘
                   │
      ┌────────────┴────────────┐
      │                         │
   ┌──▼──────────┐      ┌──────▼──────┐
   │ NSPopover   │      │ NSPopover   │
   │ (Main UI)   │      │ (Alert)     │
   │ 280×480     │      │ (6 sec)     │
   └──┬──────────┘      └─────────────┘
      │
   ┌──▼──────────────────────────┐
   │      ContentView (SwiftUI)   │
   │  ┌─────────────────────────┐ │
   │  │ TimerSetupView (idle)   │ │
   │  │ OR                       │ │
   │  │ TimerRunningView (busy) │ │
   │  └─────────────────────────┘ │
   │        @ObservedObject        │
   │         TimerViewModel        │
   └──────────────────────────────┘
```

## Component Architecture

### Layer 1: Application Lifecycle (macOS Integration)

**NSApplicationDelegate (AppDelegate)**
- Manages app lifecycle: launch, termination, focus changes
- Controls menu bar presence via `NSStatusItem`
- Presents popovers (main UI + alerts)
- Implements `TimerUpdateDelegate` to receive updates from ViewModel
- Handles keyboard shortcuts (Cmd+Q to quit)

**TimerApp (@main Swift App)**
- Entry point for SwiftUI
- Adapts `AppDelegate` to SwiftUI via `@NSApplicationDelegateAdaptor`
- Minimal—just a `Settings` scene with empty content

### Layer 2: Business Logic (ViewModel)

**TimerViewModel (ObservableObject)**
- Owns all timer state and logic
- Manages `Timer` object (1-second ticks)
- Loads and plays sounds via `AVAudioPlayer`
- Persists settings to `UserDefaults`
- Notifies `AppDelegate` via delegate protocol

**Responsibilities:**
1. Timer countdown (seconds to 0)
2. Sound management (preset loading, custom file handling)
3. Settings persistence
4. Delegate notifications (menu bar updates, alert display)
5. Mode logic (once vs. repeat)

### Layer 3: User Interface (SwiftUI Views)

**ContentView** (Router)
- Conditional rendering: `TimerSetupView` if idle, `TimerRunningView` if running
- Passes `ViewModel` via `@ObservedObject` binding
- Quit button

**TimerSetupView** (Configuration)
- Task name input (optional)
- Duration input (minutes) + Mode picker (Once/Repeat)
- Sound selection (via `SoundSelectionView`)
- Start Focus button
- Disabled if duration ≤ 0

**TimerRunningView** (Countdown)
- Displays task name (if provided)
- Circular progress ring (160×160) with smooth animation
- Monospaced countdown (MM:SS)
- "Repeating" label (if in repeat mode)
- Stop button

**SoundSelectionView** (Sound Picker)
- Preset grid: 3×3 LazyVGrid of `SoundGridItem`
- Custom file picker: "Choose File" button + filename display
- Toggle button: "Use Custom" ↔ "Use Presets"

**SoundGridItem** (Sound Tile)
- SF Symbol icon + display name
- Tap to select + preview sound
- Checkmark indicator when selected
- Border highlight when selected

### Layer 4: Delegate Bridge

**TimerUpdateDelegate (Protocol)**
- Two methods: `updateMenuBarTitle()`, `showAlert()`
- Decouples ViewModel from AppDelegate
- Enables `AppDelegate` to receive notifications without ViewModel knowing implementation details

---

## Data Flow Architecture

### State Management Flow

```
User Interaction
    │
    ├→ Set Duration → @Published didSet → UserDefaults
    ├→ Select Sound → @Published didSet → UserDefaults + AVAudioPlayer
    ├→ Start Timer → isRunning = true, init Timer
    ├→ Stop Timer → isRunning = false, invalidate Timer
    └→ Repeat Mode → on fire, reset timeLeft

        ↓ (ViewModel updates Published properties)

    ContentView observes @ObservedObject changes

        ├→ isRunning changed → SwiftUI re-renders (Setup ↔ Running view)
        ├→ timeLeft changed → TimerRunningView updates countdown + progress ring
        ├→ taskName changed → UI updates task header
        └→ initialTime changed → UI updates duration display

        ↓ (Delegate protocol notifications)

    AppDelegate receives updateMenuBarTitle() or showAlert()

        ├→ Updates NSStatusItem.button.title (menu bar countdown)
        └→ Creates/shows NSPopover alert (6-second toast)
```

### Sound Loading Flow

```
User Selects Preset
    │
    └→ updateSelectedSound(sound: AlertSound)
        └→ soundSource = .preset
        └→ loadPresetSound(sound)
            └→ Bundle.main.url(forResource:)
            └→ AVAudioPlayer(contentsOf: url)
            └→ prepareToPlay()

User Selects Custom
    │
    └→ selectCustomSound()
        └→ NSOpenPanel (file picker, MP3/WAV only)
        └→ customSoundURL = url
        └→ (didSet triggers) Bookmark saved to UserDefaults
        └→ loadCustomSound(from: url)
            └→ AVAudioPlayer(contentsOf: url)
            └→ prepareToPlay()

App Restart
    │
    └→ TimerViewModel.init()
        └→ restoreSavedSettings()
            ├→ Load isCustomSound flag
            ├→ Restore customSoundBookmark from UserDefaults
            ├→ URL(resolvingBookmarkData:) → re-access custom file
            └→ loadCurrentSound()
                ├→ if .preset → loadPresetSound()
                └→ if .custom → loadCustomSound()
```

### Persistence Architecture

**UserDefaults Keys & Restore Strategy**

| Key | Type | Restored On | Fallback |
|-----|------|-------------|----------|
| `initialTime` | Int | App launch | 8 minutes |
| `selectedSound` | String (raw) | App launch | `.singingBowl` |
| `isCustomSound` | Bool | App launch | false |
| `customSoundBookmark` | Data | App launch | nil (use preset) |
| `customSoundName` | String | App launch | "" (empty) |

**Restore Flow:**
```
App launches
    └→ AppDelegate.applicationDidFinishLaunching()
        └→ setupTimerViewModel()
            └→ TimerViewModel.init()
                └→ restoreSavedSettings()
                    ├→ Load integers, strings, bools from UserDefaults
                    ├→ Resolve bookmark data if custom sound enabled
                    ├→ Check file still exists (FileManager.fileExists)
                    ├→ If file gone → fallback to preset
                    └→ loadCurrentSound()
```

---

## Menu Bar Integration

### NSStatusItem Setup

```swift
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

if let button = statusItem.button {
    button.image = NSImage(systemSymbolName: "infinity", accessibilityDescription: "Infinity")
    button.action = #selector(togglePopover(_:))
    button.target = self
    button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    button.imagePosition = .imageLeft  // Icon left, text right
}
```

**Visual Appearance:**
- **Icon**: SF Symbol "infinity" (∞)
- **Text**: Monospaced countdown while running (e.g., " 08:30"), empty when idle
- **Width**: Variable-length (expands/contracts with text)
- **Position**: Top-right of menu bar

### Popover Behavior

**Main Popover** (280×480)
- Anchored to status item button
- Behavior: `.transient` (closes on focus loss)
- Content: `ContentView` (via `NSHostingController`)
- Toggled by clicking status item

**Alert Popover** (Auto-sizing)
- Anchored above status item button
- Behavior: `.transient`
- Content: Simple text (task name or "MindBell is ready")
- Auto-closes after 6 seconds via `DispatchQueue.main.asyncAfter(deadline: .now() + 6)`
- Replaces previous alert if one is active

---

## Sound System Architecture

### Audio Playback Pipeline

```
                    ┌─── Preset Sound ─────┐
                    │                      │
User Selects Sound──┤   Bundle (compiled)  │
                    │   in .wav format     │
                    └─── Custom Sound ─────┘
                              │
                    ┌─────────▼──────────┐
                    │  AVAudioPlayer     │
                    │  (singleton per    │
                    │   sound, replaced  │
                    │   on new selection)│
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │  System Audio Out  │
                    │  (speakers/output) │
                    └────────────────────┘
```

### Sound Formats Supported

| Format | Purpose | Limitations |
|--------|---------|-------------|
| WAV (.wav) | Preset sounds | Lossless, larger file size |
| MP3 (.mp3) | Custom imports | Lossy, smaller file size, lower latency |
| Other | Not supported | File picker filters to MP3/WAV only |

### Security-Scoped File Access

```
User Selects Custom Sound
    │
    └→ NSOpenPanel (sandboxed file picker)
        └→ User authorizes access to file
        └→ AppDelegate receives `panel.url`
        └→ customSoundURL = url
        └→ (didSet) url.bookmarkData(options: .withSecurityScope)
        └→ Bookmark saved to UserDefaults

        ↓ (App quits and restarts)

App Reopens
    │
    └→ restoreSavedSettings()
        └→ bookmarkData = UserDefaults.data(forKey: "customSoundBookmark")
        └→ URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope)
        └→ url.startAccessingSecurityScopedResource()  // ← Key!
        └→ AVAudioPlayer(contentsOf: url)
        └→ Play without re-asking user for permission
```

**Importance:** Security-scoped bookmarks allow sandboxed apps to re-access user-selected files without re-prompting. Without them, the app would need to ask the user every time it restarts.

---

## Event & Notification Flow

### Timer Tick Event Loop

```
startTimer() called
    │
    ├→ isRunning = true (triggers UI render)
    ├→ timeLeft = initialTime * 60
    ├→ playSound()
    ├→ showAlert(taskName) if task name provided
    │
    └→ Timer.scheduledTimer(withTimeInterval: 1, repeats: true)
        │
        └→ Every 1 second:
            ├→ if timeLeft > 0:
            │   ├→ timeLeft -= 1
            │   ├→ updateMenuBarTitle() → AppDelegate updates menu bar
            │   └→ (SwiftUI detects @Published change, re-renders)
            │
            └→ else (timer fires):
                ├→ playSound()
                ├→ showAlert(taskName)
                │
                └→ if mode == .once:
                    │   stopTimer()
                    │
                    └→ else (mode == .repeat):
                        └→ timeLeft = initialTime * 60
                            └→ Cycle repeats
```

### Keyboard Event Handling

```
NSEvent.addLocalMonitorForEvents(matching: .keyDown)
    │
    ├→ if Cmd+Q → NSApplication.shared.terminate(nil)
    │
    └→ (Enter handled via Button.keyboardShortcut in views)
        └→ Start Focus (Enter when idle)
        └→ Stop (Enter when running)
```

---

## Concurrency & Threading

### Main Thread Affinity

All UI updates occur on the **main thread** via:
- `@Published` properties (SwiftUI automatically dispatches to main)
- `DispatchQueue.main.async` for explicit main-thread dispatch

**Example:**
```swift
panel.begin { [weak self] response in
    guard let self = self else { return }
    if response == .OK, let url = panel.url {
        DispatchQueue.main.async {  // ← Explicit main-thread dispatch
            self.customSoundURL = url
            // UI updates triggered
        }
    }
}
```

### Timer on Main Thread

```swift
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    // Runs on main thread by default
    self?.timeLeft -= 1
    self?.updateMenuBarTitle()  // AppDelegate, main thread only
}
```

---

## Memory Management

### Reference Cycles Prevented

**1. Closure in Timer**
```swift
// ✗ Retain cycle: Timer → Closure → self → Timer
timer = Timer.scheduledTimer(...) { self.timeLeft -= 1 }

// ✓ Correct: [weak self] breaks cycle
timer = Timer.scheduledTimer(...) { [weak self] _ in
    self?.timeLeft -= 1
}
```

**2. Delegate Reference**
```swift
// ✓ Weak delegate prevents AppDelegate from being retained by ViewModel
weak var delegate: TimerUpdateDelegate?
```

### Resource Cleanup

```swift
stopTimer() {
    timer?.invalidate()  // Stop timer
    timer = nil          // Release reference
    audioPlayer?.stop()  // Stop audio
    // Player remains in memory until next load (acceptable)
}
```

---

## Sandbox & Security Model

### Entitlements Overview

```xml
<key>com.apple.security.app-sandbox</key>
<true/>                                    <!-- Process isolation -->

<key>com.apple.security.files.user-selected.read-only</key>
<true/>                                    <!-- Can read user-chosen files -->

<key>com.apple.security.files.bookmarks.app-scope</key>
<true/>                                    <!-- Can store bookmarks for re-access -->
```

### Sandbox Restrictions

| Capability | Allowed? | How |
|-----------|----------|-----|
| Read app bundle | ✓ | Preset sounds in bundle |
| Read user-selected files | ✓ | File picker + bookmarks |
| Write files | ✗ | Can't create/modify files |
| Network access | ✗ | No HTTP/TCP calls |
| System access | ✗ | Can't access /usr/bin, /Library |
| Other process access | ✗ | Can't launch or communicate with other apps |

### Security-Scoped Bookmarks

Bookmarks enable:
1. User picks file in open dialog
2. App stores bookmark token in UserDefaults
3. App restarts
4. App resolves bookmark back to URL without re-prompting user
5. App calls `url.startAccessingSecurityScopedResource()` before use

**No network transmission**: Bookmarks are opaque local tokens; they don't leave the device.

---

## Error Handling Strategy

### Sound Loading Errors

```swift
do {
    audioPlayer = try AVAudioPlayer(contentsOf: url)
    audioPlayer?.prepareToPlay()
} catch {
    print("Error loading sound file: \(error)")
    // TODO: Show user-facing alert
}
```

**Current:** Logged to console only.
**Future:** Alert user if sound fails to load, offer fallback.

### Custom Sound File Errors

```swift
if customSoundURL == nil || !FileManager.default.fileExists(atPath: url.path) {
    // File deleted or inaccessible
    soundSource = .preset
    customSoundName = ""
    loadPresetSound(selectedSound)
}
```

**Graceful fallback:** Presets always available, so no hard failure.

### Bookmark Resolution Errors

```swift
if let url = try? URL(resolvingBookmarkData: bookmarkData, ...) {
    // Success
} else {
    // Bookmark stale or invalid
    soundSource = .preset
    customSoundName = ""
    UserDefaults.standard.removeObject(forKey: "customSoundBookmark")
}
```

---

## Performance Characteristics

| Operation | Typical Time | Notes |
|-----------|--------------|-------|
| App launch | ~500 ms | MVVM initialization + UserDefaults restore |
| Sound loading | ~50–200 ms | Depends on file size; async not used (acceptable) |
| Timer tick | < 1 ms | Simple decrement + UI update |
| Sound playback | ~50 ms | Latency from audioPlayer.play() call |
| Menu bar update | < 10 ms | NSStatusItem.button.title = "08:30" |
| Alert popover show | < 100 ms | NSPopover.show() call |

**Bottleneck:** App launch (cold start). Once running, ~1ms per tick is imperceptible.

---

## Deployment Architecture

### Code Distribution

- **Single executable**: Focus Bell.app (macOS Mach-O binary)
- **Bundle resources**: 9 WAV files + app icons (≈5 MB total)
- **Settings**: Stored in UserDefaults plist (~2 KB)
- **No external dependencies**: All Apple frameworks

### Code Signing

- **Identity**: Apple Development (automatic)
- **Team ID**: `YOUR_TEAM_ID`
- **Entitlements**: Focus_Bell.entitlements (sandbox + file bookmarks)
- **Hardened Runtime**: Enabled by Xcode default

### App Store vs. Direct Distribution

**Current (Direct DMG):**
- Unsigned or ad-hoc signed
- No auto-update capability
- No App Store review

**Future (App Store):**
- Apple-signed + notarized
- Automatic update via App Store
- Review of privacy/security
- Higher distribution trust

---

## Scalability Considerations

**Current Limits:**
- Single timer only (can't run multiple in parallel)
- Linear time progression (no custom intervals)
- No background activity (app must stay running)
- In-memory sound storage (9×100 KB, negligible)

**Future Considerations:**
- **Multiple Timers:** Would need ViewModel array + multi-row display
- **Background Ticking:** Requires Darwin notifications or daemons
- **Custom Intervals:** Add interval logic to fire logic (e.g., "alert every 2 cycles")
- **iCloud Sync:** Use CloudKit or iCloud-backed UserDefaults

