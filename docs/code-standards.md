# MindBell: Code Standards & Guidelines

## Overview

MindBell follows Swift and SwiftUI conventions with an MVVM-inspired architecture optimized for simplicity and readability. This document establishes standards for current and future development.

## Naming Conventions

### Swift Naming

**Type Names** (Classes, Structs, Enums, Protocols)
- Use `UpperCamelCase` (PascalCase)
- Examples: `TimerViewModel`, `AlertSound`, `TimerUpdateDelegate`, `SoundSelectionView`
- Descriptive names that indicate type: `ViewModel` suffix for business logic, `View` suffix for SwiftUI components, `Delegate` for protocols

**Variable & Property Names**
- Use `lowerCamelCase`
- Examples: `timeLeft`, `isRunning`, `initialTime`, `customSoundURL`, `selectedSound`
- Use descriptive names that hint at type: `is` prefix for booleans, `URL` suffix for URL types
- Avoid single letters except in closures (`{ $0 }`)

**Function & Method Names**
- Use `lowerCamelCase`
- Verb-first for actions: `startTimer()`, `stopTimer()`, `resetTimer()`, `loadCustomSound()`
- Getter methods omit "get": `formatTime()` not `getFormattedTime()`
- Boolean predicates use "is" or "has": `FileManager.default.fileExists(atPath:)`

**Enum Cases**
- Use `lowerCamelCase` (associated values are lowercase)
- Examples: `.singingBowl`, `.zenBell`, `bikeBell`
- Raw values use `kebab-case` for filenames: `"singing-bowl"`, `"zen-bell"`

**Constants**
- Use `UPPER_SNAKE_CASE` for file-scope constants (rare in Swift; UserDefaults keys are exceptions)
- Example: Keys in UserDefaults might be `"initialTime"`, `"selectedSound"` (lowercase for consistency)

### File Organization

**Filename Convention**
- Use `PascalCase` matching primary type
- Example: `Focus_BellApp.swift` (contains `TimerApp`, `AppDelegate`, views, ViewModels)
- For multi-type files, name after the entry point or most prominent type

**Directory Structure**
```
Focus Bell/
├── Focus_BellApp.swift              # Main app + all logic
├── Focus_BellApp_Mobile.swift       # iOS (commented out)
└── [Asset folders & sounds]
```

**Future Refactoring Structure** (when 658 LOC → 900+ LOC):
```
Focus Bell/
├── App/
│   ├── TimerApp.swift               # @main entry point
│   └── AppDelegate.swift            # NSApplicationDelegate
├── ViewModel/
│   └── TimerViewModel.swift         # ObservableObject
├── Views/
│   ├── ContentView.swift            # Router view
│   ├── TimerSetupView.swift         # Configuration UI
│   ├── TimerRunningView.swift       # Active session UI
│   └── SoundSelectionView.swift     # Sound picker
├── Models/
│   └── TimerEnums.swift             # TimerMode, SoundSource, AlertSound
├── Delegates/
│   └── TimerUpdateDelegate.swift    # Protocol
└── [Assets, Sounds, etc.]
```

## Architecture Pattern: MVVM (Light)

**Model** (MVVM-M)
- Enums: `TimerMode`, `SoundSource`, `AlertSound`
- Data structures encapsulated in `TimerViewModel`
- No separate model classes (simple enough to live in ViewModel)

**ViewModel** (MVVM-VM)
- `TimerViewModel: ObservableObject`
- Owns business logic: timer ticks, sound loading, persistence
- Published properties drive UI updates via `@ObservedObject`
- Stateless methods for configuration changes
- Weak reference to `TimerUpdateDelegate` for menu bar updates (avoids retain cycle)

**View** (MVVM-V)
- SwiftUI only; stateless except for `@ObservedObject` bindings
- Each view has single responsibility:
  - `ContentView`: Route to Setup or Running view
  - `TimerSetupView`: Input form (task name, duration, mode, sound)
  - `TimerRunningView`: Display countdown + stop button
  - `SoundSelectionView`: Grid or file picker
  - `SoundGridItem`: Individual sound tile
- Derived state computed locally (no stored @State except for navigation)

**Delegation**
- `TimerUpdateDelegate` protocol bridges ViewModel → AppDelegate
- Enables AppDelegate to update menu bar and show alerts
- Weak reference prevents memory leaks

**Data Flow**
```
View (@State, @ObservedObject)
    ↓ (User Input)
ViewModel (@Published properties)
    ↓ (Logic, Persistence)
AppDelegate (via TimerUpdateDelegate)
    ↓ (UI Updates)
NSStatusItem & NSPopover
```

## Swift Style Guidelines

### Formatting & Indentation

**Indentation**: 4 spaces (not tabs)
```swift
class TimerViewModel: ObservableObject {
    @Published var timeLeft: Int = 0

    func startTimer() {
        // 4-space indent
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            // 8 spaces for nested blocks
        }
    }
}
```

