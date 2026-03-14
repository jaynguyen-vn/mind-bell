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
| Countdown | System (Monospaced) | 36pt | Light | Time display (MM:SS) |
| Labels | System | 14pt | Regular | Task name header |
| Captions | System | 9–10pt | Regular | Button text, sound names |
| Section Titles | System | 12pt | Regular | "Task", "Sound", "Mode" |

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
| App Icon | `infinity` | Menu bar button | 16pt |
| Singing Bowl | `circle.circle` | Preset sound tile | 16pt |
| Zen Bell | `bell` | Preset sound tile | 16pt |
| Wind Chime | `wind` | Preset sound tile | 16pt |
| Chime | `bell.fill` | Preset sound tile | 16pt |
| Bike Bell | `bicycle` | Preset sound tile | 16pt |
| School Bell | `bell.badge` | Preset sound tile | 16pt |
| Airport | `airplane` | Preset sound tile | 16pt |
| Temple Bell | `building.columns` | Preset sound tile | 16pt |
| Xylophone | `pianokeys` | Preset sound tile | 16pt |
| Start | (Implied, no icon) | Start Focus button | — |
| Stop | (Implied, no icon) | Stop button | — |
| Once Mode | `1.circle` | Mode picker option | 14pt |
| Repeat Mode | `repeat` | Mode picker option | 14pt |
| Custom Sound | `folder` | File picker button | 12pt |
| Preset Sounds | `music.note.list` | Toggle to presets | 12pt |
| Checkmark | `checkmark.circle.fill` | Selected sound indicator | 9pt |

**Icon Design Rules**
- Always pair with text label (icon alone is ambiguous)
- Use `foregroundColor(.accentColor)` for interactive icons
- Use `foregroundColor(.secondary)` for hints/disabled states

---

## UI Components

### Status Item (Menu Bar)

```
┌─────────────────────┐
│ ∞  08:30           │
└─────────────────────┘
  ↑     ↑      ↑
  |     |      └─→ Countdown text (monospaced, right-aligned)
  |     └──────────→ Icon (SF Symbol)
  └────────────────→ Draggable menu bar area
```

**Specifications**
- **Length**: Variable-width (expands with countdown)
- **Icon**: `infinity` symbol
- **Text**: Monospaced countdown (MM:SS) while running, empty when idle
- **Font**: `NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)`
- **Padding**: 4pt left/right of text
- **Background**: None (transparent, inherits menu bar)
- **Click Action**: Toggle main popover

**Visual States**
1. **Idle**: [∞ ]
2. **Running**: [∞ 08:30]
3. **Last 60 sec**: [∞ 00:45] (same styling, different numbers)

### Main Popover

```
┌─────────────────────────────────────┐
│  Focus Bell (title bar, auto)       │
├─────────────────────────────────────┤
│                                     │
│     ┌─ Setup View (idle) ──────┐   │
│     │                           │   │
│     │ Task: [Enter task...]     │   │
│     │ Min: [8] Mode: [Once ●]  │   │
│     │                           │   │
│     │ Sound:                    │   │
│     │ [Bell] [Wind] [Singing]   │   │
│     │ [Chime] [...] [...]       │   │
│     │ [Use Custom] [...]        │   │
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
│     │    │  🔄 Repeating   │   │   │
│     │    │                 │   │   │
│     │    ╰─────────────────╯   │   │
│     │                           │   │
│     │   [Stop ============]     │   │
│     │                           │   │
│     └───────────────────────────┘   │
│                                     │
│  Quit                               │
├─────────────────────────────────────┘
```

**Specifications**
- **Size**: 280×480 points
- **Behavior**: Transient (closes on focus loss)
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
│  Singing Bowl  │ Zen Bell      │ Wind   │
│  ◉             │               │ Chime  │
│  [Circle]      │ [Bell]        │ [Wind] │
│                │               │        │
├────────────────┼───────────────┼────────┤
│  Chime         │ Bike Bell     │ School │
│  ✓             │               │ Bell   │
│  [Bell]        │ [Bicycle]     │ [Bell] │
│ (highlighted)  │               │ [Badge]│
├────────────────┼───────────────┼────────┤
│  Airport       │ Temple Bell   │ Xylo   │
│                │               │ phone  │
│  [Airplane]    │ [Columns]     │ [Keys] │
│                │               │        │
└─────────────────────────────────────────┘

