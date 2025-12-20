# 🔧 Keymap 工具脚本

本目录包含 Keymap 项目的所有工具脚本和自动化工具。

## 📁 脚本列表

### 🏗️ 构建脚本
- **build_and_copy.sh** - 构建项目并复制到应用目录
  ```bash
  ./scripts/build_and_copy.sh
  ```

### 🚀 运行脚本
- **run.sh** - 快速运行应用
  ```bash
  ./scripts/run.sh
  ```

- **run_in_xcode.sh** - 在 Xcode 中运行（支持调试）
  ```bash
  ./scripts/run_in_xcode.sh
  ```

### 🧹 清理脚本
- **clean_metal_cache.sh** - 清理 Metal 着色器缓存
  ```bash
  ./scripts/clean_metal_cache.sh
  ```

### ✅ verify/ - 验证工具
- **verify-structure.sh** - 验证项目结构
  ```bash
  ./scripts/verify/verify-structure.sh
  ```

- **verify_shortcuts.swift** - 验证系统快捷键数量
  ```bash
  swift ./scripts/verify/verify_shortcuts.swift
  ```

## 📝 使用说明

### 开发工作流

1. **构建并运行**
   ```bash
   ./scripts/build_and_copy.sh
   ./scripts/run.sh
   ```

2. **Xcode 调试**
   ```bash
   ./scripts/run_in_xcode.sh
   ```

3. **清理缓存**（遇到图形问题时）
   ```bash
   ./scripts/clean_metal_cache.sh
   ```

4. **验证项目**（添加新文件后）
   ```bash
   ./scripts/verify/verify-structure.sh
   ```

## 🔗 相关链接

- [项目主页 README](../README.md)
- [快速开始指南](../QUICKSTART.md)
- [构建说明](../docs/development/BUILD_README.md)
