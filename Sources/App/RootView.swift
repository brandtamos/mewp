import SwiftUI

struct RootView: View {
    @Environment(BreakTimer.self) private var timer
    @Environment(PaySettingsStore.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var needsSetup = false

    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Meter", systemImage: "gauge.with.needle") }

            HistoryView()
                .tabItem { Label("Ledger", systemImage: "list.bullet.rectangle") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Pay", systemImage: "dollarsign.circle") }
        }
        // The meter is derived from wall clock, but the on-screen label still
        // needs a nudge every time we come back from the background.
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: timer.handleForeground()
            case .background, .inactive: timer.handleBackground()
            @unknown default: break
            }
        }
        .task {
            needsSetup = !settings.hasSetRate
        }
        .sheet(isPresented: $needsSetup) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Set your pay")
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    RootView()
        .environment(PaySettingsStore())
        .environment(SessionStore())
        .environment(BreakTimer())
}
