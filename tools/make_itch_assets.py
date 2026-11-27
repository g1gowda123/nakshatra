#!/usr/bin/env python3
"""Compose the itch.io cover and screenshots from the finished game art."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ITCH = os.path.join(ROOT, "itch")
os.makedirs(ITCH, exist_ok=True)
F_SERIF = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSerif-Bold.ttf")
F_BODY = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSans-Medium.ttf")


def font(path, size):
    return ImageFont.truetype(path, size)


def spaced(draw, xy, text, fnt, fill, spacing=3, anchor=None):
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=fill, anchor=anchor)
        x += draw.textlength(ch, font=fnt) + spacing


def cover():
    W, H = 630, 500
    art = Image.open(os.path.join(ROOT, "art_raw", "test_title.png")).convert("RGB")
    art = art.crop((14, 14, art.width - 14, art.height - 14))
    # cover-fit
    scale = max(W / art.width, H / art.height)
    art = art.resize((int(art.width * scale) + 1, int(art.height * scale) + 1), Image.LANCZOS)
    left = (art.width - W) // 2
    top = (art.height - H) // 2
    art = art.crop((left, top, left + W, top + H)).convert("RGBA")

    # darken bottom and left for type
    overlay = Image.new("L", (W, H), 0)
    od = ImageDraw.Draw(overlay)
    for y in range(H):
        t = max(0.0, (y - H * 0.35) / (H * 0.65))
        od.line([(0, y), (W, y)], fill=int(215 * t * t))
    leftmask = Image.new("L", (W, H), 0)
    ld = ImageDraw.Draw(leftmask)
    for x in range(W):
        t = max(0.0, (W * 0.55 - x) / (W * 0.55))
        ld.line([(x, 0), (x, H)], fill=int(80 * t))
    overlay = Image.composite(overlay, overlay, Image.new("L", (W, H), 255))
    dark = Image.new("RGBA", (W, H), (5, 9, 20, 255))
    art = Image.composite(dark, art, overlay)
    art = Image.composite(dark, art, leftmask.point(lambda v: int(v * 0.55)))

    d = ImageDraw.Draw(art)
    d.text((34, 286), "A SKY LAB FOR CURIOUS MINDS", font=font(F_BODY, 12), fill=(121, 214, 201))
    d.text((32, 300), "NAKSHATRA", font=font(F_SERIF, 66), fill=(231, 194, 125),
           stroke_width=1, stroke_fill=(60, 42, 18))
    spaced(d, (36, 378), "THE SKY WEAVERS", font(F_BODY, 15), (244, 236, 221), 4)
    d.text((36, 406), "Seven lanterns. One real sky. Choose any path.", font=font(F_BODY, 13),
           fill=(244, 236, 221))
    d.text((36, 430), "Free-choice space learning  ·  Classes 6–9  ·  plays on a phone", font=font(F_BODY, 10),
           fill=(155, 170, 193))
    d.line([(36, 456), (594, 456)], fill=(231, 194, 125, 90), width=1)
    d.text((36, 464), "REAL STARS  ·  MOON PHASES  ·  NAKSHATRAS  ·  SEASONS  ·  SOLAR STORMS  ·  BLACK HOLES",
           font=font(F_BODY, 9), fill=(231, 194, 125))

    # subtle gold frame
    d.rectangle([(0, 0), (W - 1, H - 1)], outline=(231, 194, 125, 130), width=2)
    art.convert("RGB").save(os.path.join(ITCH, "cover.png"), quality=95)
    art.resize((315, 250), Image.LANCZOS).convert("RGB").save(os.path.join(ITCH, "cover_small.png"))
    print("cover written")


SHOTS = [
    ("shots/boot_new.png", "01_title.png"),
    ("shots/hub7_desktop.png", "02_sky_lab.png"),
    ("shots/moon_check2.png", "03_moon_phases.png"),
    ("shots/star_success3.png", "04_constellations.png"),
    ("shots/scale_selected2.png", "05_solar_system.png"),
    ("shots/seasons_d2.png", "06_seasons.png"),
    ("shots/quiz14.png", "07_quiz.png"),
    ("shots/finale8.png", "08_certificate.png"),
    ("shots/hub7_mobile.png", "09_mobile_hub.png"),
    ("shots/solar_desktop1.png", "10_sky_note.png"),
    ("shots/solar_flare_launch.png", "11_solar_storm.png"),
    ("shots/bh_lab_final.png", "12_black_hole.png"),
    ("shots/bh_options3.png", "13_black_hole_question.png"),
    ("shots/fieldguide2.png", "14_field_guide.png"),
]


def shots():
    for src, dst in SHOTS:
        p = os.path.join(ROOT, "art_raw", src)
        if not os.path.exists(p):
            print("missing", p)
            continue
        im = Image.open(p).convert("RGB")
        if im.width > 1280:
            im = im.resize((1280, int(im.height * 1280 / im.width)), Image.LANCZOS)
        im.save(os.path.join(ITCH, dst), quality=92)
        print("shot", dst, im.size)


cover()
shots()
