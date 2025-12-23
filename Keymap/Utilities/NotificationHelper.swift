//
//  NotificationHelper.swift
//  Keymap
//
//  Created on 2025-12-21.
//

import Foundation
import UserNotifications

/// 通知助手 - 统一管理应用通知
class NotificationHelper: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationHelper()
    
    // 保存点击回调
    private var clickHandlers: [String: () -> Void] = [:]

    private override init() {
        super.init()
        requestAuthorization()
        UNUserNotificationCenter.current().delegate = self
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
    
    /// 发送带操作按钮的通知（点击通知时执行回调）
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知内容
    ///   - actionTitle: 操作按钮标题
    ///   - userInfo: 额外信息
    ///   - onClick: 点击通知的回调
    func sendWithAction(
        title: String,
        message: String,
        actionTitle: String = "查看",
        userInfo: [String: Any] = [:],
        onClick: @escaping () -> Void
    ) {
        let identifier = UUID().uuidString
        
        // 保存回调
        clickHandlers[identifier] = onClick
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.userInfo = userInfo
        content.userInfo["clickIdentifier"] = identifier
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 通知发送失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// 用户点击通知时调用
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        
        // 执行保存的回调
        if let handler = clickHandlers[identifier] {
            handler()
            clickHandlers.removeValue(forKey: identifier)
        }
        
        completionHandler()
    }
    
    /// 应用在前台时收到通知的处理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 即使应用在前台也显示通知
        completionHandler([.banner, .sound])
    }
}
