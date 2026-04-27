import SwiftUI

/// 首次启动欢迎页 — 介绍隐私承诺、热键、屏幕录制权限。
struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    let onComplete: () -> Void

    @State private var step: Int = 0
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            // Top header
            VStack(spacing: 6) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Pluck")
                    .font(.title.bold())
                Text("欢迎使用隐私优先的 Mac 截图 OCR 工具")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 28)
            .padding(.bottom, 18)

            Divider()

            // Step content
            ZStack {
                Group {
                    switch step {
                    case 0: privacyStep
                    case 1: hotkeyStep
                    default: permissionStep
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer nav
            HStack {
                pageDots
                Spacer()
                if step > 0 {
                    Button("上一步") { step -= 1 }
                }
                Button(step == totalSteps - 1 ? "完成" : "下一步") {
                    if step == totalSteps - 1 {
                        state.settings.hasCompletedOnboarding = true
                        onComplete()
                    } else {
                        step += 1
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 520, height: 460)
    }

    private var privacyStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("我们不收集任何数据", systemImage: "lock.shield.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                bullet("✓ 所有 OCR 都在你的 Mac 上完成,不上云")
                bullet("✓ 剪贴板历史只存在本地 SQLite 数据库")
                bullet("✓ 截图保存在 ~/Library/Application Support/Pluck/")
                bullet("✓ 我们不内嵌任何分析、崩溃、广告 SDK")
                bullet("✓ App 默认不申请网络访问权限")
            }
            .foregroundStyle(.secondary)
            .font(.callout)

            Spacer()

            Text("你的数据,在你的 Mac 上。")
                .font(.callout.italic())
                .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hotkeyStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("两个全局热键", systemImage: "keyboard")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                hotkeyRow(combo: state.settings.captureRegionHotkey.displayString,
                          label: "区域截图 + OCR",
                          desc: "拖动选择屏幕任意区域,文字自动识别并复制")
                hotkeyRow(combo: state.settings.toggleHistoryHotkey.displayString,
                          label: "打开剪贴板历史",
                          desc: "查看最近复制的文本和截图,点击恢复")
            }

            Spacer()

            Text("可在 设置 → 热键 中重置默认。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("一项必要权限", systemImage: "checkmark.shield")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pluck 需要 **屏幕录制** 权限以做截图。这是 Apple 在 macOS 14+ 强制的要求。")
                Text("第一次按截图热键时,系统会弹窗请求。请允许并重启 Pluck。")
                    .foregroundStyle(.secondary)
            }
            .font(.callout)

            Divider().padding(.vertical, 4)

            HStack {
                Text("当前状态:")
                if state.screenCapture?.hasPermission() == true {
                    Label("已授权", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("未授权(首次截图时弹窗)", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }
            }
            .font(.callout)

            Spacer()

            Button("打开 系统设置 → 屏幕录制") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Circle()
                    .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        Text(text)
    }

    private func hotkeyRow(combo: String, label: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(combo)
                .font(.system(.body, design: .monospaced).bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.secondary.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .frame(width: 70)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.callout.bold())
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    OnboardingView { }
        .environmentObject(AppState())
}
