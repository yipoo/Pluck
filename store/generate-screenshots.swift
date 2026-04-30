#!/usr/bin/env swift

// 程序化生成 App Store Connect 上架截图
// 6 场景 × 4 尺寸 = 24 PNG
// 跑法:cd 到 pluck/ 项目根 → `swift store/generate-screenshots.swift`

import AppKit
import Foundation
import CoreGraphics

// MARK: - 配置

let sizes: [(w: Int, h: Int)] = [
    (1280, 800),
    (1440, 900),
    (2560, 1600),
    (2880, 1800),
]

let outputBase = "store/screenshots"

// MARK: - Brand 调色

let brandBlue       = NSColor(red:   0/255, green: 102/255, blue: 230/255, alpha: 1)
let brandBlueLight  = NSColor(red:  78/255, green: 168/255, blue: 255/255, alpha: 1)
let brandBgDark     = NSColor(red:   5/255, green:   8/255, blue:  15/255, alpha: 1)
let brandBgDeep     = NSColor(red:  10/255, green:  16/255, blue:  32/255, alpha: 1)
let brandPurple     = NSColor(red: 175/255, green:  82/255, blue: 222/255, alpha: 1)
let brandGreen      = NSColor(red:  52/255, green: 199/255, blue:  89/255, alpha: 1)
let brandOrange     = NSColor(red: 255/255, green: 149/255, blue:   0/255, alpha: 1)
let brandRed        = NSColor(red: 255/255, green:  59/255, blue:  48/255, alpha: 1)

let textPrimary  = NSColor.white
let textSoft     = NSColor(white: 1, alpha: 0.78)
let textMute     = NSColor(white: 1, alpha: 0.55)
let textTertiary = NSColor(white: 1, alpha: 0.35)

// MARK: - Bitmap 工厂

func makeBitmap(width: Int, height: Int) -> NSBitmapImageRep {
    NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 32
    )!
}

func saveBitmap(_ bitmap: NSBitmapImageRep, to path: String) throws {
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ss", code: 1)
    }
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

// MARK: - 绘制工具

/// 画文本 — 默认左下基线
func drawText(_ s: String, at p: CGPoint,
              fontSize: CGFloat, weight: NSFont.Weight = .regular,
              color: NSColor) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
    ]
    NSAttributedString(string: s, attributes: attrs).draw(at: p)
}

/// 画居中文本(在给定 rect 中)
@discardableResult
func drawCentered(_ s: String, in rect: CGRect,
                  fontSize: CGFloat, weight: NSFont.Weight = .regular,
                  color: NSColor) -> CGSize {
    let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: para,
    ]
    let str = NSAttributedString(string: s, attributes: attrs)
    let size = str.boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                                options: [.usesLineFragmentOrigin, .usesFontLeading]).size
    let drawRect = CGRect(
        x: rect.minX,
        y: rect.midY - size.height / 2,
        width: rect.width,
        height: size.height
    )
    str.draw(in: drawRect)
    return size
}

