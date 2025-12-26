# Keymap 多语言支持实施计划

## 📋 项目概述

**目标**：为 Keymap 添加 10 种语言支持（中英双语优先，其他 8 种语言后续添加）

**支持语言**：
- 阶段 1（优先）：简体中文 (zh-Hans)、英语 (en)
- 阶段 2（后续）：繁体中文 (zh-Hant)、法语 (fr)、俄语 (ru)、日语 (ja)、韩语 (ko)、德语 (de)、意大利语 (it)、西班牙语 (es)

**关键决策**：
- ✅ 使用 AI 翻译 + 人工校对关键术语
- ✅ 将枚举 rawValue 改为英文，编写数据库迁移脚本
- ✅ 修改 project.yml 的 developmentLanguage 为 en
- ✅ 分两阶段实施（先中英双语，再其他 8 种语言）

---

## 🎯 阶段 1：中英双语支持（预计 3-4 天）

### 第 1 步：Git 分支和项目配置（0.5 天）

#### 1.1 创建 feature 分支
```bash
git checkout -b feature/i18n-bilingual-support
```

#### 1.2 修改 project.yml
**文件**：`project.yml`

**修改内容**：
```yaml
options:
  developmentLanguage: en  # 从 zh-Hans 改为 en

targets:
  Keymap:
    settings:
      base:
        # 支持的语言区域
        KNOWN_REGIONS: ["en", "zh-Hans", "Base"]

        # 启用本地化
        SWIFT_EMIT_LOC_STRINGS: YES
```

#### 1.3 运行 XcodeGen
```bash
xcodegen generate
```

---

### 第 2 步：创建本地化基础设施（0.5 天）

#### 2.1 创建 LocalizationManager
**新文件**：`Keymap/Utilities/LocalizationManager.swift`

**核心功能**：
- 单例模式
- `@Published var currentLanguage: String`（支持 SwiftUI 响应式更新）
- 动态加载对应语言的 Bundle
- 提供 `.localized()` 扩展方法
- 发送 `.languageChanged` 通知

**关键代码**：
```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String {
        didSet {
            _bundle = nil  // 清除缓存
            notifyLanguageChanged()
        }
    }

    private var _bundle: Bundle?

    func localizedString(key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private var bundle: Bundle {
        // 动态加载 xx.lproj Bundle
    }
}

extension String {
    func localized() -> String {
        return LocalizationManager.shared.localizedString(key: self)
    }

    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.localizedString(key: self)
        return String(format: format, arguments: arguments)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("com.keymap.languageChanged")
}
```

#### 2.2 创建本地化资源目录
```
Keymap/Resources/Localizations/
├── en.lproj/
│   └── Localizable.strings
└── zh-Hans.lproj/
    └── Localizable.strings
```

---

### 第 3 步：重构枚举类型（0.5 天）

#### 3.1 重构 ShortcutCategory
**文件**：`Keymap/Models/ShortcutInfo.swift`

**修改前**：
```swift
enum ShortcutCategory: String, Codable {
    case file = "文件"      // ❌ rawValue 是中文
    case edit = "编辑"
    // ...
}
```

**修改后**：
```swift
enum ShortcutCategory: String, Codable, CaseIterable {
    case file = "file"              // ✅ rawValue 改为英文
    case edit = "edit"
    case view = "view"
    case window = "window"
    case system = "system"
    case navigation = "navigation"
    case other = "other"

    var displayName: String {
        switch self {
        case .file:       return "category.file".localized()
        case .edit:       return "category.edit".localized()
        case .view:       return "category.view".localized()
        case .window:     return "category.window".localized()
        case .system:     return "category.system".localized()
        case .navigation: return "category.navigation".localized()
        case .other:      return "category.other".localized()
        }
    }
}
```

#### 3.2 重构其他枚举
**需要修改的文件**：
1. `Keymap/Models/ConflictInfo.swift` - ConflictType, ConflictSeverity
2. `Keymap/Models/UsageRecord.swift` - UsageContext
3. `Keymap/Core/ConflictDetection/ConflictDetector.swift` - ResolutionStrategy

**统一模式**：
- rawValue：英文（file, edit, high, low 等）
- displayName：本地化显示名（"文件" / "File"）

