import SwiftUI
import ServiceManagement

/// 设置面板(4 Tab)。
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
        .frame(width: 520, height: 380)
        .padding()
    }
}

// MARK: - General

private struct GeneralTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            Toggle("登录时自动启动", isOn: Binding(
                get: { state.settings.launchAtLogin },
                set: { newValue in
                    state.settings.launchAtLogin = newValue
                    applyLaunchAtLogin(newValue)
                }
            ))

            Picker("外观", selection: Binding(
                get: { state.settings.appearance },
                set: { state.settings.appearance = $0 }
            )) {
                Text("跟随系统").tag(SettingsStore.Appearance.system)
                Text("浅色").tag(SettingsStore.Appearance.light)
                Text("深色").tag(SettingsStore.Appearance.dark)
            }
            .pickerStyle(.segmented)

            Stepper("剪贴板历史保留 \(state.settings.historyLimit) 条",
                    value: Binding(
                        get: { state.settings.historyLimit },
                        set: { state.settings.historyLimit = $0 }
                    ),
                    in: 20...1000, step: 20)
        }
        .padding()
    }

    /// SMAppService.mainApp 需要正式 .app bundle;`swift run` 模式下会无声失败。
    private func applyLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // 静默 — 仅在 Xcode App Target 真实运行时才生效
        }
    }
}

// MARK: - Hotkeys

private struct HotkeysTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Form {
            LabeledContent("区域截图 + OCR") {
                HStack {
                    Text(state.settings.captureRegionHotkey.displayString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Button("恢复默认") {
                        state.settings.captureRegionHotkey = .captureRegionDefault
                    }
                }
            }

            LabeledContent("打开剪贴板历史") {
                HStack {
                    Text(state.settings.toggleHistoryHotkey.displayString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Button("恢复默认") {
                        state.settings.toggleHistoryHotkey = .toggleHistoryDefault
                    }
                }
            }

            Divider().padding(.vertical, 8)

            Text("热键自定义录制 UI 将在 v0.2 加入。当前可在代码中改默认值,或保持 ⌃⌥A / ⌃⌥V。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Privacy

private struct PrivacyTab: View {
    @EnvironmentObject var state: AppState
    @State private var showClearAlert = false

    var body: some View {
        Form {
            Toggle("严格离线模式(推荐)", isOn: Binding(
                get: { state.settings.strictOffline },
                set: { state.settings.strictOffline = $0 }
            ))
            Text("开启后,Pluck 不发起任何 outbound 网络请求。当前版本完全本地,默认开启。")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 8)

            HStack {
                Text("清空所有剪贴板历史")
                Spacer()
                Button("清空…", role: .destructive) {
                    showClearAlert = true
                }
            }

            HStack {
                Text("已存储:")
                    .foregroundStyle(.secondary)
                Text("\(state.clipboardHistory.count) 条剪贴板 · \(state.snapshots.count) 张截图")
                    .font(.caption)
                Spacer()
            }
        }
        .padding()
        .alert("清空所有剪贴板历史?", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                state.clearAllClipboard()
            }
        } message: {
            Text("此操作不可撤销。截图文件不会被删除(可在 Finder 手动清理)。")
        }
    }
}

// MARK: - About

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
                .padding(.horizontal)

            Divider().padding(.vertical, 8)

            VStack(spacing: 4) {
                Text("✓ 全本地处理(OCR / 历史 / 截图)")
                Text("✓ 不发起任何网络请求")
                Text("✓ 不收集任何用户数据")
                Text("✓ 开源依赖:零")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
