#!/usr/bin/env python3
"""Sinh toàn bộ icon app + icon thông báo từ một hình gốc duy nhất.

Hình: bong bóng tin nhắn trắng chứa mũi tên điều hướng, nền gradient indigo.
Toạ độ theo lưới adaptive icon 108x108 (vùng an toàn: tròn r=33 quanh 54,54).

Chạy lại sau khi sửa hình / màu:
    pip install cairosvg pillow
    python3 scripts/generate_app_icons.py
"""
import json
import math
import os

import cairosvg
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android/app/src/main/res")
IOS = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
DESIGN = os.path.join(ROOT, "design/app_icon")

GRAD_START = "#6366F1"  # AppColors.primary
GRAD_END = "#4338CA"
ARROW_COLOR = "#4F46E5"  # AppColors.primaryDark

BUBBLE = (
    "M40,32 H68 A12,12 0 0 1 80,44 V60 A12,12 0 0 1 68,72 H50 L37,81 "
    "L39.5,72 A12,12 0 0 1 28,60 V44 A12,12 0 0 1 40,32 Z"
)
ARROW_POINTS = [(54, 39), (63.5, 62), (54, 57), (44.5, 62)]
ARROW_PIVOT = (54, 52)
ARROW_ROTATION = 45


def rotated_arrow():
    a = math.radians(ARROW_ROTATION)
    cx, cy = ARROW_PIVOT
    pts = []
    for x, y in ARROW_POINTS:
        dx, dy = x - cx, y - cy
        pts.append((cx + dx * math.cos(a) - dy * math.sin(a), cy + dx * math.sin(a) + dy * math.cos(a)))
    return "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in pts) + " Z"


ARROW = rotated_arrow()


def glyph(bubble="#FFFFFF", arrow=ARROW_COLOR):
    return f'<path d="{BUBBLE}" fill="{bubble}"/><path d="{ARROW}" fill="{arrow}"/>'


GRAD = (
    '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">'
    f'<stop offset="0" stop-color="{GRAD_START}"/><stop offset="1" stop-color="{GRAD_END}"/>'
    "</linearGradient></defs>"
)


def svg(body, view_box):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view_box}">{body}</svg>'


LEGACY = svg(GRAD + '<rect x="18" y="18" width="72" height="72" rx="16" fill="url(#g)"/>' + glyph(), "18 18 72 72")
ROUND = svg(GRAD + '<circle cx="54" cy="54" r="36" fill="url(#g)"/>' + glyph(), "18 18 72 72")
# iOS tự bo góc, App Store cấm alpha → nền phủ kín
FULL = svg(GRAD + '<rect width="108" height="108" fill="url(#g)"/>' + glyph(), "18 18 72 72")


def png(svg_text, size, path, opaque=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    cairosvg.svg2png(bytestring=svg_text.encode(), write_to=path, output_width=size, output_height=size)
    if opaque:
        Image.open(path).convert("RGB").save(path, optimize=True)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def vector(paths, size=108, viewport=108, translate=0):
    group_open = f'    <group android:translateX="{-translate}" android:translateY="{-translate}">\n' if translate else ""
    group_close = "    </group>\n" if translate else ""
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Sinh bởi scripts/generate_app_icons.py — đừng sửa tay. -->\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    xmlns:aapt="http://schemas.android.com/aapt"\n'
        f'    android:width="{size}dp"\n    android:height="{size}dp"\n'
        f'    android:viewportWidth="{viewport}"\n    android:viewportHeight="{viewport}">\n'
        + group_open + paths + group_close + "</vector>\n"
    )


def android():
    # Legacy (API 24–25) + round
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        png(LEGACY, size, f"{RES}/mipmap-{density}/ic_launcher.png")
        png(ROUND, size, f"{RES}/mipmap-{density}/ic_launcher_round.png")

    # Adaptive icon (API 26+): nền gradient, tiền cảnh glyph, monochrome cho themed icon (Android 13+)
    write(f"{RES}/drawable/ic_launcher_background.xml", vector(
        '    <path android:pathData="M0,0h108v108h-108z">\n'
        '        <aapt:attr name="android:fillColor">\n'
        '            <gradient android:type="linear"\n'
        '                android:startX="0" android:startY="0" android:endX="108" android:endY="108"\n'
        f'                android:startColor="{GRAD_START}" android:endColor="{GRAD_END}" />\n'
        '        </aapt:attr>\n'
        '    </path>\n'))
    write(f"{RES}/drawable/ic_launcher_foreground.xml", vector(
        f'    <path android:fillColor="#FFFFFF" android:pathData="{BUBBLE}" />\n'
        f'    <path android:fillColor="{ARROW_COLOR}" android:pathData="{ARROW}" />\n'))
    # Monochrome: một màu duy nhất, mũi tên đục lỗ (evenOdd) để hệ thống tô theo theme
    write(f"{RES}/drawable/ic_launcher_monochrome.xml", vector(
        f'    <path android:fillColor="#FFFFFF" android:fillType="evenOdd" android:pathData="{BUBBLE} {ARROW}" />\n'))
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@drawable/ic_launcher_background" />\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n'
    )
    write(f"{RES}/mipmap-anydpi-v26/ic_launcher.xml", adaptive)
    write(f"{RES}/mipmap-anydpi-v26/ic_launcher_round.xml", adaptive)

    # Icon thông báo: hình trắng trên nền trong suốt (Android chỉ dùng kênh alpha).
    # Khung 60x60 quanh glyph → phóng to cho rõ ở 24dp.
    write(f"{RES}/drawable/ic_stat_notification.xml", vector(
        f'    <path android:fillColor="#FFFFFF" android:fillType="evenOdd" android:pathData="{BUBBLE} {ARROW}" />\n',
        size=24, viewport=60, translate=24))


def ios():
    with open(f"{IOS}/Contents.json") as f:
        images = json.load(f)["images"]
    for image in images:
        side = float(image["size"].split("x")[0]) * int(image["scale"].rstrip("x"))
        png(FULL, round(side), f"{IOS}/{image['filename']}", opaque=True)


def design():
    write(f"{DESIGN}/icon_legacy.svg", LEGACY)
    write(f"{DESIGN}/icon_round.svg", ROUND)
    write(f"{DESIGN}/icon_full.svg", FULL)
    write(f"{DESIGN}/notification.svg", svg(
        f'<path fill="#000" fill-rule="evenodd" d="{BUBBLE} {ARROW}"/>', "24 24 60 60"))
    png(FULL, 512, f"{DESIGN}/icon_512.png", opaque=True)


if __name__ == "__main__":
    android()
    ios()
    design()
    print("Đã sinh icon Android, iOS và design/app_icon/.")
