# MindBell: Project Overview & Product Development Requirements

## Product Vision

MindBell is a minimal, distraction-free focus timer for macOS that helps users maintain deep work sessions through periodic gentle bell notifications. By living entirely in the menu bar without a dock presence, it keeps the interface invisible yet always available.

**Tagline**: *Focus freely. Bell gently.*

## Target Users

- Knowledge workers, developers, writers, researchers seeking uninterrupted focus
- Users who need periodic reminders without constant visual intrusion
- Professionals practicing pomodoro or custom time-boxing techniques
- Anyone looking for a lightweight, native macOS tool

## Problem Statement

Existing focus timer apps are often:
- Heavy or cluttered with unnecessary features
- Prominent on the dock, adding visual distraction
- Difficult to customize or remember preferences
- Designed for iOS rather than native macOS workflows

MindBell solves these by offering a menu bar-only experience with sensible defaults and minimal cognitive load.

## Core Features

### 1. Menu Bar Timer (MVP)
- **Status**: Completed
- Single NSStatusItem in the menu bar showing countdown (MM:SS) while running
- Tap to open/close main popover without interrupting work
- No dock presence (LSUIElement = true)

### 2. Configurable Focus Duration
- **Status**: Completed
- Set duration from 1–999 minutes (default 8)
- Persisted via UserDefaults
- Numeric input with validation

### 3. Timer Modes
- **Status**: Completed
- **Once**: Timer stops after firing once
- **Repeat**: Timer resets and continues indefinitely until manually stopped

### 4. Task Naming
- **Status**: Completed
- Optional text field to label the focus session
- Displayed in alert notification when timer fires
- Helps track what you were focusing on

### 5. Preset Sounds
- **Status**: Completed
- 9 built-in bell/chime sounds (WAV format)
- Organized in 3×3 grid for quick selection
- Tap to preview before starting
- Persistent selection via UserDefaults

### 6. Custom Sound Import
- **Status**: Completed
- File picker for MP3 and WAV files
- Security-scoped bookmarks allow re-access after app restart
- Fallback to preset if custom file is deleted

### 7. Alert Notifications
- **Status**: Completed
- Toast-style popover shown for 6 seconds when timer fires
- Displays task name (if provided)
- Auto-dismisses; can be manually closed

### 8. Circular Progress Ring
- **Status**: Completed
- Visual countdown ring in the main view during active session
- Smooth animation with 1-second updates
- Monospaced digit display for time

### 9. Keyboard Shortcuts
- **Status**: Completed
- Enter: Start/stop timer
- Cmd+Q: Quit app

## Technical Requirements

### Non-Functional Requirements
- **Platform**: macOS 11.5 or later (Monterey+)
- **Language**: Swift 5 with SwiftUI
- **Build System**: Xcode 16.2
- **Frameworks**: SwiftUI, AVFoundation, Cocoa, UniformTypeIdentifiers
- **Code Size**: Single 658-line Swift file (main logic)
- **Sandbox**: Enabled with minimal entitlements
- **No External Dependencies**: Pure Apple frameworks only
- **No Tests**: Manual testing only (future improvement)
- **No CI/CD**: Manual signing and distribution

### Security & Privacy
- Sandbox enabled for process isolation
- File access restricted to user-selected files only
- Security-scoped bookmarks for persistent file access
- No network calls, no data collection
- No third-party libraries with privacy concerns

### Performance
- Lightweight memory footprint (menu bar app)
- Timer tick every 1 second with smooth UI updates
- Sound playback via native AVAudioPlayer
- ~50–100 MB disk footprint (including all preset sounds)

## User Stories

### 1. New User Setup
**As a** new user,
**I want to** start a focus session in 30 seconds,
**So that** I can begin work without configuration friction.

**Acceptance Criteria:**
- App launches with sensible defaults (8 min, Singing Bowl)
- Input validation prevents invalid durations
- Single "Start Focus" button initiates timer

### 2. Custom Sound Import
**As a** user with a favorite meditation bell,
**I want to** import my own MP3 file,
**So that** I hear a sound that resonates with my workflow.