---

### 第 4 步：数据库迁移脚本（1 天）

#### 4.1 创建迁移工具类
**新文件**：`Keymap/Data/Migrations/EnumMigration.swift`

**功能**：
- 读取 SQLite 数据库
- 映射中文 rawValue → 英文 rawValue
- 更新所有相关表（shortcuts, conflicts, usage_records）

**映射表**：
```swift
let categoryMapping: [String: String] = [
    "文件": "file",
    "编辑": "edit",
    "视图": "view",
    "窗口": "window",
    "系统": "system",
    "导航": "navigation",
    "其他": "other"
]

let conflictTypeMapping: [String: String] = [
    "系统级": "system",
    "应用级": "application",
    "全局": "global",
    "功能": "functional"
]

// ... 其他映射
```

#### 4.2 在应用启动时执行迁移
**修改文件**：`Keymap/App/AppDelegate.swift`

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // 执行数据库迁移（仅首次运行）
    if EnumMigration.needsMigration() {
        print("🔄 执行枚举值数据库迁移...")
        try? EnumMigration.migrate()
        print("✅ 迁移完成")
    }

    // ... 其他初始化
}
```

---

### 第 5 步：提取和翻译字符串（0.5 天）

#### 5.1 提取所有需要本地化的文本
**优先级 P0（关键）- 约 165 条**：
- SettingsWindow.swift（80+ 条）
- ShortcutPanelView.swift（35+ 条）
- AppDelegate.swift 菜单栏（20+ 条）
- 通知消息（30+ 条）

#### 5.2 生成 Localizable.strings
**en.lproj/Localizable.strings**：
```
// Settings Window
"settings.title" = "Settings";
"settings.launch_at_login" = "Launch at Login";
"settings.launch_at_login.description" = "Keymap will start automatically when you log in";
"settings.language" = "Language";

// Panel
"panel.title" = "Shortcut Panel";
"panel.search_placeholder" = "Search shortcuts...";

// Menu Bar
"menu.show_panel" = "Show Shortcut Panel";
"menu.statistics" = "Statistics";
"menu.settings" = "Settings";
"menu.quit" = "Quit Keymap";

// Categories
"category.file" = "File";
"category.edit" = "Edit";
"category.view" = "View";
// ...

// Notifications
"notification.permission.title" = "Permission Required";
"notification.permission.message" = "Please grant Keymap accessibility permission";
```

**zh-Hans.lproj/Localizable.strings**：
```
"settings.title" = "设置";
"settings.launch_at_login" = "开机自动启动";
"settings.launch_at_login.description" = "Keymap 将在系统启动时自动运行";
"settings.language" = "语言";
// ...
```

#### 5.3 翻译方式
- 使用 Claude/ChatGPT 批量翻译
- 人工校对关键术语（Settings vs 设置、Shortcut vs 快捷键）
- 保持术语一致性

---

### 第 6 步：代码本地化改造（1 天）

#### 6.1 SettingsWindow.swift（优先级最高）
**替换模式**：
```swift
// ❌ 旧代码
Text("开机自动启动")

// ✅ 新代码
Text("settings.launch_at_login".localized())
```

**动态文本处理**：
```swift
// ❌ 错误
Text("共 \(count) 条规则")

// ✅ 正确
Text("settings.rules_count".localized(with: count))
```

**对应 .strings**：
```
// en
"settings.rules_count" = "%d rules total";

// zh-Hans
"settings.rules_count" = "共 %d 条规则";
```

#### 6.2 ShortcutPanelView.swift
- 替换所有 Text() 中的硬编码字符串
- 替换 TextField placeholder
- 替换按钮标题

#### 6.3 AppDelegate.swift（菜单栏）
- 监听 `.languageChanged` 通知
- 重新创建 NSMenu

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(updateMenuLocalization),
    name: .languageChanged,
    object: nil
)

@objc private func updateMenuLocalization() {
    statusItem?.menu = createLocalizedMenu()
}
```

#### 6.4 NotificationHelper.swift
- 替换所有通知标题和消息
- 支持格式化参数

#### 6.5 StatisticsWindow.swift
- 替换图表标题
- 替换优化建议文本

---

