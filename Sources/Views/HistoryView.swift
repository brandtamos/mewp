import SwiftUI

struct HistoryView: View {
    @Environment(SessionStore.self) private var store
    @Environment(PaySettingsStore.self) private var settings

    @State private var sharingSession: BreakSession?
    @State private var editingSession: BreakSession?

    private var currency: String { settings.rate.currencyCode }

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Ledger")
            .sheet(item: $sharingSession) { session in
                ShareSessionSheet(session: session)
            }
            .sheet(item: $editingSession) { session in
                EditSessionTimesView(
                    title: "Edit trip",
                    startedAt: session.startedAt,
                    endedAt: session.endedAt,
                    hourlyRate: session.effectiveHourlyRate,
                    currencyCode: session.currencyCode,
                    onDiscard: nil,
                    onSave: { start, end in
                        var updated = session
                        updated.startedAt = start
                        updated.endedAt = end
                        store.update(updated)
                    },
                    overlaps: { start, end in
                        store.overlaps(start: start, end: end, excluding: session.id)
                    }
                )
            }
        }
    }

    private var list: some View {
        List {
            Section {
                totals
                    .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
            }

            Section("Poop Sessions") {
                ForEach(store.sessions) { session in
                    row(for: session)
                        .swipeActions(edge: .leading) {
                            Button {
                                sharingSession = session
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(Theme.amber)
                        }
                }
                .onDelete { store.delete(at: $0) }
            }
        }
    }

    private var totals: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Format.money(store.totalEarnings, code: currency))
                .meterDigits(38)
                .foregroundStyle(.primary)

            Text("earned across \(store.sessions.count) \(store.sessions.count == 1 ? "poop" : "poops"), totalling \(Format.spelledDuration(store.totalDuration))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let longest = store.longest, store.sessions.count > 1 {
                Divider().padding(.vertical, 2)
                Text("Your longest ran \(Format.spelledDuration(longest.duration)) and paid \(Format.money(longest.earnings, code: longest.currencyCode)). You average \(Format.spelledDuration(store.averageDuration)).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func row(for session: BreakSession) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Format.spelledDuration(session.duration))
                    .font(.body.weight(.medium))
                Text("\(Format.relativeDay(session.endedAt)) at \(Format.timeOfDay(session.startedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Format.money(session.earnings, code: session.currencyCode))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { editingSession = session }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No poops yet", systemImage: "clock.badge.checkmark")
        } description: {
            Text("Start the meter next time nature calls and it'll show up here.")
        }
    }
}

#Preview {
    let store = SessionStore()
    return HistoryView()
        .environment(store)
        .environment(PaySettingsStore())
}
