import SwiftUI
import AppKit

// MARK: - 颜色 / 类型映射

extension ClipboardItem.Kind {
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .image: return "图片"
        case .file: return "文件"
        }
    }
    var symbolName: String {
        switch self {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .file: return "doc.fill"
        }
    }
    var accentColor: Color {
        switch self {
        case .text: return Color(nsColor: .systemBlue)
        case .image: return Color(nsColor: .systemGreen)
        case .file: return Color(nsColor: .systemOrange)
        }
    }
}

// MARK: - 剪贴板列表卡片

struct ClipboardCard: View {
    let item: ClipboardItem
    let storage: Storage?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconView
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(displayContent)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    typeBadge
                    Text(item.createdAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if let app = item.sourceApp {
                        Text("·")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 11))
                        Text(app)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var displayContent: String {
        item.kind == .image && item.content == "[图片]"
            ? "图片(已存盘)"
            : item.content
    }

    @ViewBuilder
    private var iconView: some View {
        switch item.kind {
        case .image:
            if let path = item.imagePath,
               let storage,
               let img = ThumbnailCache.shared.thumbnail(for: storage.snapshotURL(for: path), maxDimension: 120) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 0.5)
                    )
            } else {
                glyphBox(item.kind)
            }
        default:
            glyphBox(item.kind)
        }
    }

    private func glyphBox(_ kind: ClipboardItem.Kind) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(kind.accentColor.opacity(0.13))
            Image(systemName: kind.symbolName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(kind.accentColor)
        }
    }

    private var typeBadge: some View {
        Text(item.kind.displayName)
            .font(.system(size: 9, weight: .semibold))
            .tracking(0.4)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(item.kind.accentColor.opacity(0.13))
            )
            .foregroundStyle(item.kind.accentColor)
    }
}

// MARK: - 截图列表卡片

struct SnapshotCard: View {
    let snap: Snapshot
    let imageURL: URL?

    @State private var thumb: NSImage?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            thumbnailView
                .frame(width: 72, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.20), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(snap.ocrText ?? "(未识别到文字)")
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(snap.ocrText == nil ? .secondary : .primary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Text(snap.createdAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if let text = snap.ocrText, !text.isEmpty {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Text("\(text.count) 字")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .task {
            guard let imageURL else { return }
            let loaded = ThumbnailCache.shared.thumbnail(for: imageURL, maxDimension: 200)
            await MainActor.run { thumb = loaded }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumb {
            Image(nsImage: thumb)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color.secondary.opacity(0.10))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                )
        }
    }
}

// MARK: - 右侧详情:剪贴板

struct ClipboardDetailView: View {
    let item: ClipboardItem
    @ObservedObject var state: AppState
    @State private var copyConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            actionBar
        }
    }

    // header
    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(item.kind.accentColor.opacity(0.13))
                Image(systemName: item.kind.symbolName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(item.kind.accentColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.kind.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.4)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(item.kind.accentColor.opacity(0.13))
                        )
                        .foregroundStyle(item.kind.accentColor)
                    if let app = item.sourceApp {
                        Text(app)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Text(item.createdAt, format: .dateTime.year().month().day().hour().minute().second())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // body content
    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .text:
            ScrollView {
                Text(item.content)
                    .textSelection(.enabled)
                    .font(.system(size: 14))
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        case .image:
            imageView
        case .file:
            fileView
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let path = item.imagePath,
           let storage = state.storage,
           let img = NSImage(contentsOf: storage.snapshotURL(for: path)) {
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
            }
        } else {
            ContentUnavailableView("图片无法加载", systemImage: "photo.badge.exclamationmark")
        }
    }

    @ViewBuilder
    private var fileView: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.fill")
                .font(.system(size: 56))
                .foregroundStyle(item.kind.accentColor)
            Text((item.content as NSString).lastPathComponent)
                .font(.system(size: 15, weight: .medium))
            Text(item.content)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                let url = URL(fileURLWithPath: item.content)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } label: { Label("在 Finder 显示", systemImage: "folder") }
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // bottom action bar
    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                state.copyToClipboard(item)
                copyConfirm = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copyConfirm = false }
            } label: {
                Label(copyConfirm ? "已复制" : "复制到剪贴板", systemImage: copyConfirm ? "checkmark.circle.fill" : "doc.on.doc")
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.regular)
            .tint(copyConfirm ? .green : .accentColor)

            Spacer()

            if item.kind == .text {
                Text("\(item.content.count) 字符")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
    }
}

// MARK: - 右侧详情:截图

struct SnapshotDetailView: View {
    let snap: Snapshot
    @ObservedObject var state: AppState
    @State private var image: NSImage?
    @State private var openFullPreview = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HSplitView {
                imagePane
                    .frame(minWidth: 280)
                ocrPane
                    .frame(minWidth: 220)
            }
            Divider()
            actionBar
        }
        .onAppear { load() }
        .onChange(of: snap.id) { _, _ in load() }
        .sheet(isPresented: $openFullPreview) {
            if let url = state.snapshotURL(snap) {
                SnapshotPreviewView(
                    snap: snap,
                    imageURL: url,
                    onDelete: { state.deleteSnapshot(snap) },
                    onClose: { openFullPreview = false }
                )
            }
        }
    }

    private func load() {
        if let url = state.snapshotURL(snap) {
            image = NSImage(contentsOf: url)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.purple.opacity(0.13))
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.purple)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("截图")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.4)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.purple.opacity(0.13))
                        )
                        .foregroundStyle(Color.purple)
                    if let img = image {
                        Text("\(Int(img.size.width)) × \(Int(img.size.height))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if let text = snap.ocrText, !text.isEmpty {
                        Text("· \(text.count) 字")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                Text(snap.createdAt, format: .dateTime.year().month().day().hour().minute().second())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                state.deleteSnapshot(snap)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .controlSize(.small)
            .foregroundStyle(.red.opacity(0.8))
            .help("删除截图")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var imagePane: some View {
        Group {
            if let img = image {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                }
                .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
            } else {
                ProgressView().controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var ocrPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "text.viewfinder")
                    .foregroundStyle(.secondary)
                Text("识别结果")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            if let text = snap.ocrText, !text.isEmpty {
                ScrollView {
                    Text(text)
                        .textSelection(.enabled)
                        .font(.system(size: 13))
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("(此截图未识别到文字)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                if let text = snap.ocrText, !text.isEmpty {
                    ClipboardMonitor.writeOwn(text: text)
                }
            } label: { Label("复制 OCR 文字", systemImage: "text.alignleft") }
            .disabled(snap.ocrText?.isEmpty ?? true)

            Button {
                state.copySnapshotImage(snap)
            } label: { Label("复制图片", systemImage: "photo") }

            Button {
                if let url = state.snapshotURL(snap) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } label: { Label("Finder", systemImage: "folder") }

            Spacer()

            Button {
                openFullPreview = true
            } label: { Label("放大查看…", systemImage: "arrow.up.left.and.arrow.down.right") }
        }
        .controlSize(.regular)
        .padding(16)
    }
}