**Spacing**
- 1 blank line between methods
- 2 blank lines between sections (marked with `// MARK: -`)
- Spacing around operators: `a + b`, not `a+b`
- No space before colons in type declarations: `var name: String`

**Line Length**
- Aim for ≤120 characters
- Break long function signatures across lines:
```swift
panel.begin { [weak self] response in
    guard let self = self else { return }
    // ...
}
```

### Comments & Documentation

**MARK Comments** (Section dividers)
```swift
// MARK: - Sound Grid Item

struct SoundGridItem: View {
    // ...
}

// MARK: - Sound Selection View
```

**Inline Comments** (Explain "why", not "what")
```swift
// Fallback to preset if custom file is deleted or inaccessible
if customSoundURL == nil {
    soundSource = .preset
}

// Save bookmark so app can re-access file after restart
if let bookmark = try? url.bookmarkData(...) {
    UserDefaults.standard.set(bookmark, forKey: "customSoundBookmark")
}
```

**Avoid Over-Commenting**
```swift
// ✗ Bad: Obvious from code
let minutes = timeLeft / 60  // Divide by 60

// ✓ Good: Explains intent
let minutes = timeLeft / 60  // Convert seconds to minutes for display
```

**TODO Comments**
```swift
// TODO: Add volume control slider in Sound Settings
// BUG: Occasionally skips one second tick on system wake
// HACK: Force reload custom sound to handle stale bookmarks
```

### Import Statements

**Order imports** (Apple frameworks first, then third-party, then local):
```swift
import SwiftUI
import AVFoundation
import Cocoa
import UniformTypeIdentifiers
```

**Use Qualified Names** when importing multiple frameworks:
```swift
import SwiftUI          // Use Button, Text, View from here
import AVFoundation     // Use AVAudioPlayer from here
```

Avoid importing entire modules if only 1–2 symbols used; use qualified names:
```swift
// ✓ Preferred
let player = AVFoundation.AVAudioPlayer(...)

// ✗ Less clean with many frameworks
import AVFoundation
let player = AVAudioPlayer(...)
```

### Type Annotations

**Use Explicit Types** where clarity improves readability:
```swift
// ✓ Clear
let initialTime: Int = 8
var delegate: TimerUpdateDelegate? = nil

// ✗ Unclear (type might be ambiguous)
let x = 8
var d = nil
```

**Omit Redundant Types** in obvious cases:
```swift
// ✓ Swift infers correctly
@Published var isRunning = false
let selectedSound = AlertSound.singingBowl
```

**Use Type Aliases** for complex signatures (rare in MindBell):
```swift
typealias AlertCallback = (String) -> Void
```

## Error Handling

**Prefer try-catch over try?**
```swift
// ✓ Better error visibility
do {
    audioPlayer = try AVAudioPlayer(contentsOf: url)
    audioPlayer?.prepareToPlay()
} catch {
    print("Error loading sound file: \(error)")
    // Future: Show user-facing error alert
}

// ✗ Silent failures hide bugs
audioPlayer = try? AVAudioPlayer(contentsOf: url)
```

**Use guard let for Optionals**
```swift
// ✓ Early exit, clear intent
guard let url = customSoundURL else {
    soundSource = .preset
    return
}
loadCustomSound(from: url)

// ✗ Nested optionals hard to read
if let url = customSoundURL {
    if FileManager.default.fileExists(atPath: url.path) {
        loadCustomSound(from: url)
    }
}
```

**Fallback Gracefully**
```swift
// Custom sound deleted? Fall back to preset
if customSoundURL == nil {
    soundSource = .preset
    customSoundName = ""
    loadPresetSound(selectedSound)
}
```

## Memory Management

**Avoid Retain Cycles**
```swift
// ✓ Use [weak self] in closures
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    guard let self = self else { return }
    self.timeLeft -= 1
}

// ✗ Strong reference causes memory leak
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    self.timeLeft -= 1  // Retains self!
}
```

**Weak Delegate References**
```swift
weak var delegate: TimerUpdateDelegate?  // Weak to avoid cycle
```

**Clean Up Resources**
```swift
func stopTimer() {
    isRunning = false
    timer?.invalidate()  // Stop timer
    timer = nil          // Release timer
    audioPlayer?.stop()  // Stop playback
}
```

## File Access & Sandboxing

**Always Use Security-Scoped Bookmarks for Custom Files**
```swift
// Save
if let bookmark = try? url.bookmarkData(options: .withSecurityScope, ...) {
    UserDefaults.standard.set(bookmark, forKey: "customSoundBookmark")
}

// Restore
if let bookmarkData = UserDefaults.standard.data(forKey: "customSoundBookmark") {
    var isStale = false
    if let url = try? URL(resolvingBookmarkData: bookmarkData, ..., bookmarkDataIsStale: &isStale) {
        url.startAccessingSecurityScopedResource()  // Required before access
        // Use url...
    }
}
```

