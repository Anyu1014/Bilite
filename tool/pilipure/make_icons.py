#!/usr/bin/env python3
"""Regenerate PiliPure launcher icons (Android + iOS + in-app logo) from one source image."""
import json
import os
from PIL import Image

SRC = "/Users/y/Downloads/DSH/Mac工作区/PiliPlus/src/tool/pilipure/assets_src/pilipure_icon_source.jpg"
REPO = "/Users/y/Downloads/DSH/Mac工作区/PiliPlus/src"

src = Image.open(SRC).convert("RGB")
# corner colour = background of the artwork (top-left is a flat area)
bg = src.getpixel((8, 8))


def save_png(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, "PNG", optimize=True)


# ---------- Android legacy square icons ----------
ANDROID_DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for d, size in ANDROID_DENSITIES.items():
    save_png(src.resize((size, size), Image.LANCZOS),
             f"{REPO}/android/app/src/main/res/mipmap-{d}/ic_launcher.png")

# ---------- Android adaptive foreground (image at 66.7% of 108dp canvas) ----------
FOREGROUND_SIZES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
for d, canvas in FOREGROUND_SIZES.items():
    inner = round(canvas * 72 / 108)
    layer = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    art = src.resize((inner, inner), Image.LANCZOS).convert("RGBA")
    off = (canvas - inner) // 2
    layer.paste(art, (off, off), art)
    save_png(layer, f"{REPO}/android/app/src/main/res/mipmap-{d}/ic_launcher_foreground.png")

# ---------- iOS AppIcon ----------
appicon_dir = f"{REPO}/ios/Runner/Assets.xcassets/AppIcon.appiconset"
meta = json.load(open(f"{appicon_dir}/Contents.json"))
for entry in meta["images"]:
    if "filename" not in entry:
        continue
    w, h = entry["size"].split("x")
    scale = int(entry["scale"].rstrip("x"))
    px_w, px_h = round(float(w) * scale), round(float(h) * scale)
    save_png(src.resize((px_w, px_h), Image.LANCZOS), f"{appicon_dir}/{entry['filename']}")

# ---------- in-app logo assets ----------
for rel in ("assets/images/logo/logo.png",
            "assets/images/logo/logo_2.png",
            "assets/images/logo/desktop/logo_large.png"):
    save_png(src.resize((512, 512), Image.LANCZOS), f"{REPO}/{rel}")

print("bg colour:", "#%02X%02X%02X" % bg)
