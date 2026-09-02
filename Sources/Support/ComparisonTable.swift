import Foundation

/// Absurd real-world comparisons for a session's duration, deliberately never
/// referencing money — earnings stay out of anything meant to be shared.
enum ComparisonTable {
    private struct Tier {
        let ceiling: TimeInterval
        let phrases: [String]
    }

    private static let tiers: [Tier] = [
        Tier(ceiling: 60, phrases: [
            "shorter than the trailer before the trailer",
            "about one TikTok, maybe two if they're bad",
            "roughly one ring of an unanswered phone call",
            "shorter than it takes the elevator to arrive",
        ]),
        Tier(ceiling: 180, phrases: [
            "about as long as a single pod of coffee brews",
            "roughly one verse-chorus-verse on the radio",
            "long enough to lose a staring contest with a toddler",
            "about as long as the microwave takes for leftovers",
        ]),
        Tier(ceiling: 300, phrases: [
            "long enough to microwave a burrito, twice",
            "about one NBA timeout, commercials included",
            "roughly a full load in the dishwasher's rinse cycle",
            "long enough for the group chat to ask where you went",
        ]),
        Tier(ceiling: 600, phrases: [
            "long enough to watch two TikToks and regret both",
            "about the length of a fire drill, minus the alarm",
            "roughly one Duolingo streak's worth of guilt",
            "long enough that someone refilled their coffee twice",
        ]),
        Tier(ceiling: 900, phrases: [
            "long enough to eat a full meal, unbothered",
            "about one sitcom episode, minus the ads",
            "long enough for a coworker to check if you're okay",
            "roughly the length of a mandatory workplace training video",
        ]),
        Tier(ceiling: 1800, phrases: [
            "long enough to assemble a bookshelf, poorly",
            "about one undisturbed episode of a true crime podcast",
            "long enough that someone knocked, then gave up",
            "roughly the length of a mediocre stand-up special",
        ]),
        Tier(ceiling: .infinity, phrases: [
            "long enough to have watched the extended cut of something",
            "you could've filed your taxes in this time",
            "long enough that IT probably has a ticket open",
            "roughly the length of a flight delay announcement",
        ]),
    ]

    /// A phrase for the given duration. `seed` picks deterministically within
    /// the tier (e.g. a session's id) so the same session always renders the
    /// same line instead of reshuffling on every share.
    static func phrase(for duration: TimeInterval, seed: Int) -> String {
        let tier = tiers.first { duration <= $0.ceiling } ?? tiers[tiers.count - 1]
        let index = abs(seed) % tier.phrases.count
        return tier.phrases[index]
    }

    /// How far up the absurdity scale this duration lands, as (filled, total)
    /// — the Wordle-grid-style bar in the share text is built from this.
    static func tierLevel(for duration: TimeInterval) -> (filled: Int, total: Int) {
        let index = tiers.firstIndex { duration <= $0.ceiling } ?? tiers.count - 1
        return (index + 1, tiers.count)
    }
}
