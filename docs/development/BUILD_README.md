# Keymap 构建和运行指南

## 📦 编译和复制应用

```bash
./build_and_copy.sh
```

这个脚本会：
1. ✅ 清理并编译项目
2. 🗑️  删除根目录下的旧版本 Keymap.app（如果存在）
3. 📦 将新编译的 Keymap.app 复制到项目根目录
4. ✅ 显示应用位置

## 🚀 快速运行应用

```bash
./run.sh
```

或直接：

```bash
open Keymap.app
```

## 🔍 查看运行日志

### 方法1: 使用控制台应用（推荐）

1. 打开 **控制台.app**（在 `/Applications/Utilities/` 中）
2. 在搜索框输入：`Keymap`
3. 查看实时日志，包括：
   - 🚀 全局监控启动状态
   - ⌘ 双击Cmd检测
   - 📊 统计数据加载
   - ❌ 错误信息

### 方法2: 使用终端（实时输出）

```bash
log stream --predicate 'process == "Keymap"' --level debug
```

## 🐛 调试技巧

### 查看最近的日志

```bash
log show --predicate 'process == "Keymap"' --last 5m
```

### 查看关键日志

```bash
# 查看全局监控相关日志
log show --predicate 'process == "Keymap" AND eventMessage CONTAINS "监控"' --last 5m

# 查看双击Cmd相关日志
log show --predicate 'process == "Keymap" AND eventMessage CONTAINS "Cmd"' --last 5m

# 查看权限相关日志
log show --predicate 'process == "Keymap" AND eventMessage CONTAINS "权限"' --last 5m
```

## 🔄 重新生成项目（添加新文件后）

```bash
xcodegen generate
```

## 🧹 清理缓存

```bash
# 清理 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Keymap-*

# 清理 UserDefaults 缓存
defaults delete com.yourcompany.Keymap
```

## 📝 常见问题

### Q: 编译失败怎么办？

```bash
# 查看详细编译日志
cat /tmp/keymap_build.log
```

### Q: 双击Cmd无反应？

1. 检查控制台是否有 `✅ 全局监控已启动`
2. 检查辅助功能权限是否授予
3. 查看日志中是否有 `⌘ 检测到双击Cmd`

### Q: 权限弹窗重复出现？

前往 `系统设置 → 隐私与安全性 → 辅助功能`，移除并重新添加 Keymap.app

## 🎯 关键日志标识

运行应用时，控制台应该显示：

```
✅ 辅助功能权限已授予
🚀 开始设置全局监控...
🔍 开始启动全局监控...
✅ 全局监控已启动         ← 必须看到这个
⌘ 检测到双击Cmd           ← 双击时应该出现
📊 统计周期: 本周          ← 打开统计窗口时出现
```

如果看不到这些日志，说明某个环节出问题了。
