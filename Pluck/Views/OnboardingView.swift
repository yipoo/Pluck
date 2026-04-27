import SwiftUI
import AppKit

/// 首次启动欢迎页 — 隐私 → 热键 → 权限,3 步引导。
struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    let onComplete: () -> Void

    @State private var step: Int = 0
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
        }
        .frame(width: 560, height: 520)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: Step content (transitions)

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            switch step {
            case 0:
                privacyStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 1:
                hotkeyStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            default:
                permissionStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.30), value: step)
    }

    // MARK: Step 0 — Welcome / Privacy

    private var privacyStep: some View {
        VStack(spacing: 22) {
            Spacer()

            // Brand logo
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .shadow(color: .accentColor.opacity(0.4), radius: 18, y: 6)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 92, height: 92)

            VStack(spacing: 4) {
                Text("欢迎使用 Pluck")
                    .font(.system(size: 24, weight: .bold))
                Text("本地优先的截图 OCR 与剪贴板套件")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                principle(icon: "lock.shield.fill", color: .green,
                          title: "你的数据从不离开 Mac",
                          subtitle: "OCR / 历史 / 截图全部本地处理")
                principle(icon: "wifi.slash", color: .blue,
                          title: "不申请网络权限",
                          subtitle: "在 Activity Monitor 验证零外联")
                principle(icon: "eye.slash.fill", color: .purple,
                          title: "不收集任何用户行为",
                          subtitle: "无埋点 / 无崩溃上报 / 无广告")
            }
            .padding(16)
            .frame(maxWidth: 380)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }

    private func principle(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.opacity(0.15))
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: Step 1 — Hotkeys

    private var hotkeyStep: some View {
        VStack(spacing: 22) {
            Spacer()

            // Hero icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: "command")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 78, height: 78)

            VStack(spacing: 4) {
                Text("两个全局热键")
                    .font(.system(size: 22, weight: .bold))
                Text("无论焦点在哪个 App,按下即可触发")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                hotkeyCard(
                    color: .blue,
                    icon: "selection.pin.in.out",
                    title: "区域截图 OCR",
                    subtitle: "拖动选择 → 文字自动识别 → 进剪贴板",
                    combo: state.settings.captureRegionHotkey.displayString
                )
                hotkeyCard(
                    color: .purple,
                    icon: "clock.arrow.circlepath",
                    title: "打开剪贴板历史",
                    subtitle: "查看与恢复任意一条复制内容",
                    combo: state.settings.toggleHistoryHotkey.displayString
                )
            }
            .frame(maxWidth: 400)

            Text("可在 设置 → 热键 中重置默认。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }

    private func hotkeyCard(color: Color, icon: String, title: String, subtitle: String, combo: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color.opacity(0.15))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            KeyCap(text: combo)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    // MARK: Step 2 — Permission

    private var permissionStep: some View {
        VStack(spacing: 22) {
            Spacer()

            // Hero icon
            let granted = state.screenCapture?.hasPermission() == true
            ZStack {
                Circle()
                    .fill(granted ? Color.green.opacity(0.13) : Color.orange.opacity(0.13))
                Image(systemName: granted ? "checkmark.shield.fill" : "lock.shield")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(granted ? .green : .orange)
            }
            .frame(width: 78, height: 78)

            VStack(spacing: 4) {
                Text("一项必要权限")
                    .font(.system(size: 22, weight: .bold))
                Text("Pluck 需要屏幕录制权限以做截图")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("macOS 14+ 强制要求 App 申请屏幕录制权限。第一次按截图热键时,系统会弹窗请求。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(granted ? .green : .orange)
                    Text(granted ? "已授权 — 立即可用" : "尚未授权")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill((granted ? Color.green : Color.orange).opacity(0.10))
                )
            }
            .padding(16)
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )

            Button {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("打开系统设置 → 屏幕录制", systemImage: "arrow.up.right.square")
            }
            .controlSize(.regular)
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                pageDots

                Spacer()

                if step > 0 {
                    Button("上一步") {
                        withAnimation(.easeInOut(duration: 0.30)) { step -= 1 }
                    }
                    .buttonStyle(.borderless)
                }

                Button {
                    if step == totalSteps - 1 {
                        state.settings.hasCompletedOnboarding = true
                        onComplete()
                    } else {
                        withAnimation(.easeInOut(duration: 0.30)) { step += 1 }
                    }
                } label: {
                    Text(step == totalSteps - 1 ? "开始使用 Pluck" : "下一步")
                        .frame(minWidth: 110)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.30))
                    .frame(width: i == step ? 18 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
    }
}

#Preview {
    OnboardingView { }
        .environmentObject(AppState())
}
