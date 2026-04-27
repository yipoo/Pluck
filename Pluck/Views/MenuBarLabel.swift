import SwiftUI

/// 状态感知的菜单栏图标。
/// - 截图中:fill 变体 + 脉冲动画(SF Symbol effect)
/// - 启动中:opacity 调暗 + 旋转 spinner
/// - 就绪:常规 viewfinder
struct MenuBarLabel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Group {
            if !state.isReady {
                Image(systemName: "viewfinder")
                    .opacity(0.5)
            } else if state.isCapturing {
                Image(systemName: "viewfinder.circle.fill")
                    .symbolEffect(.pulse, options: .repeating, isActive: true)
            } else {
                Image(systemName: "camera.viewfinder")
            }
        }
        .accessibilityLabel("Pluck")
    }
}
