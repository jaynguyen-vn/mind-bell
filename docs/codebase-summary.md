# MindBell: Codebase Summary

## Directory Structure

```
Focus Bell/
├── Focus_BellApp.swift               (658 LOC) Main app: enums, ViewModel, Views, AppDelegate
├── Focus_BellApp_Mobile.swift        (303 LOC) iOS version (commented out, not compiled)
├── Focus_Bell.entitlements           (12 LOC)  Sandbox and file access permissions
├── Assets.xcassets/                  App icons and image assets
│   ├── AppIcon.appiconset/
│   └── AccentColor.colorset/
├── Preview Content/
│   └── Preview Assets.xcassets/      (Preview images for Xcode canvas)
├── singing-bowl.wav, zen-bell.wav, wind-chime.wav, chime.wav
├── bike-bell-ring.wav, school-bell.wav
├── airport-announcement-ding.wav, temple-bell.wav, xylophone.wav
└── Info.plist                        (Empty placeholder)

MindBell.xcodeproj/
├── project.pbxproj                   (390 LOC) Xcode project config
└── [Build settings, schemes]
```

## File Breakdown

### Focus_BellApp.swift (658 LOC)

The entire app logic in one well-organized file with clear MARK: sections.

#### Enums

**TimerMode**
- `.once`: Timer fires once and stops
- `.repeat`: Timer fires and auto-resets

**SoundSource**
- `.preset`: Using built-in alert sound
- `.custom`: Using imported MP3/WAV file

**AlertSound** (9 cases)
- `singingBowl`, `zenBell`, `windChime`, `chime`, `bikeBell`, `schoolBell`, `airportAnnouncementBell`, `templeBell`, `xylophone`
- Each has: `rawValue` (filename), `displayName` (UI text), `icon` (SF Symbol)

#### TimerViewModel (ObservableObject, ~210 LOC)

Core business logic for the timer. Published properties:
- `timeLeft: Int` — Remaining seconds
- `initialTime: Int` — Duration in minutes (default 8), persisted
- `isRunning: Bool` — Whether timer is active
- `mode: TimerMode` — Once or Repeat
- `taskName: String` — Optional focus session label
- `selectedSound: AlertSound` — Current preset
- `soundSource: SoundSource` — Preset or custom
- `customSoundURL: URL?` — Path to imported sound, persisted with security-scoped bookmarks
- `customSoundName: String` — Display name of custom sound, persisted
- `delegate: TimerUpdateDelegate?` — Weak reference to AppDelegate for UI updates

**Key Methods:**
- `init()` — Initializes and restores saved settings
- `restoreSavedSettings()` — Loads UserDefaults values
- `loadCurrentSound()`, `loadPresetSound()`, `loadCustomSound()` — Audio loading
- `selectCustomSound()` — Opens file picker
- `previewSound()`, `updateSelectedSound()` — Preview functionality
- `startTimer()` — Begins countdown, schedules 1-second ticks
- `stopTimer()`, `resetTimer()` — Pause/reset controls
- `formatTime()` — MM:SS formatting
- `updateMenuBarTitle()` — Notifies delegate of countdown display
- `progress: Double` — Computed property for circular progress ring (0–1 scale)

**Sound Management:**
- Loads sounds into `AVAudioPlayer` on demand
- Preset sounds bundled as WAV files
- Custom sounds accessed via security-scoped bookmarks (survives app restart)
- Fallback to preset if custom file is deleted

**Persistence:**
- All `@Published` properties use `didSet` to auto-save UserDefaults
- Custom sound file access persisted via security-scoped bookmarks
- Restored on app launch via `restoreSavedSettings()`

#### Views (~390 LOC)

**SoundGridItem** (~40 LOC)
- Displays individual sound tile in 3×3 grid
- Shows SF Symbol icon + display name
- Checkmark overlay when selected
- Tappable button with selection callback

**SoundSelectionView** (~55 LOC)
- 3-column LazyVGrid for preset sounds
- Conditional rendering: preset grid OR custom file picker
- Toggle button to switch between preset/custom modes
- File picker triggers `selectCustomSound()`

**TimerRunningView** (~55 LOC)
- Shows active focus session UI
- Task name header (if provided)
- Circular progress ring (160×160) with animated fill
- Monospaced time display (MM:SS)
- "Repeating" label in repeat mode
- Stop button (keyboard shortcut: Enter)

**TimerSetupView** (~65 LOC)
- Configuration screen when timer is idle
- Task name input (optional)
- Duration input (minutes) + Mode picker (Once/Repeat) in one row
- Validation: disables Start button if duration ≤ 0
- Sound selection via SoundSelectionView
- Start Focus button (keyboard shortcut: Enter)

**ContentView** (~30 LOC)
- Router view that switches between TimerSetupView and TimerRunningView
- Quit link at bottom
- 280×480 popover size

