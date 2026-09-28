# MindBell: Codebase Summary

## Directory Structure

```
Focus Bell/
├── Focus_BellApp.swift               (959 LOC) Main app: enums, ViewModel, Views, AppDelegate
├── Focus_BellApp_Mobile.swift        (303 LOC) iOS version (commented out, not compiled)
├── Focus_Bell.entitlements           (12 LOC)  Sandbox and file access permissions
├── Assets.xcassets/                  App icons and image assets
│   ├── AppIcon.appiconset/
│   └── AccentColor.colorset/
├── Preview Content/
│   └── Preview Assets.xcassets/      (Preview images for Xcode canvas)
├── singing-bowl.m4a, temple-bell.m4a, tingsha.m4a, wind-chime.m4a
├── kalimba.m4a, marimba.m4a
├── airport-announcement-ding.m4a, soft-ding.m4a
└── Info.plist                        (Empty placeholder)

MindBell.xcodeproj/
├── project.pbxproj                   (390 LOC) Xcode project config
└── [Build settings, schemes]
```

## File Breakdown

### Focus_BellApp.swift (959 LOC)

The entire app logic in one well-organized file with clear MARK: sections.

#### Enums

**TimerMode**
- `.once`: Timer fires once and stops
- `.repeat`: Timer fires and auto-resets

**SoundSource**
- `.preset`: Using built-in alert sound
- `.custom`: Using imported MP3/WAV file

**AlertSound** (8 cases)
- `singingBowl`, `templeBell`, `tingsha`, `windChime`, `kalimba`, `marimba`, `airport`, `softDing`
- Each has: `rawValue` (filename), `displayName` (UI text), `icon` (SF Symbol)
- `init?(savedValue:)` remaps a saved raw value from a sound removed from the preset set to its closest replacement (e.g. `zen-bell`→`temple-bell`, `chime`→`soft-ding`, `xylophone`→`marimba`, `school-bell`→`airport-announcement-ding`, `bike-bell-ring`→`soft-ding`)

#### TimerViewModel (ObservableObject, ~320 LOC)

Core business logic for the timer. Published properties:
- `timeLeft: Int` — Remaining seconds
- `initialTime: Int` — Duration in minutes (default 8), persisted
- `isRunning: Bool` — Whether timer is active
- `isPaused: Bool` — Whether the running timer is paused
- `endDate: Date?` — Wall-clock time the current cycle ends (read-only outside the class)
- `mode: TimerMode` — Once or Repeat
- `taskName: String` — Optional focus session label
- `selectedSound: AlertSound` — Current preset
- `soundSource: SoundSource` — Preset or custom
- `customSoundURL: URL?` — Path to imported sound, persisted with security-scoped bookmarks (kept even while a preset is selected)
- `customSoundName: String` — Display name of custom sound, persisted
- `volume: Double` — Playback volume 0–1 (default 1.0), persisted
- `launchAtLogin: Bool` — Login item state (macOS 13+)
- `delegate: TimerUpdateDelegate?` — Weak reference to AppDelegate for UI updates

**Key Methods:**
- `init()` — Initializes and restores saved settings
- `restoreSavedSettings()` — Loads UserDefaults values
- `loadCurrentSound()`, `loadPresetSound()`, `loadSound(from:)` — Audio loading
- `selectCustomSound()` — Opens file picker (MP3/WAV)
- `selectCustomTile()` — Custom grid tile action: switches back to the saved file, or opens the picker when there is none or Custom is already selected
- `previewSound()`, `updateSelectedSound()` — Preview functionality
- `startTimer()` — Begins countdown, schedules 1-second ticks, plays the start cue
- `togglePause()`, `pauseTimer()`, `resumeTimer()` — Pause/resume without losing remaining time
- `stopTimer(stopSound:)`, `resetTimer()` — Stop/reset controls
- `formatTime()` — MM:SS formatting
- `updateMenuBarTitle()` — Notifies delegate of countdown display and pause state
- `progress: Double` — Computed property for circular progress ring (0–1 scale)

