#!/usr/bin/env python3
"""Build the images used by Seminar mode.

The presentation deck uses real captures of the shipped game, compressed for
the web export, plus one generated architecture diagram. Run this after
regenerating the itch screenshots:

    python tools/make_seminar_assets.py
"""
import os
import random

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ITCH = os.path.join(ROOT, "itch")
OUT = os.path.join(ROOT, "nakshatra", "assets", "seminar")
os.makedirs(OUT, exist_ok=True)

F_SERIF = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSerif-Bold.ttf")
F_BODY = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSans-Regular.ttf")
F_BODY_MED = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSans-Medium.ttf")

SHOTS = {
    "01_title.png": "title.webp",
    "10_sky_note.png": "why.webp",
    "02_sky_lab.png": "hub.webp",
    "03_moon_phases.png": "moon.webp",
    "04_constellations.png": "stars.webp",
    "05_solar_system.png": "scale.webp",
    "06_seasons.png": "seasons.webp",
    "11_solar_storm.png": "solar.webp",
    "12_black_hole.png": "blackhole.webp",
    "07_quiz.png": "quiz.webp",
    "08_certificate.png": "certificate.webp",
    "09_mobile_hub.png": "mobile.webp",
    "14_field_guide.png": "fieldguide.webp",
}

# (source, (left, top, right, bottom), output, output size) — crops that show
# one idea at a readable size instead of shrinking a whole 1280×720 UI into a
# slide.
CROPS = [
    ("08_certificate.png", (313, 161, 967, 529), "certificate_detail.webp", (1252, 704)),
]


def why_card():
    """A designed pull-quote card for the 'why this exists' slide.

    A screenshot of a whole lesson page shrinks its body text below the
    projector threshold, so this slide uses the lesson's idea at poster scale.
    """
    scale = 2
    W, H = 1252, 704
    img = Image.new("RGBA", (W * scale, H * scale), (244, 236, 221, 255))
    d = ImageDraw.Draw(img)
    ink = (20, 27, 42, 255)
    soft = (74, 83, 102, 255)
    gold = (148, 102, 43, 255)
    paper = (244, 236, 221, 255)

    # Subtle paper grain.
    rng = random.Random(11)
    for _ in range(1500):
        x, y = rng.randrange(W * scale), rng.randrange(H * scale)
        d.point((x, y), fill=(210, 196, 170, 40))

    # A quiet moon-phase motif in the lower right.
    cx, cy, r = 1018, 432, 140
    for i in range(3):
        d.arc([(cx - r - i * 8) * scale, (cy - r - i * 8) * scale,
               (cx + r + i * 8) * scale, (cy + r + i * 8) * scale],
              200, 340, fill=(148, 102, 43, 85), width=2 * scale)
    d.ellipse([(cx - 46) * scale, (cy - 46) * scale, (cx + 46) * scale, (cy + 46) * scale],
              outline=(148, 102, 43, 130), width=2 * scale)
    # A crescent: a gold disc with a paper-coloured disc offset across it.
    d.ellipse([(cx - 34) * scale, (cy - 34) * scale, (cx + 34) * scale, (cy + 34) * scale],
              fill=(231, 194, 125, 235))
    d.ellipse([(cx - 20) * scale, (cy - 40) * scale, (cx + 46) * scale, (cy + 28) * scale],
              fill=paper)

    d.text((86 * scale, 64 * scale), "SKY NOTE  ·  BEFORE THE INTERACTION",
           font=font(F_BODY_MED, 17 * scale), fill=gold)
    d.text((84 * scale, 112 * scale), "A blackboard can draw", font=font(F_SERIF, 58 * scale), fill=ink)
    d.text((84 * scale, 186 * scale), "a circle.", font=font(F_SERIF, 58 * scale), fill=ink)
    d.text((84 * scale, 300 * scale), "It cannot show why", font=font(F_SERIF, 58 * scale), fill=ink)
    d.text((84 * scale, 374 * scale), "the Moon changes shape.", font=font(F_SERIF, 58 * scale), fill=gold)

    d.rectangle([84 * scale, 482 * scale, 790 * scale, 485 * scale], fill=(148, 102, 43, 90))
    body = [
        "Every exhibit opens with a one-page written note:",
        "the big idea, the context and the key words —",
        "before the student touches anything.",
    ]
    ly = 510
    for line in body:
        d.text((86 * scale, ly * scale), line, font=font(F_BODY, 21 * scale), fill=soft)
        ly += 32

    d.text((86 * scale, 632 * scale), "NAKSHATRA  ·  THE SKY WEAVERS",
           font=font(F_BODY_MED, 13 * scale), fill=(148, 102, 43, 190))
    d.rectangle([0, 0, W * scale - 1, H * scale - 1], outline=(148, 102, 43, 90), width=2 * scale)

    img = img.resize((W, H), Image.LANCZOS).convert("RGB")
    img.save(os.path.join(OUT, "why_card.webp"), "WEBP", quality=90, method=6)
    print("image why_card.webp", img.size)


def convert_crops():
    for src, crop, dst, size in CROPS:
        path = os.path.join(ITCH, src)
        if not os.path.exists(path):
            print("missing", path)
            continue
        im = Image.open(path).convert("RGB").crop(crop)
        im = im.resize(size, Image.LANCZOS)
        im.save(os.path.join(OUT, dst), "WEBP", quality=88, method=6)
        print("crop", dst, im.size)


