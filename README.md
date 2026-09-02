# LooLoot

A meter for the one break nobody expenses. Save your hourly rate or salary, hit start on the way in, and watch the money accrue.

SwiftUI, iOS 17+, no third-party dependencies.

## Getting it running

**Option A — new Xcode project (no tools needed)**

1. Xcode → File → New → Project → iOS → App
2. Interface: SwiftUI, Language: Swift, product name `LooLoot`
3. Delete the generated `ContentView.swift` and `LooLootApp.swift`
4. Drag the `Sources` folder into the project navigator, with "Copy items if needed" and "Create groups" checked
5. Set the deployment target to iOS 17.0

**Option B — generate the project**

```bash
brew install xcodegen
cd LooLoot
xcodegen generate
open LooLoot.xcodeproj
```

## How it's laid out

```
Sources/
├── LooLootApp.swift          entry point, owns the three stores
├── Models/
│   ├── PayRate.swift         hourly ⇄ salary conversion, per-second rate
│   └── BreakSession.swift    one completed trip
├── Stores/
│   ├── PaySettingsStore.swift  rate persistence (UserDefaults)
│   ├── SessionStore.swift      history persistence (JSON in Documents)
│   └── BreakTimer.swift        the meter
├── Views/
│   ├── RootView.swift        tabs + scene-phase handling
│   ├── TimerView.swift       the meter panel
│   ├── HistoryView.swift     ledger and lifetime stats
│   └── SettingsView.swift    rate entry
└── Support/
    ├── Theme.swift           palette and type
    └── Formatters.swift      currency and duration strings
```

State uses the iOS 17 `@Observable` macro with `.environment(_:)` injection, so views read stores via `@Environment(SessionStore.self)`. Where a view needs to write, it re-binds locally with `@Bindable var settings = settings` — that's the intended pattern and it will look wrong if you're used to `@ObservedObject`.

## Three decisions worth knowing about

**The timer never accumulates ticks.** Elapsed time is always `Date() - startedAt`. iOS suspends timers when the app backgrounds or the screen locks, which is precisely what happens when someone pockets their phone and walks down the hall. A tick-counting timer would undercount every real session. The repeating `Timer` in `BreakTimer` exists only to redraw the label; kill it and the math still works.

**A running session survives being killed.** `startedAt` is written to `UserDefaults` on start and cleared on stop, so a crash or force quit mid-trip recovers on next launch rather than silently losing the session.

**Sessions snapshot the rate.** `BreakSession` stores `hourlyRateSnapshot` rather than pointing at current settings, so a raise doesn't retroactively inflate last year's ledger.

## Design direction

The premise is juvenile, so the interface plays it completely straight — a taxi meter that happens to be pointed at a toilet. Amber monospaced digits on an unlit panel, an "in service" lamp that pulses while running, and no bathroom iconography anywhere. Everything decorative lives in that one panel; the rest of the app is stock iOS.

If you want to rename it, the module name appears in `LooLootApp.swift`, `project.yml`, and nowhere else.

## Things it deliberately doesn't do yet

- **Live Activity / Dynamic Island.** This is the real version of this app. The meter ticking on the lock screen while your phone is face-down is a much better experience than opening the app. `ActivityKit` with a `Text(timerInterval:)` label handles the counting natively, though you'll need a small trick to display money instead of time — precompute a `ClosedRange` of amounts or update the activity every few seconds.
- **Working-hours guard.** Right now the meter runs at 2am on a Sunday. A schedule check would let it either refuse or tag the session as off-the-clock.
- **Widget + Shortcuts.** "Hey Siri, start the meter" is a one-file `AppIntent`.
- **Taxes.** Gross pay is a lie and everyone knows it. A flat effective-rate field would sharpen the joke.
- **Charts.** `Swift Charts` over `SessionStore.sessions` for a weekly view.
- **iCloud sync.** Swap `SessionStore` for SwiftData with CloudKit; the store's interface is small enough that nothing else changes.

## Known rough edges

- Currency is a picker of ten codes rather than a full list, and old sessions keep their original code — the ledger total naively sums across currencies if you switch.
- Decimal `TextField`s accept nonsense like negative pay; add a `.onChange` clamp before shipping.
- No tests. `PayRate.effectiveHourlyRate` and `BreakSession.earnings` are pure functions and are the obvious first two.
