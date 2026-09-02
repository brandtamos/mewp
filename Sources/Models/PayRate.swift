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
