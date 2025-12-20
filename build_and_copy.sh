#!/bin/bash

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔨 开始编译 Keymap...${NC}"

# 1. 清理并编译项目
xcodebuild -project Keymap.xcodeproj -scheme Keymap clean build > /tmp/keymap_build.log 2>&1

# 检查编译是否成功
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 编译成功${NC}"
    
    # 2. 删除根目录下的旧版本
    if [ -d "Keymap.app" ]; then
        echo -e "${YELLOW}🗑  删除旧版本 Keymap.app...${NC}"
        rm -rf Keymap.app
    fi
    
    # 3. 查找编译后的app文件
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Keymap-*/Build/Products/Debug -name "Keymap.app" -type d 2>/dev/null | head -n 1)
    
    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}❌ 找不到编译后的 Keymap.app${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}📦 复制 Keymap.app 到项目根目录...${NC}"
    echo -e "   源路径: ${APP_PATH}"
    
    # 4. 复制到根目录
    cp -R "$APP_PATH" .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 复制成功！${NC}"
        echo -e "${GREEN}📍 应用位置: $(pwd)/Keymap.app${NC}"
        echo ""
        echo -e "${YELLOW}运行应用:${NC}"
        echo -e "  ${GREEN}open Keymap.app${NC}"
    else
        echo -e "${RED}❌ 复制失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 编译失败${NC}"
    echo -e "${YELLOW}查看详细日志:${NC}"
    echo -e "  ${GREEN}cat /tmp/keymap_build.log${NC}"
    tail -20 /tmp/keymap_build.log
    exit 1
fi