/// 圆角矩形(描边 / 填充均可)
func drawRRect(_ rect: CGRect, radius: CGFloat,
               fill: NSColor? = nil,
               stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    if let fill = fill {
        fill.setFill()
        path.fill()
    }
    if let stroke = stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

/// 线性渐变(角度,以度数,0=从左到右,90=从下到上)
func drawLinearGradient(in rect: CGRect, colors: [NSColor], angle: CGFloat) {
    let g = NSGradient(colors: colors)!
    g.draw(in: rect, angle: angle)
}

/// 径向渐变,以 center 为中心
func drawRadialGradient(in rect: CGRect, colors: [NSColor], center: CGPoint, radius: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let cgColors = colors.map { $0.cgColor } as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    guard let g = CGGradient(colorsSpace: space, colors: cgColors, locations: nil) else { return }
    ctx.saveGState()
    ctx.addRect(rect)
    ctx.clip()
    ctx.drawRadialGradient(g, startCenter: center, startRadius: 0,
                           endCenter: center, endRadius: radius,
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

/// SF Symbol → NSImage(配色 + 大小)
func sfSymbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight = .semibold,
              color: NSColor) -> NSImage? {
    let conf = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        .applying(.init(paletteColors: [color]))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(conf)
}

func drawSymbol(_ name: String, in rect: CGRect, weight: NSFont.Weight = .semibold,
                color: NSColor) {
    guard let img = sfSymbol(name, pointSize: rect.height * 0.85,
                             weight: weight, color: color) else { return }
    let drawRect = CGRect(
        x: rect.midX - img.size.width / 2,
        y: rect.midY - img.size.height / 2,
        width: img.size.width,
        height: img.size.height
    )
    img.draw(in: drawRect)
}

/// Brand logo(渐变圆角 + 白色 viewfinder)
func drawBrandLogo(in rect: CGRect) {
    drawRRect(rect, radius: rect.width * 0.225)
    let path = NSBezierPath(roundedRect: rect,
                            xRadius: rect.width * 0.225,
                            yRadius: rect.width * 0.225)
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    drawLinearGradient(in: rect, colors: [brandBlueLight, brandBlue], angle: -90)
    NSGraphicsContext.restoreGraphicsState()
    drawSymbol("camera.viewfinder",
               in: rect.insetBy(dx: rect.width * 0.20, dy: rect.height * 0.20),
               color: textPrimary)
}

/// 阴影包装
func withShadow(color: NSColor, offset: NSSize, blur: CGFloat, _ block: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowOffset = offset
    shadow.shadowBlurRadius = blur
    shadow.set()
    block()
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: - 共用:背景

func drawBrandBackground(_ size: CGSize) {
    let bgRect = CGRect(origin: .zero, size: size)
    NSColor(red: 8/255, green: 14/255, blue: 28/255, alpha: 1).setFill()
    bgRect.fill()
    drawRadialGradient(
        in: bgRect,
        colors: [
            NSColor(red: 0/255, green: 102/255, blue: 230/255, alpha: 0.45),
            NSColor(red: 5/255, green: 8/255, blue: 15/255, alpha: 0)
        ],
        center: CGPoint(x: size.width * 0.30, y: size.height * 0.85),
        radius: size.width * 0.55
    )
    drawRadialGradient(
        in: bgRect,
        colors: [
            NSColor(red: 175/255, green: 82/255, blue: 222/255, alpha: 0.35),
            NSColor(red: 5/255, green: 8/255, blue: 15/255, alpha: 0)
        ],
        center: CGPoint(x: size.width * 0.85, y: size.height * 0.20),
        radius: size.width * 0.50
    )
    // subtle grain — 用细密点格
    let pattern = NSColor.white.withAlphaComponent(0.012)
    pattern.setFill()
    let grain: CGFloat = 4
    for x in stride(from: 0, to: size.width, by: grain * 2) {
        for y in stride(from: 0, to: size.height, by: grain * 2) {
            CGRect(x: x, y: y, width: 1, height: 1).fill()
        }
    }
}

// MARK: - 场景 1:Hero

func renderHero(_ size: CGSize) {
    drawBrandBackground(size)

    // Brand 行 — 顶部居中
    let logoSize = size.height * 0.12
    let logoX = size.width / 2 - logoSize / 2
    let logoY = size.height * 0.78
    let logoRect = CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize)
    withShadow(color: brandBlue.withAlphaComponent(0.5),
               offset: NSSize(width: 0, height: -size.height * 0.005),
               blur: size.height * 0.025) {
        drawBrandLogo(in: logoRect)
    }

    // 主标题
    let titleFont = size.width * 0.062
    drawCentered(
        "本地优先的截图 OCR",
        in: CGRect(x: 0, y: size.height * 0.50, width: size.width, height: titleFont * 1.2),
        fontSize: titleFont, weight: .bold, color: textPrimary
    )

    // 副标题
    let subFont = size.width * 0.024
    drawCentered(
        "拖动选择  →  自动识别  →  进剪贴板",
        in: CGRect(x: 0, y: size.height * 0.41, width: size.width, height: subFont * 1.5),
        fontSize: subFont, weight: .regular, color: textSoft
    )

    // 三个胶囊 badge
    let badges: [(symbol: String, label: String, color: NSColor)] = [
        ("lock.shield.fill", "完全本地", brandGreen),
        ("wifi.slash", "0 网络请求", brandBlueLight),
        ("eye.slash.fill", "0 追踪", brandPurple),
    ]
    let badgeFontSize = size.width * 0.014
    let badgeHeight = size.height * 0.052
    let badgeY = size.height * 0.27
    let totalWidth = size.width * 0.55
    let badgeWidth = totalWidth / 3
    for (i, badge) in badges.enumerated() {
        let bx = size.width / 2 - totalWidth / 2 + CGFloat(i) * badgeWidth + badgeWidth * 0.10
        let bw = badgeWidth * 0.80
        let rect = CGRect(x: bx, y: badgeY, width: bw, height: badgeHeight)
        drawRRect(rect,
                  radius: badgeHeight / 2,
                  fill: NSColor.white.withAlphaComponent(0.06),
                  stroke: NSColor.white.withAlphaComponent(0.18),
                  lineWidth: 1)
        // icon
        let iconSize = badgeHeight * 0.50
        drawSymbol(badge.symbol,
                   in: CGRect(x: bx + badgeHeight * 0.30,
                              y: badgeY + (badgeHeight - iconSize) / 2,
                              width: iconSize, height: iconSize),
                   color: badge.color)
        // label
        let label = NSAttributedString(string: badge.label, attributes: [
            .font: NSFont.systemFont(ofSize: badgeFontSize, weight: .medium),
            .foregroundColor: textSoft
        ])
        let labelSize = label.size()
        label.draw(at: CGPoint(
            x: bx + badgeHeight * 0.30 + iconSize + badgeHeight * 0.20,
            y: badgeY + (badgeHeight - labelSize.height) / 2
        ))
    }

    // 底部 brand
    drawCentered(
        "Pluck  ·  for macOS 14+",
        in: CGRect(x: 0, y: size.height * 0.10,
                   width: size.width, height: size.width * 0.020 * 1.5),
        fontSize: size.width * 0.014, weight: .medium, color: textTertiary
    )
}

// MARK: - 场景 2:Region Capture overlay

func renderCapture(_ size: CGSize) {
    // 模拟桌面背景
    drawLinearGradient(in: CGRect(origin: .zero, size: size),
                       colors: [NSColor(red: 22/255, green: 28/255, blue: 45/255, alpha: 1),
                                NSColor(red: 8/255, green: 12/255, blue: 22/255, alpha: 1)],
                       angle: -90)
    // 假窗口装饰
    drawFakeWindow(at: CGRect(x: size.width * 0.10, y: size.height * 0.18,
                              width: size.width * 0.80, height: size.height * 0.65),
                   title: "Pluck 截图 OCR")

    // 半透明蒙版
    NSColor(white: 0, alpha: 0.40).setFill()
    CGRect(origin: .zero, size: size).fill()

    // 选区框
    let selW = size.width * 0.50
    let selH = size.height * 0.32
    let selRect = CGRect(
        x: size.width / 2 - selW / 2,
        y: size.height / 2 - selH / 2,
        width: selW, height: selH
    )
    NSColor.white.withAlphaComponent(0.04).setFill()
    selRect.fill()
    let path = NSBezierPath(rect: selRect)
    path.lineWidth = 1.6
    NSColor.white.setStroke()
    path.stroke()

    // 尺寸标签
    let sizeStr = "\(Int(selRect.width)) × \(Int(selRect.height))"
    let labelFont = NSFont.monospacedSystemFont(ofSize: size.width * 0.012, weight: .semibold)
    let labelAttr = NSAttributedString(string: sizeStr, attributes: [
        .font: labelFont,
        .foregroundColor: NSColor.white,
    ])
    let lSize = labelAttr.size()
    let lRect = CGRect(
        x: selRect.midX - lSize.width / 2 - 8,
        y: selRect.maxY + 8,
        width: lSize.width + 16, height: lSize.height + 8
    )
    drawRRect(lRect, radius: 4, fill: NSColor.black.withAlphaComponent(0.75))
    labelAttr.draw(at: CGPoint(x: lRect.minX + 8, y: lRect.minY + 4))

    // 中心提示
    let hintRect = CGRect(x: 0, y: size.height * 0.12,
                          width: size.width, height: size.height * 0.06)
    drawCentered("拖动选择区域  ·  ESC 取消",
                 in: hintRect, fontSize: size.width * 0.018,
                 weight: .medium, color: textPrimary)

    // 顶部标题
    drawCentered("⌃⌥A   全局热键 · 任意 App 都能截",
                 in: CGRect(x: 0, y: size.height * 0.86,
                            width: size.width, height: size.height * 0.06),
                 fontSize: size.width * 0.020, weight: .semibold, color: textSoft)
}

// MARK: - 场景 3:OCR result

func renderOCR(_ size: CGSize) {
    drawBrandBackground(size)

    // 标题
    drawCentered("Apple Vision · 中文 95%+ 准确率",
                 in: CGRect(x: 0, y: size.height * 0.84,
                            width: size.width, height: size.height * 0.06),
                 fontSize: size.width * 0.026, weight: .semibold, color: textPrimary)
    drawCentered("毫秒级识别 · 直接进剪贴板",
                 in: CGRect(x: 0, y: size.height * 0.78,
                            width: size.width, height: size.height * 0.04),
                 fontSize: size.width * 0.016, color: textMute)

    // 左右两卡
    let cardY = size.height * 0.20
    let cardH = size.height * 0.50
    let cardW = size.width * 0.36

    // 左:截到的文字图(假装)
    let leftRect = CGRect(x: size.width * 0.07, y: cardY,
                          width: cardW, height: cardH)
    drawRRect(leftRect, radius: 12,
              fill: NSColor.white.withAlphaComponent(0.06),
              stroke: NSColor.white.withAlphaComponent(0.12), lineWidth: 1)
    // 假装是文档内容
    drawText("RESEARCH NOTE  ·  2026-04",
             at: CGPoint(x: leftRect.minX + 24, y: leftRect.maxY - 36),
             fontSize: size.width * 0.011, weight: .medium, color: textTertiary)
    drawText("拖动鼠标选择",
             at: CGPoint(x: leftRect.minX + 24, y: leftRect.maxY - 80),
             fontSize: size.width * 0.025, weight: .bold, color: textPrimary)
    drawText("屏幕任意区域",
             at: CGPoint(x: leftRect.minX + 24, y: leftRect.maxY - 124),
             fontSize: size.width * 0.025, weight: .bold, color: textPrimary)
    drawText("文字会被自动识别 → 直接进剪贴板",
             at: CGPoint(x: leftRect.minX + 24, y: leftRect.maxY - 168),
             fontSize: size.width * 0.014, color: textSoft)
    drawText("OCR 引擎:Apple Vision",
             at: CGPoint(x: leftRect.minX + 24, y: leftRect.minY + 24),
             fontSize: size.width * 0.012, color: textMute)
    // 选区蓝框模拟"选中"
    let selRect2 = CGRect(x: leftRect.minX + 18, y: leftRect.maxY - 138,
                          width: cardW - 36, height: 80)
    let selPath = NSBezierPath(rect: selRect2)
    selPath.lineWidth = 1.6
    brandBlueLight.setStroke()
    selPath.stroke()

    // 中间箭头
    let arrowY = cardY + cardH / 2
    let arrowX1 = leftRect.maxX + 16
    let arrowX2 = size.width * 0.57 - 16
    drawSymbol("arrow.right",
               in: CGRect(x: (arrowX1 + arrowX2) / 2 - 30, y: arrowY - 30,
                          width: 60, height: 60),
               color: textSoft)

    // 右:剪贴板内容 + 通知
    let rightRect = CGRect(x: size.width * 0.57, y: cardY,
                           width: cardW, height: cardH)
    drawRRect(rightRect, radius: 12,
              fill: NSColor.white.withAlphaComponent(0.06),
              stroke: NSColor.white.withAlphaComponent(0.12), lineWidth: 1)
    drawText("剪贴板",
             at: CGPoint(x: rightRect.minX + 24, y: rightRect.maxY - 36),
             fontSize: size.width * 0.011, weight: .medium, color: textTertiary)
    drawText("拖动鼠标选择屏幕任意区域文字",
             at: CGPoint(x: rightRect.minX + 24, y: rightRect.maxY - 80),
             fontSize: size.width * 0.020, weight: .medium, color: textPrimary)
    drawText("会被自动识别 → 直接进剪贴板",
             at: CGPoint(x: rightRect.minX + 24, y: rightRect.maxY - 116),
             fontSize: size.width * 0.020, weight: .medium, color: textPrimary)

    // 通知:已复制
    let notifRect = CGRect(x: rightRect.minX + 24, y: rightRect.minY + 24,
                           width: rightRect.width - 48, height: 56)
    drawRRect(notifRect, radius: 8, fill: brandGreen.withAlphaComponent(0.18),
              stroke: brandGreen.withAlphaComponent(0.40), lineWidth: 1)
    drawSymbol("checkmark.circle.fill",
               in: CGRect(x: notifRect.minX + 16, y: notifRect.minY + 14,
                          width: 28, height: 28),
               color: brandGreen)
    drawText("已写入剪贴板  ·  29 字符",
             at: CGPoint(x: notifRect.minX + 56, y: notifRect.minY + 19),
             fontSize: size.width * 0.013, weight: .semibold, color: textPrimary)
}

// MARK: - 场景 4:Clipboard history

func renderClipboard(_ size: CGSize) {
    drawBrandBackground(size)
    drawCentered("完整剪贴板历史 · 全文搜索",
                 in: CGRect(x: 0, y: size.height * 0.86,
                            width: size.width, height: size.height * 0.06),
                 fontSize: size.width * 0.026, weight: .semibold, color: textPrimary)
    drawCentered("文本 · 图片 · 文件  ·  100 条结果 < 100ms",
                 in: CGRect(x: 0, y: size.height * 0.80,
                            width: size.width, height: size.height * 0.04),
                 fontSize: size.width * 0.016, color: textMute)

    // 3-pane mockup
    let winRect = CGRect(x: size.width * 0.06, y: size.height * 0.12,
                         width: size.width * 0.88, height: size.height * 0.62)
    withShadow(color: NSColor.black.withAlphaComponent(0.5),
               offset: NSSize(width: 0, height: -size.height * 0.01),
               blur: size.width * 0.025) {
        drawRRect(winRect, radius: 14,
                  fill: NSColor(white: 0.13, alpha: 1),
                  stroke: NSColor.white.withAlphaComponent(0.10), lineWidth: 1)
    }
    // titlebar
    let tbRect = CGRect(x: winRect.minX, y: winRect.maxY - 32,
                        width: winRect.width, height: 32)
    NSColor(white: 0.16, alpha: 1).setFill()
    NSBezierPath(roundedRect: tbRect, xRadius: 14, yRadius: 14).fill()
    let dotR: CGFloat = 6
    let dotY = tbRect.midY - dotR / 2
    [(NSColor(red: 1, green: 0.37, blue: 0.34, alpha: 1), 16),
     (NSColor(red: 1, green: 0.74, blue: 0.18, alpha: 1), 32),
     (NSColor(red: 0.15, green: 0.79, blue: 0.25, alpha: 1), 48)]
        .forEach { c, x in
            c.setFill()
            CGRect(x: tbRect.minX + CGFloat(x), y: dotY + 8,
                   width: dotR * 1.7, height: dotR * 1.7).fill()
        }
    drawCentered("Pluck", in: tbRect, fontSize: 12, weight: .semibold, color: textSoft)

    // sidebar
    let sbW: CGFloat = winRect.width * 0.18
    let sbRect = CGRect(x: winRect.minX, y: winRect.minY,
                        width: sbW, height: winRect.height - 32)
    NSColor(white: 0.10, alpha: 1).setFill()
    sbRect.fill()
    let sidebarItems: [(icon: String, label: String, count: String, hot: Bool)] = [
        ("tray.full", "全部", "152", true),
        ("text.alignleft", "文本", "98", false),
        ("photo", "图片", "32", false),
        ("doc", "文件", "22", false),
        ("camera.viewfinder", "截图历史", "47", false),
    ]
    let rowH = sbRect.height / CGFloat(sidebarItems.count + 2)
    var rowY = sbRect.maxY - rowH
    for item in sidebarItems {
        let row = CGRect(x: sbRect.minX + 8, y: rowY - 8,
                         width: sbW - 16, height: rowH * 0.7)
        if item.hot {
            drawRRect(row, radius: 5, fill: NSColor.white.withAlphaComponent(0.08))
        }
        let iconSize: CGFloat = row.height * 0.45
        drawSymbol(item.icon,
                   in: CGRect(x: row.minX + 8, y: row.midY - iconSize / 2,
                              width: iconSize, height: iconSize),
                   color: item.hot ? textPrimary : textMute)
        let labelFont = NSFont.systemFont(ofSize: size.width * 0.011, weight: .medium)
        NSAttributedString(string: item.label, attributes: [
            .font: labelFont, .foregroundColor: item.hot ? textPrimary : textSoft
        ]).draw(at: CGPoint(x: row.minX + 8 + iconSize + 8,
                            y: row.midY - labelFont.pointSize * 0.6))
        let countAttr = NSAttributedString(string: item.count, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: size.width * 0.009, weight: .regular),
            .foregroundColor: textTertiary
        ])
        let cs = countAttr.size()
        countAttr.draw(at: CGPoint(x: row.maxX - cs.width - 8,
                                   y: row.midY - cs.height / 2))
        rowY -= rowH * 0.7 + 4
    }

    // list
    let listW = winRect.width * 0.34
    let listRect = CGRect(x: sbRect.maxX, y: winRect.minY,
                          width: listW, height: winRect.height - 32)
    NSColor(white: 0.13, alpha: 1).setFill()
    listRect.fill()
    let mockClips: [(kind: String, content: String, time: String, color: NSColor)] = [
        ("文本", "今天调研了银发市场 → 适老化 App 增速 350%...", "刚刚", brandBlueLight),
        ("文本", "Pluck = 全本地隐私 + 一站式工作流 + AI 增强(可选)", "2 分钟前", brandBlueLight),
        ("图片", "[图片]  截图  1280×800", "8 分钟前", brandGreen),
        ("文件", "/Users/.../docs/PRD.md", "12 分钟前", brandOrange),
        ("文本", "ScreenCaptureKit + Vision Framework", "1 小时前", brandBlueLight),
    ]
    let cellH = (listRect.height - 16) / CGFloat(mockClips.count) - 4
    var cellY = listRect.maxY - cellH - 8
    for (i, clip) in mockClips.enumerated() {
        let cell = CGRect(x: listRect.minX + 8, y: cellY,
                          width: listRect.width - 16, height: cellH - 4)
        if i == 1 {
            drawRRect(cell, radius: 6, fill: brandBlue.withAlphaComponent(0.20))
        } else {
            drawRRect(cell, radius: 6, fill: .clear,
                      stroke: NSColor.white.withAlphaComponent(0.05), lineWidth: 0.5)
        }
        // type chip
        let chipText = clip.kind
        let chipFont = NSFont.systemFont(ofSize: size.width * 0.008, weight: .semibold)
        let chip = NSAttributedString(string: chipText, attributes: [
            .font: chipFont, .foregroundColor: clip.color
        ])
        let cs = chip.size()
        let chipBg = CGRect(x: cell.minX + 10, y: cell.maxY - 8 - cs.height - 4,
                            width: cs.width + 12, height: cs.height + 4)
        drawRRect(chipBg, radius: 6, fill: clip.color.withAlphaComponent(0.18))
        chip.draw(at: CGPoint(x: chipBg.minX + 6, y: chipBg.minY + 2))

        // 内容
        let contentFont = NSFont.systemFont(ofSize: size.width * 0.010, weight: .regular)
        NSAttributedString(string: clip.content, attributes: [
            .font: contentFont,
            .foregroundColor: textPrimary
        ]).draw(in: CGRect(x: cell.minX + 10, y: cell.minY + cell.height * 0.30,
                           width: cell.width - 90, height: contentFont.pointSize * 1.3))

        // 时间
        let timeFont = NSFont.systemFont(ofSize: size.width * 0.008, weight: .regular)
        let time = NSAttributedString(string: clip.time, attributes: [
            .font: timeFont, .foregroundColor: textTertiary
        ])
        let ts = time.size()
        time.draw(at: CGPoint(x: cell.maxX - ts.width - 10, y: cell.maxY - 8 - ts.height))
        cellY -= cellH
    }

    // detail pane
    let detailRect = CGRect(x: listRect.maxX, y: winRect.minY,
                            width: winRect.maxX - listRect.maxX, height: winRect.height - 32)
    NSColor(white: 0.11, alpha: 1).setFill()
    detailRect.fill()

    // header
    let headerY = detailRect.maxY - 60
    let badgeRect = CGRect(x: detailRect.minX + 24, y: headerY,
                           width: 50, height: 22)
    drawRRect(badgeRect, radius: 11, fill: brandBlueLight.withAlphaComponent(0.22))
    drawText("文本",
             at: CGPoint(x: badgeRect.minX + 12, y: badgeRect.minY + 4),
             fontSize: size.width * 0.009, weight: .semibold, color: brandBlueLight)
    drawText("Pluck",
             at: CGPoint(x: badgeRect.maxX + 14, y: badgeRect.minY + 4),
             fontSize: size.width * 0.011, color: textMute)
    drawText("2026-04-27 16:42:18",
             at: CGPoint(x: detailRect.minX + 24, y: headerY - 22),
             fontSize: size.width * 0.009, color: textTertiary)
    // 分隔线
    NSColor.white.withAlphaComponent(0.10).setFill()
    CGRect(x: detailRect.minX, y: headerY - 32, width: detailRect.width, height: 1).fill()

    // body
    let bodyText = "Pluck = 全本地隐私 + 一站式工作流 + AI 增强(可选)\n\n• 拖动选择 → Apple Vision 自动识别中英文\n• ⌃⌥V 历史窗口 LIKE 模糊搜索\n• 0 外部 SDK · 0 网络请求 · 0 用户追踪"
    let bodyFont = NSFont.systemFont(ofSize: size.width * 0.012, weight: .regular)
    NSAttributedString(string: bodyText, attributes: [
        .font: bodyFont,
        .foregroundColor: textSoft,
    ]).draw(in: CGRect(x: detailRect.minX + 24, y: detailRect.minY + 60,
                       width: detailRect.width - 48, height: headerY - 32 - 60 - 30))

    // bottom action
    let actionRect = CGRect(x: detailRect.minX + 24, y: detailRect.minY + 16,
                            width: 130, height: 32)
    drawRRect(actionRect, radius: 6, fill: brandBlue)
    drawSymbol("doc.on.doc",
               in: CGRect(x: actionRect.minX + 12, y: actionRect.midY - 8,
                          width: 16, height: 16),
               color: textPrimary)
    drawText("复制到剪贴板",
             at: CGPoint(x: actionRect.minX + 36, y: actionRect.minY + 8),
             fontSize: size.width * 0.011, weight: .semibold, color: textPrimary)
}

