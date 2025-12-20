# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Keymap 是一个 macOS 快捷键管理工具，使用 Swift + SwiftUI + AppKit 开发，最低支持 macOS 14.0。采用 MVVM 架构，非沙盒应用（需要辅助功能权限以监控全局键盘事件）。

**核心功能**:
- 全局快捷键监控（使用 CGEvent API）
- 从应用菜单自动提取快捷键（Accessibility API）
- 双击 Cmd 触发快捷键面板
- 快捷键冲突检测（开发中）
- 临时快捷键重映射（计划中）

## 构建和运行

### 项目生成
项目使用 **XcodeGen** 管理，源配置文件为 `project.yml`。

```bash
# 重新生成 Xcode 项目（添加新文件后必须执行）
xcodegen generate

# 或使用 brew 安装后生成
brew install xcodegen
xcodegen generate
```

### 编译
```bash
# 清理并编译
xcodebuild -project Keymap.xcodeproj -scheme Keymap clean build

# 仅编译
xcodebuild -project Keymap.xcodeproj -scheme Keymap build
```

### 运行
```bash
# 方式1: 在 Xcode 中运行（推荐，方便调试）
open Keymap.xcodeproj
# 然后按 ⌘R

# 方式2: 命令行运行编译后的应用
open ~/Library/Developer/Xcode/DerivedData/Keymap-*/Build/Products/Debug/Keymap.app
```

**首次运行**: 系统会提示授予辅助功能权限，前往 `系统设置 → 隐私与安全性 → 辅助功能` 勾选 Keymap.app。

## 代码架构

### 应用生命周期
- **KeymapApp.swift** (SwiftUI 入口): 使用 `@NSApplicationDelegateAdaptor` 桥接 AppDelegate
- **AppDelegate.swift** (AppKit 生命周期):
  - 初始化菜单栏图标（LSUIElement=true，不在 Dock 显示）
  - 启动 GlobalEventMonitor 监控全局键盘事件
  - 管理 ShortcutPanelWindow 的显示/隐藏

### 全局监控架构
**三层检测机制**:

1. **GlobalEventMonitor** (`Core/Monitoring/GlobalEventMonitor.swift`)
   - 使用 `CGEvent.tapCreate` 创建事件 tap
   - 监听 `keyDown` 和 `flagsChanged` 事件
   - 分发事件到 DoubleCmdDetector 和 KeyCombinationDetector

2. **DoubleCmdDetector** (`Core/Monitoring/DoubleCmdDetector.swift`)
   - 检测双击 Cmd 键（默认阈值 0.3 秒）
   - 通过 NotificationCenter 发送 `doubleCmdDetected` 通知
   - AppDelegate 监听此通知后显示快捷键面板

3. **KeyCombinationDetector** (`Core/Monitoring/KeyCombinationDetector.swift`)
   - 检测快捷键组合（Cmd/Shift/Option/Control + 字母/数字）
   - 返回 KeyCombination 结构体（keyCode + modifiers）
   - 用于记录使用统计和冲突检测（未来）

### 快捷键提取架构
**四个核心组件**:

1. **AppShortcutExtractor** (`Core/ShortcutExtraction/AppShortcutExtractor.swift`)
   - 从运行中的应用菜单提取快捷键
   - 使用 AXUIElement API 遍历菜单层级
   - async/await 异步提取，TaskGroup 实现 5 秒超时

2. **MenuItemParser** (`Core/ShortcutExtraction/MenuItemParser.swift`)
   - 解析单个菜单项（标题、快捷键、状态）
   - 修饰键位掩码转换: Control=0x0001, Shift=0x0002, Option=0x0004, Command=0x0008
   - 字符到键码映射（支持 A-Z, 0-9, 特殊字符）

3. **SystemShortcutProvider** (`Core/ShortcutExtraction/SystemShortcutProvider.swift`)
   - 提供 30 个硬编码的系统快捷键（⌘Q, ⌘W, ⌘Space 等）
   - 单例模式，按分类组织（通用、窗口、截图、Spotlight、辅助功能）

