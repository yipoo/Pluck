import Foundation
import UserNotifications

/// 系统通知封装。所有通知本地展示,无远程推送 token。
/// 注意:`swift run` 模式(无 .app bundle / bundle id)下通知不会展示,但调用不会崩溃。
/// Xcode App Target + 正确 bundle id 后才会真正弹出。
enum NotificationService {

    /// App 启动时请求一次权限(用户拒绝后系统不再询问)。
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { _, _ in
            // 静默处理,不打扰用户
        }
    }

    static func ocrDone(charCount: Int) {
        post(title: "Pluck",
             body: charCount > 0 ? "已识别 \(charCount) 字,已写入剪贴板" : "未识别到文字")
    }

    static func captureCancelled() {
        // 静默 — 用户主动取消,不弹通知
    }

    static func error(_ message: String) {
        post(title: "Pluck", body: "出错:\(message)")
    }

    private static func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req) { _ in }
    }
}
