# MindBell: Project Roadmap

## Current Status

**Version:** 1.1.0
**Build:** 8
**Release Date:** 2026-03-14
**Platform:** macOS 11.5+ (menu bar app)
**Language:** Swift 5, SwiftUI
**Status:** Feature-complete (MVP + preset sounds)

---

## Milestone Timeline

### ✅ Phase 1: MVP & Preset Sounds (COMPLETED)

**Completed in v1.1.0:**
- [x] Menu bar timer with countdown display
- [x] Configurable focus duration (1–999 minutes)
- [x] Once / Repeat timer modes
- [x] 9 preset bell/chime sounds
- [x] Sound preview (tap to hear)
- [x] Custom sound import (MP3/WAV)
- [x] Task naming (optional label)
- [x] Circular progress ring UI
- [x] 6-second alert popover
- [x] UserDefaults persistence
- [x] Keyboard shortcuts (Enter, Cmd+Q)
- [x] App icon redesign
- [x] Rename from "Focus Bell" to "MindBell"
- [x] Sandbox security model with file bookmarks

**What Was Learned:**
- MVVM pattern works well for single-timer app
- Security-scoped bookmarks reliable for custom files
- Single 658-line file is at comfort limit; next phase should split views
- No external dependencies is a strength for macOS distro

---

### Phase 2: iOS Support (PLANNED)

**Timeline:** 2026 Q3–Q4
**Effort:** Medium (code exists, needs extraction)

**Scope:**
- [ ] Extract `TimerViewModel` into shared Swift Package Manager (SPM)
- [ ] Uncomment and adapt `Focus_BellApp_Mobile.swift` for iOS
- [ ] Redesign UI for iPad/iPhone (vertical orientation)
- [ ] Unified iCloud sync of timer settings (NSUbiquitousKeyValueStore)
- [ ] iOS background task for persistent timer (if device locked)
- [ ] App Store submission for both platforms

**Acceptance Criteria:**
- Single ViewModel shared between macOS and iOS
- Unit tests for ViewModel (0% → 80% coverage)
- Both apps sync preferences via iCloud
- iOS timer works even when app backgrounded
- iOS App Store listing live

**Risks:**
- Background task execution complexity (requires special entitlements)
- Unified sync may diverge behavior between platforms
- iOS UI requires significant redesign (horizontal popovers → vertical views)

**Blockers:**
- Must decide on background timer strategy (local notifications vs. Darwin notifications)
- Requires TestFlight beta testing on real devices

---

### Phase 3: App Store Distribution (PLANNED)

**Timeline:** 2026 Q4
**Effort:** Medium (process overhead, not code complexity)

**Scope:**
- [ ] Create privacy policy (no data collection, purely local)
- [ ] Setup Apple Developer account & team
- [ ] Generate signed DMG with Sparkle auto-update framework
- [ ] Notarize app with Apple (security scanning)
- [ ] Submit to Mac App Store (review process, ~48 hours)
- [ ] Submit to iOS App Store (similar review)
- [ ] Create marketing assets (screenshots, descriptions)
- [ ] Setup public website/landing page

**Acceptance Criteria:**
- App published on Mac App Store
- App published on iOS App Store
- Auto-update working via Sparkle
- Privacy policy linked in App Store listing
- ≥ 4.5 star rating from 50+ users (aspirational)

**Marketing Plan:**
- Launch post on Indie Hackers
- Submit to Product Hunt
- Share on r/macapps, r/iosdev
- Reach out to macOS productivity newsletters (MacStories, etc.)
- Cross-promote in focus timer communities

**Risks:**
- App Store review rejection (privacy concern, over-broad permissions)
- Competitor products already established (Forest, Be Focused, etc.)
- Monetization strategy unclear (free? $2.99?)

**Decision Pending:**
- Pricing: Free, freemium, or one-time purchase?
- In-app purchases: Custom sounds store? Themes?

---

### Phase 4: Advanced Features (BACKLOG)

**Timeline:** 2027 (post-App Store launch)
**Effort:** Varies per feature

**High Priority (User-Requested):**
- [ ] Volume control slider for notifications
- [ ] Multiple simultaneous timers (add/remove timer "cards")
- [ ] Statistics dashboard: Total focus hours, sessions completed, streaks
- [ ] Custom notification intervals (e.g., "alert every 2 cycles")
- [ ] Focus goal (e.g., "5 hours today")
- [ ] Daily/weekly summary notifications
- [ ] Export session logs as CSV

