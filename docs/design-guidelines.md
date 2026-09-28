# MindBell: Design Guidelines

## Design Philosophy

**Minimalism Over Maximalism**

MindBell embraces Apple's design principles:
- **Clarity**: Remove visual clutter, show only what's essential
- **Deference**: Don't compete with user's content; stay in the background
- **Depth**: Use subtle animations and spatial hierarchy

**Menu bar app paradigm**: The UI should be invisible until needed, then present a focused, single-purpose interface.

---

## Visual Identity

### Color Palette

**Primary Accent Color**
- **Light Mode**: macOS system accent color (default blue)
- **Dark Mode**: Same accent color (auto-inverted by system)
- **Usage**: Progress ring fill, selected button states, checkmarks
- **Configuration**: System → Settings > Appearance (user-configurable)

**Neutral Colors**
- **Text**: System foreground color (black in light, white in dark)
- **Secondary Text**: `.secondary` (gray in both modes)
- **Background**: System background (white in light, dark gray in dark)
- **Borders**: `.gray.opacity(0.2)` for subtle dividers

**Alert States**
- **Valid**: Green tint (via system's `.green`)
- **Invalid**: Red tint for duration ≤ 0 (via system's `.red`)
- **Info**: Blue tint (accent color)

**No Custom Colors**
- Leverage macOS system colors for:
  - Automatic light/dark mode support
  - User accessibility preferences (high contrast, reduced transparency)
  - Future OS version compatibility

### Typography

**Font Stack**

| Purpose | Font | Size | Weight | Usage |
|---------|------|------|--------|-------|
| Countdown | System (Rounded, Monospaced digits) | 36pt | Light | Time display (MM:SS) |
| Labels | System | 14pt | Regular | Task name header |
| Captions | System | 11–12pt | Regular | Button text, sound names, status label |
| Section Titles | System | 12pt | Regular | "Task", "Minutes", "Mode", "Sound" |

**Font Properties**
- **Monospaced for digits**: `NSFont.monospacedDigitSystemFont(ofSize:weight:)` ensures consistent width for countdown
- **System fonts only**: No custom fonts; macOS fonts auto-update with OS

### Icon System

**SF Symbols (San Francisco Symbols)**
- Apple's native icon library
- Auto-scales with text
- Respects system accent color
- All icons used in MindBell are from SF Symbols 5+

**Icons Used**

| Icon | SF Symbol Name | Context | Size |
|------|----------------|---------|------|
| App Icon | `bell` (running/idle) / `pause.circle` (paused) | Menu bar button | 16pt |
| Singing Bowl | `circle.bottomhalf.filled` | Preset sound tile | 16pt |
| Temple Bell | `bell` | Preset sound tile | 16pt |
| Tingsha | `sparkles` | Preset sound tile | 16pt |
| Wind Chime | `wind` | Preset sound tile | 16pt |
| Kalimba | `music.note` | Preset sound tile | 16pt |
| Marimba | `music.quarternote.3` | Preset sound tile | 16pt |
| Airport | `airplane` | Preset sound tile | 16pt |
| Soft Ding | `tuningfork` | Preset sound tile | 16pt |
| Custom Sound | `folder.badge.plus` | Custom sound grid tile (9th tile) | 16pt |
| Start Focus | (Implied, no icon) | Start Focus button | — |
| Pause / Resume | (Implied, no icon on button; status label uses `pause.fill`) | Pause/Resume button + status label | — |
| Stop | (Implied, no icon) | Stop button | — |
| Once Mode | `1.circle` | Mode picker option; "Ends at" status uses `clock` | 14pt |
| Repeat Mode | `repeat` | Mode picker option; "Next bell" status | 14pt |
| Volume | `speaker.fill` / `speaker.wave.3.fill` | Volume slider endpoints | 12pt |
| Checkmark | `checkmark.circle.fill` | Selected sound indicator | 11pt |

**Icon Design Rules**
- Always pair with text label (icon alone is ambiguous)
- Use `foregroundColor(.accentColor)` for interactive icons
- Use `foregroundColor(.secondary)` for hints/disabled states

---

## UI Components

### Status Item (Menu Bar)

```
┌─────────────────────┐
│ 🔔  08:30           │
└─────────────────────┘
  ↑     ↑      ↑
  |     |      └─→ Countdown text (monospaced, right-aligned)
  |     └──────────→ Icon (SF Symbol)
  └────────────────→ Draggable menu bar area
```

**Specifications**
- **Length**: Variable-width (expands with countdown)
- **Icon**: `bell` symbol; swaps to `pause.circle` while paused
- **Text**: Monospaced countdown (MM:SS) while running, empty when idle
- **Font**: `NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)`
- **Padding**: 4pt left/right of text
- **Background**: None (transparent, inherits menu bar)
- **Click Action**: Toggle main popover (also activates the app)

**Visual States**
1. **Idle**: [🔔 ]
2. **Running**: [🔔 08:30]
3. **Paused**: [⏸ 08:30] (`pause.circle` icon)

### Main Popover

```
┌─────────────────────────────────────┐
│  Focus Bell (title bar, auto)       │
├─────────────────────────────────────┤
│                                     │
│     ┌─ Setup View (idle) ──────┐   │
│     │                           │   │
│     │ Task: [Enter task...]     │   │
│     │ Minutes: [8] (5)(15)(25)(50)│  │
│     │ Mode: [Once ●] [Repeat ○] │   │
│     │                           │   │
│     │ Sound:                    │   │
│     │ [Bowl] [Bell] [Tingsha]   │   │
│     │ [Wind] [Kalimba] [Marimba]│   │
│     │ [Airport] [Ding] [Custom] │   │
│     │ 🔈 ────●──────── 🔊       │   │
│     │                           │   │
│     │ [Start Focus =========]   │   │
│     │                           │   │
│     └───────────────────────────┘   │
│                                     │
│     OR                              │
│                                     │
│     ┌─ Running View (busy) ────┐   │
│     │                           │   │
│     │   Focus Session Label     │   │
│     │                           │   │
│     │    ╭─────────────────╮   │   │
│     │    │                 │   │   │
│     │    │    ◯──── ◮      │   │   │
│     │    │   08:30         │   │   │
│     │    │  Next bell 9:14 │   │   │
│     │    │                 │   │   │
│     │    ╰─────────────────╯   │   │
│     │                           │   │
│     │  [Pause ====] [Stop ====] │   │
│     │                           │   │
│     └───────────────────────────┘   │
│                                     │
│  ☐ Launch at Login          Quit    │
│  MindBell by Jay                    │
├─────────────────────────────────────┘
```

**Specifications**
- **Width**: Fixed 280 points; height follows content (setup vs. running), sized via `sizingOptions = .preferredContentSize` on macOS 13+
- **Behavior**: Transient (closes on focus loss); activates the app when it opens and returns focus to the previous app when closed with Esc or the menu bar icon
- **Padding**: 20pt all sides
- **Spacing between sections**: 16pt
- **Corner radius**: Automatic (NSPopover default)
- **Appearance**: Respects light/dark mode

**Component Spacing**
- Vertical spacing between sections: 16pt
- Vertical spacing within sections: 4–8pt
- Horizontal spacing between columns: 12pt

### Sound Selection Grid

```
┌─────────────────────────────────────────┐
│  Singing Bowl  │ Temple Bell   │ Tingsha│
│  ◉             │               │        │
│  [Circle]      │ [Bell]        │ [✨]   │
│                │               │        │
├────────────────┼───────────────┼────────┤
│  Wind Chime    │ Kalimba       │ Marimba│
│  ✓             │               │        │
│  [Wind]        │ [Note]        │ [Notes]│
│ (highlighted)  │               │        │
├────────────────┼───────────────┼────────┤
│  Airport       │ Soft Ding     │ Custom │
│                │               │        │
│  [Airplane]    │ [Tuning Fork] │ [Folder+]│
│                │               │        │
└─────────────────────────────────────────┘
```

Custom is the 9th tile; tapping it opens the file picker (first pick, or when Custom is
already selected) or switches back to the previously saved custom file. A volume slider
sits below the grid; releasing it previews the sound.

**Grid Layout**
- **Columns**: 3 (fixed), 9 tiles total (8 presets + Custom)
- **Spacing**: 6pt between tiles
- **Tile Size**: ~70×70pt (flexible)
- **Tile Padding**: 6pt vertical, 8pt horizontal

**Tile Styling**
- **Normal**: Border (1pt gray@0.2), rounded corners (8pt), transparent background
- **Selected**: Border (1pt accent@0.5), rounded corners (8pt), background (accent@0.15), checkmark overlay
- **Hover**: Subtle opacity change (not animated)

### Sound Grid Item (Tile)

```
┌──────────────────┐
│  ✓ (top-right)   │
│  [Icon 16pt]     │
│  Singing Bowl    │
│  (caption)       │
└──────────────────┘
```

**Specifications**
- **Icon Size**: 16pt
- **Icon-to-Text Spacing**: 4pt
- **Text Size**: 11pt
- **Text Alignment**: Center
- **Border Radius**: 8pt
- **Border Width**: 1pt
- **Checkmark Size**: 11pt (top-right corner)

**States**
1. **Normal**: Transparent background, gray@0.2 border
2. **Selected**: Accent-colored background (opacity 0.15) + border (accent@0.5) + accent-colored checkmark
3. **Pressed**: Slight scale-down or opacity change (subtle feedback)
4. **Accessibility**: Selected tiles expose the `.isSelected` trait alongside `.isButton`

### Input Fields

```
┌────────────────────────────────────┐
│ Task                               │
│ [What are you focusing on?........]│
└────────────────────────────────────┘

┌──────────────────────────┐
│ Minutes                  │
│ [8] (5)(15)(25)(50)      │  ← text field (48pt) + preset chips
└──────────────────────────┘

┌──────────────────────┐
│ Mode                 │
│ [Once ●] [Repeat ○] │  ← Segmented picker
└──────────────────────┘
```

**Text Field (Task Input)**
- **Style**: `.roundedBorder`
- **Height**: ~32pt (auto)
- **Placeholder**: "What are you focusing on?"
- **Placeholder Color**: `.secondary`
- **Font**: System, 13pt regular

**Numeric Field (Duration)**
- **Width**: 48pt (fixed for short numbers)
- **Style**: `.roundedBorder`
- **Font**: System, 13pt regular
- **Input Type**: Numbers only, updates on every keystroke
- **Quick presets**: `MinutePresetChip` row for 5/15/25/50 minutes, highlighted when it matches the current value
- **Validation**: Must be ≥ 1; shows inline red "Enter at least 1 minute" and disables Start Focus otherwise

**Mode Picker**
- **Style**: Segmented control
- **Options**: "Once", "Repeat"
- **Icons**: 1.circle, repeat
- **Width**: Flexible
- **Behavior**: Toggle between modes

### Progress Ring (Countdown View)

```
        ┌─────────────┐
        │             │
      ╱             ╲
    ╱    ◯───────     ╲
    │    │         │    │
    │    │  08:30  │    │
    │    │Next bell│    │
    │    │  9:14   │    │
    ╲    ╲─────────╱    ╱
      ╲             ╱
        └─────────────┘

        (animated fill from 0–100%; ring dims to 40% opacity while paused)
```

**Circle Specifications**
- **Diameter**: 160pt
- **Background Ring**: Gray@0.15, 6pt stroke width
- **Progress Ring**: Accent color, 6pt stroke width, rounded caps
- **Rotation**: Starts at top (-90°), fills clockwise
- **Animation**: Linear, 1-second duration per tick
- **Paused State**: Ring opacity drops to 0.4

**Time Display**
- **Font**: System, rounded design, monospaced digits, 36pt, light weight
- **Format**: MM:SS (e.g., "08:30")
- **Vertical Alignment**: Center in ring
- **Color**: System foreground (auto-inverted for dark mode)

**Status Label (below time)**
- **Text**: "Ends at h:mm" (once mode), "Next bell h:mm" (repeat mode), or "Paused"
- **Icon**: `clock`, `repeat`, or `pause.fill` to match the text
- **Font**: System, 11pt, regular
- **Color**: `.secondary`
- **Visible**: Always, while running

### Buttons

```
┌─────────────────────────────────┐
│  Start Focus / Pause / Resume   │
│  (full width, controlSize.large)│
└─────────────────────────────────┘

[Stop]  (large, default style, no accent fill)
Change… (link-style, under the Custom tile)
```

**Primary Button (Start Focus / Pause / Resume)**
- **Style**: `.borderedProminent`
- **Size**: Control size `.large`
- **Width**: Full width (Start Focus) or half width next to Stop (Pause/Resume)
- **Background**: System accent color
- **Text Color**: White (auto-adjusted on accent)
- **Border Radius**: Default (auto)
- **State Disabled**: Start Focus only, when duration ≤ 0
- **Keyboard Shortcut**: Return — Start Focus while idle, Pause/Resume while running

**Stop Button**
- **Style**: Default (no `.buttonStyle` override — system bordered look, not accent-filled)
- **Size**: Control size `.large`
- **Width**: Half width, next to Pause/Resume
- **Keyboard Shortcut**: None (intentional — Stop ends the session and should never fire by accident)

**Link-Style Controls (Change…, Quit, credit)**
- **Style**: `.link` (Change…) or `.plain` (Quit) / `Link` (credit)
- **Font**: `.caption`
- **Text Color**: `.secondary` (Quit) or default link color (Change…, credit)
- **Cursor**: Pointing-hand on hover (`PointingHandCursor` modifier)

### Alert Popover (Toast)

```
┌────────────────────────────────┐
│  "Focus started · task"        │
│  "Time's up" / "Time's up · task"│
│  or "MindBell is ready"        │
│  (auto-sizes, max 484pt wide)  │
└────────────────────────────────┘

Duration: 6 seconds, then auto-dismisses
Position: Above menu bar icon
```

**Specifications**
- **Padding**: 6pt vertical, 12pt horizontal
- **Font**: System, 13pt, regular
- **Text Alignment**: Center
- **Max Width**: 484pt
- **Background**: System background (with default popover styling)
- **Border**: None
- **Auto-dismiss**: 6 seconds via DispatchQueue

**Behavior**
- "Focus started" shows only when a task name is set; "Time's up" always shows on every cycle
- "MindBell is ready" shows once, on first launch only
- Every "Time's up" is paired with a silent system notification (fixed identifier, so repeat mode replaces rather than stacks)
- Replaces previous alert if one was showing
- Auto-closes after 6 seconds
- User can click to close immediately (no click handler; just let popover dismiss)

---

## Layout & Spacing

### Vertical Rhythm

**Standard Spacing Scale**
- 4pt: Micro-spacing (icon padding)
- 6pt: Compact spacing (grid items)
- 8pt: Small spacing (within sections)
- 12pt: Medium spacing (between form fields)
- 16pt: Large spacing (between major sections)
- 20pt: Popover padding (top/bottom/left/right)

**Example**
```
Setup View (20pt padding on all sides):

Task [16pt vertical spacing]
Duration + Mode [12pt spacing between fields]
Sound [16pt vertical spacing]
[6pt within sound grid]
Start Button [16pt vertical spacing]
```

### Responsive Behavior

**Popover Size**
- Fixed 280pt width; height follows content (Setup vs. Running) instead of a fixed height
- Text wraps as needed
- VStack handles overflow with Spacer

**Grid Columns**
- Fixed 3 columns (determined by visual design, not screen width)
- Always shows a 3×3 grid: 8 preset tiles + the Custom tile

**Button Width**
- Primary buttons: Full width of container
- Secondary buttons: Intrinsic size (fit content)

---

## Animation & Motion

### Timing Functions

| Animation | Duration | Curve | Used For |
|-----------|----------|-------|----------|
| Progress ring fill | 1.0 sec | Linear | Countdown circle updates |
| Text transition | 0.3 sec | EaseInOut | Label changes |
| Popover show | 0.15 sec | EaseOut | Main window appears |
| Alert toast show | 0.2 sec | EaseOut | Toast notification appears |

### Animation Examples

**Progress Ring Tick**
```swift
Circle()
    .trim(from: 0, to: viewModel.progress)
    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
    .animation(.linear(duration: 1), value: viewModel.progress)
```

**Reduces Motion**
- Not explicitly implemented (future accessibility improvement)
- SwiftUI respects system reduce-motion preference by default

### Interaction Feedback

- **Button Press**: Native system feedback (slight scale/opacity change)
- **Sound Selection**: Sound preview plays immediately (audio feedback)
- **Input Validation**: Red error text appears instantly
- **Timer Fire**: Popover appears + sound plays (visual + audio feedback)

---

## Accessibility Considerations

### Current Implementation

- ✅ System colors auto-invert for dark mode
- ✅ SF Symbols scale with text
- ✅ Keyboard shortcuts (Enter, Cmd+Q)
- ✅ Button labels are clear
- ✅ Sound tiles and minute chips carry an accessibility label and expose the `.isSelected` trait when active
- ✅ Volume slider and minutes field have accessibility labels
- ❌ Full VoiceOver pass not done
- ❌ High contrast mode not tested

### Future Improvements

- [ ] Test with VoiceOver enabled end-to-end
- [ ] Ensure keyboard navigation works (Tab, Shift+Tab)
- [ ] Support high-contrast mode
- [ ] Add haptic feedback option

### Labels & Descriptions

**Accessibility Labels in Use**

| Control | Label | Trait/Value |
|---------|-------|-------|
| Sound Tile | Sound display name (e.g. "Singing Bowl") | `.isSelected` when active |
| Minute Preset Chip | "N minutes" | `.isSelected` when it matches the current duration |
| Volume Slider | "Volume" | — |
| Minutes Field | "Minutes" | — |
| Progress Ring | Combined child elements | — |

**Still Recommended**

| Control | Label | Value |
|---------|-------|-------|
| Status Item | "MindBell menu bar timer" | "08:30 remaining" |
| Mode Picker | "Timer mode" | "Once" or "Repeating" |

---

## Dark Mode Support

**Automatic via System Colors**

All colors specified in this guide use system names:
- `.foregroundColor` (text) → auto-inverts
- `.secondary` (gray) → auto-inverts
- `.accentColor` (blue) → no change needed
- `.background` → auto-inverts

**Manual Testing**
1. Open System Preferences > Appearance
2. Switch between "Light" and "Dark"
3. MindBell UI should auto-adjust

**No Additional Work Needed** (system handles it)

---

## Design Debt

### Known Limitations

1. **No Custom Themes**: Only system accent color available
2. **Fixed Popover Width**: 280pt width can't be resized by the user (height now follows content on macOS 13+)
3. **No Animations on Duration Change**: Could be smoother
4. **Sound Grid Icon Sizes**: Could be fine-tuned per icon

### Future Improvements

- Optimize grid item icon sizing
- Add smooth transitions between Setup/Running views
- Consider custom color schemes (if high user demand)

---

## Design Review Checklist

Before shipping UI changes, verify:

- [ ] Follows system colors (not custom hex)
- [ ] Icons are SF Symbols (not custom assets)
- [ ] Spacing follows 4pt/8pt/16pt grid
- [ ] Font sizes are standard (13pt, 11pt, 36pt, etc.)
- [ ] Dark mode tested (System Preferences > Appearance)
- [ ] High contrast mode tested (Accessibility settings)
- [ ] All buttons have clear labels
- [ ] Popover width still 280pt
- [ ] Keyboard shortcuts still work
- [ ] No hardcoded colors (use `.foregroundColor`, `.secondary`, etc.)

---

## Resources & References

### Apple Design Resources
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SF Symbols 5 Reference](https://developer.apple.com/sf-symbols/)
- [Color & Contrast Accessibility](https://developer.apple.com/accessibility/)

### SwiftUI Documentation
- [View Composition](https://developer.apple.com/documentation/swiftui/view)
- [Environment Values](https://developer.apple.com/documentation/swiftui/environmentvalues)
- [Animation](https://developer.apple.com/documentation/swiftui/animation)

