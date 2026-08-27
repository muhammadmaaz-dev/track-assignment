#!/usr/bin/env python3
"""Reformat 1290x2796 (Apple) scaffolds to Google Play 9:16 (1080x1920).

Pads the sides with the brand background colour to reach a 9:16 aspect
ratio (never stretches), then downscales to 1080x1920 — a Play-recommended
phone screenshot size that satisfies Play's "longest side <= 2x shortest" rule.
"""
import argparse
from PIL import Image


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def reformat(src, dst, bg_hex, target_w, target_h):
    bg = hex_to_rgb(bg_hex)
    img = Image.open(src).convert("RGB")
    w, h = img.size
    # Add width so aspect matches target (source is too narrow -> pad sides).
    new_w = round(h * target_w / target_h)
    if new_w < w:
        new_w = w
    canvas = Image.new("RGB", (new_w, h), bg)
    canvas.paste(img, ((new_w - w) // 2, 0))
    canvas = canvas.resize((target_w, target_h), Image.LANCZOS)
    canvas.save(dst, "PNG")
    print(f"OK {dst} ({target_w}x{target_h})")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--src", required=True)
    p.add_argument("--dst", required=True)
    p.add_argument("--bg", required=True)
    p.add_argument("--width", type=int, default=1080)   # 9:16 phone default
    p.add_argument("--height", type=int, default=1920)
    a = p.parse_args()
    reformat(a.src, a.dst, a.bg, a.width, a.height)
