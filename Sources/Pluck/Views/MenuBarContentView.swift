import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                NSApp.activate(ignoringOtherApps: true)
                Task { await state.captureRegion() }
            } label: {
                row(icon: "selection.pin.in.out",
                    label: "区域截图 + OCR",
                    hint: state.settings.captureRegionHotkey.displayString)
            }
            .disabled(state.isCapturing || !state.isReady)
            .buttonStyle(.plain)

            Button {
                state.openHistory()
            } label: {
                row(icon: "clock.arrow.circlepath",
                    label: "剪贴板历史",
                    hint: state.settings.toggleHistoryHotkey.displayString)
            }
            .disabled(!state.isReady)
            .buttonStyle(.plain)

            Divider()

            // 状态行
            statusLine

            Divider()

            HStack {
                SettingsLink {
                    Label("设置", systemImage: "gearshape")
                }
                .buttonStyle(.plain)

                Spacer()

                Button("退出 Pluck") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }

            if let err = state.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 300)
    }

    @ViewBuilder
    private func row(icon: String, label: String, hint: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 18)
            Text(label)
            Spacer()
            Text(hint)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusLine: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.isReady ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(state.isReady ? "服务就绪 · 历史 \(state.clipboardHistory.count) 条" : "正在启动…")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if state.isCapturing {
                ProgressView()
                    .controlSize(.mini)
            }
        }
    }
}

#Preview {
    MenuBarContentView()
        .environmentObject(AppState())
}
