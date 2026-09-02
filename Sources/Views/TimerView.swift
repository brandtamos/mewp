import SwiftUI

struct TimerView: View {
    @Environment(PaySettingsStore.self) private var settings
    @Environment(SessionStore.self) private var sessions
    @Environment(BreakTimer.self) private var timer

    @State private var showingRateSetup = false
    @State private var lampIsLit = false
    @State private var sharingSession: BreakSession?

    private var rate: PayRate { settings.rate }

    private var liveEarnings: Decimal {
        rate.earnings(forSeconds: timer.elapsed)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                meterPanel
                controls
                Spacer(minLength: 0)
                todaySummary
            }
            .padding(20)
            .navigationTitle("MEWP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MEWP")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                }
            }
            .sheet(isPresented: $showingRateSetup) {
                NavigationStack { SettingsView() }
            }
            .sheet(item: $sharingSession) { session in
                ShareSessionSheet(session: session)
            }
        }
    }

    // MARK: - Panel

    private var meterPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("💩")
                    .font(.system(size: 13))
                    .opacity(timer.isRunning ? (lampIsLit ? 1 : 0.25) : 0.35)
                Text(timer.isRunning ? "Poop active" : "Not currently pooping")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.amberDim)
                Spacer()
                Text(Format.clock(timer.elapsed))
                    .meterDigits(15)
                    .foregroundStyle(Theme.amberDim)
            }

            Text(Format.money(liveEarnings, code: rate.currencyCode))
                .meterDigits(64)
                .foregroundStyle(Theme.amber)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 4)

            Text("Earning \(Format.money(rate.effectiveHourlyRate, code: rate.currencyCode)) an hour")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.amberDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.panelEdge, lineWidth: 1)
                )
        )
        // The one piece of ambient motion in the app: the in-service lamp.
        .onChange(of: timer.isRunning, initial: true) { _, running in
            lampIsLit = false
            guard running else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                lampIsLit = true
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: primaryAction) {
                Text(timer.isRunning ? "Done Pooping" : "Start Pooping")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(timer.isRunning ? Color.primary : Theme.amber)
            .sensoryFeedback(timer.isRunning ? .stop : .start, trigger: timer.isRunning)

            if timer.isRunning {
                Button("Discard this poop", role: .destructive) {
                    timer.cancel()
                }
                .font(.subheadline)
            }
        }
    }

    private func primaryAction() {
        guard rate.isConfigured else {
            showingRateSetup = true
            return
        }

        if let interval = timer.stop() {
            let session = BreakSession(
                startedAt: interval.start,
                endedAt: interval.end,
                hourlyRateSnapshot: rate.effectiveHourlyRate,
                currencyCode: rate.currencyCode
            )
            sessions.add(session)
            sharingSession = session
        } else {
            timer.start()
        }
    }

    // MARK: - Footer

    private var todaySummary: some View {
        let today = sessions.sessions(on: .now)
        return Group {
            if today.isEmpty {
                Text("Nothing banked today.")
            } else {
                Text("\(Format.money(sessions.earningsToday, code: rate.currencyCode)) today, across \(today.count) \(today.count == 1 ? "poop" : "poops").")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    TimerView()
        .environment(PaySettingsStore())
        .environment(SessionStore())
        .environment(BreakTimer())
}
