# MindBell

A minimal, distraction-free focus timer for macOS that lives entirely in the menu bar. Set a duration, choose a calm sound notification, and stay focused.

## Features

- **Menu bar timer**: Minimalist interface—no dock icon, no distractions
- **Configurable focus sessions**: Set duration in minutes (default 8) and choose once or repeat mode
- **9 preset sounds**: Singing Bowl, Zen Bell, Wind Chime, Chime, Bike Bell, School Bell, Airport, Temple Bell, Xylophone
- **Custom sound support**: Import your own MP3 or WAV files for alert notifications
- **Sound preview**: Tap any sound to hear it immediately before starting
- **Task labels**: Optionally name your focus session (e.g., "Deep Work", "Reading")
- **Circular progress ring**: Visual countdown during focus time
- **Toast notifications**: Shows a 6-second alert when timer fires
- **Persistent settings**: Remembers your last duration, sound, and custom files
- **Keyboard shortcuts**: Enter to start/stop, Cmd+Q to quit

## Requirements

- macOS 11.5 or later
- Swift 5
- Xcode 16.2 (for building)

## Building & Running

### From Xcode
1. Open `MindBell.xcodeproj` in Xcode 16.2
2. Select the "Focus Bell" target
3. Choose **Product > Build** (Cmd+B) to compile
4. Choose **Product > Run** (Cmd+R) to launch the app

### From Command Line
```bash
xcodebuild -project "MindBell.xcodeproj" -scheme "Focus Bell" -configuration Release build
open "build/Release/Focus Bell.app"
```

## Project Structure

```
Focus Bell/
├── Focus_BellApp.swift          # Main app entry point, views, and core logic
├── Focus_BellApp_Mobile.swift   # iOS version (commented out, not compiled)
├── Focus_Bell.entitlements      # Sandbox and file access permissions
├── Assets.xcassets/             # App icons and image assets
├── Preview Content/             # SwiftUI preview data
└── [9 sound files]              # Preset alert sounds (WAV format)
```

## Architecture Overview

**MindBell** uses a single-file MVVM pattern:

- **TimerViewModel**: Manages timer logic, sound loading/playback, and UserDefaults persistence
- **AppDelegate**: Manages the menu bar status item, main popover UI, and alert notifications
- **Views**: `ContentView` (router), `TimerSetupView` (configuration), `TimerRunningView` (countdown display), `SoundSelectionView` (sound picker)
- **Enums**: `TimerMode`, `SoundSource`, `AlertSound`
- **Protocol**: `TimerUpdateDelegate` bridges ViewModel to AppDelegate for UI updates

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Enter | Start focus / Stop timer |
| Cmd+Q | Quit MindBell |

## Entitlements

MindBell runs in Apple's macOS sandbox with these permissions:
- **App Sandbox**: Enabled for security
- **File Access**: Can read user-selected files (custom sounds)
- **Security-Scoped Bookmarks**: Remembers access to imported sound files

## License

This project is licensed under the [MIT License](LICENSE).

## Support

For issues or feature requests, visit the project repository.
