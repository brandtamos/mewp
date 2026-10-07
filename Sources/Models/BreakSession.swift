import Foundation

/// One completed trip. The pay rate is snapshotted at save time so that a raise
/// (or a pay cut) never rewrites history.
struct BreakSession: Codable, Identifiable, Equatable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date
    var hourlyRateSnapshot: Decimal
    var currencyCode: String
    /// Overtime applied to this session. Optional so sessions saved before the
    /// feature existed still decode — a missing key would otherwise fail the
    /// whole history load. A nil value is treated as `.regular`.
    var overtime: OvertimeRate?
    var note: String?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        hourlyRateSnapshot: Decimal,
        currencyCode: String,
        overtime: OvertimeRate? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.hourlyRateSnapshot = hourlyRateSnapshot
        self.currencyCode = currencyCode
        self.overtime = overtime
        self.note = note
    }

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    /// Base rate with any overtime multiplier folded in.
    var effectiveHourlyRate: Decimal {
        hourlyRateSnapshot * (overtime?.multiplier ?? 1)
    }

    var earnings: Decimal {
        (effectiveHourlyRate / 3600) * Decimal(duration)
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
