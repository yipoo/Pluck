import SwiftUI
import AppKit

/// 剪贴板 / 截图历史窗口。
struct HistoryView: View {
    @EnvironmentObject var state: AppState
    @State private var searchText = ""
    @State private var selectedTab: Tab = .clipboard
    @State private var searchResults: [ClipboardItem] = []
    @State private var searchTask: Task<Void, Never>?

    enum Tab: String, CaseIterable, Identifiable {
        case clipboard = "剪贴板"
        case snapshots = "截图"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                TextField("搜索…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)
                    .onChange(of: searchText) { _, newValue in
                        scheduleSearch(newValue)
                    }
            }
            .padding()

            Divider()

            switch selectedTab {
            case .clipboard:
                clipboardList
            case .snapshots:
                snapshotList
            }
        }
        .frame(minWidth: 700, minHeight: 460)
        .onAppear {
            state.refreshHistory()
            searchResults = state.clipboardHistory
        }
    }

    // MARK: - Clipboard

    private var clipboardItems: [ClipboardItem] {
        searchText.isEmpty ? state.clipboardHistory : searchResults
    }

    private var clipboardList: some View {
        Group {
            if clipboardItems.isEmpty {
                empty(text: searchText.isEmpty ? "还没有剪贴板历史" : "未匹配到结果")
            } else {
                List {
                    ForEach(clipboardItems) { item in
                        ClipboardRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                state.copyToClipboard(item)
                            }
                            .contextMenu {
                                Button("复制到剪贴板") { state.copyToClipboard(item) }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func scheduleSearch(_ keyword: String) {
        searchTask?.cancel()
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = state.clipboardHistory
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms 防抖
            if Task.isCancelled { return }
            let results = state.search(trimmed)
            await MainActor.run {
                searchResults = results
            }
        }
    }

    // MARK: - Snapshots

    private var snapshotList: some View {
        Group {
            if state.snapshots.isEmpty {
                empty(text: "还没有截图")
            } else {
                List {
                    ForEach(state.snapshots) { snap in
                        SnapshotRow(snap: snap)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let text = snap.ocrText, !text.isEmpty {
                                    ClipboardMonitor.writeOwn(text: text)
                                }
                            }
                            .contextMenu {
                                if let text = snap.ocrText, !text.isEmpty {
                                    Button("复制 OCR 文字") {
                                        ClipboardMonitor.writeOwn(text: text)
                                    }
                                }
                                Button("在 Finder 显示") {
                                    if let storage = state.storage {
                                        let url = storage.snapshotURL(for: snap.imagePath)
                                        NSWorkspace.shared.activateFileViewerSelecting([url])
                                    }
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func empty(text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(text)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Rows

private struct ClipboardRow: View {
    let item: ClipboardItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .lineLimit(2)
                    .truncationMode(.tail)
                HStack(spacing: 6) {
                    Text(item.kind.rawValue.uppercased())
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                    Text(item.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let app = item.sourceApp {
                        Text("· \(app)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var icon: String {
        switch item.kind {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
}

private struct SnapshotRow: View {
    let snap: Snapshot

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "camera")
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(snap.ocrText ?? "(无 OCR 文本)")
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(snap.ocrText == nil ? .secondary : .primary)
                Text(snap.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
