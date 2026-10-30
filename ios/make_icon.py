#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 iOS App 图标（1024x1024 PNG，纯标准库，无第三方依赖）。

深蓝渐变背景 + 白色速度曲线。
"""
import os
import struct
import zlib

SIZE = 1024
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "Resources", "Assets.xcassets", "AppIcon.appiconset")
OUT = os.path.join(OUT_DIR, "AppIcon-1024.png")

# 速度曲线控制点（0..1 归一化，第二个值是高度占比）
CURVE = [(0.00, 0.18), (0.10, 0.42), (0.22, 0.78), (0.34, 0.55),
         (0.46, 0.86), (0.58, 0.62), (0.70, 0.92), (0.84, 0.48), (1.00, 0.70)]


def curve_y(x):
    for i in range(len(CURVE) - 1):
        x0, y0 = CURVE[i]
        x1, y1 = CURVE[i + 1]
        if x0 <= x <= x1:
            t = (x - x0) / (x1 - x0)
            return y0 + (y1 - y0) * t
    return CURVE[-1][1]


def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    raw = bytearray()
    pad = 0.10                    # 曲线区域留白
    lw = SIZE * 0.055             # 线宽

    for y in range(SIZE):
        raw.append(0)             # PNG 每行开头的 filter type
        for x in range(SIZE):
            u, v = x / SIZE, y / SIZE
            # 背景渐变：左上 #2563eb -> 右下 #0b1220
            r = int(0x25 + (0x0b - 0x25) * (u * 0.5 + v * 0.5))
            g = int(0x63 + (0x12 - 0x63) * (u * 0.5 + v * 0.5))
            b = int(0xeb + (0x20 - 0xeb) * (u * 0.5 + v * 0.5))

            # 曲线：只画中间区域
            if pad <= u <= 1 - pad:
                cx = (u - pad) / (1 - 2 * pad)
                cy = 1.0 - curve_y(cx)          # 屏幕坐标向下
                cy = pad + cy * (1 - 2 * pad)
                if abs(v - cy) * SIZE <= lw / 2:
                    r, g, b = 0xFF, 0xFF, 0xFF

            raw += bytes((r, g, b, 255))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(OUT, "wb") as f:
        f.write(png)

    contents = """{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
    with open(os.path.join(OUT_DIR, "Contents.json"), "w", encoding="utf-8") as f:
        f.write(contents)

    print("[✓] 图标 %s (%.0f KB)" % (OUT, os.path.getsize(OUT) / 1024))


if __name__ == "__main__":
    main()
