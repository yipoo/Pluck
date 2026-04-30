# Sparkle 自动更新集成指南

代码已就位(`Pluck/Services/UpdaterService.swift`),用 `#if canImport(Sparkle)` 保护,所以**没装依赖时也能 build**。要让"检查更新"真正工作,做下面这些步骤。

## 1. 在 Xcode 添加 Sparkle SPM 依赖

1. Xcode 打开 `Pluck.xcodeproj`
2. **File → Add Package Dependencies…**
3. URL 填:`https://github.com/sparkle-project/Sparkle`
4. Dependency Rule 选 **Up to Next Major Version**,起点填 `2.5.0`
5. Add Package
6. 弹窗确认 — `Sparkle` library 勾选,Add to Target = **Pluck**(只这一个,不要勾 Tests)

完成后 `#if canImport(Sparkle)` 分支自动生效,真正调用 Sparkle SDK。

## 2. 生成 EdDSA 签名密钥(只一次)

```bash
cd ~/Library/Developer/Xcode/DerivedData
# 找到 Sparkle 编译后的 generate_keys 工具
find . -name generate_keys -type f 2>/dev/null | head -1
# 例:./Pluck-xxxxx/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys

# 跑它,会把私钥写到 keychain,公钥打印出来
/path/to/generate_keys
```

输出大概像:

```
Public key: dKlUm7e6QqSgKTV...wq== (Base64 后 44 字符)
Private key 已写入 keychain:Sparkle Private Key
```

## 3. 把公钥贴进 Info.plist

打开 `Pluck/Info.plist`,把这一行的 placeholder 替换:

```xml
<key>SUPublicEDKey</key>
<string>__PASTE_ED_PUBLIC_KEY_HERE__</string>
```

改成:

```xml
<key>SUPublicEDKey</key>
<string>dKlUm7e6QqSgKTV...wq==</string>
```

> ⚠️ 公钥泄漏没事(它就是公开的);**私钥永远不要 commit**。它已在你 keychain。

## 4. 配 SUFeedURL

`Info.plist` 里:

```xml
<key>SUFeedURL</key>
<string>https://pluck.yipoo.com/appcast.xml</string>
```

改成你的真实域名(自己买的 .app 域名 / Vercel / Cloudflare Pages 都行)。

## 5. 维护 appcast.xml

每次发新版,在你的 CDN / 网站上更新 `appcast.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Pluck</title>
    <link>https://pluck.yipoo.com/appcast.xml</link>
    <description>Pluck 自动更新源</description>
    <language>zh-CN</language>

    <item>
      <title>Pluck 0.2.0</title>
      <pubDate>Sat, 21 Jun 2026 12:00:00 +0800</pubDate>
      <sparkle:version>2</sparkle:version>
      <sparkle:shortVersionString>0.2.0</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[
        <h2>新版本 0.2.0</h2>
        <ul>
          <li>新增标注功能(箭头/矩形/文字/马赛克)</li>
          <li>新增长截图(滚动拼接)</li>
          <li>修复多屏环境下的若干 bug</li>
        </ul>
      ]]></description>
      <enclosure
        url="https://pluck.yipoo.com/dl/Pluck-0.2.0.dmg"
        sparkle:edSignature="__sign_with_sign_update_tool__"
        length="12345678"
        type="application/octet-stream"/>
    </item>

    <!-- 老版本可以保留作历史记录,Sparkle 只看最新 -->
  </channel>
</rss>
```

### 用 sign_update 给 DMG 签名

跟 generate_keys 同目录还有 `sign_update`:

```bash
/path/to/sign_update path/to/Pluck-0.2.0.dmg
```

输出会给你 `sparkle:edSignature="..."` 那一行,复制贴进 appcast.xml。

## 6. 常见问题

### Q: SUEnableInstallerLauncherService 是干啥的?

Sparkle 2.x 在 Sandbox 下需要一个 XPC service 帮它替换 .app。我们关了它(`false`)— 简化方案:用户在弹窗里点"安装并重启",Sparkle 直接下载 + 替换 + 重启。这要求 App 用 Developer ID 签名,我们已经配了。

### Q: 用户怎么触发更新?

- 设置 → 通用 → "检查更新"(用户主动点)
- 自动:把 `SUEnableAutomaticChecks` 改成 `true`,Sparkle 每 24 小时自动检查一次

我们默认关掉自动检查,**契合"隐私优先"产品定位**。

### Q: 测试更新流程?

1. 你的网站上传 `appcast.xml`(版本号写得高些,如 99.0.0)
2. 同样位置放真 DMG(可以是任意旧 DMG)
3. 在 Pluck 设置点"检查更新"
4. Sparkle 应该弹"有新版"对话框

## 7. 不集成 Sparkle 的场景

如果你不想现在折腾,**`UpdaterService.swift` 的 `#else` 分支**会兜底:点"检查更新"会弹 NSAlert 引导用户去官网。这样用户体验不会断,你可以先不接 Sparkle。

接 Sparkle 是 v0.1.0 → 公测前的关键基础设施,迟早要做。但**不影响内测**(自己用一台 Mac 完全没必要)。
