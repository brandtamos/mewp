import SwiftUI

/// Lets the user correct a session's start/end times — either right after
/// stopping a long-running meter (where "when I tapped Done" and "when I
/// actually finished" can be far apart), or later from the ledger.
struct EditSessionTimesView: View {
    let title: String
    let hourlyRate: Decimal
    let currencyCode: String

    /// Non-nil only for the just-stopped flow: discarding there throws the
    /// whole session away, since there's nothing saved yet to fall back to.
    /// Nil when editing an already-saved session, where the toolbar shows a
    /// plain, non-destructive Cancel instead.
    let onDiscard: (() -> Void)?
    let onSave: (Date, Date) -> Void

    /// Returns true if the proposed start/end range collides with another
    /// saved session. Defaults to never overlapping for callers that don't
    /// care (e.g. previews).
    let overlaps: (Date, Date) -> Bool

    @State private var startedAt: Date
    @State private var endedAt: Date

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        startedAt: Date,
        endedAt: Date,
        hourlyRate: Decimal,
        currencyCode: String,
        onDiscard: (() -> Void)?,
        onSave: @escaping (Date, Date) -> Void,
        overlaps: @escaping (Date, Date) -> Bool = { _, _ in false }
    ) {
        self.title = title
        self._startedAt = State(initialValue: startedAt)
        self._endedAt = State(initialValue: endedAt)
        self.hourlyRate = hourlyRate
        self.currencyCode = currencyCode
        self.onDiscard = onDiscard
        self.onSave = onSave
        self.overlaps = overlaps
    }

    private var duration: TimeInterval { max(0, endedAt.timeIntervalSince(startedAt)) }
    private var earnings: Decimal { (hourlyRate / 3600) * Decimal(duration) }
    private var orderIsValid: Bool { endedAt >= startedAt }
    private var conflictsWithOther: Bool { orderIsValid && overlaps(startedAt, endedAt) }
    private var isValid: Bool { orderIsValid && !conflictsWithOther }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Started", selection: $startedAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Ended", selection: $endedAt, displayedComponents: [.date, .hourAndMinute])
                } footer: {
                    if !orderIsValid {
                        Text("End time can't be before the start time.")
                            .foregroundStyle(.red)
                    } else if conflictsWithOther {
                        Text("These times overlap another poop. Pick a slot that doesn't collide.")
                            .foregroundStyle(.red)
                    }
                }

                Section("Recalculated") {
                    LabeledContent("Duration", value: Format.spelledDuration(duration))
                    LabeledContent("Earnings", value: Format.money(earnings, code: currencyCode))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if let onDiscard {
                        Button("Discard", role: .destructive, action: onDiscard)
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(startedAt, endedAt)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .interactiveDismissDisabled(onDiscard != nil)
    }
}

#Preview {
    EditSessionTimesView(
        title: "Confirm times",
        startedAt: .now.addingTimeInterval(-1800),
        endedAt: .now,
        hourlyRate: 25,
        currencyCode: "USD",
        onDiscard: {},
        onSave: { _, _ in }
    )
}
