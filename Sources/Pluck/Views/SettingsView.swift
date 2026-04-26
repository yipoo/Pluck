import SwiftUI

/// 设置面板。W6 实现真实绑定。
struct SettingsView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("通用", systemImage: "gearshape") }
                .environmentObject(state)

            HotkeysTab()
                .tabItem { Label("热键", systemImage: "keyboard") }
                .environmentObject(state)

            PrivacyTab()
                .tabItem { Label("隐私", systemImage: "lock.shield") }
                .environmentObject(state)

            AboutTab()
                .tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 480, height: 360)
    }
}

private struct GeneralTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            Toggle("登录时启动", isOn: Binding(
                get: { state.settings.launchAtLogin },
                set: { state.settings.launchAtLogin = $0; state.settings.persist() }
            ))

            Picker("外观", selection: Binding(
                get: { state.settings.appearance },
                set: { state.settings.appearance = $0; state.settings.persist() }
            )) {
                Text("跟随系统").tag(SettingsStore.Appearance.system)
                Text("浅色").tag(SettingsStore.Appearance.light)
                Text("深色").tag(SettingsStore.Appearance.dark)
            }

            Stepper("剪贴板历史保留 \(state.settings.historyLimit) 条",
                    value: Binding(
                        get: { state.settings.historyLimit },
                        set: { state.settings.historyLimit = $0; state.settings.persist() }
                    ),
                    in: 20...1000, step: 20)
        }
        .padding()
    }
}

private struct HotkeysTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            // TODO W6:接入 KeyboardShortcuts 库,提供录制 UI
            LabeledContent("区域截图 + OCR", value: state.settings.captureRegionHotkey.displayString)
            LabeledContent("打开剪贴板历史", value: state.settings.toggleHistoryHotkey.displayString)
            Text("热键自定义将在 W6 实装。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

private struct PrivacyTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            Toggle("严格离线模式(推荐)", isOn: Binding(
                get: { state.settings.strictOffline },
                set: { state.settings.strictOffline = $0; state.settings.persist() }
            ))
            Text("开启后,Pluck 不发起任何 outbound 网络请求。AI 增强功能将不可用。")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 8)

            Button("清空所有剪贴板历史", role: .destructive) {
                // TODO W6:storage.clearAllClipboard()
            }
        }
        .padding()
    }
}

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Pluck")
                .font(.title2.bold())
            Text("v0.1.0-dev")
                .foregroundStyle(.secondary)
            Text("隐私优先的 OCR / 截图 / 剪贴板套件,数据全本地处理。")
                .font(.callout)
                .multilineTextAlignment(.center)
            Link("项目仓库", destination: URL(string: "https://github.com/dinglei/pluck")!)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
