# MindBell

A minimal, distraction-free focus timer for macOS that lives entirely in the menu bar. Set a duration, choose a calm sound notification, and stay focused.

## Features

- **Menu bar timer**: Minimalist interface—no dock icon, no distractions
- **Configurable focus sessions**: Set duration in minutes (default 8, or pick a 5/15/25/50 preset) and choose once or repeat mode
- **8 preset sounds**: Singing Bowl, Temple Bell, Tingsha, Wind Chime, Kalimba, Marimba, Airport, Soft Ding
- **Custom sound support**: Pick your own MP3 or WAV file from the 9th grid tile
- **Sound preview**: Tap any sound (or release the volume slider) to hear it immediately
- **Volume control**: Slider under the sound grid, remembered across launches
- **Task labels**: Optionally name your focus session (e.g., "Deep Work", "Reading")
- **Circular progress ring**: Visual countdown during focus time; dims while paused
- **Pause & resume**: Pause a running session and pick up where you left off
- **Toast + notification**: Shows an on-screen alert when the timer fires, plus a silent system notification
- **Persistent settings**: Remembers your last duration, sound, volume, and custom file
- **Keyboard shortcuts**: Enter to start a session (or pause/resume it while running), Cmd+Q to quit

## Installation

### Download (Recommended)

1. Go to the [Releases](https://github.com/jaynguyen-vn/mind-bell/releases/latest) page
2. Download **MindBell.dmg** (or MindBell.zip)
3. Open the `.dmg` and drag **MindBell.app** to your **Applications** folder
4. On first launch, right-click the app and select **Open** (macOS Gatekeeper prompt for unsigned apps)
5. MindBell appears as a bell icon in your menu bar — no dock icon

> **Note:** MindBell is not notarized by Apple. On first run macOS may block it. Go to **System Settings > Privacy & Security** and click **Open Anyway**, or right-click → Open.

### Build from Source

**Requirements:** macOS 12.0+, Xcode 16.2 or later, Swift 5

#### From Xcode
1. Open `MindBell.xcodeproj` in Xcode
2. Select the "MindBell" scheme
3. **Product > Build** (Cmd+B), then **Product > Run** (Cmd+R)

#### From Command Line
```bash
xcodebuild -project "MindBell.xcodeproj" -scheme "MindBell" -configuration Release -derivedDataPath build build
open "build/Build/Products/Release/MindBell.app"
```

## Project Structure

```
MindBell/
├── MindBell.xcodeproj/              # Xcode project file
├── Info.plist                       # App configuration and metadata
├── LICENSE                          # MIT License
├── README.md
└── Focus Bell/                      # Source code
    ├── Focus_BellApp.swift          # Main app entry point, views, and core logic
    ├── Focus_BellApp_Mobile.swift   # iOS version (commented out, not compiled)
    ├── Focus_Bell.entitlements      # Sandbox and file access permissions
    ├── Assets.xcassets/             # App icons and image assets
    ├── Preview Content/             # SwiftUI preview data
    └── [8 sound files]              # Preset alert sounds (.m4a)
```

## Architecture Overview

**MindBell** uses a single-file MVVM pattern:

- **TimerViewModel**: Manages timer logic, sound loading/playback, and UserDefaults persistence
- **AppDelegate**: Manages the menu bar status item, main popover UI, and alert notifications
- **Views**: `ContentView` (router), `TimerSetupView` (configuration), `TimerRunningView` (countdown display), `SoundSelectionView` (sound picker), `SoundGridItem` (individual sound cell), `MinutePresetChip` (quick duration picker)
- **App Entry**: `TimerApp` (`@main` struct)
- **Enums**: `TimerMode`, `SoundSource`, `AlertSound`
- **Protocol**: `TimerUpdateDelegate` bridges ViewModel to AppDelegate for UI updates

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Enter | Start focus (setup) / Pause–Resume (running) |
| Cmd+Q | Quit MindBell |

## Entitlements

MindBell runs in Apple's macOS sandbox with these permissions:
- **App Sandbox**: Enabled for security
- **File Access**: Can read user-selected files (custom sounds)
- **Security-Scoped Bookmarks**: Remembers access to imported sound files

## Sound Credits

The recorded presets come from [Freesound](https://freesound.org) under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (no attribution required, credited with thanks). Each was trimmed, faded, converted to mono and loudness-normalized to about −18 LUFS.

| Preset | Source | Author |
|--------|--------|--------|
| Singing Bowl | [E flat Tibetan singing bowl struck](https://freesound.org/people/mttvn/sounds/535950/) | mttvn |
| Temple Bell | [Bright Tibetan Bell Ding B Note - cleaner](https://freesound.org/people/steaq/sounds/346328/) | steaq |
| Tingsha | [Tingsha Cymbal](https://freesound.org/people/steffcaffrey/sounds/435074/) | steffcaffrey |
| Wind Chime | [Wind Chimes.wav](https://freesound.org/people/MPTSound/sounds/552458/) | MPTSound |
| Kalimba | [Sansula 04 F' [RAW]](https://freesound.org/people/cabled_mess/sounds/380739/) | cabled_mess |
| Marimba | [Marimba - E#4 (VSCO 2 CE)](https://freesound.org/people/sgossner/sounds/373583/) | sgossner |

Airport is MindBell's original chime, cleaned up; Soft Ding is synthesized for the app.

## License

This project is licensed under the [MIT License](LICENSE).

## Support

For issues or feature requests, visit the project repository.
