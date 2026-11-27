#!/usr/bin/env python3
"""Compose the Seminar deck figures from the latest DeckCapture screenshots.

    python tools/capture_deck_shots.sh     # writes art_raw/shots_new/*.png
    python tools/compose_deck_images.py    # writes nakshatra/assets/seminar/*.webp

The certificate crop is computed from the cream panel's bounding box, so it does
not depend on a hard-coded pixel position.
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_raw", "shots_new")
OUT = os.path.join(ROOT, "nakshatra", "assets", "seminar")
os.makedirs(OUT, exist_ok=True)

# 16:9 figures used by the deck.
MAP = [
    ("hub.png", "hub.webp"),
    ("moon.png", "moon.webp"),
    ("stars.png", "stars.webp"),
    ("scale.png", "scale.webp"),
    ("seasons.png", "seasons.webp"),
    ("solar.png", "solar.webp"),
    ("blackhole.png", "blackhole.webp"),
    ("quiz.png", "quiz.webp"),
    ("certificate.png", "certificate.webp"),
    ("hub_phone.png", "mobile.webp"),
]


def save(im, name, quality=86):
    if im.width > 1280:
        im = im.resize((1280, round(im.height * 1280 / im.width)), Image.LANCZOS)
    path = os.path.join(OUT, name)
    im.convert("RGB").save(path, "WEBP", quality=quality, method=6)
    print("wrote", name, im.size)


def certificate_detail():
    path = os.path.join(SRC, "certificate.png")
    if not os.path.exists(path):
        print("missing", path)
        return
    im = Image.open(path).convert("RGB")
    a = np.asarray(im)
    # Cream paper of the certificate (the same family as the Sky Note pages).
    mask = (a[:, :, 0] > 224) & (a[:, :, 1] > 212) & (a[:, :, 2] > 190)
    ys, xs = np.where(mask)
    if len(xs) < 1000:
        save(im, "certificate_detail.webp", 88)
        return
    left, right = int(xs.min()), int(xs.max())
    top, bottom = int(ys.min()), int(ys.max())
    pad_x = max(18, int((right - left) * 0.08))
    pad_y = max(18, int((bottom - top) * 0.10))
    left = max(0, left - pad_x)
    right = min(im.width, right + pad_x)
    top = max(0, top - pad_y)
    bottom = min(im.height, bottom + pad_y)
    w, h = right - left, bottom - top
    target = 16 / 9
    if w / h < target:
        want = int(h * target)
        grow = want - w
        left = max(0, left - grow // 2)
        right = min(im.width, right + grow // 2)
    else:
        want = int(w / target)
        grow = want - h
        top = max(0, top - grow // 2)
        bottom = min(im.height, bottom + grow // 2)
    crop = im.crop((left, top, right, bottom))
    crop = crop.resize((1252, 704), Image.LANCZOS)
    save(crop, "certificate_detail.webp", 88)


if __name__ == "__main__":
    for src, dst in MAP:
        p = os.path.join(SRC, src)
        if not os.path.exists(p):
            print("missing", p)
            continue
        save(Image.open(p), dst)
    certificate_detail()
    print("deck figures written to", OUT)