4. **ShortcutCache** (`Core/ShortcutExtraction/ShortcutCache.swift`)
   - 两层缓存: NSCache（内存，最多 50 个应用）+ UserDefaults（持久化）
   - 缓存过期: 24 小时
   - 自动管理内存，支持缓存统计

### 冲突检测架构
**三个核心组件**:

1. **ConflictDetector** (`Core/ConflictDetection/ConflictDetector.swift`)
   - 冲突检测主引擎
   - 四种冲突类型：系统级、全局、应用级、功能级
   - 智能严重程度计算（high/medium/low）
   - 实时冲突检测（集成到 GlobalEventMonitor）

2. **ConflictAnalyzer** (`Core/ConflictDetection/ConflictAnalyzer.swift`)
   - 冲突分析与建议生成
   - 寻找替代快捷键（修饰键变化 + 相邻按键）
   - 基于 QWERTY 键盘布局的智能建议
   - 最多返回 5 个替代方案

3. **ConflictResolver** (`Core/ConflictDetection/ConflictResolver.swift`)
   - 冲突解决方案执行
   - 支持策略：disable, remap（阶段5）, ignore, manual
   - 解决记录持久化（UserDefaults）
   - 提供统计功能（已解决/已忽略/待处理）

**冲突检测流程**:
```
1. 用户按下快捷键 → GlobalEventMonitor 捕获
2. handleShortcutDetected → 异步调用 ConflictDetector
3. detectRealTimeConflict → 检查与所有已知快捷键的冲突
4. 如果发现冲突 → 发送 .conflictFound 通知
5. UI 监听通知 → 显示冲突警告和建议
```

### 数据持久化架构
**四个核心组件**:

1. **DatabaseManager** (`Data/DatabaseManager.swift`)
   - SQLite 数据库管理器（单例）
   - 5张表：applications, shortcuts, conflicts, usage_records, statistics_summary
   - 参数化查询、事务支持、数据库索引优化
   - 自动创建数据库目录：`~/Library/Application Support/Keymap/keymap.db`

2. **ShortcutRepository** (`Data/Repositories/ShortcutRepository.swift`)
   - 快捷键数据访问层（Repository 模式）
   - CRUD 操作、搜索、批量保存
   - 自动创建应用记录、智能更新/插入判断

3. **UsageRepository** (`Data/Repositories/UsageRepository.swift`)
   - 使用记录数据访问层
   - 记录快捷键使用、统计聚合、趋势分析
   - 自动每日摘要聚合（异步 Task）
   - 支持多种统计周期（today/week/month/all）

4. **SettingsManager** (`Data/SettingsManager.swift`)
   - 用户设置管理（单例，UserDefaults 持久化）
   - 9个设置项：双击阈值、实时检测、使用追踪、缓存时长等
   - 导出/导入、默认值注册、变更通知（NotificationCenter）

**数据库表结构**:
```sql
applications       - 应用信息（bundle_id, name, icon_data）
shortcuts          - 快捷键（key_combination, description, category）
conflicts          - 冲突记录（conflict_type, severity）
usage_records      - 使用记录（shortcut_key, timestamp, context）
statistics_summary - 统计摘要（按日期聚合）
```

**自动记录流程**:
```
1. 用户按下快捷键 → GlobalEventMonitor 捕获
2. recordUsageStatistics → 检查设置是否开启追踪
3. 创建 UsageRecord → Task 异步保存到数据库
4. UsageRepository.recordUsage → 写入 usage_records 表
5. updateDailySummary → 自动更新 statistics_summary 表
```

### 快捷键重映射架构
**两个核心组件**:

1. **RemappingEngine** (`Core/Remapping/RemappingEngine.swift`)
   - 快捷键重映射引擎
   - 数据结构: `[bundleId: [fromKey: toKey]]`
   - 智能规则验证（不能自映射、循环、链式、系统保留键）
   - 字符到键码映射（A-Z, 0-9, 特殊键）

2. **RemappingManager** (`Core/Remapping/RemappingManager.swift`)
   - 重映射规则管理器（单例）
   - 持久化到 UserDefaults（JSON 格式）
   - 导出/导入功能（JSON 文件）
   - 验证和统计功能

