#!/usr/bin/env swift

// 程序化生成 Pluck AppIcon — 输出 10 个尺寸 + Contents.json
// 运行:swift scripts/generate-app-icon.swift  (在 pluck/ 项目根)
//
// 关键技巧:用 NSBitmapImageRep 直接锁定物理像素尺寸,
// 否则 NSImage(size:) 在 Retina 上会自动 2× 放大,导致 16px 输出 32px。

import AppKit
import Foundation

// MARK: - 配置

let outputDir = "Pluck/Assets.xcassets/AppIcon.appiconset"

let specs: [(name: String, pixels: Int)] = [
    ("icon_16x16.png",      16),
    ("icon_16x16@2x.png",   32),
    ("icon_32x32.png",      32),
    ("icon_32x32@2x.png",   64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png", 1024),
]

// MARK: - 渲染到精确像素的 BitmapImageRep

func renderIcon(pixels: Int) -> NSBitmapImageRep {
    let size = CGFloat(pixels)
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    )!

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    let nsCtx = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = nsCtx
    nsCtx.imageInterpolation = .high

    // ===== 1. 圆角矩形背景(macOS squircle ~22.5% 圆角) =====
    let cornerRadius = size * 0.225
    let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
    bgPath.addClip()

    // ===== 2. 主渐变(Pluck 蓝,从亮到深) =====
    let topColor = NSColor(red: 78/255, green: 168/255, blue: 255/255, alpha: 1)
    let bottomColor = NSColor(red: 0/255, green: 102/255, blue: 230/255, alpha: 1)
    let mainGradient = NSGradient(colors: [topColor, bottomColor])!
    mainGradient.draw(in: bgRect, angle: -90)

    // ===== 3. 顶部高光带 =====
    let highlight = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.20),
        NSColor.white.withAlphaComponent(0)
    ])!
    let highlightRect = NSRect(x: 0, y: size * 0.55, width: size, height: size * 0.45)
    highlight.draw(in: highlightRect, angle: -90)

    // ===== 4. SF Symbol: camera.viewfinder 白色 + 微阴影 =====
    let symbolPointSize = size * 0.50
    let baseConfig = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
    let coloredConfig = baseConfig.applying(NSImage.SymbolConfiguration(paletteColors: [.white]))

    if let symbol = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: nil)?
        .withSymbolConfiguration(coloredConfig)
    {
        let drawRect = NSRect(
            x: (size - symbol.size.width) / 2,
            y: (size - symbol.size.height) / 2,
            width: symbol.size.width,
            height: symbol.size.height
        )
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
        shadow.shadowOffset = NSSize(width: 0, height: -size * 0.012)
        shadow.shadowBlurRadius = size * 0.020
        shadow.set()
        symbol.draw(in: drawRect)
    }

    return bitmap
}

// MARK: - PNG 写盘

func savePNG(_ bitmap: NSBitmapImageRep, to path: String) throws {
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "icon-gen", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "PNG 序列化失败"])
    }
    try png.write(to: URL(fileURLWithPath: path), options: .atomic)
}

// MARK: - Contents.json

func writeContentsJSON(at path: String) throws {
    let images = specs.map { spec -> String in
        let scale = spec.name.contains("@2x") ? "2x" : "1x"
        let baseName = spec.name
            .replacingOccurrences(of: "icon_", with: "")
            .replacingOccurrences(of: "@2x", with: "")
            .replacingOccurrences(of: ".png", with: "")
        return """
            {
              "filename" : "\(spec.name)",
              "idiom" : "mac",
              "scale" : "\(scale)",
              "size" : "\(baseName)"
            }
        """
    }.joined(separator: ",\n")

    let json = """
    {
      "images" : [
    \(images)
      ],
      "info" : {
        "author" : "pluck-icon-generator",
        "version" : 1
      }
    }
    """
    try json.write(toFile: path, atomically: true, encoding: .utf8)
}

// MARK: - Main

print("→ Generating Pluck AppIcon at \(outputDir)/")

try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for spec in specs {
    let bitmap = renderIcon(pixels: spec.pixels)
    try savePNG(bitmap, to: "\(outputDir)/\(spec.name)")
    print("  ✓ \(spec.name) — \(bitmap.pixelsWide)×\(bitmap.pixelsHigh)")
}

try writeContentsJSON(at: "\(outputDir)/Contents.json")
print("  ✓ Contents.json")

print("\n✓ Done. \(specs.count) PNGs + Contents.json written.")