**Medium Priority (Nice-to-Have):**
- [ ] Dark/light mode preferences
- [ ] Custom themes (color palettes)
- [ ] Pause/resume (not just stop)
- [ ] Snooze alert (5-minute extension)
- [ ] Focus history calendar view (heatmap)
- [ ] Integration with calendar apps (block time)
- [ ] Dock icon option (users may want it visible)

**Low Priority (Consider Later):**
- [ ] Website with web timer (companion app)
- [ ] Subreddit/Discord community
- [ ] Merchandise (t-shirts with "MindBell" logo)
- [ ] Android version (would need redesign, new codebase)
- [ ] Cloud sync across multiple Macs (iCloud, Dropbox)

**Constraints:**
- Keep core MVVM simple; don't over-engineer
- Maintain zero external dependencies where possible
- Avoid feature creep; stay focused timer

---

## Technical Debt & Refactoring

### Code Organization

**Current Issue:** Main file at 658 LOC; approaching readability limit

**Refactoring (v1.5, 2026 Q2):**
```
Focus Bell/
├── App/
│   ├── TimerApp.swift             (Entry point)
│   └── AppDelegate.swift          (Menu bar, lifecycle)
├── ViewModel/
│   └── TimerViewModel.swift       (Business logic)
├── Views/
│   ├── ContentView.swift          (Router)
│   ├── TimerSetupView.swift       (Config)
│   ├── TimerRunningView.swift     (Countdown)
│   └── SoundSelectionView.swift   (Sound picker)
├── Models/
│   └── TimerEnums.swift           (Enums)
├── Delegates/
│   └── TimerUpdateDelegate.swift  (Protocol)
└── Resources/
    ├── Assets.xcassets
    └── [Sound files]
```

**Effort:** 4 hours (pure refactoring, no feature changes)

---

### Test Coverage

**Current:** 0% (manual testing only)

**Target (Phase 2, with iOS):** 80% unit tests + 60% integration tests

**Test Suite Plan:**

1. **ViewModel Tests** (target: 90% coverage)
   - Timer countdown accuracy
   - Sound loading (preset vs. custom)
   - UserDefaults restore
   - Mode switching (once → repeat)

2. **View Tests** (target: 50% coverage)
   - UI state transitions (Setup → Running)
   - Button actions trigger correct ViewModel methods
   - Progress ring computed correctly

3. **Integration Tests** (target: 60% coverage)
   - Full timer lifecycle (start → alert → stop)
   - Custom sound file handling
   - Popover show/hide behavior

