import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 截图标注编辑器(sheet 形式弹出)。
/// 工具栏在顶部 + 图像 + canvas 叠加 + 底部确认/取消。
struct AnnotationEditorView: View {
    let imageURL: URL
    let onClose: () -> Void

    @State private var nsImage: NSImage?
    @State private var annotations: [Annotation] = []
    @State private var redoStack: [[Annotation]] = []

    @State private var tool: Annotation.Kind? = .rect
    @State private var color: String = "#FF3B30"
    @State private var stroke: Annotation.Stroke = .medium

    @State private var exportConfirm = false
    @State private var pendingTextAnnotation: Annotation.ID?
    @State private var pendingTextString: String = ""

    var body: some View {
        VStack(spacing: 0) {
            AnnotationToolbar(
                tool: $tool,
                color: $color,
                stroke: $stroke,
                canUndo: !annotations.isEmpty,
                canRedo: !redoStack.isEmpty,
                onUndo: undo,
                onRedo: redo,
                onClear: clearAll,
                onCancel: onClose,
                onExport: exportPNG
            )

            Divider()

            canvas
                .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
        }
        .frame(minWidth: 800, minHeight: 540)
        .frame(idealWidth: 1100, idealHeight: 700)
        .onAppear {
            nsImage = NSImage(contentsOf: imageURL)
        }
        // 文本输入弹窗(添加 .text 标注后)
        .alert("输入文字", isPresented: Binding(
            get: { pendingTextAnnotation != nil },
            set: { if !$0 { pendingTextAnnotation = nil } }
        )) {
            TextField("文字内容", text: $pendingTextString)
            Button("取消", role: .cancel) {
                if let id = pendingTextAnnotation {
                    annotations.removeAll { $0.id == id }
                }
                pendingTextAnnotation = nil
                pendingTextString = ""
            }
            Button("确定") {
                if let id = pendingTextAnnotation,
                   let idx = annotations.firstIndex(where: { $0.id == id }) {
                    annotations[idx].text = pendingTextString
                }
                pendingTextAnnotation = nil
                pendingTextString = ""
            }
        }
        // 监听新增 .text 标注 → 弹输入框
        .onChange(of: annotations) { old, new in
            // 重置 redo 栈(任何编辑后)
            if old.count != new.count {
                redoStack.removeAll()
            }
            if let last = new.last,
               last.kind == .text,
               last.text == nil,
               !old.contains(where: { $0.id == last.id }) {
                pendingTextString = ""
                pendingTextAnnotation = last.id
            }
        }
    }

    // MARK: - 画布(图 + 标注层)

    @ViewBuilder
    private var canvas: some View {
        if let img = nsImage {
            GeometryReader { geo in
                let imageSize = img.size
                let aspect = imageSize.width / max(imageSize.height, 1)
                let containerAspect = geo.size.width / max(geo.size.height, 1)
                let drawnSize: CGSize = aspect > containerAspect
                    ? CGSize(width: geo.size.width, height: geo.size.width / aspect)
                    : CGSize(width: geo.size.height * aspect, height: geo.size.height)
                let originX = (geo.size.width - drawnSize.width) / 2
                let originY = (geo.size.height - drawnSize.height) / 2

                ZStack(alignment: .topLeading) {
                    // 底图
                    Image(nsImage: img)
                        .resizable()
                        .frame(width: drawnSize.width, height: drawnSize.height)
                        .position(x: originX + drawnSize.width / 2, y: originY + drawnSize.height / 2)

                    // 标注层
                    AnnotationCanvas(
                        annotations: $annotations,
                        tool: tool,
                        color: color,
                        stroke: stroke
                    )
                    .frame(width: drawnSize.width, height: drawnSize.height)
                    .offset(x: originX, y: originY)
                }
            }
            .padding(12)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text("图片无法加载")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 撤销 / 重做

    private func undo() {
        guard let last = annotations.popLast() else { return }
        redoStack.append([last])
    }

    private func redo() {
        guard let restore = redoStack.popLast() else { return }
        annotations.append(contentsOf: restore)
    }

    private func clearAll() {
        if !annotations.isEmpty {
            redoStack.append(annotations)
            annotations.removeAll()
        }
    }

    // MARK: - 导出

    private func exportPNG() {
        guard let img = nsImage,
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let rendered = AnnotationRenderer.render(image: cg, with: annotations) else {
            NSAlert.showError("无法渲染标注图")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Pluck-annotated-\(ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")).png"
        panel.canCreateDirectories = true
        panel.title = "导出标注图"
        panel.begin { response in
            guard response == .OK, let dest = panel.url else { return }
            try? FileManager.default.removeItem(at: dest)
            if AnnotationRenderer.writePNG(rendered, to: dest) {
                NSWorkspace.shared.activateFileViewerSelecting([dest])
            } else {
                NSAlert.showError("写入文件失败:\(dest.path)")
            }
        }
    }
}

private extension NSAlert {
    static func showError(_ message: String) {
        let a = NSAlert()
        a.messageText = "出错"
        a.informativeText = message
        a.alertStyle = .warning
        a.runModal()
    }
}
