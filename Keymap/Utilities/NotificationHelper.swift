//
//  NotificationHelper.swift
//  Keymap
//
//  Created on 2025-12-21.
//

import Foundation
import UserNotifications

/// 通知助手 - 统一管理应用通知
class NotificationHelper {

    static let shared = NotificationHelper()

    private init() {
        requestAuthorization()
    }

    /// 请求通知权限
    private func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("⚠️ 通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }

    /// 发送本地通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知内容
    ///   - identifier: 通知标识符（可选）
    func send(title: String, message: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // nil 表示立即发送
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 通知发送失败: \(error.localizedDescription)")
            }
        }
    }
}
