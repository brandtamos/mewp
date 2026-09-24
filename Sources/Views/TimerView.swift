import SwiftUI

struct TimerView: View {
    @Environment(PaySettingsStore.self) private var settings
    @Environment(SessionStore.self) private var sessions
    @Environment(BreakTimer.self) private var timer

    @State private var showingRateSetup = false
    @State private var showingDiscardConfirmation = false
    @State private var lampIsLit = false
    @State private var sharingSession: BreakSession?
    @State private var pendingInterval: PendingInterval?

    private struct PendingInterval: Identifiable {
        let id = UUID()
        var start: Date
        var end: Date
    }

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
            .sheet(item: $pendingInterval) { pending in
                EditSessionTimesView(
                    title: "Confirm times",
                    startedAt: pending.start,
                    endedAt: pending.end,
                    hourlyRate: rate.effectiveHourlyRate,
                    currencyCode: rate.currencyCode,
                    onDiscard: { pendingInterval = nil },
                    onSave: commit,
                    overlaps: { start, end in
                        sessions.overlaps(start: start, end: end)
                    }
                )
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
                    // .primary tint renders white in dark mode; without an
                    // explicit inverse label color the text disappears.
                    .foregroundStyle(timer.isRunning ? Color(.systemBackground) : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(timer.isRunning ? Color.primary : Theme.amber)
            .sensoryFeedback(timer.isRunning ? .stop : .start, trigger: timer.isRunning)

            if timer.isRunning {
                Button("Discard this poop", role: .destructive) {
                    showingDiscardConfirmation = true
                }
                .font(.subheadline)
                .alert(
                    "Discard this poop?",
                    isPresented: $showingDiscardConfirmation
                ) {
                    Button("Discard", role: .destructive) {
                        timer.cancel()
                    }
                    Button("Keep poopin'", role: .cancel) {}
                } message: {
                    Text("Your time and earnings from this session will be lost.")
                }
            }
        }
    }

    private func primaryAction() {
        guard rate.isConfigured else {
            showingRateSetup = true
            return
        }

        if let interval = timer.stop() {
            // A session this long may have run past when the person actually
            // finished (that's what the "still in there?" nudge is for), so
            // give them a chance to correct the end time before it's saved.
            if interval.duration >= NotificationScheduler.firstReminderDelay {
                pendingInterval = PendingInterval(start: interval.start, end: interval.end)
            } else {
                commit(start: interval.start, end: interval.end)
            }
        } else {
            timer.start()
        }
    }

    private func commit(start: Date, end: Date) {
        let session = BreakSession(
            startedAt: start,
            endedAt: end,
            hourlyRateSnapshot: rate.effectiveHourlyRate,
            currencyCode: rate.currencyCode
        )
        sessions.add(session)
        sharingSession = session
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
