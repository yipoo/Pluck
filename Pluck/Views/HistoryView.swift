import SwiftUI
import AppKit

// MARK: - 侧栏过滤器

enum HistoryFilter: Hashable, Identifiable, CaseIterable {
    case all, text, image, file, snapshots
    var id: Self { self }

    var title: String {
        switch self {
        case .all: return "全部"
        case .text: return "文本"
        case .image: return "图片"
        case .file: return "文件"
        case .snapshots: return "截图历史"
        }
    }
    var symbol: String {
        switch self {
        case .all: return "tray.full"
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .file: return "doc"
        case .snapshots: return "camera.viewfinder"
        }
    }
}

// MARK: - 主视图

struct HistoryView: View {
    @EnvironmentObject var state: AppState

    @State private var filter: HistoryFilter? = .all
    @State private var searchText = ""
    @State private var searchResults: [ClipboardItem] = []
    @State private var searchTask: Task<Void, Never>?

    @State private var selectedClipID: ClipboardItem.ID?
    @State private var selectedSnapID: Snapshot.ID?

    @State private var showClearConfirm = false
    @State private var clearTarget: ClearTarget = .clipboard
    enum ClearTarget { case clipboard, snapshots }

    var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            middleColumn
        } detail: {
            detailColumn
        }
        .navigationTitle("Pluck")
        .frame(minWidth: 1000, minHeight: 600)
        .onAppear { state.refreshHistory() }
        .onChange(of: state.clipboardHistory) { _, _ in
            // 数据变化时,如果当前选中已不存在,清空选择
            if let id = selectedClipID,
               !state.clipboardHistory.contains(where: { $0.id == id }) {
                selectedClipID = nil
            }
        }
        .onChange(of: state.snapshots) { _, _ in
            if let id = selectedSnapID,
               !state.snapshots.contains(where: { $0.id == id }) {
                selectedSnapID = nil
            }
        }
        .alert(clearTarget == .clipboard ? "清空所有剪贴板历史?" : "清空所有截图?",
               isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                if clearTarget == .clipboard { state.clearAllClipboard() }
                else { state.clearAllSnapshots() }
            }
        } message: {
            Text("此操作不可撤销。")
        }
    }

    // MARK: - 侧栏

    private var sidebar: some View {
        List(selection: $filter) {
            Section {
                row(.all)
                row(.text)
                row(.image)
                row(.file)
            } header: {
                Text("剪贴板")
                    .textCase(nil)
                    .font(.system(size: 11, weight: .semibold))
            }

            Section {
                row(.snapshots)
            } header: {
                Text("截图")
                    .textCase(nil)
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
    }

    private func row(_ f: HistoryFilter) -> some View {
        Label {
            HStack {
                Text(f.title)
                Spacer()
                Text("\(count(for: f))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        } icon: {
            Image(systemName: f.symbol)
                .foregroundStyle(.secondary)
        }
        .tag(f)
    }

    private func count(for f: HistoryFilter) -> Int {
        switch f {
        case .all: return state.clipboardHistory.count
        case .text: return state.clipboardHistory.filter { $0.kind == .text }.count
        case .image: return state.clipboardHistory.filter { $0.kind == .image }.count
        case .file: return state.clipboardHistory.filter { $0.kind == .file }.count
        case .snapshots: return state.snapshots.count
        }
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11))
                Text("全本地 · 不上云")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 中栏

    @ViewBuilder
    private var middleColumn: some View {
        Group {
            if filter == .snapshots {
                snapshotMiddle
            } else {
                clipboardMiddle
            }
        }
        .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 520)
    }

    private var clipboardItemsForCurrentFilter: [ClipboardItem] {
        let base = searchText.isEmpty ? state.clipboardHistory : searchResults
        switch filter ?? .all {
        case .all: return base
        case .text: return base.filter { $0.kind == .text }
        case .image: return base.filter { $0.kind == .image }
        case .file: return base.filter { $0.kind == .file }
        case .snapshots: return []
        }
    }

    private var clipboardMiddle: some View {
        ZStack {
            List(selection: $selectedClipID) {
                ForEach(clipboardItemsForCurrentFilter) { item in
                    ClipboardCard(item: item, storage: state.storage)
                        .tag(item.id)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .contextMenu {
                            Button {
                                state.copyToClipboard(item)
                            } label: { Label("复制到剪贴板", systemImage: "doc.on.doc") }
                            Divider()
                            Button(role: .destructive) {
                                // 删除剪贴板单条 — 当前 Storage 没暴露,后续可加
                            } label: { Label("删除", systemImage: "trash") }
                                .disabled(true) // 后续版本启用
                        }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .windowBackgroundColor))

            if clipboardItemsForCurrentFilter.isEmpty {
                emptyState(
                    title: searchText.isEmpty ? emptyTitle : "未找到结果",
                    systemImage: searchText.isEmpty ? (filter ?? .all).symbol : "magnifyingglass",
                    description: searchText.isEmpty ? "复制任何内容,会自动出现在这里" : "试试别的关键词"
                )
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: searchPrompt)
        .onChange(of: searchText) { _, newValue in scheduleSearch(newValue) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        clearTarget = .clipboard
                        showClearConfirm = true
                    } label: { Label("清空剪贴板历史", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var emptyTitle: String {
        switch filter ?? .all {
        case .text: return "还没有文本"
        case .image: return "还没有图片"
        case .file: return "还没有文件"
        default: return "还没有剪贴板历史"
        }
    }

    private var searchPrompt: String {
        switch filter ?? .all {
        case .text: return "搜索文本…"
        case .image: return "搜索图片…"
        case .file: return "搜索文件…"
        default: return "搜索剪贴板…"
        }
    }

    private var snapshotMiddle: some View {
        ZStack {
            List(selection: $selectedSnapID) {
                ForEach(state.snapshots) { snap in
                    SnapshotCard(snap: snap, imageURL: state.snapshotURL(snap))
                        .tag(snap.id)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .contextMenu {
                            if let text = snap.ocrText, !text.isEmpty {
                                Button {
                                    ClipboardMonitor.writeOwn(text: text)
                                } label: { Label("复制 OCR 文字", systemImage: "text.alignleft") }
                            }
                            Button {
                                state.copySnapshotImage(snap)
                            } label: { Label("复制图片", systemImage: "photo") }
                            Button {
                                if let url = state.snapshotURL(snap) {
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                }
                            } label: { Label("在 Finder 显示", systemImage: "folder") }
                            Divider()
                            Button(role: .destructive) {
                                state.deleteSnapshot(snap)
                            } label: { Label("删除", systemImage: "trash") }
                        }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .windowBackgroundColor))

            if state.snapshots.isEmpty {
                emptyState(
                    title: "还没有截图",
                    systemImage: "camera",
                    description: "按 ⌃⌥A 拖动选择屏幕区域,即可截图并自动 OCR"
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        clearTarget = .snapshots
                        showClearConfirm = true
                    } label: { Label("清空所有截图", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - 详情列

    @ViewBuilder
    private var detailColumn: some View {
        if filter == .snapshots {
            if let id = selectedSnapID,
               let snap = state.snapshots.first(where: { $0.id == id }) {
                SnapshotDetailView(snap: snap, state: state)
            } else {
                emptyDetail("选择一张截图", "从左侧列表点击查看大图与识别结果")
            }
        } else {
            if let id = selectedClipID,
               let item = state.clipboardHistory.first(where: { $0.id == id }) {
                ClipboardDetailView(item: item, state: state)
            } else {
                emptyDetail("选择一个项目", "从中间列表选择以查看完整内容、来源、时间")
            }
        }
    }

    private func emptyDetail(_ title: String, _ desc: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(desc)
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - 通用空状态(中栏)

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 搜索防抖

    private func scheduleSearch(_ keyword: String) {
        searchTask?.cancel()
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = state.clipboardHistory
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }
            let results = state.search(trimmed)
            await MainActor.run { searchResults = results }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