#### AppDelegate (NSObject, NSApplicationDelegate, ~110 LOC)

Manages macOS app lifecycle and UI integration.

**Properties:**
- `statusItem: NSStatusItem` — Menu bar icon/text
- `popover: NSPopover` — Main 280×480 window
- `timerViewModel: TimerViewModel` — Shared data model
- `alertPopover: NSPopover?` — Toast notification (optional, auto-dismissed)

**Key Methods:**
- `applicationDidFinishLaunching()` — Sets up ViewModel, popover, status item; registers Cmd+Q shortcut; shows greeting
- `setupTimerViewModel()` — Creates ViewModel and sets delegate to self
- `setupPopover()` — Creates transient popover with ContentView
- `setupStatusItem()` — Creates variable-width status item with ∞ icon, monospaced font
- `togglePopover()` — Shows/hides popover on status item click
- `showAlert()` — Creates 6-second toast notification above status item
- `updateMenuBarTitle()` — Updates status item text with countdown

**Delegate Conformance:** `TimerUpdateDelegate`
- `updateMenuBarTitle(_ title: String)` — Called every 1 second during countdown
- `showAlert(_ message: String)` — Called when timer fires

#### TimerUpdateDelegate Protocol (~5 LOC)

Weak interface for ViewModel to notify AppDelegate of UI updates without creating retain cycle.

```swift
protocol TimerUpdateDelegate: AnyObject {
    func updateMenuBarTitle(_ title: String)
    func showAlert(_ message: String)
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
        │   ├ Input: Task name, Duration, Mode
        │   └ Action: Click "Start Focus"
        │
        └→ TimerRunningView (active)
            ├ Display: Circular progress, Countdown
            └ Action: Click "Stop"
        ↓
    TimerViewModel (@ObservedObject)
        ├ Timer logic (1-second ticks)
        ├ Sound loading & playback (AVAudioPlayer)
        ├ UserDefaults persistence
        └ @Published updates → UI re-renders
        ↓
    AppDelegate (TimerUpdateDelegate)
        ├ Updates NSStatusItem text (menu bar countdown)
        └ Shows NSPopover alert (6-second toast)
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
| AppDelegate | NSObject | Menu bar UI, lifecycle, alerts | 110 |
| TimerViewModel | ObservableObject | Timer logic, sounds, persistence | 210 |
| ContentView | View | Router (Setup ↔ Running) | 30 |
| TimerSetupView | View | Configuration UI (idle state) | 65 |
| TimerRunningView | View | Countdown UI (active state) | 55 |
| SoundSelectionView | View | Sound grid + file picker | 55 |
| SoundGridItem | View | Individual sound tile | 40 |
| TimerUpdateDelegate | Protocol | AppDelegate ↔ ViewModel bridge | 5 |
| TimerMode | Enum | Once / Repeat | — |
| SoundSource | Enum | Preset / Custom | — |
| AlertSound | Enum | 9 preset sound cases | — |

---

## Dependencies

| Framework | Purpose | Risk Level |
|-----------|---------|-----------|
| SwiftUI | UI rendering | Low |
| AVFoundation | Audio playback | Low |
| Cocoa | NSStatusItem, NSPopover, NSOpenPanel | Low |
| UniformTypeIdentifiers | File type filtering (.mp3, .wav) | Low |
| Foundation | UserDefaults, Timer, URL, FileManager | Low |

**External Dependencies:** None. Pure Apple frameworks.

---

## Code Quality Metrics

- **Total LOC** (compiled): 658
- **Cyclomatic Complexity**: Low (mostly linear flows)
- **Test Coverage**: 0% (manual testing only)
- **External Dependencies**: 0
- **Compiler Warnings**: 0
- **Sandbox Entitlements**: Minimal (read-only file access)

---

## Build Configuration

- **Language**: Swift 5
- **Target OS**: macOS 11.5+
- **Build System**: Xcode 16.2
- **Signing**: Automatic, Team ID `YOUR_TEAM_ID`
- **Code Signing Identity**: Apple Development
- **Bundle ID**: `Jay8448.Mind-Bell`
- **Version**: 1.1.0
- **Build Number**: 8

---

## Known Implementation Details

1. **Menu Bar Icon**: Uses SF Symbol "infinity" (∞) with variable-length status item
2. **Time Format**: MM:SS (e.g., "08:30" for 8.5 minutes)
3. **Progress Ring**: Filled from 0 (empty) to 1 (full) using Circle.trim()
4. **Sound Playback**: AVAudioPlayer (not AVAudioEngine or AudioContext)
5. **Persistence**: UserDefaults, not Core Data (simple key-value suffices)
6. **File Access**: Security-scoped bookmarks for sandboxed file re-access
7. **Popover Behavior**: Transient (closes when app loses focus)
8. **Alert Toast**: 6-second auto-dismiss via DispatchQueue.main.asyncAfter()
