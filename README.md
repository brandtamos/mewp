# MEWP

A meter for the one break nobody expenses. Save your hourly rate or salary, hit start on the way in, and watch the money accrue.

SwiftUI, iOS 17+, no third-party dependencies.

## Getting it running

The Xcode project is checked in — open `Mewp.xcodeproj`, pick a simulator, and hit ⌘R.

`project.yml` (XcodeGen) is kept in sync with the checked-in project, so `xcodegen generate` is safe to run. One habit to keep: version bumps and any settings changed through Xcode's UI land only in the `.xcodeproj` — mirror them into `project.yml` (especially `CURRENT_PROJECT_VERSION` before a TestFlight upload) or the next generate will roll them back.

## How it's laid out

```
Sources/
├── PrivacyInfo.xcprivacy       privacy manifest
├── App/
│   ├── MewpApp.swift           entry point, owns the three stores
│   └── RootView.swift          tabs + scene-phase handling
├── Models/
│   ├── PayRate.swift           hourly ⇄ salary conversion, per-second rate
│   └── BreakSession.swift      one completed trip
├── Stores/
│   ├── PaySettingsStore.swift  rate persistence (encrypted, UserDefaults)
│   ├── SessionStore.swift      history persistence (encrypted JSON in Documents)
│   └── BreakTimer.swift        the meter
├── Views/
│   ├── TimerView.swift         the meter panel
│   ├── HistoryView.swift       ledger and lifetime stats
│   ├── SettingsView.swift      rate entry
│   ├── EditSessionTimesView.swift  correct start/end times before or after saving
│   └── ShareSessionSheet.swift shareable session card
└── Support/
    ├── Theme.swift             palette and type
    ├── Formatters.swift        currency and duration strings
    ├── DataCipher.swift        AES-GCM with a Keychain-held key
    ├── NotificationScheduler.swift  "still in there?" local notification nudges
    ├── ShareText.swift         Wordle-style copy-paste block (no dollar amounts)
    ├── ComparisonTable.swift   absurd duration comparisons for share text
    └── Media.xcassets          app icon (any/dark/tinted)
```

State uses the iOS 17 `@Observable` macro with `.environment(_:)` injection, so views read stores via `@Environment(SessionStore.self)`. Where a view needs to write, it re-binds locally with `@Bindable var settings = settings` — that's the intended pattern and it will look wrong if you're used to `@ObservedObject`.

## Decisions worth knowing about

**The timer never accumulates ticks.** Elapsed time is always `Date() - startedAt`. iOS suspends timers when the app backgrounds or the screen locks, which is precisely what happens when someone pockets their phone and walks down the hall. A tick-counting timer would undercount every real session. The repeating `Timer` in `BreakTimer` exists only to redraw the label; kill it and the math still works.

**A running session survives being killed.** `startedAt` is written to `UserDefaults` on start and cleared on stop, so a crash or force quit mid-trip recovers on next launch rather than silently losing the session.

**Sessions snapshot the rate.** `BreakSession` stores `hourlyRateSnapshot` rather than pointing at current settings, so a raise doesn't retroactively inflate last year's ledger.

**Everything on disk is encrypted.** `DataCipher` wraps CryptoKit AES-GCM with a 256-bit key held in the Keychain (`kSecAttrAccessibleAfterFirstUnlock`, so it survives encrypted backups). Both stores encrypt on write and transparently migrate plaintext data left by older builds. If the Keychain is ever unavailable, the stores fall back to plaintext rather than lose data. Because the app uses only Apple's standard algorithms, `ITSAppUsesNonExemptEncryption` is set to `NO`.

**Long sessions get nudged, then double-checked.** `NotificationScheduler` fires a local "still in there?" notification at 20 minutes and every 20 minutes after, up to four. Any session that runs past that first threshold gets an `EditSessionTimesView` confirmation on stop, so a forgotten meter doesn't quietly bank an hour.

**Sharing never mentions money.** `ShareText` produces a Wordle-style block — duration, emoji bar, and an absurd comparison from `ComparisonTable` — with no dollar amounts, on the theory that the joke travels better than the salary does.

## Design direction

The premise is juvenile, so the interface plays it completely straight — a taxi meter that happens to be pointed at a toilet. Amber monospaced digits on an unlit panel, a lamp that pulses while running (fine, the lamp is a 💩), and stock iOS everywhere else. Destructive actions confirm first: discarding a running session asks before it throws the money away.

If you want to rename it, the display name lives in the target's build settings (`INFOPLIST_KEY_CFBundleDisplayName`); the module name appears in `MewpApp.swift`, `project.yml`, and nowhere else.

## Things it deliberately doesn't do yet

- **Live Activity / Dynamic Island.** This is the real version of this app. The meter ticking on the lock screen while your phone is face-down is a much better experience than opening the app. `ActivityKit` with a `Text(timerInterval:)` label handles the counting natively, though you'll need a small trick to display money instead of time — precompute a `ClosedRange` of amounts or update the activity every few seconds.
- **Working-hours guard.** Right now the meter runs at 2am on a Sunday. A schedule check would let it either refuse or tag the session as off-the-clock.
- **Widget + Shortcuts.** "Hey Siri, start the meter" is a one-file `AppIntent`.
- **Taxes.** Gross pay is a lie and everyone knows it. A flat effective-rate field would sharpen the joke.
- **Charts.** `Swift Charts` over `SessionStore.sessions` for a weekly view.
- **iCloud sync.** Swap `SessionStore` for SwiftData with CloudKit; the store's interface is small enough that nothing else changes. Mind the encryption layer if you do — synced records need a shared key story.

## Known rough edges

- Currency is a picker of ten codes rather than a full list, and old sessions keep their original code — the ledger total naively sums across currencies if you switch.
- Decimal `TextField`s accept nonsense like negative pay; add a `.onChange` clamp before shipping.
- No tests. `PayRate.effectiveHourlyRate`, `BreakSession.earnings`, and `DataCipher`'s seal/open round-trip are pure enough to be the obvious first three.