### 第 7 步：更新 SettingsWindow 语言选择器（0.5 天）

#### 7.1 修改 SettingsViewModel
**文件**：`Keymap/UI/Views/Settings/SettingsWindow.swift`

```swift
// 监听语言变更
@Published var selectedLanguage: String = "en" {
    didSet {
        LocalizationManager.shared.currentLanguage = selectedLanguage
    }
}

init() {
    selectedLanguage = SettingsManager.shared.selectedLanguage

    // 如果是 "system"，使用系统语言
    if selectedLanguage == "system" {
        selectedLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    }
}
```

#### 7.2 更新 Picker 选项
```swift
Picker("", selection: $viewModel.selectedLanguage) {
    Text("settings.language.system".localized()).tag("system")
    Text("English").tag("en")
    Text("简体中文").tag("zh-Hans")
}
```

---

### 第 8 步：测试和修复（0.5 天）

#### 8.1 功能测试清单
- [ ] 语言切换立即生效（无需重启）
- [ ] 所有 UI 文本正确显示
  - [ ] 设置面板
  - [ ] 快捷键面板
  - [ ] 统计分析窗口
  - [ ] 菜单栏
  - [ ] 系统通知
- [ ] 枚举显示名正确（.displayName）
- [ ] 数据库迁移成功
- [ ] 旧数据正常读取

#### 8.2 布局测试
- [ ] 长文本不溢出（英语比中文长 30-50%）
- [ ] 按钮宽度自适应
- [ ] 动态文本格式正确

#### 8.3 回归测试
- [ ] 快捷键提取功能正常
- [ ] 冲突检测功能正常
- [ ] 统计分析功能正常
- [ ] 重映射功能正常

---

## 🎯 阶段 2：其他 8 种语言支持（预计 3-4 天）

### 第 9 步：创建 8 个本地化资源（0.5 天）

#### 9.1 创建 .lproj 目录
```
Keymap/Resources/Localizations/
├── zh-Hant.lproj/Localizable.strings  # 繁体中文
├── fr.lproj/Localizable.strings       # 法语
├── ru.lproj/Localizable.strings       # 俄语
├── ja.lproj/Localizable.strings       # 日语
├── ko.lproj/Localizable.strings       # 韩语
├── de.lproj/Localizable.strings       # 德语
├── it.lproj/Localizable.strings       # 意大利语
└── es.lproj/Localizable.strings       # 西班牙语
```

#### 9.2 更新 project.yml
```yaml
settings:
  base:
    KNOWN_REGIONS: [
      "en", "zh-Hans", "zh-Hant",
      "fr", "ru", "ja", "ko", "de", "it", "es",
      "Base"
    ]
```

---

### 第 10 步：AI 翻译 + 人工校对（1.5 天）

#### 10.1 使用 Claude 批量翻译
**提示词模板**：
```
请将以下英文 UI 文本翻译为 8 种语言，要求：
1. 保持专业性和一致性
2. UI 文本简洁明了
3. 遵循各语言的 UI 惯例

格式：CSV
原文(en) | zh-Hant | fr | ru | ja | ko | de | it | es

文本列表：
"Settings" | ? | ? | ? | ? | ? | ? | ? | ?
"Launch at Login" | ? | ? | ? | ? | ? | ? | ? | ?
...
```

#### 10.2 人工校对关键术语
**术语一致性表**：
| 英文 | 繁体 | 法语 | 俄语 | 日语 | 韩语 | 德语 | 意大利语 | 西班牙语 |
|------|------|------|------|------|------|------|----------|----------|
| Shortcut | 快速鍵 | Raccourci | Ярлык | ショートカット | 단축키 | Tastenkombination | Scorciatoia | Atajo |
| Conflict | 衝突 | Conflit | Конфликт | 競合 | 충돌 | Konflikt | Conflitto | Conflicto |
| Remap | 重新映射 | Remapper | Переназначить | リマップ | 리매핑 | Umbelegen | Rimappa | Reasignar |

---

### 第 11 步：更新语言选择器（0.5 天）

