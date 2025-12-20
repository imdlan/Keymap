# Keymap 快速开始指南

## 📦 已完成的工作

### ✅ 项目基础结构
- 完整的目录组织（App, Core, UI, Models, Data, Utilities）
- 13个Swift源文件
- 3个配置文件（Info.plist, Entitlements）
- 完整的README文档

### ✅ 核心功能代码

#### 1. 应用入口和生命周期
- ✅ `KeymapApp.swift` - SwiftUI应用主入口
- ✅ `AppDelegate.swift` - AppKit生命周期管理
  - 菜单栏图标和菜单
  - 权限管理集成
  - 全局监控初始化
  - 快捷键面板控制

#### 2. 权限管理
- ✅ `PermissionManager.swift`
  - 辅助功能权限检查和申请
  - 权限状态监控
  - 用户友好的提示界面

#### 3. 全局事件监控
- ✅ `GlobalEventMonitor.swift` - CGEvent API封装
- ✅ `KeyCombinationDetector.swift` - 快捷键组合识别
- ✅ `DoubleCmdDetector.swift` - 双击Cmd检测

#### 4. 数据模型
- ✅ `ShortcutInfo.swift` - 快捷键信息
- ✅ `ConflictInfo.swift` - 冲突信息
- ✅ `UsageRecord.swift` - 使用记录
- ✅ `StatisticsSummary.swift` - 统计摘要

#### 5. 用户界面
- ✅ `ShortcutPanelWindow.swift` - 面板窗口控制器
- ✅ `ShortcutPanelView.swift` - SwiftUI面板视图
- ✅ `ShortcutPanelViewModel.swift` - MVVM视图模型
  - 演示数据展示
  - 搜索过滤功能
  - 冲突标记显示

## 🚀 立即开始

### 方法1: 使用Xcode创建项目（推荐）

```bash
# 1. 打开Xcode
open -a Xcode

# 2. 按照README.md中的详细步骤操作:
#    - 创建新的macOS App项目
#    - 删除默认文件
#    - 导入Keymap目录
#    - 配置签名和权限
#    - 运行项目
```

### 方法2: 使用命令行快速检查

```bash
# 验证项目结构
./verify-structure.sh

# 查看所有Swift文件
find Keymap -name "*.swift" -type f

# 统计代码行数
find Keymap -name "*.swift" -exec wc -l {} + | tail -1
```

## 📋 下一步开发任务

### 当前阶段: 在Xcode中创建项目（待完成）

1. [ ] 在Xcode中创建新项目
2. [ ] 导入所有源文件
3. [ ] 配置项目设置
4. [ ] 编译并运行
5. [ ] 测试基础功能

### 下一阶段: 快捷键提取功能

1. [ ] 实现 `AppShortcutExtractor.swift`
2. [ ] 实现 `MenuItemParser.swift`（Accessibility API）
3. [ ] 实现 `SystemShortcutProvider.swift`
4. [ ] 添加缓存机制
5. [ ] 集成到面板ViewModel

### 后续阶段

- 冲突检测引擎
- 临时重映射功能
- 统计分析模块
- Core Data持久化
- 完整的UI界面

详见: `/Users/David/.claude/plans/glowing-snacking-parrot.md`

## 🎯 核心功能演示

当前实现的功能：

### 1. 菜单栏应用
- ✅ 菜单栏图标（键盘符号）
- ✅ 下拉菜单（显示面板、统计、设置、退出）

### 2. 权限管理
- ✅ 自动检测辅助功能权限
- ✅ 友好的权限申请提示
- ✅ 一键打开系统设置

### 3. 全局监控（需要权限后测试）
- ✅ 监听所有键盘事件
- ✅ 识别快捷键组合
- ✅ 检测双击Cmd

### 4. 快捷键面板（演示UI）
- ✅ 半透明浮动窗口
- ✅ 搜索过滤
- ✅ 分类显示（冲突/常用）
- ✅ 冲突高亮标记

## 🔧 技术亮点

### SwiftUI + AppKit 混合架构
```swift
// SwiftUI作为主UI框架
@main
struct KeymapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
}

// AppKit处理底层系统交互
class AppDelegate: NSObject, NSApplicationDelegate {
    // 菜单栏、全局监控、系统事件
}
```

### 全局事件监控
```swift
// 使用CGEvent API监听所有键盘事件
CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventMask,
    callback: eventCallback
)
```

### 双击Cmd检测
```swift
// 时间阈值内检测连续两次Cmd按下
if Date().timeIntervalSince(lastPress) < 0.3 {
    // 触发面板显示
}
```

## 📖 文档索引

- **设计文档**: `快捷键冲突管理 2025-12-18-20-30-02.md`
- **开发计划**: `/Users/David/.claude/plans/glowing-snacking-parrot.md`
- **使用说明**: `README.md`
- **本指南**: `QUICKSTART.md`

## ⚠️ 注意事项

1. **最低系统要求**: macOS 14.0+
2. **必需权限**: 辅助功能权限
3. **非沙盒应用**: 需要完整系统访问权限
4. **开发者签名**: 需要有效的开发者证书

## 🐛 故障排除

### 编译错误
- 确认Xcode 15+
- 确认deployment target设置为14.0
- 清理构建 (⇧⌘K)

### 运行时问题
- 检查辅助功能权限
- 查看控制台日志
- 确认Entitlements配置正确

### 无法监控键盘
- 必须授予辅助功能权限
- 可能需要重启应用
- 检查App Sandbox是否禁用

## 💡 提示

### 快速测试
1. 运行应用
2. 授予权限
3. 双击Cmd键 → 应该弹出面板
4. 按任意快捷键 → 控制台应输出日志

### 调试模式
在`GlobalEventMonitor.swift`中，所有检测到的快捷键都会打印到控制台：
```
⌨️ 检测到快捷键: ⌘C - Safari
```

## 📞 获取帮助

- 查看代码注释
- 阅读README.md详细说明
- 参考设计文档了解架构

---

**状态**: 基础架构完成，可以开始Xcode项目创建和测试 ✅
**下一步**: 在Xcode中创建项目并运行测试