**重映射流程**:
```
1. 用户按下快捷键（如⌘T）→ GlobalEventMonitor 捕获 keyDown 事件
2. checkAndApplyRemapping → 查找重映射规则
3. 如果有规则（⌘T → ⇧⌘T）→ 创建新 CGEvent
4. 设置新的 keyCode 和 modifiers
5. 返回新事件 → 系统接收⇧⌘T而不是⌘T
```

**验证规则**:
- ❌ 不能映射到相同的键（⌘T → ⌘T）
- ❌ 不能映射系统保留快捷键（→ ⌘Q, ⌘Space）
- ❌ 不能创建循环映射（⌘T→⇧⌘T, ⇧⌘T→⌘T）
- ❌ 不能创建链式映射（⌘T→⇧⌘T→⌃⌘T）

**系统保留快捷键**:
```swift
⌘Q         - 退出应用
⌘⌥Esc      - 强制退出
⌘Space     - Spotlight
⌃⌘Q        - 锁定屏幕
⌃⌘Power    - 关机对话框
```

**限制**:
- 仅在应用运行期间有效（临时重映射）
- 无法修改 macOS 系统级快捷键
- 需要辅助功能权限
- SIP 保护的应用可能无法重映射

### UI 架构
**SwiftUI + AppKit 混合架构**:

- **ShortcutPanelWindow** (`UI/Views/ShortcutPanel/ShortcutPanelWindow.swift`)
  - NSPanel 子类，半透明浮动窗口
  - 使用 NSHostingView 承载 SwiftUI 视图
  - 无边框、总在最前、点击外部关闭

- **ShortcutPanelView** (`UI/Views/ShortcutPanel/ShortcutPanelView.swift`)
  - SwiftUI 视图，显示快捷键列表
  - 支持搜索、分类显示、冲突高亮

- **ShortcutPanelViewModel** (`UI/ViewModels/ShortcutPanelViewModel.swift`)
  - MVVM 模式的 ViewModel
  - 集成 AppShortcutExtractor、ShortcutCache、SystemShortcutProvider
  - 提取流程: 检查缓存 → 异步提取 → 合并系统快捷键 → 缓存结果

### 数据模型
- **ShortcutInfo** (`Models/ShortcutInfo.swift`): 快捷键信息，包含 keyCombination, description, application, category, conflicts
- **ConflictInfo** (`Models/ConflictInfo.swift`): 冲突信息，包含 id, shortcutId, conflictType, severity, suggestions
- **UsageRecord** (`Models/UsageRecord.swift`): 使用记录，包含 id, shortcutKey, application, timestamp, context
- **StatisticsSummary** (`Models/StatisticsSummary.swift`): 统计摘要，包含 totalUsage, conflictCount, efficiencyScore, topShortcuts, timeRange
- **KeyCombination** (`Models/KeyCombination.swift`): 快捷键组合，包含 keyCode, modifiers, displayString
- **RemappingRule** (`Core/Remapping/RemappingEngine.swift`): 重映射规则，包含 fromKey, toKey, bundleId, createdAt

### 枚举类型
- **ShortcutCategory**: 快捷键分类（general, edit, window, navigation, search, view, help, custom）
- **ConflictType**: 冲突类型（system, global, application, functional）
- **ConflictSeverity**: 冲突严重程度（high, medium, low）
- **UsageContext**: 使用上下文（normal, conflict, remapped）
- **ResolutionStrategy**: 冲突解决策略（disable, remap, ignore, manual）
- **StatisticsPeriod**: 统计周期（today, week, month, all）

## 重要约定

### 添加新文件后
**必须重新生成项目**:
```bash
xcodegen generate
```
否则 Xcode 无法识别新文件。

### 修改 ShortcutCategory 枚举
使用 `.edit` 而不是 `.editing`（已在 ShortcutInfo.swift 中统一）。

### 权限相关
- **Entitlements.plist** 必须设置 `com.apple.security.app-sandbox = false`（非沙盒应用）
- **Info.plist** 必须设置 `LSUIElement = true`（菜单栏应用）
- 需要 `NSAppleEventsUsageDescription` 说明（Accessibility API）

