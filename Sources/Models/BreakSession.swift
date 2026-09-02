import Foundation

/// One completed trip. The pay rate is snapshotted at save time so that a raise
/// (or a pay cut) never rewrites history.
struct BreakSession: Codable, Identifiable, Equatable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date
    var hourlyRateSnapshot: Decimal
    var currencyCode: String
    var note: String?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        hourlyRateSnapshot: Decimal,
        currencyCode: String,
        note: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.hourlyRateSnapshot = hourlyRateSnapshot
        self.currencyCode = currencyCode
        self.note = note
    }

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    var earnings: Decimal {
        (hourlyRateSnapshot / 3600) * Decimal(duration)
    }
}

extension BreakSession {
    static func sample(minutes: Double, rate: Decimal = 25, daysAgo: Int = 0) -> BreakSession {
        let end = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        return BreakSession(
            startedAt: end.addingTimeInterval(-minutes * 60),
            endedAt: end,
            hourlyRateSnapshot: rate,
            currencyCode: "USD"
        )
    }
}
