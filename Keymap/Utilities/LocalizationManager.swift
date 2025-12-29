//
//  LocalizationManager.swift
//  Keymap
//
//  Created on 2025-12-25.
//

import Foundation
import Combine

/// 本地化管理器
/// 负责动态语言切换、本地化字符串加载和应用内语言管理
class LocalizationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = LocalizationManager()

    // MARK: - Published Properties

    /// 当前语言代码（如 "en", "zh-Hans"）
    @Published var currentLanguage: String {
        didSet {
            _bundle = nil  // 清除缓存的 Bundle
            notifyLanguageChanged()
            saveLanguagePreference()
            Logger.info("🌍 语言已切换到: \(currentLanguage)")
        }
    }

    // MARK: - Private Properties

    /// 缓存的语言 Bundle
    private var _bundle: Bundle?

    /// 支持的语言列表
    static let supportedLanguages = [
        "system", "en", "zh-Hans", "zh-Hant",
        "ja", "ko", "de", "fr", "es", "it", "ru"
    ]

    // MARK: - Initialization

    private init() {
        // 从设置中读取保存的语言，如果没有则使用系统语言
        let savedLanguage = SettingsManager.shared.selectedLanguage

        if savedLanguage == "system" {
            // 获取系统语言
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = Self.supportedLanguages.contains(systemLanguage) ? systemLanguage : "en"
        } else {
            currentLanguage = savedLanguage
        }

        Logger.info("🌍 LocalizationManager 初始化，当前语言: \(currentLanguage)")
    }

    // MARK: - Public Methods

    /// 获取本地化字符串
    /// - Parameter key: 本地化键名
    /// - Returns: 本地化后的字符串
    func localizedString(key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// 获取带参数的本地化字符串
    /// - Parameters:
    ///   - key: 本地化键名
    ///   - arguments: 格式化参数
    /// - Returns: 格式化后的本地化字符串
    func localizedString(key: String, arguments: [CVarArg]) -> String {
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, arguments: arguments)
    }

    // MARK: - Private Methods

    /// 动态加载语言 Bundle
    private var bundle: Bundle {
        if let cachedBundle = _bundle {
            return cachedBundle
        }

        // 查找对应语言的 .lproj 目录
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            Logger.warning("⚠️ 无法加载语言包: \(currentLanguage)，使用主 Bundle")
            return Bundle.main
        }

        _bundle = bundle
        return bundle
    }

    /// 发送语言变更通知
    private func notifyLanguageChanged() {
        NotificationCenter.default.post(
            name: .languageChanged,
            object: nil,
            userInfo: ["language": currentLanguage]
        )
    }

    /// 保存语言偏好到设置
    private func saveLanguagePreference() {
        SettingsManager.shared.selectedLanguage = currentLanguage
    }
}

// MARK: - String Extensions

extension String {

    /// 获取本地化字符串
    /// - Returns: 本地化后的字符串
    func localized() -> String {
        return LocalizationManager.shared.localizedString(key: self)
    }

    /// 获取带参数的本地化字符串
    /// - Parameter arguments: 格式化参数（可变参数）
    /// - Returns: 格式化后的本地化字符串
    ///
    /// 使用示例：
    /// ```swift
    /// "settings.rules_count".localized(with: 5)
    /// // 英语: "5 rules total"
    /// // 中文: "共 5 条规则"
    /// ```
    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.localizedString(key: self)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {

    /// 语言变更通知
    /// 当用户切换应用语言时发送此通知
    static let languageChanged = Notification.Name("com.keymap.languageChanged")
}
