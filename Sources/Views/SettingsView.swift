import SwiftUI

struct SettingsView: View {
    @Environment(PaySettingsStore.self) private var settings
    @Environment(SessionStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @FocusState private var amountIsFocused: Bool
    @State private var confirmingClear = false

    var body: some View {
        @Bindable var settings = settings
        let rate = settings.rate
        let weeksError = weeksValidationMessage(for: rate)

        Form {
            Section {
                Picker("How you're paid", selection: $settings.rate.type) {
                    ForEach(RateType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                switch rate.type {
                case .hourly:
                    LabeledContent("Hourly rate") {
                        TextField("25.00", value: nonNegative($settings.rate.hourlyAmount), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($amountIsFocused)
                    }

                case .salary:
                    LabeledContent("Annual salary") {
                        TextField("52000", value: nonNegative($settings.rate.annualSalary), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($amountIsFocused)
                    }
                    LabeledContent("Hours a week") {
                        TextField("40", value: nonNegative($settings.rate.hoursPerWeek), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($amountIsFocused)
                    }
                    LabeledContent("Weeks a year") {
                        TextField("52", value: $settings.rate.weeksPerYear, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(weeksError != nil ? Color.red : Color.primary)
                            .focused($amountIsFocused)
                    }
                }
            } footer: {
                if let weeksError {
                    Label(weeksError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.footnote.weight(.medium))
                } else if rate.type == .salary {
                    Text("Unpaid time off lowers your weeks a year, which raises what each hour is worth.")
                }
            }

            Section("What the meter will count") {
                LabeledContent("Per hour", value: Format.money(rate.effectiveHourlyRate, code: rate.currencyCode))
                LabeledContent("Per minute", value: Format.money(rate.ratePerMinute, code: rate.currencyCode, fractionDigits: 3))
                LabeledContent("Per second", value: Format.money(rate.ratePerSecond, code: rate.currencyCode, fractionDigits: 4))
            }

            Section {
                Picker("Currency", selection: $settings.rate.currencyCode) {
                    ForEach(Self.commonCurrencies, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
            }

            Section {
                Button("Delete all history", role: .destructive) {
                    confirmingClear = true
                }
                .disabled(store.sessions.isEmpty)
            } footer: {
                Text("Saved trips keep the rate they were recorded at, so changing your pay here won't rewrite them.")
            }
        }
        .navigationTitle("Your pay")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    amountIsFocused = false
                    settings.markConfigured()
                    dismiss()
                }
                .disabled(weeksError != nil)
            }
        }
        .confirmationDialog(
            "Delete every saved trip?",
            isPresented: $confirmingClear,
            titleVisibility: .visible
        ) {
            Button("Delete all history", role: .destructive) { store.removeAll() }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    /// Wraps a numeric binding so negative entries are floored at zero on
    /// commit — pay and hours can't be negative. Works for `Decimal` and
    /// `Double` alike.
    private func nonNegative<V: Comparable & AdditiveArithmetic>(_ binding: Binding<V>) -> Binding<V> {
        Binding(
            get: { binding.wrappedValue },
            set: { binding.wrappedValue = max($0, .zero) }
        )
    }

    /// Weeks a year only matters for salaried pay, where it must fall in
    /// 1...52. Returns a message describing the problem, or nil when valid.
    private func weeksValidationMessage(for rate: PayRate) -> String? {
        guard rate.type == .salary else { return nil }
        if rate.weeksPerYear > 52 {
            return "A year only has 52 weeks. Enter 52 or fewer."
        }
        if rate.weeksPerYear < 1 {
            return "Enter at least 1 week a year."
        }
        return nil
    }

    private static let commonCurrencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "INR", "SEK", "CHF", "BRL"]
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(PaySettingsStore())
        .environment(SessionStore())
}