// MARK: - 场景 5:Annotation

func renderSnapshots(_ size: CGSize) {
    drawBrandBackground(size)
    drawCentered("标注 · 高亮 · 一键导出",
                 in: CGRect(x: 0, y: size.height * 0.86,
                            width: size.width, height: size.height * 0.06),
                 fontSize: size.width * 0.026, weight: .semibold, color: textPrimary)
    drawCentered("矩形 / 箭头 / 高亮 / 文本  +  调色板 + 撤销重做",
                 in: CGRect(x: 0, y: size.height * 0.80,
                            width: size.width, height: size.height * 0.04),
                 fontSize: size.width * 0.016, color: textMute)

    // mock window
    let winRect = CGRect(x: size.width * 0.10, y: size.height * 0.10,
                         width: size.width * 0.80, height: size.height * 0.65)
    withShadow(color: NSColor.black.withAlphaComponent(0.5),
               offset: NSSize(width: 0, height: -size.height * 0.01),
               blur: size.width * 0.022) {
        drawRRect(winRect, radius: 14,
                  fill: NSColor(white: 0.10, alpha: 1),
                  stroke: NSColor.white.withAlphaComponent(0.10), lineWidth: 1)
    }
    // titlebar with toolbar
    let tbH: CGFloat = 56
    let tbRect = CGRect(x: winRect.minX, y: winRect.maxY - tbH,
                        width: winRect.width, height: tbH)
    NSColor(white: 0.13, alpha: 1).setFill()
    NSBezierPath(roundedRect: tbRect, xRadius: 14, yRadius: 14).fill()

    // 标注工具按钮
    let tools: [(icon: String, color: NSColor, active: Bool)] = [
        ("rectangle", brandRed, false),
        ("highlighter", brandOrange, true),  // 高亮被选中
        ("arrow.up.right", brandBlueLight, false),
        ("textformat", brandPurple, false),
    ]
    var toolX = tbRect.minX + 16
    let toolBoxSize: CGFloat = 32
    for tool in tools {
        let box = CGRect(x: toolX, y: tbRect.midY - toolBoxSize / 2,
                         width: toolBoxSize, height: toolBoxSize)
        if tool.active {
            drawRRect(box, radius: 5, fill: tool.color.withAlphaComponent(0.22))
        }
        drawSymbol(tool.icon,
                   in: box.insetBy(dx: 8, dy: 8),
                   color: tool.active ? tool.color : textSoft)
        toolX += toolBoxSize + 8
    }
    // 调色板
    toolX += 10
    let palette: [NSColor] = [brandRed, brandOrange, brandGreen, brandBlueLight, brandPurple, NSColor.white]
    for c in palette {
        let dot = CGRect(x: toolX, y: tbRect.midY - 8, width: 16, height: 16)
        c.setFill()
        NSBezierPath(ovalIn: dot).fill()
        if c == brandRed {
            NSColor.white.setStroke()
            let p = NSBezierPath(ovalIn: dot.insetBy(dx: -2, dy: -2))
            p.lineWidth = 2
            p.stroke()
        }
        toolX += 22
    }
    // 右侧导出按钮
    let exportRect = CGRect(x: tbRect.maxX - 110, y: tbRect.midY - 14,
                            width: 96, height: 28)
    drawRRect(exportRect, radius: 5, fill: brandBlue)
    drawText("导出标注图",
             at: CGPoint(x: exportRect.minX + 16, y: exportRect.minY + 6),
             fontSize: size.width * 0.011, weight: .semibold, color: textPrimary)

    // canvas 区
    let canvasRect = winRect.insetBy(dx: 24, dy: 24)
    let canvasH = canvasRect.height - tbH - 24
    let canvas = CGRect(x: canvasRect.minX, y: canvasRect.minY,
                        width: canvasRect.width, height: canvasH)
    NSColor(white: 0.07, alpha: 1).setFill()
    canvas.fill()

    // 模拟一张文档截图(用渐变占位)
    drawLinearGradient(in: canvas.insetBy(dx: 8, dy: 8),
                       colors: [NSColor(white: 0.95, alpha: 1),
                                NSColor(white: 0.85, alpha: 1)],
                       angle: -90)
    // 模拟文字行(灰色横线)
    NSColor(white: 0.5, alpha: 0.4).setFill()
    let lines = 12
    let lineH: CGFloat = 12
    let lineSpacing: CGFloat = 22
    for i in 0..<lines {
        let widthVar = [0.95, 0.80, 0.70, 0.92, 0.65, 0.85, 0.78, 0.55, 0.90, 0.72, 0.83, 0.60][i]
        CGRect(x: canvas.minX + 40,
               y: canvas.maxY - 50 - CGFloat(i) * lineSpacing,
               width: (canvas.width - 80) * widthVar,
               height: lineH).fill()
    }

    // 加几个标注 demo
    // 1. 高亮(黄色半透明)— 第 4 行
    brandOrange.withAlphaComponent(0.40).setFill()
    CGRect(x: canvas.minX + 40, y: canvas.maxY - 50 - 3 * lineSpacing - 4,
           width: (canvas.width - 80) * 0.92, height: lineH + 8).fill()

    // 2. 矩形(红色描边)— 围绕第 7 行
    let r1 = CGRect(x: canvas.minX + 40, y: canvas.maxY - 50 - 6 * lineSpacing - 6,
                    width: (canvas.width - 80) * 0.78, height: lineH + 12)
    let p1 = NSBezierPath(rect: r1)
    p1.lineWidth = 3
    brandRed.setStroke()
    p1.stroke()

    // 3. 箭头 — 从右下角指到第 1 行
    let arrowFrom = CGPoint(x: canvas.maxX - 60, y: canvas.minY + 60)
    let arrowTo = CGPoint(x: canvas.minX + 40 + (canvas.width - 80) * 0.95 - 40,
                          y: canvas.maxY - 50 - 0 * lineSpacing + lineH / 2)
    let arrowPath = NSBezierPath()
    arrowPath.move(to: arrowFrom)
    arrowPath.line(to: arrowTo)
    brandBlueLight.setStroke()
    arrowPath.lineWidth = 4
    arrowPath.lineCapStyle = .round
    arrowPath.stroke()
    // 箭头头部
    let dx = arrowTo.x - arrowFrom.x
    let dy = arrowTo.y - arrowFrom.y
    let len = max(sqrt(dx * dx + dy * dy), 1)
    let ux = dx / len
    let uy = dy / len
    let headSize: CGFloat = 18
    let angle: CGFloat = .pi * 5 / 6
    let leftWing = CGPoint(
        x: arrowTo.x + headSize * (ux * cos(angle) - uy * sin(angle)),
        y: arrowTo.y + headSize * (ux * sin(angle) + uy * cos(angle)))
    let rightWing = CGPoint(
        x: arrowTo.x + headSize * (ux * cos(-angle) - uy * sin(-angle)),
        y: arrowTo.y + headSize * (ux * sin(-angle) + uy * cos(-angle)))
    let head = NSBezierPath()
    head.move(to: arrowTo); head.line(to: leftWing)
    head.move(to: arrowTo); head.line(to: rightWing)
    head.lineWidth = 4
    head.lineCapStyle = .round
    head.stroke()

    // 4. 文本标注
    drawText("看这里 ⬉",
             at: CGPoint(x: arrowFrom.x - 80, y: arrowFrom.y - 24),
             fontSize: size.width * 0.014, weight: .bold, color: brandPurple)
}

