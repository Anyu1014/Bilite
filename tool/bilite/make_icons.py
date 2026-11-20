#!/usr/bin/env python3
"""Regenerate Bilite launcher icons (Android + iOS + in-app logo) from one source image."""
import json
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(
    HERE, "assets_src", os.environ.get("ICON_SRC", "bilite_icon_source.jpg")
)

src = Image.open(SRC).convert("RGB")
w, h = src.size
# 居中裁成正方形，铺满整块画布（新图无白边，不需要内缩）
side = min(w, h)
left = (w - side) // 2
top = (h - side) // 2
art = src.crop((left, top, left + side, top + side))


def rounded(im, radius_ratio=0.22, super_sample=4):
    """给图片加圆角（透明边角），用超采样保证边缘平滑。"""
    w, h = im.size
    r = round(min(w, h) * radius_ratio)
    ss = super_sample
    mask = Image.new("L", (w * ss, h * ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, w * ss - 1, h * ss - 1), radius=r * ss, fill=255
    )
    mask = mask.resize((w, h), Image.LANCZOS)
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out

# 取裁切边缘的平均色，用于自适应图标外圈的底色
edges = [art.getpixel((x, 0)) for x in range(0, art.width, 48)] + [
    art.getpixel((x, art.height - 1)) for x in range(0, art.width, 48)
]
edge = tuple(sum(c[i] for c in edges) // len(edges) for i in range(3))


def save_png(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, "PNG", optimize=True)


# ---------- Android legacy square icons ----------
ANDROID_DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for d, size in ANDROID_DENSITIES.items():
    save_png(
        rounded(art.resize((size, size), Image.LANCZOS)),
        f"{REPO}/android/app/src/main/res/mipmap-{d}/ic_launcher.png",
    )

# ---------- Android adaptive foreground (art at 72/108 of the canvas) ----------
FOREGROUND_SIZES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
for d, canvas in FOREGROUND_SIZES.items():
    inner = round(canvas * 72 / 108)
    layer = Image.new("RGBA", (canvas, canvas), edge + (255,))
    # 自适应图标由系统遮罩裁切，前景保持整块，避免圆角套圆形
    inner_art = art.resize((inner, inner), Image.LANCZOS).convert("RGBA")
    off = (canvas - inner) // 2
    layer.paste(inner_art, (off, off), inner_art)
    save_png(layer, f"{REPO}/android/app/src/main/res/mipmap-{d}/ic_launcher_foreground.png")

# ---------- iOS AppIcon ----------
appicon_dir = f"{REPO}/ios/Runner/Assets.xcassets/AppIcon.appiconset"
with open(f"{appicon_dir}/Contents.json") as f:
    meta = json.load(f)
for entry in meta["images"]:
    if "filename" not in entry:
        continue
    width, _ = entry["size"].split("x")
    scale = int(entry["scale"].rstrip("x"))
    px = round(float(width) * scale)
    save_png(art.resize((px, px), Image.LANCZOS), f"{appicon_dir}/{entry['filename']}")

# ---------- desktop icon (.ico) ----------
ico = rounded(art.resize((256, 256), Image.LANCZOS))
ico.save(
    f"{REPO}/assets/images/logo/ico/app_icon.ico",
    sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
)

# ---------- in-app logo assets (rounded corners, 4x supersampled mask) ----------
LOGO = 512
logo = rounded(art.resize((LOGO, LOGO), Image.LANCZOS))
for rel in (
    "assets/images/logo/logo.png",
    "assets/images/logo/logo_2.png",
    "assets/images/logo/desktop/logo_large.png",
):
    save_png(logo, f"{REPO}/{rel}")

print("edge colour: #%02X%02X%02X" % edge)