def convert_shots():
    for src, dst in SHOTS.items():
        path = os.path.join(ITCH, src)
        if not os.path.exists(path):
            print("missing", path)
            continue
        im = Image.open(path).convert("RGB")
        if im.width > 1280:
            im = im.resize((1280, round(im.height * 1280 / im.width)), Image.LANCZOS)
        im.save(os.path.join(OUT, dst), "WEBP", quality=86, method=6)
        print("image", dst, im.size)


def font(path, size):
    return ImageFont.truetype(path, size)


def wrap(draw, text, fnt, max_width):
    words = text.split()
    lines, line = [], ""
    for word in words:
        candidate = (line + " " + word).strip()
        if draw.textlength(candidate, font=fnt) <= max_width:
            line = candidate
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def architecture():
    """A three-stage pipeline that reads at slide size, not only on ENLARGE."""
    scale = 2
    W, H = 1200, 750
    img = Image.new("RGBA", (W * scale, H * scale), (7, 11, 22, 255))
    d = ImageDraw.Draw(img)

    rng = random.Random(7)
    for _ in range(180):
        x, y = rng.randrange(W * scale), rng.randrange(H * scale)
        a = rng.randrange(30, 140)
        r = 1 if rng.random() > 0.2 else 2
        d.ellipse([x, y, x + r, y + r], fill=(210, 220, 255, a))

    gold = (231, 194, 125, 255)
    teal = (121, 214, 201, 255)
    cream = (244, 236, 221, 255)
    muted = (170, 184, 204, 255)
    line = (231, 194, 125, 120)

    d.text((50 * scale, 38 * scale), "NAKSHATRA  ·  UNDER THE HOOD", font=font(F_BODY_MED, 22 * scale), fill=teal)
    d.text((48 * scale, 72 * scale), "From a star catalogue to a browser", font=font(F_SERIF, 44 * scale), fill=gold)
    d.text((50 * scale, 132 * scale), "Three stages. No server at play time.",
           font=font(F_BODY, 20 * scale), fill=muted)

    cols = [
        {
            "x": 50, "name": "DATA", "color": gold,
            "boxes": [
                ("HYG v3", ["8,879 naked-eye stars", "position · magnitude · colour"]),
                ("Skycultures", ["88 constellations", "28 nakshatras · line figures"]),
            ],
        },
        {
            "x": 425, "name": "BUILD", "color": teal,
            "boxes": [
                ("Python pipeline", ["compact JSON", "written at build time"]),
                ("Godot 4.7", ["12 scenes", "16 custom shaders"]),
            ],
        },
        {
            "x": 800, "name": "BROWSER", "color": cream,
            "boxes": [
                ("One MultiMesh", ["8,879 stars", "one draw call"]),
                ("Static folder", ["no server · no accounts", "offline after first load"]),
            ],
        },
    ]

    box_w = 350
    box_h = 120
    gap = 34
    top = 212
    for col in cols:
        x = col["x"]
        d.text((x * scale, 166 * scale), col["name"], font=font(F_BODY_MED, 24 * scale), fill=col["color"])
        d.rectangle([x * scale, 202 * scale, (x + box_w) * scale, 204 * scale], fill=col["color"])
        y = top
        for title, lines in col["boxes"]:
            d.rounded_rectangle(
                [x * scale, y * scale, (x + box_w) * scale, (y + box_h) * scale],
                radius=14 * scale,
                fill=(11, 20, 36, 255),
                outline=(col["color"][0], col["color"][1], col["color"][2], 110),
                width=2 * scale,
            )
            d.text(((x + 20) * scale, (y + 16) * scale), title,
                   font=font(F_BODY_MED, 28 * scale), fill=col["color"])
            ly = y + 60
            for text in lines:
                d.text(((x + 20) * scale, ly * scale), text,
                       font=font(F_BODY, 20 * scale), fill=muted)
                ly += 28
            y += box_h + gap

    for i in range(2):
        x1 = cols[i]["x"] + box_w + 8
        x2 = cols[i + 1]["x"] - 10
        y = top + box_h + gap // 2
        d.line([x1 * scale, y * scale, x2 * scale, y * scale], fill=line, width=3 * scale)
        d.polygon([(x2 * scale, y * scale), ((x2 - 12) * scale, (y - 7) * scale), ((x2 - 12) * scale, (y + 7) * scale)], fill=gold)

    d.rounded_rectangle([50 * scale, 668 * scale, 1150 * scale, 712 * scale],
                        radius=12 * scale, fill=(10, 18, 33, 255), outline=(231, 194, 125, 90), width=2 * scale)
    d.text((70 * scale, 680 * scale),
           "8,879 stars · 88 constellations · 28 nakshatras · 7 exhibits · 14 questions",
           font=font(F_BODY_MED, 20 * scale), fill=cream)

    img = img.resize((W, H), Image.LANCZOS).convert("RGB")
    path = os.path.join(OUT, "architecture.webp")
    img.save(path, "WEBP", quality=93, method=6)
    print("image architecture.webp", img.size)

if __name__ == "__main__":
    convert_shots()
    convert_crops()
    why_card()
    architecture()
    print("seminar assets written to", OUT)