**Check File Existence**
```swift
if FileManager.default.fileExists(atPath: url.path) {
    // Safe to use
} else {
    // File deleted, fall back
}
```

## UserDefaults Persistence

**Naming Convention for Keys**
- Use `lowerCamelCase` for consistency with variable names
- Examples: `"initialTime"`, `"selectedSound"`, `"isCustomSound"`, `"customSoundBookmark"`
- Document keys near usage:
```swift
// UserDefaults keys
private let kInitialTime = "initialTime"
private let kSelectedSound = "selectedSound"
private let kIsCustomSound = "isCustomSound"
private let kCustomSoundBookmark = "customSoundBookmark"
```

**Persist in didSet**
```swift
@Published var initialTime: Int = 8 {
    didSet { UserDefaults.standard.set(initialTime, forKey: "initialTime") }
}
```

**Restore in init**
```swift
init() {
    restoreSavedSettings()
}

private func restoreSavedSettings() {
    let savedTime = UserDefaults.standard.integer(forKey: "initialTime")
    if savedTime > 0 { initialTime = savedTime }
}
```

## Testing (Future)

**Unit Tests** (when implemented):
- Test `TimerViewModel` logic (timer ticks, sound loading, persistence)
- Mock `AVAudioPlayer` for sound tests
- Test UserDefaults save/restore

**Integration Tests**:
- Timer lifecycle (start → tick → stop)
- Custom sound file handling
- Alert popover display

**Manual Testing Checklist** (current):
- [ ] Timer counts down correctly (1 sec per tick)
- [ ] Menu bar updates every second
- [ ] Stop button halts timer
- [ ] Repeat mode auto-resets
- [ ] Preset sounds play
- [ ] Custom sound import works
- [ ] Settings persist after app restart
- [ ] Sound preview works
- [ ] Keyboard shortcuts (Enter, Cmd+Q) work

## Code Review Checklist

Before committing code, verify:
- [ ] Naming follows conventions (PascalCase types, lowerCamelCase vars)
- [ ] No retain cycles (weak self in closures, weak delegates)
- [ ] Error handling present (try-catch, guard let)
- [ ] UserDefaults updates wrapped in didSet
- [ ] MARK sections organize code
- [ ] Comments explain "why", not "what"
- [ ] No print() statements (use proper logging)
- [ ] File paths are absolute, not relative
- [ ] Security-scoped bookmarks used for file access
- [ ] No hard-coded strings (localization-ready)
- [ ] Indentation consistent (4 spaces)
- [ ] No trailing whitespace

## Architectural Decisions

**Single-File Architecture**
- **Decision**: Keep main logic in one file (Focus_BellApp.swift) until 800+ LOC
- **Rationale**: Quick to navigate, single mental model for new contributors
- **Tradeoff**: Readability over modularity at this scale
- **Refactor Point**: When Xcode's outline pane shows > 20 symbols, split by domain (Views, ViewModel, Models)

**MVVM over MVC**
- **Decision**: Use MVVM pattern with ObservableObject
- **Rationale**: SwiftUI's reactive model pairs naturally with MVVM
- **Alternative Considered**: Redux/Redux-like, deemed overkill for single-timer app

**UserDefaults over Core Data**
- **Decision**: Use UserDefaults for all persistence
- **Rationale**: Simple key-value (duration, sound selection) doesn't need relational DB
- **Tradeoff**: Can't easily query historical data, but not needed yet

**Weak Delegate over Observers**
- **Decision**: Use weak delegate reference instead of NotificationCenter
- **Rationale**: AppDelegate is the single consumer; clearer, less magic
- **Future**: If multiple listeners needed, switch to Combine @Published

**No External Dependencies**
- **Decision**: Use only Apple frameworks
- **Rationale**: Reduces attack surface, simplifies distribution, zero build complexity
- **Tradeoff**: Reimplement some utilities (e.g., logging), accept simpler featureset

## Future Refactoring Guidelines

**When to Refactor**:
1. File exceeds 800 LOC
2. Test suite grows (extract testable components)
3. iOS codebase uncommented (extract shared ViewModel)
4. New architecture needed (e.g., Combine for complex state)

**Refactoring Strategy**:
1. Move Views to `Views/{ComponentName}.swift`
2. Extract ViewModel to `ViewModel/TimerViewModel.swift`
3. Isolate Enums in `Models/TimerEnums.swift`
4. Create `AppDelegate.swift` for macOS lifecycle
5. Use SPM to share code between macOS and iOS

## Accessibility Guidelines (Future)

When implementing accessibility features:
- Add `.accessibilityLabel()` to custom controls
- Use `.accessibilityValue()` for dynamic values (countdown)
- Test with VoiceOver enabled
- Maintain keyboard navigation for all interactive elements

## Localization Guidelines (Future)

When adding multi-language support:
- Use `NSLocalizedString("key", comment: "description")`
- Create Strings catalogs for each supported language
- Extract all UI text to localization files
- Test RTL languages (Arabic, Hebrew)