// MARK: - 场景 6:Privacy

func renderSettings(_ size: CGSize) {
    // 深色背景
    NSColor(red: 5/255, green: 8/255, blue: 15/255, alpha: 1).setFill()
    CGRect(origin: .zero, size: size).fill()
    drawRadialGradient(
        in: CGRect(origin: .zero, size: size),
        colors: [
            NSColor(red: 0/255, green: 102/255, blue: 230/255, alpha: 0.40),
            NSColor(red: 5/255, green: 8/255, blue: 15/255, alpha: 0)
        ],
        center: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
        radius: size.width * 0.55
    )

    // shield logo
    let shieldSize = size.height * 0.16
    let shieldRect = CGRect(x: size.width / 2 - shieldSize / 2,
                            y: size.height * 0.74,
                            width: shieldSize, height: shieldSize)
    drawSymbol("lock.shield.fill", in: shieldRect, color: brandGreen)

    drawCentered("你的数据,从不离开 Mac",
                 in: CGRect(x: 0, y: size.height * 0.59,
                            width: size.width, height: size.height * 0.08),
                 fontSize: size.width * 0.046, weight: .bold, color: textPrimary)
    drawCentered("默认不申请网络权限  ·  Activity Monitor 可验证零外联",
                 in: CGRect(x: 0, y: size.height * 0.54,
                            width: size.width, height: size.height * 0.04),
                 fontSize: size.width * 0.018, color: textSoft)

    // 三个 0 的大数字
    let stats: [(num: String, label: String, color: NSColor, icon: String)] = [
        ("0", "外部 SDK", brandBlueLight, "shippingbox"),
        ("0", "网络请求", brandGreen, "wifi.slash"),
        ("0", "用户追踪", brandPurple, "eye.slash.fill"),
    ]
    let statY = size.height * 0.18
    let statH = size.height * 0.28
    let totalW = size.width * 0.72
    let statW = totalW / 3 - 24
    let startX = size.width / 2 - totalW / 2

    for (i, stat) in stats.enumerated() {
        let cardX = startX + CGFloat(i) * (statW + 36)
        let cardRect = CGRect(x: cardX, y: statY, width: statW, height: statH)
        drawRRect(cardRect, radius: 16,
                  fill: NSColor.white.withAlphaComponent(0.05),
                  stroke: stat.color.withAlphaComponent(0.30), lineWidth: 1)

        // 大 0
        let numFont = NSFont.systemFont(ofSize: cardRect.height * 0.55, weight: .bold)
        let numAttr = NSAttributedString(string: stat.num, attributes: [
            .font: numFont, .foregroundColor: stat.color
        ])
        let ns = numAttr.size()
        numAttr.draw(at: CGPoint(x: cardRect.midX - ns.width / 2,
                                 y: cardRect.minY + cardRect.height * 0.30))

        // icon 装饰右上
        drawSymbol(stat.icon,
                   in: CGRect(x: cardRect.maxX - 36, y: cardRect.maxY - 36,
                              width: 24, height: 24),
                   color: stat.color.withAlphaComponent(0.50))

        // label
        let labelFont = NSFont.systemFont(ofSize: size.width * 0.018, weight: .medium)
        let labelAttr = NSAttributedString(string: stat.label, attributes: [
            .font: labelFont, .foregroundColor: textSoft
        ])
        let ls = labelAttr.size()
        labelAttr.draw(at: CGPoint(x: cardRect.midX - ls.width / 2,
                                   y: cardRect.minY + 24))
    }

    // bottom 副标题
    drawCentered("零外部依赖  ·  仅 Apple 原生框架",
                 in: CGRect(x: 0, y: size.height * 0.07,
                            width: size.width, height: size.height * 0.04),
                 fontSize: size.width * 0.014, weight: .medium, color: textTertiary)
}

