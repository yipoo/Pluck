import SwiftUI

/// 标注工具栏(横向)— 工具选择 + 颜色 + 线宽 + 撤销 / 重做 / 清空
struct AnnotationToolbar: View {
    @Binding var tool: Annotation.Kind?
    @Binding var color: String
    @Binding var stroke: Annotation.Stroke

    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    let onCancel: () -> Void
    let onExport: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            toolButton(.rect, symbol: "rectangle", label: "矩形")
            toolButton(.highlight, symbol: "highlighter", label: "高亮")
            toolButton(.arrow, symbol: "arrow.up.right", label: "箭头")
            toolButton(.text, symbol: "textformat", label: "文本")
            toolButton(.mosaic, symbol: "rectangle.dashed", label: "马赛克 (v0.3)", disabled: true)

            divider

            // 颜色
            HStack(spacing: 4) {
                ForEach(Annotation.palette, id: \.hex) { item in
                    Button {
                        color = item.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: item.hex))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        color == item.hex ? Color.accentColor : Color.secondary.opacity(0.3),
                                        lineWidth: color == item.hex ? 2 : 0.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help(item.name)
                }
            }

            divider

            // 线宽
            Picker("", selection: $stroke) {
                ForEach(Annotation.Stroke.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 110)
            .labelsHidden()

            divider

            // 撤销 / 重做 / 清空
            Button { onUndo() } label: { Image(systemName: "arrow.uturn.backward") }
                .disabled(!canUndo)
                .help("撤销 ⌘Z")
            Button { onRedo() } label: { Image(systemName: "arrow.uturn.forward") }
                .disabled(!canRedo)
                .help("重做 ⇧⌘Z")
            Button { onClear() } label: { Image(systemName: "trash") }
                .help("清空所有标注")

            Spacer()

            Button("取消", role: .cancel) { onCancel() }
                .controlSize(.regular)

            Button {
                onExport()
            } label: {
                Label("导出标注图", systemImage: "square.and.arrow.up.fill")
            }
            .controlSize(.regular)
            .buttonStyle(.borderedProminent)
        }
        .controlSize(.small)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.20))
            .frame(width: 1, height: 18)
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func toolButton(_ kind: Annotation.Kind,
                            symbol: String,
                            label: String,
                            disabled: Bool = false) -> some View {
        Button {
            tool = (tool == kind) ? nil : kind
        } label: {
            Image(systemName: symbol)
                .frame(width: 26, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tool == kind ? Color.accentColor.opacity(0.2) : .clear)
                )
                .foregroundStyle(tool == kind ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
        .help(label)
    }
}
