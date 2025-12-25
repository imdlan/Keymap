# Changelog

所有重要的项目更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且该项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.1.0] - 2025-12-25

### 新增功能
- ✨ 统计分析窗口添加数字滚动动画效果
- ✨ 进度条和柱状图添加生长动画效果
- ✨ 所有动画组件支持数据切换时自动重新播放

### 优化改进
- 🎨 时间周期选择器文案优化："本周"改为"过去7天"，"本月"改为"过去30天"
- 📊 统计数据来源统一：概览和趋势图都从 `usage_records` 表查询，确保数据一致性
- 🐛 修复快速切换时间周期标签时，动画状态不同步导致的数据显示错误
- 🐛 修复概览板块与趋势图统计数据相差1的问题
- 🎯 优化动画触发机制：确保每次切换都能正确播放动画

### 技术改进
- 🔧 所有动画组件采用统一的状态缓存模式（`pendingValue` 模式）
- 🔧 趋势图查询改为实时数据查询，避免聚合表延迟问题
- 🔧 动画触发采用 `isAnimating` 先重置再触发的方式，确保 `onChange` 被调用

### 已知问题
- 无

---

## [1.0.0] - 2025-12-20

### 新增功能
- 🎉 初始版本发布
- ⌨️ 全局快捷键监控（使用 CGEvent API）
- 📱 从应用菜单自动提取快捷键（Accessibility API）
- ⌘⌘ 双击 Cmd 触发快捷键面板
- 🔍 快捷键冲突检测（系统级、全局、应用级、功能级）
- 🔄 临时快捷键重映射功能
- 📊 使用统计分析（今天、过去7天、过去30天、全部）
- 🎨 现代化 SwiftUI + AppKit 混合 UI 界面
- ⚙️ 完整的设置面板（通用、快捷键、全局映射、长驻应用、数据、高级）
- 📝 日志系统（5级日志：off/error/warning/info/debug）

### 核心功能
- 🔐 辅助功能权限管理
- 💾 SQLite 数据库持久化（5张表：applications, shortcuts, conflicts, usage_records, statistics_summary）
- 🗂️ 快捷键缓存系统（内存 + 磁盘双层缓存）
- 🔔 系统通知支持（UserNotifications API）
- 🚀 开机自动启动（SMAppService API）
- 🎯 智能冲突建议（基于 QWERTY 键盘布局）
- 📈 趋势图可视化（柱状图展示使用趋势）
- 🎨 深色/浅色主题自适应

### 技术特性
- 🏗️ MVVM 架构模式
- 🔄 Repository 数据访问层
- ⚡ async/await 异步编程
- 🧩 模块化设计
- 🔒 非沙盒应用（需要辅助功能权限）
- 🎯 最低支持 macOS 14.0

### 配置选项
- ⏱️ 双击 Cmd 阈值可调节（0.1-1.0秒）
- 🎚️ 触发快捷键选择（双击Cmd/Option/Control）
- ⏰ 面板自动关闭延迟（0-30秒，0为禁用）
- 📦 缓存时长可调节（1-72小时）
- 🗄️ 最大缓存应用数可调节（10-100个）
- 🔄 全局快捷键重映射开关
- 📝 日志级别可调节（off/error/warning/info/debug）
- 🔐 快捷键录制模式（实验性功能）

[1.1.0]: https://github.com/yourusername/Keymap/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/yourusername/Keymap/releases/tag/v1.0.0