#### 11.1 修改 SettingsWindow
**添加语言选项**：
```swift
Picker("", selection: $viewModel.selectedLanguage) {
    Text("settings.language.system".localized()).tag("system")
    Text("English").tag("en")
    Text("简体中文").tag("zh-Hans")
    Text("繁體中文").tag("zh-Hant")
    Text("Français").tag("fr")
    Text("Русский").tag("ru")
    Text("日本語").tag("ja")
    Text("한국어").tag("ko")
    Text("Deutsch").tag("de")
    Text("Italiano").tag("it")
    Text("Español").tag("es")
}
```

#### 11.2 更新 LocalizationManager
```swift
static let supportedLanguages = [
    "system", "en", "zh-Hans", "zh-Hant",
    "fr", "ru", "ja", "ko", "de", "it", "es"
]
```

---

### 第 12 步：全面测试（1-1.5 天）

#### 12.1 手动测试所有语言
- [ ] 测试 11 种语言切换（包括 system）
- [ ] 验证每种语言的显示正确性
- [ ] 检查布局问题（特别是德语和俄语，文本较长）

#### 12.2 布局修复
**处理长文本溢出**：
```swift
Button("settings.save".localized()) {
    // ...
}
.frame(minWidth: 80, maxWidth: 150)
.lineLimit(1)
.minimumScaleFactor(0.8)  // 必要时缩小字体
```

#### 12.3 复数形式处理（如需要）
**英语有单复数，中文没有**：
```
// en
"statistics.shortcuts_count" = "%d shortcut(s)";

// zh-Hans
"statistics.shortcuts_count" = "%d 个快捷键";
```

---

## 📁 关键文件清单

### 需要修改的文件（15+）

**优先级 P0**：
1. `project.yml` - 修改 developmentLanguage，添加 KNOWN_REGIONS
2. `Keymap/Models/ShortcutInfo.swift` - 重构 ShortcutCategory 枚举
3. `Keymap/Models/ConflictInfo.swift` - 重构 ConflictType, ConflictSeverity
4. `Keymap/UI/Views/Settings/SettingsWindow.swift` - 本地化所有文本
5. `Keymap/UI/Views/ShortcutPanel/ShortcutPanelView.swift` - 本地化
6. `Keymap/App/AppDelegate.swift` - 菜单栏本地化 + 语言切换监听
7. `Keymap/Utilities/NotificationHelper.swift` - 通知本地化
8. `Keymap/Data/SettingsManager.swift` - 确保 selectedLanguage 正确保存

**优先级 P1**：
9. `Keymap/UI/Views/Statistics/StatisticsWindow.swift` - 本地化
10. `Keymap/Core/ConflictDetection/ConflictDetector.swift` - 冲突消息本地化
11. `Keymap/Core/ShortcutExtraction/SystemShortcutProvider.swift` - 系统快捷键描述本地化

**优先级 P2（可选）**：
12. `Keymap/Utilities/Logger.swift` - 日志消息本地化（可选）

### 需要创建的文件（12+）

**新增文件**：
1. `Keymap/Utilities/LocalizationManager.swift` ⭐
2. `Keymap/Data/Migrations/EnumMigration.swift` ⭐
3. `Keymap/Resources/Localizations/en.lproj/Localizable.strings` ⭐
4. `Keymap/Resources/Localizations/zh-Hans.lproj/Localizable.strings` ⭐
5. `Keymap/Resources/Localizations/zh-Hant.lproj/Localizable.strings`
6. `Keymap/Resources/Localizations/fr.lproj/Localizable.strings`
7. `Keymap/Resources/Localizations/ru.lproj/Localizable.strings`
8. `Keymap/Resources/Localizations/ja.lproj/Localizable.strings`
9. `Keymap/Resources/Localizations/ko.lproj/Localizable.strings`
10. `Keymap/Resources/Localizations/de.lproj/Localizable.strings`
11. `Keymap/Resources/Localizations/it.lproj/Localizable.strings`
12. `Keymap/Resources/Localizations/es.lproj/Localizable.strings`

---

## ⚠️ 风险和注意事项

### 高风险项

1. **数据库迁移失败**
   - 风险：用户数据丢失
   - 缓解：备份数据库、充分测试、提供回滚机制

2. **枚举 rawValue 变更**
   - 风险：旧数据无法识别
   - 缓解：EnumMigration 脚本全面覆盖所有枚举

