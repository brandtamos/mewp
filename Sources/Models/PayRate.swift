import Foundation

enum RateType: String, Codable, CaseIterable, Identifiable {
    case hourly
    case salary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hourly: return "Hourly"
        case .salary: return "Salary"
        }
    }
}

/// How much a session pays relative to the base hourly rate. Only offered to
/// hourly workers, adjustable live while a session is running. Ordering of the
/// cases is the slider order, so keep them ascending.
enum OvertimeRate: String, Codable, CaseIterable, Identifiable {
    case regular
    case timeAndAHalf
    case doubleTime
    case tripleTime

    var id: String { rawValue }

    var multiplier: Decimal {
        switch self {
        case .regular: return 1
        case .timeAndAHalf: return 1.5
        case .doubleTime: return 2
        case .tripleTime: return 3
        }
    }

    var label: String {
        switch self {
        case .regular: return "Regular pay"
        case .timeAndAHalf: return "Time and a half"
        case .doubleTime: return "Double time"
        case .tripleTime: return "Triple time"
        }
    }

    /// Compact multiplier badge for the slider tick labels.
    var shortLabel: String {
        switch self {
        case .regular: return "1×"
        case .timeAndAHalf: return "1.5×"
        case .doubleTime: return "2×"
        case .tripleTime: return "3×"
        }
    }
}

/// Everything needed to turn elapsed seconds into money.
struct PayRate: Codable, Equatable {
    var type: RateType = .hourly
    var hourlyAmount: Decimal = 25
    var annualSalary: Decimal = 52_000
    var hoursPerWeek: Double = 40
    var weeksPerYear: Double = 52
    var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    /// The hourly figure everything else is derived from, whichever way the
    /// user entered their pay.
    var effectiveHourlyRate: Decimal {
        switch type {
        case .hourly:
            return hourlyAmount
        case .salary:
            let annualHours = hoursPerWeek * weeksPerYear
            guard annualHours > 0 else { return 0 }
            return annualSalary / Decimal(annualHours)
        }
    }

    var ratePerSecond: Decimal {
        effectiveHourlyRate / 3600
    }

    var ratePerMinute: Decimal {
        effectiveHourlyRate / 60
    }

    func earnings(forSeconds seconds: TimeInterval) -> Decimal {
        guard seconds > 0 else { return 0 }
        return ratePerSecond * Decimal(seconds)
    }

    /// A rate of zero means the user hasn't set anything up yet.
    var isConfigured: Bool {
        effectiveHourlyRate > 0
    }
}
