import SwiftUI

@main
struct MewpApp: App {
    @State private var settings = PaySettingsStore()
    @State private var sessions = SessionStore()
    @State private var timer = BreakTimer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(sessions)
                .environment(timer)
        }
    }
}
