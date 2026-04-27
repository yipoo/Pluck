# Pluck — Scripts

可执行脚本,用于图标生成和发布。在 `pluck/` 项目根运行。

## generate-app-icon.swift

程序化生成 macOS AppIcon(10 个尺寸 16-1024)。

```bash
swift scripts/generate-app-icon.swift
```

输出 → `Pluck/Assets.xcassets/AppIcon.appiconset/`(包含 Contents.json)

修改 brand:编辑脚本里的颜色和 SF Symbol 名,重跑即可。

## build-dmg.sh

构建 + 打包 Release 版 .app 为 DMG。

```bash
chmod +x scripts/build-dmg.sh
./scripts/build-dmg.sh
```

输出 → `dist/Pluck-X.Y.Z.dmg`

可选:`brew install create-dmg` 让 DMG 更美观(自定义窗口、图标位置、Applications 拖入提示)。

## release.sh

完整发布流程编排(构建 → DMG → 公证 → Staple → 验证)。

### 一次性配置(只做一遍)

把 Apple 公证凭证存进 keychain:

```bash
xcrun notarytool store-credentials "Pluck-Notary" \
    --apple-id "your@apple.id" \
    --team-id "CX3VYP5JYR" \
    --password "app-specific-password"
```

> App-specific password 在 https://appleid.apple.com → 安全 → 应用专用密码 中生成。

### 子命令

```bash
./scripts/release.sh build              # 只 Release build
./scripts/release.sh dmg                # 只打 DMG
./scripts/release.sh notarize <dmg>     # 公证
./scripts/release.sh staple <dmg>       # 装订公证票据
./scripts/release.sh verify <dmg>       # 验证签名 + 公证状态
./scripts/release.sh full 0.1.0         # 一条龙(build + dmg + notarize + staple + verify)
```

### 一条龙发布

```bash
./scripts/release.sh full 0.1.0
```

跑完会得到 `dist/Pluck-0.1.0.dmg`,在干净 Mac 双击即可运行。

## 常见问题

### Q: 公证失败 / 卡很久

跑 `xcrun notarytool log <submission-id> --keychain-profile Pluck-Notary` 看具体原因。常见:
- entitlements 与 sandbox 不一致
- Hardened Runtime 没开
- 二进制没用 Developer ID 签名

### Q: 签名 identity 找不到

```bash
security find-identity -v -p codesigning
```
看是否有 `Developer ID Application: ...` 这条。没有的话去 Apple Developer 网站申请证书。

### Q: 只想测 DMG 是否正常打开

```bash
hdiutil attach dist/Pluck-0.1.0.dmg
# 双击 .app 应能启动(若 macOS 报"无法验证开发者",说明公证还没做或失败)
```
