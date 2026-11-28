#!/usr/bin/env python3
"""Generate the seven hub medal icons for the Night Almanac menu.

Each icon is a dark disc with one bold brass/cream glyph, sized for a 76 px
button. The icons are intentionally simpler than the exhibit plates: a menu
medal has to read at a glance, not retell the lesson.
"""
from PIL import Image, ImageDraw, ImageFont
import math
import os

OUT = 160
SS = 8
SIZE = OUT * SS
DISC = (36, 46, 74, 255)
GOLD = (213, 165, 90, 255)
CREAM = (244, 232, 212, 255)
VERMILION = (200, 80, 58, 255)
INK = (10, 14, 24, 255)


def base() -> Image.Image:
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((8 * SS, 8 * SS, SIZE - 8 * SS, SIZE - 8 * SS), fill=DISC)
    return im


def star4(d, cx, cy, r, fill):
    pts = []
    for i in range(8):
        ang = -math.pi / 2 + i * math.pi / 4
        rad = r if i % 2 == 0 else r * 0.34
        pts.append((cx + math.cos(ang) * rad, cy + math.sin(ang) * rad))
    d.polygon(pts, fill=fill)


def moon() -> Image.Image:
    im = base()
    d = ImageDraw.Draw(im)
    c = SIZE * 0.5
    r = SIZE * 0.28
    # A cream disc, then an ink disc offset to cut the crescent.
    d.ellipse((c - r, c - r, c + r, c + r), fill=CREAM)
    off = SIZE * 0.10
    cut = SIZE * 0.26
    d.ellipse((c - cut + off, c - cut - off * 0.4, c + cut + off, c + cut - off * 0.4), fill=DISC)
    # One small gold star keeps the almanac language.
    star4(d, c + SIZE * 0.20, c - SIZE * 0.18, SIZE * 0.045, GOLD)
    return im


def stars() -> Image.Image:
    im = base()
    d = ImageDraw.Draw(im)
    c = SIZE * 0.5
    star4(d, c, c, SIZE * 0.24, CREAM)
    for dx, dy, col in [(-0.26, 0.20, GOLD), (0.24, 0.22, GOLD), (0.02, -0.30, VERMILION)]:
        x = c + dx * SIZE
        y = c + dy * SIZE
        d.ellipse((x - SIZE * 0.035, y - SIZE * 0.035, x + SIZE * 0.035, y + SIZE * 0.035), fill=col)
    return im


def scale() -> Image.Image:
    im = base()
    d = ImageDraw.Draw(im)
    c = SIZE * 0.5
    # A Sun with one clear orbit and one world on it: the solar system at a glance.
    sun_r = SIZE * 0.15
    d.ellipse((c - sun_r, c - sun_r, c + sun_r, c + sun_r), fill=GOLD)
    orbit_r = SIZE * 0.28
    d.ellipse((c - orbit_r, c - orbit_r, c + orbit_r, c + orbit_r), outline=CREAM, width=9 * SS)
    px = c + orbit_r * math.cos(math.radians(35))
    py = c - orbit_r * math.sin(math.radians(35))
    pr = SIZE * 0.065
    d.ellipse((px - pr, py - pr, px + pr, py + pr), fill=CREAM)
    return im


def seasons() -> Image.Image:
    im = base()
    d = ImageDraw.Draw(im)
    c = SIZE * 0.5
    # A filled Earth with a bold tilted axis and a small Sun to the side.
    r = SIZE * 0.23
    d.ellipse((c - SIZE * 0.04 - r, c - r, c - SIZE * 0.04 + r, c + r), fill=CREAM)
    tilt = math.radians(23.4)
    dx = math.cos(tilt) * r * 1.45
    dy = math.sin(tilt) * r * 1.45
    d.line((c - SIZE * 0.04 - dx, c - dy, c - SIZE * 0.04 + dx, c + dy), fill=GOLD, width=9 * SS)
    sun_r = SIZE * 0.075
    sun = (c + SIZE * 0.22, c - SIZE * 0.20)
    d.ellipse((sun[0] - sun_r, sun[1] - sun_r, sun[0] + sun_r, sun[1] + sun_r), fill=GOLD)
    return im


def flares() -> Image.Image:
    im = base()
    d = ImageDraw.Draw(im)
    c = SIZE * 0.5
    r = SIZE * 0.20
    d.ellipse((c - r, c - r, c + r, c + r), fill=GOLD)
    # Three bold rays to the upper right, the storm leaving the Sun.
    for ang in [-70, -35, 0]:
        a = math.radians(ang)
        x0 = c + math.cos(a) * r
        y0 = c + math.sin(a) * r
        x1 = c + math.cos(a) * r * 1.9
        y1 = c + math.sin(a) * r * 1.9
        d.line((x0, y0, x1, y1), fill=CREAM, width=8 * SS)
        d.ellipse((x1 - SIZE * 0.028, y1 - SIZE * 0.028, x1 + SIZE * 0.028, y1 + SIZE * 0.028), fill=CREAM)
    return im


def blackhole() -> Image.Image:
    im = base()
    d = ImageDraw.Draw(im)
    c = SIZE * 0.5
    r = SIZE * 0.24
    d.ellipse((c - r, c - r, c + r, c + r), outline=GOLD, width=9 * SS)
    # The event horizon: a dark core with one bright accretion arc.
    core = SIZE * 0.10
    d.ellipse((c - core, c - core, c + core, c + core), fill=INK)
    d.arc((c - r * 1.2, c - r * 1.2, c + r * 1.2, c + r * 1.2), 200, 340, fill=(226, 94, 64, 255), width=12 * SS)
    return im


def quiz() -> Image.Image:
    im = base()
    d = ImageDraw.Draw(im)
    c = SIZE * 0.5
    # A real bold question mark: the riddle should not be the icon itself.
    font = ImageFont.truetype("nakshatra/assets/fonts/ArchivoBlack-Regular.ttf", int(SIZE * 0.52))
    bbox = d.textbbox((0, 0), "?", font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    d.text((c - w * 0.5 - bbox[0], c - h * 0.52 - bbox[1]), "?", font=font, fill=CREAM)
    return im


ICONS = {
    "icon_moon": moon,
    "icon_stars": stars,
    "icon_scale": scale,
    "icon_seasons": seasons,
    "icon_flares": flares,
    "icon_blackhole": blackhole,
    "icon_quiz": quiz,
}


def main() -> None:
    root = os.path.join(os.path.dirname(__file__), "..", "nakshatra", "assets", "art", "icons")
    os.makedirs(root, exist_ok=True)
    for name, fn in ICONS.items():
        im = fn().resize((OUT, OUT), Image.Resampling.LANCZOS)
        path = os.path.join(root, f"{name}.png")
        im.save(path)
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
