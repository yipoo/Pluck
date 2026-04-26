import SwiftUI

@main
struct SnapApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra("Snap", systemImage: "camera.viewfinder") {
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