**Sound Management:**
- Loads sounds into `AVAudioPlayer` on demand
- Preset sounds bundled as `.m4a` files
- Custom sounds accessed via security-scoped bookmarks (survives app restart, kept even when a preset is selected)
- Fallback to preset if custom file is deleted
- Start cue plays the selected sound at half volume and fades it out after ~1.2 s; the end-of-cycle bell plays in full at the set volume

**Persistence:**
- All `@Published` properties use `didSet` to auto-save UserDefaults
- Custom sound file access persisted via security-scoped bookmarks
- Restored on app launch via `restoreSavedSettings()`

#### Views (~470 LOC)

**SoundGridItem** (~45 LOC)
- Displays individual sound tile in the grid
- Shows SF Symbol icon + display name
- Checkmark overlay when selected
- Tappable button with selection callback; exposes `.isSelected` accessibility trait

**SoundSelectionView** (~60 LOC)
- 3-column LazyVGrid: the 8 preset tiles plus a 9th "Custom" tile (`folder.badge.plus`)
- Tapping Custom calls `selectCustomTile()`; when Custom is selected, the file name and a "Change…" link show below the grid
- Volume slider below the grid; releasing it calls `previewSound()`

**TimerRunningView** (~70 LOC)
- Shows active focus session UI
- Task name header (if provided)
- Circular progress ring (160×160) with animated fill, dimmed to 40% opacity while paused
- Rounded, monospaced-digit time display (MM:SS)
- Status label: "Ends at h:mm" (once), "Next bell h:mm" (repeat), or "Paused"
- Pause/Resume button (`.borderedProminent`, keyboard shortcut: Enter) and Stop button (no shortcut, so it can't fire by accident)

**TimerSetupView** (~90 LOC)
- Configuration screen when timer is idle
- Task name input (optional)
- Minutes text field plus quick preset chips (`MinutePresetChip`: 5/15/25/50); inline "Enter at least 1 minute" error when ≤ 0
- Mode picker (Once/Repeat)
- Sound selection via SoundSelectionView
- Start Focus button (`.borderedProminent`, keyboard shortcut: Enter), disabled while duration ≤ 0

**MinutePresetChip** (~25 LOC)
- Small pill button for a quick duration pick; highlighted when it matches the current duration

**PointingHandCursor** (view modifier, ~20 LOC)
- Shows the pointing-hand cursor on hover for link-style controls (Quit, credit link); balances the cursor push/pop if the view disappears mid-hover

**ContentView** (~55 LOC)
- Router view that switches between TimerSetupView and TimerRunningView
- Footer: Launch at Login checkbox (macOS 13+) + Quit button, and a credit line linking to the author
- Fixed width (280pt); height follows content (see popover sizing below)

#### AppDelegate (NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, ~165 LOC)

Manages macOS app lifecycle and UI integration.

**Properties:**
- `statusItem: NSStatusItem` — Menu bar icon/text
- `popover: NSPopover` — Main popover window
- `timerViewModel: TimerViewModel` — Shared data model
- `alertPopover: NSPopover?` — Toast notification (optional, auto-dismissed)
- `bellImage` / `pausedImage` — Menu bar icons (`bell`, `pause.circle`)

**Key Methods:**
- `applicationDidFinishLaunching()` — Sets up ViewModel, popover, status item; registers Cmd+Q shortcut; sets itself as `UNUserNotificationCenter` delegate; shows the "MindBell is ready" toast once, on first launch only
- `setupTimerViewModel()` — Creates ViewModel and sets delegate to self
- `setupPopover()` — Creates a transient popover with ContentView; on macOS 13+ the hosting controller's `sizingOptions = .preferredContentSize` lets the popover follow content height
- `setupStatusItem()` — Creates variable-width status item with the bell icon, monospaced font
- `togglePopover()` — Activates the app and shows/hides the popover on status item click; `popoverDidClose(_:)` hands focus back to the previous app unless one of MindBell's windows (e.g. the file picker) is key
- `showAlert()` — Creates a 6-second toast notification above the status item
- `sessionDidStart(taskName:)` — Requests notification authorization on first use; shows "Focus started · task" toast only when a task name is set
- `sessionDidFinish(taskName:nextBellMinutes:)` — Shows "Time's up[ · task]" toast, plus a silent `UNUserNotificationCenter` banner with a fixed identifier (`mindbell.time-up`) so repeat mode replaces the previous banner instead of stacking
- `updateMenuBarTitle(_:isPaused:)` — Updates status item text with the countdown and swaps the bell/pause icon
- `userNotificationCenter(_:willPresent:withCompletionHandler:)` — Shows notification banners even while MindBell is the active app

**Delegate Conformance:** `TimerUpdateDelegate`
- `updateMenuBarTitle(_ title: String, isPaused: Bool)` — Called every 1 second during countdown and on pause/resume
- `sessionDidStart(taskName: String)` — Called when a session starts
- `sessionDidFinish(taskName: String, nextBellMinutes: Int?)` — Called when a cycle ends; `nextBellMinutes` is set only in repeat mode

#### TimerUpdateDelegate Protocol (~6 LOC)

Weak interface for ViewModel to notify AppDelegate of UI updates without creating retain cycle.

```swift
protocol TimerUpdateDelegate: AnyObject {
    func updateMenuBarTitle(_ title: String, isPaused: Bool)
    func sessionDidStart(taskName: String)
    func sessionDidFinish(taskName: String, nextBellMinutes: Int?)
}
```

#### Entry Point: TimerApp (@main App)

SwiftUI app struct with NSApplicationDelegateAdaptor, enabling AppDelegate lifecycle management.

---

### Focus_BellApp_Mobile.swift (303 LOC, Not Compiled)

Commented-out iOS version. Contains:
- Duplicate ViewModel (adapted for iOS)
- iOS-specific views: `MobileContentView`, `MobileTimerSetupView`, `MobileTimerRunningView`
- Intended for potential iOS release (future Phase 2)

**Note:** This file is not included in build target. To enable iOS support, extract shared ViewModel into SPM and uncomment target.

---

### Focus_Bell.entitlements

XML plist with sandbox configuration:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.files.bookmarks.app-scope</key>
<true/>
```

**Effect:**
- App runs in sandbox (process isolation)
- Can read files user selects in open dialog
- Can store security-scoped bookmarks to re-access those files after restart

---

### Info.plist

Empty placeholder. Xcode auto-generates at build time with values from project settings.

---

## Data Flow Diagram

```
User Interaction (UI)
        ↓
    ContentView
        ├→ TimerSetupView (idle)
        │   ├ Input: Task name, Minutes (+ presets), Mode, Sound, Volume
        │   └ Action: Click "Start Focus" (or press Enter)
        │
        └→ TimerRunningView (active)
            ├ Display: Circular progress, Countdown, status line
            └ Action: Pause/Resume (Enter) or Stop
        ↓
    TimerViewModel (@ObservedObject)
        ├ Timer logic (1-second ticks, pause/resume)
        ├ Sound loading & playback (AVAudioPlayer)
        ├ UserDefaults persistence
        └ @Published updates → UI re-renders
        ↓
    AppDelegate (TimerUpdateDelegate, UNUserNotificationCenterDelegate)
        ├ Updates NSStatusItem text + icon (menu bar countdown, paused state)
        ├ Shows NSPopover alert (6-second toast)
        └ Posts a silent UNUserNotification on session finish
```

**Persistence Flow:**
```
User Sets Duration → @Published didSet → UserDefaults.set()
                                              ↓ (App restart)
                    UserDefaults.get() → init() → restoreSavedSettings()
```

**Sound Playback Flow:**
```
User Selects Sound
    ├→ Preset: Bundle.main.url() → AVAudioPlayer → previewSound()
    └→ Custom: FileManager → Security-Scoped Bookmark → AVAudioPlayer
                                        ↓ (App restart)
                        Restored from UserDefaults → re-access via bookmark
```

---

## Key Classes & Their Responsibilities

| Class/Struct | Type | Responsibility | LOC |
|--------------|------|-----------------|-----|
| TimerApp | App | Entry point, AppDelegate adapter | 10 |
| AppDelegate | NSObject | Menu bar UI, lifecycle, alerts, notifications | 165 |
| TimerViewModel | ObservableObject | Timer logic, sounds, persistence | 320 |
| ContentView | View | Router (Setup ↔ Running) + footer | 55 |
| TimerSetupView | View | Configuration UI (idle state) | 90 |
| TimerRunningView | View | Countdown UI (active state) | 70 |
| SoundSelectionView | View | Sound grid + custom tile + volume | 60 |
| SoundGridItem | View | Individual sound tile | 45 |
| MinutePresetChip | View | Quick duration pick | 25 |
| PointingHandCursor | ViewModifier | Pointing-hand cursor on hover | 20 |
| TimerUpdateDelegate | Protocol | AppDelegate ↔ ViewModel bridge | 6 |
| TimerMode | Enum | Once / Repeat | — |
| SoundSource | Enum | Preset / Custom | — |
| AlertSound | Enum | 8 preset sound cases | — |

---

## Dependencies

| Framework | Purpose | Risk Level |
|-----------|---------|-----------|
| SwiftUI | UI rendering | Low |
| AVFoundation | Audio playback | Low |
| Cocoa | NSStatusItem, NSPopover, NSOpenPanel | Low |
| UniformTypeIdentifiers | File type filtering (.mp3, .wav) | Low |
| ServiceManagement | Launch at Login (`SMAppService`) | Low |
| UserNotifications | Silent system banner on session finish | Low |
| Foundation | UserDefaults, Timer, URL, FileManager | Low |

**External Dependencies:** None. Pure Apple frameworks.

---

## Code Quality Metrics

- **Total LOC** (compiled): 959
- **Cyclomatic Complexity**: Low (mostly linear flows)
- **Test Coverage**: 0% (manual testing only)
- **External Dependencies**: 0
- **Compiler Warnings**: 0
- **Sandbox Entitlements**: Minimal (read-only file access)

---

## Build Configuration

- **Language**: Swift 5
- **Target OS**: macOS 12.0+
- **Build System**: Xcode 16.2
- **Signing**: Automatic, Team ID `YOUR_TEAM_ID`
- **Code Signing Identity**: Apple Development
- **Bundle ID**: `Jay8448.Mind-Bell`
- **Version**: 1.2.1
- **Build Number**: 10

---

## Known Implementation Details

1. **Menu Bar Icon**: SF Symbol `bell`, swaps to `pause.circle` while paused; variable-length status item
2. **Time Format**: MM:SS (e.g., "08:30" for 8.5 minutes), rounded font with monospaced digits
3. **Progress Ring**: Filled from 0 (empty) to 1 (full) using Circle.trim(); dims to 40% opacity while paused
4. **Sound Playback**: AVAudioPlayer (not AVAudioEngine or AudioContext)
5. **Persistence**: UserDefaults, not Core Data (simple key-value suffices)
6. **File Access**: Security-scoped bookmarks for sandboxed file re-access
7. **Popover Behavior**: Transient (closes when app loses focus); sizes to SwiftUI content on macOS 13+ (`sizingOptions = .preferredContentSize`) instead of a fixed size
8. **Alert Toast**: 6-second auto-dismiss via DispatchQueue.main.asyncAfter(), paired with a silent UNUserNotification banner (fixed identifier `mindbell.time-up`) on session finish