**Tools:**
- XCTest (Apple's native framework)
- Mock AVAudioPlayer for sound tests

**Effort:** 20 hours for comprehensive test suite

---

### Error Handling

**Current Gaps:**
- Sound loading errors logged to console only
- No user-facing error alerts
- Silent fallback if custom file deleted

**Improvement Plan (v1.2):**
- Show user-facing alert if sound fails to load
- Log errors to local file for debugging
- Graceful timeout if file picker hangs

**Effort:** 4 hours

---

### Localization

**Current:** English only

**Phase 3 (with App Store):** Support 5 languages
- English (✓ current)
- Spanish (es)
- French (fr)
- German (de)
- Japanese (ja)

**Implementation:** NSLocalizedString + Strings catalogs

**Effort:** 8 hours

---

### Performance Optimization

**Current:** Already snappy (< 500ms launch)

**Potential Improvements (if needed):**
- Lazy-load sounds only on first use
- Cache compiled SwiftUI views
- Profile memory with Instruments
- Optimize circular progress ring animation

**Priority:** Low (already fast enough)

---

## Community & Feedback

### User Feedback Channels (Post-App Store)

1. **GitHub Discussions** (or website)
   - Feature requests
   - Bug reports
   - General feedback

2. **Social Media**
   - Twitter/X announcements
   - Reddit r/macapps engagement

3. **Email** (contact form on website)
   - Business inquiries
   - Accessibility requests
   - Feature ideas

### Feature Request Process

1. User submits via GitHub/email
2. Triage: Bug vs. Feature vs. Duplicate
3. Add to backlog with estimated effort
4. Announce roadmap update on next release

---

## Revenue & Sustainability

**Current Model:** Free (no revenue)

**Post-App Store Options:**

1. **Freemium ($2.99 base, optional IAP)**
   - Base app: Free or paid
   - Premium features: Custom themes, unlimited timers, stats export
   - Estimated revenue: $50–500/month (indie app scale)

2. **Free + Donations**
   - Free app
   - In-app "Buy me a coffee" button
   - Sustainability depends on user base

3. **Sponsorships**
   - Productivity tool sponsorships
   - Newsletter ads
   - Feature sponsorships (e.g., "Powered by Company X")

**Decision:** TBD post-launch; gather user feedback first

---

## Success Metrics

### User Engagement

| Metric | Target | Measurement |
|--------|--------|-------------|
| Monthly Active Users | 500+ (Year 1) | App Store analytics |
| App Store Rating | 4.5+ stars | Aggregated reviews |
| Retention (30-day) | 40%+ | Cohort analysis |
| Session Duration | > 5 min avg | Analytics |

### Product Quality

| Metric | Target | Measurement |
|--------|--------|-------------|
| Crash Rate | < 0.1% | Crash logs |
| Startup Time | < 500ms | Instruments profiling |
| Memory Footprint | < 50 MB | Activity Monitor |
| Test Coverage | > 80% | Xcode coverage report |

### Business (Post-Monetization)

| Metric | Target (Year 1) | Measurement |
|--------|-----------------|-------------|
| Downloads | 1000+ | App Store |
| Conversion Rate (free→paid) | 2–5% | Analytics |
| Monthly Recurring Revenue | $100–500 | App Store reporting |
| Customer Acquisition Cost | $0 (organic) | Marketing budget |

---

## Known Limitations & Deliberate Decisions

### Intentional Constraints

1. **No Background Timer**
   - Decision: App must stay running
   - Rationale: Simplicity; prevents battery drain from daemon
   - Alternative: Darwin notifications (complex, requires testing)

2. **Single Timer Only**
   - Decision: One active focus session at a time
   - Rationale: MVVM simplicity; pomodoro use case doesn't need multiples
   - Alternative: ViewModel array + multi-row UI (Phase 4)

3. **No Custom Themes**
   - Decision: Use macOS system accent color only
   - Rationale: Reduce scope; theming requires design + i18n
   - Alternative: Phase 4 ("Advanced Features")

4. **No iCloud Sync (v1.1)**
   - Decision: Local UserDefaults only
   - Rationale: Settings are not critical; sync adds complexity
   - Alternative: Phase 2 (with iOS, use NSUbiquitousKeyValueStore)

5. **No Analytics**
   - Decision: Privacy-first; no event tracking
   - Rationale: Indie developers can't afford privacy review costs
   - Alternative: Privacy-preserving telemetry (future, if needed)

### Why These Decisions Matter

MindBell's strength is **simplicity**. Each feature delayed is complexity avoided. As codebase grows, we'll reassess which constraints to relax.

---

## Dependency Management

**Current:** Zero external dependencies

**Future Decisions:**

| Dependency | Use Case | Risk | Verdict |
|------------|----------|------|---------|
| Sparkle | Auto-update | Low (well-maintained) | Yes (Phase 3) |
| Sentry | Crash reporting | Medium (privacy) | Maybe (Phase 2) |
| Analytics SDK | Usage metrics | High (privacy) | No (focus on App Store analytics) |
| SPM | Shared iOS code | Low (first-party) | Yes (Phase 2) |
| SwiftLint | Code style | Low (dev tool) | Yes (Phase 1.5) |

---

## Communication & Release Plan

### Release Cadence

- **v1.1.0** (current): MVP + presets
- **v1.2** (2026-04): Bug fixes, localization
- **v1.3** (2026-06): Refactoring to modular files
- **v2.0** (2026-Q4): iOS launch + App Store
- **v2.1+** (2027+): Advanced features per Phase 4

### Release Notes Template

```
## MindBell v1.X.X

### New
- [Feature] ...

### Fixed
- [Bug] ...

### Improved
- [Performance] ...

### Known Issues
- [Limitation] ...

### Thanks to
- Community testers
- Beta feedback
```

### Version Numbering

- **Major.Minor.Patch** (e.g., 1.1.0)
- Major: New platform or breaking changes
- Minor: New features
- Patch: Bug fixes only

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| App Store rejection | Medium | High | Early privacy/entitlements review with Apple |
| Competitor undercuts price | Medium | Medium | Focus on quality & brand; differentiate on UX |
| iOS background timer too complex | High | Medium | Research alternative (local notifs + daemon) |
| User data loss (corrupt UserDefaults) | Low | High | Add manual backup/export in Phase 4 |
| Security vulnerability in custom file handling | Low | High | Regular security audits; fuzz test bookmark handling |

---

## Conclusion

MindBell is in a strong position for growth:
- ✅ Feature-complete MVP
- ✅ Quality codebase (Swift + SwiftUI best practices)
- ✅ Solid foundation for iOS (code structure allows extraction)
- ✅ Clear roadmap with prioritized features

The focus over the next 12 months is **App Store launch + iOS support**, followed by **user feedback-driven feature prioritization**.

