#!/usr/bin/env bash
#
# release.sh — Pluck 发布流程编排
#
# 子命令:
#   build              构建 Release .app
#   dmg                打包 DMG(调用 build-dmg.sh)
#   notarize <dmg>     公证 DMG(需要 keychain 中的 notary credentials)
#   staple <dmg>       Staple 公证票据到 DMG
#   verify <dmg>       验证签名 + 公证状态
#   full <version>     完整流程:build → dmg → notarize → staple → verify
#
# 公证前置:把凭证存到 keychain,运行一次:
#   xcrun notarytool store-credentials "Pluck-Notary" \
#       --apple-id "your@apple.id" \
#       --team-id "CX3VYP5JYR" \
#       --password "app-specific-password"

set -euo pipefail

# ---------- 配置 ----------
NOTARY_PROFILE="${NOTARY_PROFILE:-Pluck-Notary}"
TEAM_ID="${TEAM_ID:-CX3VYP5JYR}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application}"

# ---------- 工具 ----------
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; RESET='\033[0m'
log()  { echo -e "${GREEN}→${RESET} $*"; }
warn() { echo -e "${YELLOW}!${RESET} $*"; }
err()  { echo -e "${RED}✘${RESET} $*"; exit 1; }

usage() {
    sed -n '3,18p' "$0" | sed 's/^# \?//'
    exit 1
}

# ---------- 子命令 ----------

cmd_build() {
    log "构建 Release..."
    xcodebuild -project Pluck.xcodeproj -scheme Pluck -configuration Release \
        -derivedDataPath build clean build | tail -5
    log "✓ 构建完成: build/Build/Products/Release/Pluck.app"
}

cmd_dmg() {
    SKIP_BUILD=0 ./scripts/build-dmg.sh
}

cmd_notarize() {
    DMG="${1:-}"
    [ -f "$DMG" ] || err "找不到 DMG: $DMG"
    log "提交 $DMG 给 Apple 公证(可能 1-30 分钟)..."

    xcrun notarytool submit "$DMG" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait \
        || err "公证失败 — 检查 'xcrun notarytool log <submission-id>'"

    log "✓ 公证通过"
}

cmd_staple() {
    DMG="${1:-}"
    [ -f "$DMG" ] || err "找不到 DMG: $DMG"
    log "Staple 公证票据到 $DMG..."
    xcrun stapler staple "$DMG"
    log "✓ Staple 完成"
}

cmd_verify() {
    DMG="${1:-}"
    [ -f "$DMG" ] || err "找不到 DMG: $DMG"
    log "验证 $DMG..."
    echo ""
    echo "── codesign 检查 ──"
    spctl -a -t open --context context:primary-signature -vv "$DMG" || warn "spctl 验证失败"
    echo ""
    echo "── stapler 检查 ──"
    xcrun stapler validate "$DMG" || warn "stapler 验证失败"
    echo ""
    log "✓ 验证完成"
}

cmd_full() {
    VERSION="${1:-}"
    [ -n "$VERSION" ] || err "用法: $0 full <version>(例如 0.1.0)"

    log "完整发布流程:v$VERSION"
    log "  ⚠️  确保 Info.plist 的 CFBundleShortVersionString = $VERSION"
    sleep 2

    cmd_build
    cmd_dmg

    DMG="dist/Pluck-$VERSION.dmg"
    [ -f "$DMG" ] || err "DMG 不在预期路径: $DMG"

    cmd_notarize "$DMG"
    cmd_staple "$DMG"
    cmd_verify "$DMG"

    echo ""
    echo "═══════════════════════════════════════════════"
    log "🎉 发布就绪: $DMG"
    echo ""
    echo "上传清单:"
    echo "  • 自有官网下载页 → $DMG"
    echo "  • Sparkle appcast.xml 更新版本号 + 链接"
    echo "  • GitHub Release(可选)"
    echo "  • 内测群通知"
    echo "═══════════════════════════════════════════════"
}

# ---------- 派发 ----------

CMD="${1:-}"
shift || true

case "$CMD" in
    build)    cmd_build "$@" ;;
    dmg)      cmd_dmg "$@" ;;
    notarize) cmd_notarize "$@" ;;
    staple)   cmd_staple "$@" ;;
    verify)   cmd_verify "$@" ;;
    full)     cmd_full "$@" ;;
    -h|--help|"") usage ;;
    *) err "未知命令: $CMD"; usage ;;
esac