### 缓存清理
```bash
# 清除 UserDefaults 缓存（重新测试提取功能时）
defaults delete com.yourcompany.Keymap
```

### 双击 Cmd 灵敏度调整
修改 `DoubleCmdDetector.swift` 中的 `doublePressThreshold`（默认 0.3 秒）。

## 开发进度

参考 `PLAN.md`。当前状态:
- ✅ 阶段1: Xcode 项目创建（90% - 编译成功，待运行测试）
- ✅ 阶段2: 快捷键提取（100%）
- ✅ 阶段3: 冲突检测（100%）
- ✅ 阶段4: 数据持久化（100%）
- ✅ 阶段5: 快捷键重映射（100%）
- ⏳ 阶段6: UI 完善（0%）- **下一步**

**总体进度**: 90%

### ⏸️ 阶段1剩余工作（10%）
虽然编译成功，但需要完成运行时验证测试（参考 `TEST_CHECKLIST.md`）：
- [ ] 应用成功启动
- [ ] Dock 无图标，菜单栏有图标
- [ ] 辅助功能权限请求流程
- [ ] 双击 Cmd 触发面板
- [ ] 快捷键检测正常
- [ ] 性能指标达标

### 下一阶段任务（阶段6）
创建UI完善功能，需要新建:
- `UI/Views/Statistics/StatisticsWindow.swift` - 统计分析窗口
- `UI/Views/Settings/SettingsWindow.swift` - 设置窗口
- 修改 `ShortcutPanelView.swift` - 添加重映射按钮
- 修改 `AppDelegate.swift` - 实现窗口显示方法

## 测试

参考 `TEST_GUIDE.md` 进行功能测试。

**基础验证**:
1. 应用启动后 Dock 不显示图标
2. 菜单栏显示键盘图标 ⌨️
3. 双击 Cmd 键弹出快捷键面板
4. 打开 Safari，双击 Cmd，应显示 Safari 和系统快捷键

**验证脚本**:
```bash
swift verify_shortcuts.swift  # 验证系统快捷键数量
```

## 性能目标

- CPU 使用率: < 5%（后台运行）
- 内存占用: < 100MB
- 首次提取快捷键: < 5 秒
- 缓存命中响应: < 0.1 秒
- 面板响应时间: < 200ms

## 故障排除

### 应用无法监控键盘事件
1. 检查辅助功能权限是否授予
2. 在系统设置中移除并重新添加 Keymap 权限
3. 检查控制台是否有 "✅ 全局监控已启动" 输出

### 双击 Cmd 无反应
1. 查看控制台是否有 "⌘ 检测到双击Cmd" 输出
2. 确认 GlobalEventMonitor 已启动
3. 调整 DoubleCmdDetector 的阈值

### 快捷键提取失败
1. 查看控制台错误信息（"⚠️ 无法获取应用菜单栏"）
2. 确认应用有菜单栏且包含快捷键
3. 提取超时时显示演示数据（正常降级行为）

### 编译错误
1. 确认 macOS >= 14.0, Xcode >= 15.0
2. 清理构建文件夹 (⇧⌘K)
3. 检查新文件是否通过 `xcodegen generate` 添加到项目
4. 验证 Info.plist 和 Entitlements.plist 路径

## 相关文档

- **PLAN.md**: 详细开发计划和进度跟踪
- **TEST_CHECKLIST.md**: 阶段1运行时测试清单
- **STAGE1_SUMMARY.md**: 阶段1完成总结（Xcode项目创建）
- **STAGE2_SUMMARY.md**: 阶段2完成总结（快捷键提取）
- **STAGE3_SUMMARY.md**: 阶段3完成总结（冲突检测）
- **STAGE4_SUMMARY.md**: 阶段4完成总结（数据持久化）
- **STAGE5_SUMMARY.md**: 阶段5完成总结（快捷键重映射）
- **TEST_GUIDE.md**: 功能测试指南
- **QUICKSTART.md**: 快速启动指南
- **快捷键冲突管理 2025-12-18-20-30-02.md**: 原始设计文档

