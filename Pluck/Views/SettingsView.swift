import SwiftUI
import ServiceManagement

/// 设置面板(4 Tab,高质感版)
struct SettingsView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("通用", systemImage: "gearshape") }
                .environmentObject(state)

            HotkeysTab()
                .tabItem { Label("热键", systemImage: "command") }
                .environmentObject(state)

            PrivacyTab()
                .tabItem { Label("隐私", systemImage: "lock.shield") }
                .environmentObject(state)

            AboutTab()
                .tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 580, height: 460)
        .scenePadding()
    }
}

// MARK: - 通用 SettingRow 组件

private struct SettingRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: () -> Content

    init(icon: String,
         iconColor: Color = .accentColor,
         title: String,
         subtitle: String? = nil,
         @ViewBuilder trailing: @escaping () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 通用 Tab(包装统一 padding + 标题 + 描述)

private struct TabContent<Body: View>: View {
    let title: String
    let description: String?
    @ViewBuilder let content: () -> Body

    init(title: String, description: String? = nil, @ViewBuilder content: @escaping () -> Body) {
        self.title = title
        self.description = description
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                if let description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)

            content()
        }
        .padding(20)
    }
}

// MARK: - 通用 Tab

private struct GeneralTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabContent(title: "通用",
                   description: "外观、启动项与历史保留策略") {
            VStack(spacing: 0) {
                Form {
                    SettingRow(icon: "power",
                               iconColor: .green,
                               title: "登录时自动启动",
                               subtitle: "macOS 启动后 Pluck 自动驻留菜单栏") {
                        Toggle("", isOn: Binding(
                            get: { state.settings.launchAtLogin },
                            set: { newValue in
                                state.settings.launchAtLogin = newValue
                                applyLaunchAtLogin(newValue)
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                    }

                    SettingRow(icon: "circle.lefthalf.filled",
                               iconColor: .indigo,
                               title: "外观",
                               subtitle: "Pluck 窗口的明暗主题") {
                        Picker("", selection: Binding(
                            get: { state.settings.appearance },
                            set: { state.settings.appearance = $0 }
                        )) {
                            Text("跟随系统").tag(SettingsStore.Appearance.system)
                            Text("浅色").tag(SettingsStore.Appearance.light)
                            Text("深色").tag(SettingsStore.Appearance.dark)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                        .labelsHidden()
                    }

                    SettingRow(icon: "tray.full",
                               iconColor: .blue,
                               title: "剪贴板历史保留",
                               subtitle: "超出后自动删除最旧条目") {
                        Stepper("\(state.settings.historyLimit) 条",
                                value: Binding(
                                    get: { state.settings.historyLimit },
                                    set: { state.settings.historyLimit = $0 }
                                ),
                                in: 20...1000, step: 20)
                            .frame(width: 130)
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
            }
        }
    }

    private func applyLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // 静默 — Xcode 真实运行时才生效
        }
    }
}

// MARK: - 热键 Tab

private struct HotkeysTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        TabContent(title: "全局热键",
                   description: "无论焦点在哪个 App 都可触发") {
            VStack(spacing: 0) {
                Form {
                    SettingRow(icon: "selection.pin.in.out",
                               iconColor: .blue,
                               title: "区域截图 OCR",
                               subtitle: "拖动选择 → 自动识别 → 写入剪贴板") {
                        HStack(spacing: 8) {
                            KeyCap(text: state.settings.captureRegionHotkey.displayString)
                            Button("重置") {
                                state.settings.captureRegionHotkey = .captureRegionDefault
                            }
                            .controlSize(.small)
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                        }
                    }

                    SettingRow(icon: "clock.arrow.circlepath",
                               iconColor: .purple,
                               title: "打开剪贴板历史",
                               subtitle: "切换历史窗口的显示与隐藏") {
                        HStack(spacing: 8) {
                            KeyCap(text: state.settings.toggleHistoryHotkey.displayString)
                            Button("重置") {
                                state.settings.toggleHistoryHotkey = .toggleHistoryDefault
                            }
                            .controlSize(.small)
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.tertiary)
                    Text("热键自定义录制器将在 v0.2 加入。当前可使用默认快捷键。")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - 隐私 Tab

private struct PrivacyTab: View {
    @EnvironmentObject var state: AppState
    @State private var showClearClipboardAlert = false
    @State private var showClearSnapshotsAlert = false

    var body: some View {
        TabContent(title: "隐私与数据",
                   description: "Pluck 不收集任何数据,所有处理均在本机完成") {
            VStack(spacing: 0) {
                Form {
                    SettingRow(icon: "wifi.slash",
                               iconColor: .green,
                               title: "严格离线模式(推荐)",
                               subtitle: "禁止任何 outbound 网络请求") {
                        Toggle("", isOn: Binding(
                            get: { state.settings.strictOffline },
                            set: { state.settings.strictOffline = $0 }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                    }

                    SettingRow(icon: "doc.on.doc.fill",
                               iconColor: .blue,
                               title: "已存储的剪贴板",
                               subtitle: "\(state.clipboardHistory.count) 条记录") {
                        Button("清空") {
                            showClearClipboardAlert = true
                        }
                        .controlSize(.small)
                        .tint(.red)
                    }

                    SettingRow(icon: "photo.fill.on.rectangle.fill",
                               iconColor: .orange,
                               title: "已存储的截图",
                               subtitle: "\(state.snapshots.count) 张图片(含磁盘 PNG)") {
                        Button("清空") {
                            showClearSnapshotsAlert = true
                        }
                        .controlSize(.small)
                        .tint(.red)
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                    Text("Pluck 不内嵌任何分析 / 崩溃 / 广告 SDK,默认不申请网络权限。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.top, 8)
            }
        }
        .alert("清空所有剪贴板历史?", isPresented: $showClearClipboardAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) { state.clearAllClipboard() }
        } message: { Text("此操作不可撤销。") }
        .alert("清空所有截图?", isPresented: $showClearSnapshotsAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) { state.clearAllSnapshots() }
        } message: { Text("此操作不可撤销 — 数据库记录与磁盘 PNG 文件都会被删除。") }
    }
}

// MARK: - 关于 Tab

private struct AboutTab: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 18) {
            // Brand
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        .shadow(color: .accentColor.opacity(0.35), radius: 12, y: 4)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 84, height: 84)

                VStack(spacing: 3) {
                    Text("Pluck")
                        .font(.system(size: 26, weight: .bold))
                    Text("v0.1.0-dev")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 14)

            Text("本地优先的截图 OCR 与剪贴板套件")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // 价值主张
            VStack(alignment: .leading, spacing: 7) {
                principle(icon: "lock.shield.fill", color: .green, text: "全部数据本地处理,绝不上云")
                principle(icon: "wifi.slash", color: .blue, text: "默认不申请网络权限")
                principle(icon: "eye.slash.fill", color: .purple, text: "不收集 / 追踪任何用户行为")
                principle(icon: "shippingbox", color: .orange, text: "零外部依赖,仅用 Apple 原生框架")
            }
            .padding(14)
            .frame(maxWidth: 380)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.regularMaterial)
            )

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Button {
                    state.settings.hasCompletedOnboarding = false
                    state.showOnboardingAgain()
                } label: {
                    Label("重看欢迎页", systemImage: "sparkles")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(.secondary)
            }

            Text("© 2026 dinglei. All rights reserved.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func principle(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 18)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