// MARK: - 假窗口装饰

func drawFakeWindow(at rect: CGRect, title: String) {
    drawRRect(rect, radius: 10, fill: NSColor(white: 0.18, alpha: 1))
    let tbH: CGFloat = 28
    let tbRect = CGRect(x: rect.minX, y: rect.maxY - tbH,
                        width: rect.width, height: tbH)
    NSColor(white: 0.22, alpha: 1).setFill()
    NSBezierPath(roundedRect: tbRect, xRadius: 10, yRadius: 10).fill()
    [(NSColor(red: 1, green: 0.37, blue: 0.34, alpha: 1), 12),
     (NSColor(red: 1, green: 0.74, blue: 0.18, alpha: 1), 28),
     (NSColor(red: 0.15, green: 0.79, blue: 0.25, alpha: 1), 44)]
        .forEach { c, x in
            c.setFill()
            CGRect(x: tbRect.minX + CGFloat(x), y: tbRect.midY - 5, width: 11, height: 11).fill()
        }
    drawCentered(title, in: tbRect, fontSize: 11, weight: .semibold, color: textMute)
}

// MARK: - 主流程

let scenes: [(name: String, render: (CGSize) -> Void)] = [
    ("01-hero.png", renderHero),
    ("02-capture.png", renderCapture),
    ("03-ocr.png", renderOCR),
    ("04-clipboard.png", renderClipboard),
    ("05-snapshots.png", renderSnapshots),
    ("06-settings.png", renderSettings),
]

print("→ 生成 App Store Connect 截图")
print("   \(scenes.count) 场景 × \(sizes.count) 尺寸 = \(scenes.count * sizes.count) PNG\n")

for s in sizes {
    let dir = "\(outputBase)/\(s.w)x\(s.h)"
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    print("[\(s.w)×\(s.h)]")
    for scene in scenes {
        let bitmap = makeBitmap(width: s.w, height: s.h)
        NSGraphicsContext.saveGraphicsState()
        let nsCtx = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.current = nsCtx
        nsCtx.imageInterpolation = .high
        scene.render(CGSize(width: s.w, height: s.h))
        NSGraphicsContext.restoreGraphicsState()
        try? saveBitmap(bitmap, to: "\(dir)/\(scene.name)")
        print("  ✓ \(scene.name)")
    }
}

print("\n✓ Done. 输出目录:\(outputBase)/{1280x800,1440x900,2560x1600,2880x1800}/")