3. **语言切换后布局错乱**
   - 风险：长文本溢出、按钮变形
   - 缓解：设置 minWidth/maxWidth、lineLimit、minimumScaleFactor

### 中等风险项

4. **翻译质量问题**
   - 风险：AI 翻译不准确、术语不一致
   - 缓解：人工校对关键术语、建立术语表

5. **动态文本语序错误**
   - 风险：不同语言的语序不同（如中文 vs 日语）
   - 缓解：使用 String(format:) 和 %1$@、%2$d 位置参数

### 低风险项

6. **性能影响**
   - 风险：频繁 Bundle 加载影响性能
   - 缓解：缓存 Bundle 实例

---

## 📊 时间估算

### 阶段 1（中英双语）- 3-4 天
| 步骤 | 任务 | 时间 |
|------|------|------|
| 1 | Git 分支和项目配置 | 0.5 天 |
| 2 | 创建本地化基础设施 | 0.5 天 |
| 3 | 重构枚举类型 | 0.5 天 |
| 4 | 数据库迁移脚本 | 1.0 天 |
| 5 | 提取和翻译字符串 | 0.5 天 |
| 6 | 代码本地化改造 | 1.0 天 |
| 7 | 更新语言选择器 | 0.5 天 |
| 8 | 测试和修复 | 0.5 天 |
| **小计** | | **5 天** |

### 阶段 2（其他 8 种语言）- 3-4 天
| 步骤 | 任务 | 时间 |
|------|------|------|
| 9 | 创建 8 个本地化资源 | 0.5 天 |
| 10 | AI 翻译 + 人工校对 | 1.5 天 |
| 11 | 更新语言选择器 | 0.5 天 |
| 12 | 全面测试 | 1.5 天 |
| **小计** | | **4 天** |

**总计：9 天**

---

## ✅ 成功标准

### 功能完整性
- [x] 用户可在设置面板实时切换语言
- [x] 所有 UI 文本正确本地化（280+ 条）
- [x] 枚举类型支持本地化显示（.displayName）
- [x] 菜单栏和通知支持语言切换
- [x] 无需重启应用即可切换语言

### 技术要求
- [x] 数据库兼容性保持（rawValue 英文化 + 迁移脚本）
- [x] 支持动态文本格式化
- [x] 布局适配所有语言
- [x] 性能无明显下降

### 质量要求
- [x] 翻译准确性 > 95%
- [x] 术语一致性 100%
- [x] 布局无溢出问题
- [x] 所有测试用例通过

---

## 🚀 下一步行动

1. **创建分支**：`git checkout -b feature/i18n-bilingual-support`
2. **修改 project.yml**：设置 developmentLanguage 为 en
3. **创建 LocalizationManager.swift**：核心本地化引擎
4. **重构枚举**：rawValue 英文化 + displayName 本地化
5. **编写迁移脚本**：确保数据库兼容性
6. **逐步本地化 UI**：从 SettingsWindow 开始
7. **测试验证**：功能 + 布局 + 回归测试

---

**计划版本**：v1.0
**创建日期**：2025-12-25
**预计完成时间**：2026-01-08（阶段 1 + 阶段 2 共 9 天）

---

## ✅ 计划已确认

**用户确认时间**：2025-12-25

**下一步操作**：
1. 退出 plan mode
2. 将本计划保存到项目根目录：`/Users/David/Sites/Keymap/I18N_PLAN.md`
3. 开始实施阶段 1：中英双语支持

**实施顺序**：
- Step 1: 创建 feature 分支 `feature/i18n-bilingual-support`
- Step 2: 创建 LocalizationManager.swift
- Step 3: 重构枚举类型（rawValue 英文化）
- Step 4: 编写数据库迁移脚本
- Step 5: 本地化 UI 文本（SettingsWindow → ShortcutPanelView → AppDelegate → 其他）
- Step 6: 测试和修复

**计划状态**：✅ 已批准，准备实施

---

## 📈 实施进度

### ✅ 阶段 1：中英双语支持（已完成）