**Acceptance Criteria:**
- File picker restricts to MP3/WAV only
- Selection persists across app restarts
- Fallback to preset if file is deleted
- File access is secure (sandboxed)

### 3. Repeated Focus Sessions
**As a** user practicing pomodoro,
**I want to** set repeat mode,
**So that** my timer automatically resets without manual intervention.

**Acceptance Criteria:**
- Toggle between "Once" and "Repeat" modes
- Repeat mode fires alert and auto-resets
- Stop button halts the cycle

### 4. Menu Bar Visibility
**As a** a focused developer,
**I want to** see the countdown in the menu bar,
**So that** I don't need to switch windows to check remaining time.

**Acceptance Criteria:**
- Menu bar shows MM:SS while running
- Updates every second
- Clears when timer stops
- No dock icon (true menu bar app)

## Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| App launch time | < 500ms | ✓ |
| Menu bar countdown accuracy | ±1 second | ✓ |
| Sound playback latency | < 100ms | ✓ |
| Memory footprint | < 50 MB | ✓ |
| Sound loading time | < 500ms | ✓ |
| UserDefaults persistence | 100% reliability | ✓ |

## Future Roadmap

### Phase 2: iOS Support
- Unfold iOS code currently in `Focus_BellApp_Mobile.swift`
- Share TimerViewModel via SPM
- Adapt UI for iPad and iPhone

### Phase 3: App Store Distribution
- Generate signed DMG for auto-update capability
- Create privacy policy and ASC listing
- Implement Sparkle framework for delta updates

### Phase 4: Advanced Features
- Custom notification intervals (e.g., "Alert every 2 cycles")
- Sound volume control
- Dark/light mode preferences
- Statistics dashboard (sessions completed, total focus time)
- iCloud sync of preferences across Mac devices
- Dock/menubar app toggles

### Phase 5: Accessibility
- VoiceOver support for vision-impaired users
- Haptic feedback option
- High-contrast mode support
- Keyboard-only navigation

## Technical Debt & Known Limitations

1. **No Test Coverage**: Currently manual testing only. Recommend unit tests for TimerViewModel and integration tests for sound playback.
2. **Single-File Architecture**: 658-line main file is readable but approaching split point. Future refactoring: extract Views, ViewModel, and Models into separate files.
3. **iOS Code Commented Out**: `Focus_BellApp_Mobile.swift` is not compiled. Recommend extracting shared code into framework.
4. **No Localization**: Currently English only. Add i18n for international markets.
5. **Limited Error Handling**: Sound loading errors log to console but don't notify user. Add user-facing error alerts.
6. **No Analytics**: No usage tracking or crash reporting. Consider privacy-preserving telemetry.

## Dependencies

| Dependency | Version | Purpose | Risk |
|------------|---------|---------|------|
| SwiftUI | iOS 15+ | UI framework | Low—Apple platform |
| AVFoundation | macOS 10.7+ | Audio playback | Low—system framework |
| Cocoa | macOS 10.0+ | Menu bar integration | Low—system framework |
| UniformTypeIdentifiers | macOS 11+ | File type detection | Low—system framework |

## Go-to-Market Strategy

1. **Beta Phase** (Current): Manual distribution, user feedback gathering
2. **v1.1 Release**: Polish UI, finalize feature set, prepare for App Store
3. **App Store Submission**: Target mid-2026
4. **Marketing**: Indie Hackers, Product Hunt, macOS newsletters
5. **Community**: GitHub discussions, Reddit r/macapps

## Glossary

| Term | Definition |
|------|-----------|
| Focus Session | One active timer cycle from start to alert |
| Menu Bar | The macOS top-right system area showing clock, battery, etc. |
| Popover | Small floating window anchored to the status item |
| Toast | Short-lived notification (MindBell: 6 seconds) |
| UserDefaults | macOS persistent key-value storage (like SharedPreferences) |
| Security-Scoped Bookmark | Token that allows app to re-access user-selected files |
