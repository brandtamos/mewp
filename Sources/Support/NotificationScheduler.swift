import Foundation
import UserNotifications

/// Nudges the user if a session runs long enough that they might have
/// forgotten about it — phone pocketed, walked off. Scheduled as local
/// notifications so they fire even if MEWP isn't running, and cancelled the
/// moment the session stops (see `BreakTimer.reset()`).
enum NotificationScheduler {
    /// How long a session runs before the first nudge. `TimerView` reuses
    /// this to decide whether a just-stopped session is long enough that its
    /// recorded end time is worth double-checking before saving.
    static let firstReminderDelay: TimeInterval = 20 * 60
    static let repeatInterval: TimeInterval = 20 * 60
    static let maxReminders = 4

    private static let identifierPrefix = "still-running-"

    /// Call when a session starts, and again when one is recovered after a
    /// crash or relaunch. Idempotent — cancels anything already pending
    /// before scheduling, so recovering the same session twice never doubles
    /// up the reminders.
    static func scheduleReminders(from startedAt: Date) {
        cancelReminders()

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                schedule(from: startedAt, center: center)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    guard granted else { return }
                    schedule(from: startedAt, center: center)
                }
            default:
                break
            }
        }
    }

    static func cancelReminders() {
        let ids = (0..<maxReminders).map { "\(identifierPrefix)\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func schedule(from startedAt: Date, center: UNUserNotificationCenter) {
        let now = Date()
        for index in 0..<maxReminders {
            let fireAt = startedAt.addingTimeInterval(firstReminderDelay + Double(index) * repeatInterval)
            let delay = fireAt.timeIntervalSince(now)
            guard delay > 0 else { continue }

            let elapsedAtFire = fireAt.timeIntervalSince(startedAt)
            let content = UNMutableNotificationContent()
            content.title = "Still in there?"
            content.body = "\(Format.clock(elapsedAtFire)) and counting — "
                + "\(ComparisonTable.phrase(for: elapsedAtFire, seed: startedAt.hashValue))."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(index)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            )
            center.add(request)
        }
    }
}
