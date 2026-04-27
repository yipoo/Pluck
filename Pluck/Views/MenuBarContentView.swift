import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @EnvironmentObject var state: AppState
    @State private var hover: HoverID?

    private enum HoverID: Hashable {
        case capture, history, settings, quit
        case recent(UUID)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            primaryActions
            if !state.clipboardHistory.isEmpty {
                divider
                recentSection
            }
            divider
            footer
        }
        .frame(width: 320)
        .padding(.vertical, 4)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .shadow(color: .accentColor.opacity(0.3), radius: 3, y: 1)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text("Pluck")
                    .font(.system(size: 14, weight: .semibold))
                Text("本地优先 · 截图 OCR")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            statusBadge
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(state.isReady ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .fill(state.isReady ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .blur(radius: 3)
                        .opacity(0.6)
                )
            Text(state.isReady ? "就绪" : "启动中")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(.secondary.opacity(0.10))
        )
    }

    // MARK: Primary actions

    private var primaryActions: some View {
        VStack(spacing: 2) {
            actionRow(
                id: .capture,
                symbol: "selection.pin.in.out",
                tint: .blue,
                title: "区域截图 OCR",
                subtitle: "拖动选择 → 自动识别复制",
                shortcut: state.settings.captureRegionHotkey.displayString,
                disabled: state.isCapturing || !state.isReady
            ) {
                NSApp.activate(ignoringOtherApps: true)
                Task { await state.captureRegion() }
            }

            actionRow(
                id: .history,
                symbol: "clock.arrow.circlepath",
                tint: .purple,
                title: "剪贴板历史",
                subtitle: "查看与恢复任意一条",
                shortcut: state.settings.toggleHistoryHotkey.displayString,
                disabled: !state.isReady
            ) {
                state.openHistory()
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 4)
    }

    private func actionRow(
        id: HoverID,
        symbol: String,
        tint: Color,
        title: String,
        subtitle: String,
        shortcut: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(tint.opacity(hover == id ? 0.20 : 0.13))
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                KeyCap(text: shortcut)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hover == id ? Color.accentColor.opacity(0.10) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
        .onHover { isOver in
            withAnimation(.easeInOut(duration: 0.10)) {
                hover = isOver ? id : nil
            }
        }
    }

    // MARK: Recent section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("最近")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    state.openHistory()
                } label: {
                    HStack(spacing: 2) {
                        Text("全部")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 4)

            VStack(spacing: 1) {
                ForEach(state.clipboardHistory.prefix(3)) { item in
                    recentRow(item)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
    }

    private func recentRow(_ item: ClipboardItem) -> some View {
        Button {
            state.copyToClipboard(item)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: item.kind.symbolName)
                    .foregroundStyle(item.kind.accentColor)
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 16)

                Text(displayContent(of: item))
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)

                Spacer()

                Text(item.createdAt, style: .relative)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(hover == .recent(item.id) ? Color.accentColor.opacity(0.10) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isOver in
            withAnimation(.easeInOut(duration: 0.10)) {
                hover = isOver ? .recent(item.id) : nil
            }
        }
    }

    private func displayContent(of item: ClipboardItem) -> String {
        item.kind == .image && item.content == "[图片]" ? "图片(已存)" : item.content
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 4) {
            SettingsLink {
                footerCell(symbol: "gearshape", text: "设置", id: .settings)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                footerCell(symbol: "power", text: "退出", id: .quit)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private func footerCell(symbol: String, text: String, id: HoverID) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .foregroundStyle(.secondary)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(hover == id ? Color.secondary.opacity(0.18) : .clear)
        )
        .contentShape(Rectangle())
        .onHover { isOver in
            withAnimation(.easeInOut(duration: 0.10)) {
                hover = isOver ? id : nil
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, 10)
    }
}

// MARK: - 通用键帽组件(被设置面板复用)

struct KeyCap: View {
    let text: String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(text), id: \.self) { ch in
                Text(String(ch))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .frame(minWidth: 16, minHeight: 18)
                    .padding(.horizontal, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.30), lineWidth: 0.5)
                    )
                    .foregroundStyle(.secondary)
                    .shadow(color: .black.opacity(0.06), radius: 0.5, y: 0.5)
            }
        }
    }
}

#Preview {
    MenuBarContentView()
        .environmentObject(AppState())
        .padding()
}