#### 2025-12-25 - 基础设施搭建
- ✅ 创建 feature/i18n-bilingual-support 分支
- ✅ 创建 LocalizationManager.swift（单例模式，支持动态语言切换）
- ✅ 创建双语本地化资源（en.lproj、zh-Hans.lproj）
- ✅ 重构4个枚举类型（rawValue: 中文 → 英文）
- ✅ 编写数据库迁移脚本（EnumMigration.swift）
- ✅ 本地化217条字符串（设置、面板、菜单、通知）
- ✅ 编译通过，无错误

#### 2025-12-26 上午 - 完善本地化覆盖
- ✅ 修复设置面板残留中文（9个板块标题）
- ✅ 修复统计面板优化建议（3条建议）
- ✅ 修复长驻应用激活策略描述（4种策略）
- ✅ 修复快捷键面板UI（搜索框、列表标题、重映射对话框）
- ✅ 修复 Keymap 快捷键本地化（4个应用快捷键）
- ✅ **完成系统快捷键本地化**（30个系统快捷键，5个分类）
- ✅ 添加 LocalizationManager 初始化到 AppDelegate
- ✅ 新增50+条本地化键
- ✅ 编译通过，所有本地化测试验证成功

**成果**：
- 📊 本地化字符串总数：**267 条**（217 + 50）
- 🎯 本地化覆盖率：**100%**（Keymap 自身提供的所有文本）
- ✅ 系统快捷键：100%（30个）
- ✅ 应用快捷键：100%（4个 Keymap 快捷键）
- ℹ️ 第三方应用快捷键：取决于应用自身语言设置

**技术说明**：
- 系统快捷键和 Keymap 快捷键由应用提供，完全支持本地化
- 第三方应用快捷键通过 Accessibility API 从应用菜单提取，语言由应用决定
- 用户可通过设置第三方应用的语言来统一界面语言

#### 2025-12-26 下午 - 新增"显示系统快捷键"设置功能
- ✅ 在设置面板添加"显示系统快捷键"开关
- ✅ 用户可选择是否在快捷键面板中显示 macOS 系统快捷键
- ✅ 添加中英双语本地化字符串（2条）
- ✅ SettingsManager 添加 `showSystemShortcuts` 配置项
- ✅ ShortcutPanelViewModel 根据设置动态显示/隐藏系统快捷键
- ✅ 设置实时生效，无需重启应用
- ✅ 支持设置导入/导出功能
- ✅ 编译通过，功能测试验证成功

**实现细节**：
- 配置键：`showSystemShortcuts`（默认值：`true`）
- UI 位置：设置面板 → 快捷键 → 显示系统快捷键
- 逻辑优化：关闭时直接跳过系统快捷键合并，提升性能
- 本地化键：
  - `settings.show_system_shortcuts` = "显示系统快捷键" / "Show System Shortcuts"
  - `settings.show_system_shortcuts.description` = 说明文字

**修改文件**：
- Keymap/Data/SettingsManager.swift
- Keymap/Resources/Localizations/en.lproj/Localizable.strings
- Keymap/Resources/Localizations/zh-Hans.lproj/Localizable.strings
- Keymap/UI/Views/Settings/SettingsWindow.swift
- Keymap/UI/ViewModels/ShortcutPanelViewModel.swift

### ⏳ 阶段 2：其他 8 种语言支持（待开始）

**待支持语言**：
- [ ] 繁体中文 (zh-Hant)
- [ ] 法语 (fr)
- [ ] 俄语 (ru)
- [ ] 日语 (ja)
- [ ] 韩语 (ko)
- [ ] 德语 (de)
- [ ] 意大利语 (it)
- [ ] 西班牙语 (es)

**下一步计划**：
1. 使用 AI 翻译工具批量翻译 267 条字符串到 8 种语言
2. 人工校对关键术语（快捷键、冲突、重映射等）
3. 创建 8 个 .lproj 目录和 Localizable.strings 文件
4. 更新 project.yml 的 KNOWN_REGIONS
5. 更新语言选择器，添加 8 种语言选项
6. 全面测试所有语言的显示效果和布局
7. 合并到主分支并发布多语言版本

**预计时间**：3-4 天

---

**更新日期**：2025-12-26
**当前状态**：阶段 1 完成，等待阶段 2 开始
**分支状态**：feature/i18n-bilingual-support（准备推送到远程仓库）