[Use Presets] ← Toggle to show file picker instead
```

**Grid Layout**
- **Columns**: 3 (fixed)
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
- **Text Size**: 9pt (caption)
- **Text Alignment**: Center
- **Border Radius**: 8pt
- **Border Width**: 1pt
- **Checkmark Size**: 9pt (top-right corner)

**States**
1. **Normal**: Transparent background, gray@0.2 border
2. **Selected**: Accent-colored background (opacity 0.15) + border (accent@0.5) + white checkmark
3. **Pressed**: Slight scale-down or opacity change (subtle feedback)

### Input Fields

```
┌────────────────────────────────────┐
│ Task                               │
│ [What are you focusing on?........]│
└────────────────────────────────────┘

┌────────┐
│ Minutes│
│ [8...] │  ← 60pt width
└────────┘

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
- **Width**: 60pt (fixed for short numbers)
- **Style**: `.roundedBorder`
- **Font**: System, 13pt regular
- **Input Type**: Numbers only
- **Validation**: Min 1, max 999

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
    │    │ Repeat  │    │
    │    │         │    │
    ╲    ╲─────────╱    ╱
      ╲             ╱
        └─────────────┘

        (animated fill from 0–100%)
```

**Circle Specifications**
- **Diameter**: 160pt
- **Background Ring**: Gray@0.15, 6pt stroke width
- **Progress Ring**: Accent color, 6pt stroke width, rounded caps
- **Rotation**: Starts at top (-90°), fills clockwise
- **Animation**: Linear, 1-second duration per tick

**Time Display**
- **Font**: System, monospaced, 36pt, light weight
- **Format**: MM:SS (e.g., "08:30")
- **Vertical Alignment**: Center in ring
- **Color**: System foreground (auto-inverted for dark mode)

**Mode Label (below time)**
- **Text**: "🔄 Repeating" (icon + text)
- **Font**: System, 10pt, regular
- **Color**: `.secondary`
- **Visible**: Only when mode == .repeat

### Buttons

```
┌─────────────────────────────────┐
│  Start Focus                    │
│  (full width, controlSize.large)│
└─────────────────────────────────┘

[Use Custom] [Choose File] (smaller buttons)
```

**Primary Button (Start/Stop)**
- **Size**: Control size `.large`
- **Width**: Full width (less padding)
- **Height**: ~48pt
- **Background**: System accent color
- **Text Color**: White (auto-adjusted on accent)
- **Border Radius**: Default (auto)
- **Font**: 13pt, semibold
- **State Normal**: Opaque blue
- **State Disabled**: Opaque gray (when duration ≤ 0)
- **State Pressed**: Darker blue (native system handling)

**Secondary Buttons (Toggle, File Picker)**
- **Size**: Control size `.small`
- **Style**: `.bordered`
- **Background**: Transparent
- **Border**: 1pt system border
- **Text Color**: Accent color
- **Font**: 12pt, regular

**Link-Style Buttons (Quit)**
- **Style**: `.plain`
- **Text Color**: `.secondary`
- **Font**: 11pt, regular
- **Hover**: Slightly darker (native system)
- **No background** or border

### Alert Popover (Toast)

```
┌────────────────────────────────┐
│  Focus Session (task name)     │
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
- Appears above status item when timer fires
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
- Fixed 280×480pt (macOS doesn't need responsive breakpoints)
- Text wraps as needed
- VStack handles overflow with Spacer

**Grid Columns**
- Fixed 3 columns (determined by visual design, not screen width)
- Always shows 3×3 grid for sound selection

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
- ❌ VoiceOver support not yet added
- ❌ High contrast mode not tested

### Future Improvements (Phase 4)

- [ ] Add `.accessibilityLabel()` and `.accessibilityValue()` to all controls
- [ ] Test with VoiceOver enabled
- [ ] Ensure keyboard navigation works (Tab, Shift+Tab)
- [ ] Support high-contrast mode
- [ ] Add haptic feedback option

### Labels & Descriptions

**Recommended Accessibility Labels** (for future implementation)

| Control | Label | Value |
|---------|-------|-------|
| Status Item | "MindBell menu bar timer" | "08:30 remaining" |
| Start Button | "Start Focus" | (dynamic) |
| Progress Ring | "Focus progress" | "50% complete" |
| Sound Tile | "Singing Bowl preset" | "selected" (if selected) |
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
2. **Fixed Popover Size**: Can't resize (design constraint)
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
- [ ] Font sizes are standard (13pt, 9pt, 36pt, etc.)
- [ ] Dark mode tested (System Preferences > Appearance)
- [ ] High contrast mode tested (Accessibility settings)
- [ ] All buttons have clear labels
- [ ] Popover size still 280×480pt
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

