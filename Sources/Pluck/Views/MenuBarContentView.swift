import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.viewfinder")
                Text("Pluck")
                    .font(.headline)
                Spacer()
                Text("v0.1.0-dev")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button {
                Task { await state.captureRegion() }
            } label: {
                HStack {
                    Image(systemName: "selection.pin.in.out")
                    Text("区域截图 + OCR")
                    Spacer()
                    Text(state.settings.captureRegionHotkey.displayString)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(state.isCapturing)
            .buttonStyle(.plain)

            Button {
                // TODO W5:打开 HistoryView
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("剪贴板历史")
                    Spacer()
                    Text(state.settings.toggleHistoryHotkey.displayString)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Divider()

            HStack {
                SettingsLink {
                    Label("设置", systemImage: "gearshape")
                }
                .buttonStyle(.plain)

                Spacer()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }

            if let err = state.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}

#Preview {
    MenuBarContentView()
        .environmentObject(AppState())
}
