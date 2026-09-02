import Foundation

/// The copy-paste block for a session — plain text so it drops cleanly into
/// Messages, notes, anywhere, the way a Wordle grid does. No dollar amounts.
enum ShareText {
    static func wordleStyle(for session: BreakSession) -> String {
        let level = ComparisonTable.tierLevel(for: session.duration)
        let bar = String(repeating: "🟧", count: level.filled)
            + String(repeating: "⬛", count: level.total - level.filled)
        let comparison = ComparisonTable.phrase(for: session.duration, seed: session.id.hashValue)

        return """
        MEWP 🧻 \(Format.clock(session.duration))
        \(bar)
        \(comparison)
        """
    }
}
