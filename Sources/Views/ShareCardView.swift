import SwiftUI

/// The card people actually share. Deliberately shows only duration and an
/// absurd comparison — never earnings, since that would leak someone's pay rate.
struct ShareCardView: View {
    let session: BreakSession

    private var comparison: String {
        ComparisonTable.phrase(for: session.duration, seed: session.id.hashValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("MEWP")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.amberDim)
                Spacer()
                Text("FARE COMPLETE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.amberFaint)
            }

            Text(Format.clock(session.duration))
                .meterDigits(56)
                .foregroundStyle(Theme.amber)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(comparison)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.amberDim)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Theme.panelEdge)
                .frame(height: 1)

            Text(Format.relativeDay(session.endedAt))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.amberFaint)
        }
        .padding(24)
        .frame(width: 340, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Theme.panelEdge, lineWidth: 1)
                )
        )
    }
}

#Preview {
    ShareCardView(session: .sample(minutes: 22))
        .padding()
        .background(Color(.systemGroupedBackground))
}
