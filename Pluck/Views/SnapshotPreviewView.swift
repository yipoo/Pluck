import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 截图详情:大图 + 完整 OCR 文字 + 操作栏。
struct SnapshotPreviewView: View {
    let snap: Snapshot
    let imageURL: URL
    let onDelete: () -> Void
    let onClose: () -> Void

    @State private var nsImage: NSImage?
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // ===== 顶部:操作工具栏 =====
            HStack(spacing: 8) {
                Text(snap.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                if let img = nsImage {
                    Text("· \(Int(img.size.width)) × \(Int(img.size.height))")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                }
                Spacer()

                Button {
                    if let text = snap.ocrText, !text.isEmpty {
                        ClipboardMonitor.writeOwn(text: text)
                    }
                } label: {
                    Label("复制文字", systemImage: "text.alignleft")
                }
                .disabled(snap.ocrText?.isEmpty ?? true)

                Button {
                    copyImage()
                } label: {
                    Label("复制图片", systemImage: "photo")
                }
                .disabled(nsImage == nil)

                Button {
                    exportPNG()
                } label: {
                    Label("导出…", systemImage: "square.and.arrow.up")
                }

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([imageURL])
                } label: {
                    Label("Finder", systemImage: "folder")
                }

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("删除", systemImage: "trash")
                }

                Button("关闭") { onClose() }
                    .keyboardShortcut(.cancelAction)
            }
            .labelStyle(.titleAndIcon)
            .controlSize(.small)
            .padding(10)

            Divider()

            // ===== 中部:图像 + OCR 文字 二栏分割 =====
            HSplitView {
                imagePane
                    .frame(minWidth: 320)
                ocrPane
                    .frame(minWidth: 240)
            }
        }
        .frame(minWidth: 760, minHeight: 460)
        .frame(idealWidth: 960, idealHeight: 600)
        .onAppear {
            nsImage = NSImage(contentsOf: imageURL)
        }
        .alert("删除这张截图?", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete()
                onClose()
            }
        } message: {
            Text("将同时删除磁盘文件,不可撤销。")
        }
    }

    // MARK: - Panes

    @ViewBuilder
    private var imagePane: some View {
        Group {
            if let img = nsImage {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(8)
                }
                .background(checkerboard)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("图片无法加载")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var ocrPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("OCR 识别结果")
                    .font(.subheadline.bold())
                Spacer()
                if let text = snap.ocrText, !text.isEmpty {
                    Text("\(text.count) 字")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            if let text = snap.ocrText, !text.isEmpty {
                ScrollView {
                    Text(text)
                        .textSelection(.enabled)
                        .font(.system(.body))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("(此截图未识别到文字)")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Background helpers

    /// 透明区域用棋盘格表示,方便看 PNG 透明度
    private var checkerboard: some View {
        Canvas { context, size in
            let tile: CGFloat = 12
            let cols = Int(ceil(size.width / tile))
            let rows = Int(ceil(size.height / tile))
            for r in 0..<rows {
                for c in 0..<cols {
                    if (r + c).isMultiple(of: 2) {
                        let rect = CGRect(x: CGFloat(c) * tile, y: CGFloat(r) * tile, width: tile, height: tile)
                        context.fill(Path(rect), with: .color(.gray.opacity(0.10)))
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func copyImage() {
        guard let img = nsImage else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.declareTypes([.tiff, ClipboardMonitor.ownWriteMarker], owner: nil)
        pb.writeObjects([img])
        pb.setString("", forType: ClipboardMonitor.ownWriteMarker)
    }

    private func exportPNG() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        let stamp = ISO8601DateFormatter().string(from: snap.createdAt)
            .replacingOccurrences(of: ":", with: "-")
        panel.nameFieldStringValue = "Pluck-\(stamp).png"
        panel.canCreateDirectories = true
        panel.title = "导出截图"

        panel.begin { response in
            guard response == .OK, let dest = panel.url else { return }
            try? FileManager.default.removeItem(at: dest) // 覆盖旧
            try? FileManager.default.copyItem(at: imageURL, to: dest)
        }
    }
}
