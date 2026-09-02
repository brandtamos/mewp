import Foundation

enum Format {
    static func money(_ value: Decimal, code: String, fractionDigits: Int = 2) -> String {
        value.formatted(
            .currency(code: code)
            .precision(.fractionLength(fractionDigits))
        )
    }

    /// 4:07, or 1:04:07 once it crosses an hour. No leading zero on the first
    /// unit, the way a stopwatch reads.
    static func clock(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// "4 min 7 sec" — for lists, where a running clock would be misleading.
    static func spelledDuration(_ interval: TimeInterval) -> String {
        let style = Duration.UnitsFormatStyle(
            allowedUnits: interval >= 3600 ? [.hours, .minutes] : [.minutes, .seconds],
            width: .abbreviated
        )
        return Duration.seconds(Int(interval)).formatted(style)
    }

    static func relativeDay(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    static func timeOfDay(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
