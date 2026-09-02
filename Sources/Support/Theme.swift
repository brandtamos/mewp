import SwiftUI

/// The app is one joke told with a straight face: a piece of metering hardware
/// that happens to be pointed at a toilet. Everything here is borrowed from
/// taxi meters and vacuum-fluorescent displays — warm amber digits on an unlit
/// panel — so the humor comes from how seriously the interface takes the money.
enum Theme {
    /// The unlit display panel. Warm rather than blue-black, like real VFD glass.
    static let panel = Color(red: 0.078, green: 0.071, blue: 0.055)
    static let panelEdge = Color(red: 0.16, green: 0.15, blue: 0.12)

    /// Sodium-lamp amber. The only saturated color in the app.
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.13)
    static let amberDim = Color(red: 1.0, green: 0.69, blue: 0.13).opacity(0.55)
    static let amberFaint = Color(red: 1.0, green: 0.69, blue: 0.13).opacity(0.28)

    static func meterFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

extension View {
    /// Digits that don't jitter as they change width. Non-negotiable on a
    /// counter that redraws ten times a second.
    func meterDigits(_ size: CGFloat) -> some View {
        self
            .font(Theme.meterFont(size))
            .monospacedDigit()
            .kerning(-0.5)
    }
}
