import Foundation
import Observation

/// The meter.
///
/// Design note: elapsed time is *always* derived from `Date() - startedAt`,
/// never accumulated tick by tick. iOS suspends timers when the app is
/// backgrounded or the screen locks, which is exactly what happens when
/// someone puts their phone in their pocket. Deriving from wall clock means
/// the count is correct the moment the app comes back, and it survives the
/// app being killed mid-session.
@Observable
final class BreakTimer {
    private static let activeStartKey = "active_session_started_at"

    private(set) var startedAt: Date?
    private(set) var elapsed: TimeInterval = 0

    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let defaults: UserDefaults

    var isRunning: Bool { startedAt != nil }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Recover a session that was interrupted by a crash or a force quit.
        if let saved = defaults.object(forKey: Self.activeStartKey) as? Date {
            startedAt = saved
            elapsed = Date().timeIntervalSince(saved)
            resumeTicking()
        }
    }

    deinit {
        ticker?.invalidate()
    }

    // MARK: - Control

    func start(at date: Date = .now) {
        guard !isRunning else { return }
        startedAt = date
        elapsed = 0
        defaults.set(date, forKey: Self.activeStartKey)
        resumeTicking()
    }

    /// Stops the meter and hands back the interval so the caller can build a
    /// `BreakSession` with the current rate. Returns nil if nothing was running.
    @discardableResult
    func stop(at date: Date = .now) -> DateInterval? {
        guard let start = startedAt else { return nil }
        let interval = DateInterval(start: start, end: max(date, start))
        reset()
        return interval
    }

    /// Throw the session away without recording it.
    func cancel() {
        reset()
    }

    private func reset() {
        pauseTicking()
        startedAt = nil
        elapsed = 0
        defaults.removeObject(forKey: Self.activeStartKey)
    }

    // MARK: - Lifecycle

    /// Call when the scene becomes active. Re-reads the wall clock and
    /// restarts the display ticker.
    func handleForeground() {
        syncElapsed()
        if isRunning { resumeTicking() }
    }

    /// Call when the scene backgrounds. The ticker is only there to redraw the
    /// label, so there's no reason to keep it alive off screen.
    func handleBackground() {
        pauseTicking()
    }

    private func syncElapsed() {
        guard let startedAt else { return }
        elapsed = Date().timeIntervalSince(startedAt)
    }

    // MARK: - Ticking

    private func resumeTicking() {
        pauseTicking()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.syncElapsed()
        }
        // .common keeps it ticking while the user scrolls.
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func pauseTicking() {
        ticker?.invalidate()
        ticker = nil
    }
}
