import SwiftUI

@main
struct PluckApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra("Pluck", systemImage: "camera.viewfinder") {
            MenuBarContentView()
                .environmentObject(state)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(state)
        }
    }
}
