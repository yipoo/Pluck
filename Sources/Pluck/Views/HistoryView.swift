import SwiftUI

/// 剪贴板 / 截图历史窗口。W5 任务实现完整 UI。
struct HistoryView: View {
    @EnvironmentObject var state: AppState
    @State private var searchText = ""
    @State private var selectedTab: Tab = .clipboard

    enum Tab: String, CaseIterable {
        case clipboard = "剪贴板"
        case snapshots = "截图"
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部:Tab + 搜索
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                TextField("搜索", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            .padding()

            Divider()

            // 列表
            switch selectedTab {
            case .clipboard:
                clipboardList
            case .snapshots:
                snapshotList
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private var clipboardList: some View {
        // TODO W5:接 storage.searchClipboard(searchText)
        List(state.clipboardHistory) { item in
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .lineLimit(2)
                HStack {
                    Text(item.kind.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var snapshotList: some View {
        // TODO W5:展示截图缩略图 grid
        List(state.snapshots) { pluck in
            VStack(alignment: .leading) {
                Text(pluck.ocrText ?? "(无 OCR 文本)")
                    .lineLimit(2)
                Text(pluck.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
