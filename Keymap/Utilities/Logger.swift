//
//  Logger.swift
//  Keymap
//
//  Created on 2025-12-22.
//

import Foundation

/// 日志系统
class Logger {
    
    // MARK: - Singleton
    
    static let shared = Logger()
    
    // MARK: - Log Levels
    
    enum Level: Int {
        case off = 0      // 关闭
        case error = 1    // 错误
        case warning = 2  // 警告
        case info = 3     // 信息
        case debug = 4    // 调试
        
        var icon: String {
            switch self {
            case .off: return ""
            case .error: return "❌"
            case .warning: return "⚠️"
            case .info: return "ℹ️"
            case .debug: return "🔍"
            }
        }
        
        var prefix: String {
            switch self {
            case .off: return ""
            case .error: return "ERROR"
            case .warning: return "WARN"
            case .info: return "INFO"
            case .debug: return "DEBUG"
            }
        }
    }
    
    // MARK: - Properties
    
    private let settings = SettingsManager.shared
    
    private var currentLevel: Level {
        return Level(rawValue: settings.logLevel) ?? .warning
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 记录错误日志
    func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .error, message: message, file: file, line: line, function: function)
    }
    
    /// 记录警告日志
    func warning(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .warning, message: message, file: file, line: line, function: function)
    }
    
    /// 记录信息日志
    func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .info, message: message, file: file, line: line, function: function)
    }
    
    /// 记录调试日志
    func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level: .debug, message: message, file: file, line: line, function: function)
    }
    
    // MARK: - Private Methods
    
    private func log(level: Level, message: String, file: String, line: Int, function: String) {
        // 检查日志级别
        guard level.rawValue <= currentLevel.rawValue else {
            return
        }
        
        // 关闭时不输出
        guard currentLevel != .off else {
            return
        }
        
        // 格式化文件名
        let filename = (file as NSString).lastPathComponent
        
        // 格式化时间
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        
        // 构建日志消息
        let logMessage: String
        if level == .debug {
            // 调试级别显示完整信息
            logMessage = "\(level.icon) [\(timestamp)] [\(level.prefix)] [\(filename):\(line)] \(message)"
        } else {
            // 其他级别显示简化信息
            logMessage = "\(level.icon) [\(level.prefix)] \(message)"
        }
        
        // 输出到控制台
        print(logMessage)
    }
}

// MARK: - Convenience Methods

extension Logger {
    /// 简写：错误日志
    static func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        shared.error(message, file: file, line: line, function: function)
    }
    
    /// 简写：警告日志
    static func warning(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        shared.warning(message, file: file, line: line, function: function)
    }
    
    /// 简写：信息日志
    static func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        shared.info(message, file: file, line: line, function: function)
    }
    
    /// 简写：调试日志
    static func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        shared.debug(message, file: file, line: line, function: function)
    }
}
