#!/usr/bin/env bash
#
# build-dmg.sh — 构建 + 打包 Pluck 为可分发 DMG
#
# 用法:在 pluck/ 项目根运行
#   ./scripts/build-dmg.sh           # Release build,产出 dist/Pluck-X.Y.Z.dmg
#   SKIP_BUILD=1 ./scripts/build-dmg.sh  # 跳过 build,只重打包(用现有 .app)
#
# 必要环境:
#   - Xcode 命令行工具
#   - 可选:create-dmg(brew install create-dmg)— 没装会降级到 hdiutil
#
# 后续步骤(签名 / 公证)见 scripts/release.sh

set -euo pipefail

# ---------- 配置 ----------
PROJECT="Pluck.xcodeproj"
SCHEME="Pluck"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_NAME="Pluck"
BUILD_DIR="${BUILD_DIR:-build}"
DIST_DIR="${DIST_DIR:-dist}"

# ---------- 颜色 ----------
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; RESET='\033[0m'
log()  { echo -e "${GREEN}→${RESET} $*"; }
warn() { echo -e "${YELLOW}!${RESET} $*"; }
err()  { echo -e "${RED}✘${RESET} $*"; exit 1; }

# ---------- 检查 ----------
[ -f "$PROJECT/project.pbxproj" ] || err "找不到 $PROJECT。请在 pluck/ 项目根运行。"
command -v xcodebuild >/dev/null || err "xcodebuild 不可用,请装 Xcode 命令行工具:xcode-select --install"

mkdir -p "$BUILD_DIR" "$DIST_DIR"

# ---------- Build ----------

if [ "${SKIP_BUILD:-0}" = "0" ]; then
    log "构建 $CONFIGURATION..."
    if command -v xcbeautify >/dev/null 2>&1; then
        set +e
        xcodebuild \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -derivedDataPath "$BUILD_DIR" \
            clean build \
            | xcbeautify
        BUILD_RC=${PIPESTATUS[0]}
        set -e
    else
        set +e
        xcodebuild \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -derivedDataPath "$BUILD_DIR" \
            clean build \
            | tail -30
        BUILD_RC=${PIPESTATUS[0]}
        set -e
    fi
    [ "$BUILD_RC" -eq 0 ] || err "xcodebuild 失败(退出码 $BUILD_RC)"
fi

# ---------- 定位 .app(关键:动态查询,不假设路径)----------
# 项目可能自定义 BUILT_PRODUCTS_DIR(比如绝对路径),硬写路径会找不到
log "定位 $APP_NAME.app..."
BUILT_PRODUCTS_DIR=$(xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    -showBuildSettings 2>/dev/null \
    | awk -F ' = ' '/^[[:space:]]+BUILT_PRODUCTS_DIR = /{print $2; exit}')

APP_PATH="$BUILT_PRODUCTS_DIR/$APP_NAME.app"

# 兜底:如果 -showBuildSettings 没拿到 / .app 不在那,fallback 到默认 derivedData 路径
if [ ! -d "$APP_PATH" ]; then
    warn "BUILT_PRODUCTS_DIR 路径下没找到 .app,尝试常见位置..."
    for candidate in \
        "$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app" \
        "$HOME/Library/Developer/Xcode/DerivedData/Build/Products/$CONFIGURATION/$APP_NAME.app" \
        "$HOME/Library/Developer/Xcode/DerivedData/$APP_NAME"-*"/Build/Products/$CONFIGURATION/$APP_NAME.app"; do
        if [ -d "$candidate" ]; then
            APP_PATH="$candidate"
            break
        fi
    done
fi

[ -d "$APP_PATH" ] || err "找不到 $APP_NAME.app。检查:1) build 是否真成功,2) 项目是否自定义了 BUILT_PRODUCTS_DIR"
log ".app: $APP_PATH"

# ---------- 取版本 ----------
INFO_PLIST="$APP_PATH/Contents/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || echo "0.1.0")
BUILD_NUM=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$INFO_PLIST" 2>/dev/null || echo "1")
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

log "版本: $VERSION (build $BUILD_NUM)"
log "目标: $DMG_PATH"

[ -f "$DMG_PATH" ] && rm -f "$DMG_PATH"

# ---------- 打包 ----------
if command -v create-dmg >/dev/null 2>&1; then
    log "用 create-dmg(美观版)..."
    create-dmg \
        --volname "$APP_NAME $VERSION" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 175 200 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 425 200 \
        "$DMG_PATH" \
        "$APP_PATH" \
        || warn "create-dmg 报错,但 DMG 可能已生成"
else
    warn "create-dmg 没装,用 hdiutil 降级版"
    warn "推荐 brew install create-dmg 装上,DMG 更美观"

    STAGING="$BUILD_DIR/dmg-staging"
    rm -rf "$STAGING"
    mkdir -p "$STAGING"
    cp -R "$APP_PATH" "$STAGING/"
    ln -s /Applications "$STAGING/Applications"

    hdiutil create \
        -volname "$APP_NAME $VERSION" \
        -srcfolder "$STAGING" \
        -ov \
        -format UDZO \
        "$DMG_PATH" \
        | tail -3
fi

[ -f "$DMG_PATH" ] || err "DMG 打包失败"

# ---------- 完成报告 ----------
SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo ""
echo "─────────────────────────────────────────────"
log "✓ DMG 打包完成"
echo "  路径: $DMG_PATH"
echo "  大小: $SIZE"
echo "─────────────────────────────────────────────"
echo ""
echo "下一步(分发前必做):"
echo "  1. 签名验证: codesign -dvv \"$APP_PATH\""
echo "  2. 公证:     ./scripts/release.sh notarize \"$DMG_PATH\""
echo "  3. Staple:   xcrun stapler staple \"$DMG_PATH\""
echo "  4. 上传到自有 CDN / 七牛 / R2"
