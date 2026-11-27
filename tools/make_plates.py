"""Draw the seven exhibit plates + title plate as engraved almanac diagrams.

Everything is generated with flat shapes and hairlines in the game palette, so
the art reads as printed linework rather than a generated illustration. Run:

    .venv/bin/python tools/make_plates.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "nakshatra", "assets", "art", "plates")
FONT_DISPLAY = os.path.join(ROOT, "nakshatra", "assets", "fonts", "CormorantGaramond-Variable.ttf")
FONT_SANS = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSans-Medium.ttf")

INK = (9, 15, 26, 255)
INK2 = (13, 22, 38, 255)
GOLD = (217, 179, 108, 255)
GOLD_DIM = (217, 179, 108, 110)
GOLD_FAINT = (217, 179, 108, 46)
CREAM = (242, 232, 213, 255)
MUTED = (150, 163, 184, 200)
VERM = (207, 107, 74, 230)
TEAL = (143, 199, 184, 210)

SS = 2  # supersample


def canvas(w, h):
    img = Image.new("RGB", (w * SS, h * SS), INK)
    d = ImageDraw.Draw(img)
    for y in range(h * SS):
        t = y / max(1, h * SS - 1)
        r = int(13 - 8 * t)
        g = int(22 - 13 * t)
        b = int(38 - 22 * t)
        d.line([(0, y), (w * SS, y)], fill=(r, g, b))
    # vignette
    vign = Image.new("L", (w * SS, h * SS), 0)
    vd = ImageDraw.Draw(vign)
    vd.ellipse([-w * SS * 0.35, -h * SS * 0.35, w * SS * 1.35, h * SS * 1.35], fill=255)
    vign = vign.filter(ImageFilter.GaussianBlur(w * SS * 0.18))
    black = Image.new("RGB", img.size, (2, 4, 8))
    img = Image.composite(img, black, vign)
    return img


def grain(img, strength=10):
    noise = Image.effect_noise(img.size, 26).convert("L")
    noise = noise.filter(ImageFilter.GaussianBlur(0.4))
    overlay = Image.merge("RGB", (noise, noise, noise))
    return Image.blend(img, overlay, strength / 255.0)


def border(img, w, h, inset=22):
    d = ImageDraw.Draw(img, "RGBA")
    s = SS
    d.rectangle([inset * s, inset * s, w * s - inset * s, h * s - inset * s], outline=GOLD_DIM, width=max(1, s))
    d.rectangle([(inset + 5) * s, (inset + 5) * s, w * s - (inset + 5) * s, h * s - (inset + 5) * s], outline=GOLD_FAINT, width=max(1, s))
    # corner ticks
    for cx, cy, dx, dy in [(inset, inset, 1, 1), (w - inset, inset, -1, 1),
                           (inset, h - inset, 1, -1), (w - inset, h - inset, -1, -1)]:
        x, y = cx * s, cy * s
        d.line([(x, y), (x + dx * 16 * s, y)], fill=GOLD, width=s)
        d.line([(x, y), (x, y + dy * 16 * s)], fill=GOLD, width=s)


def stars(d, w, h, count=70, seed=1, maxr=2.2):
    rnd = random.Random(seed)
    for _ in range(count):
        x = rnd.uniform(40, w - 40) * SS
        y = rnd.uniform(40, h - 40) * SS
        r = rnd.uniform(0.5, maxr) * SS
        a = int(rnd.uniform(30, 150))
        d.ellipse([x - r, y - r, x + r, y + r], fill=(242, 232, 213, a))


def diamond(d, x, y, r, fill=None, outline=None, width=1):
    pts = [(x, y - r), (x + r, y), (x, y + r), (x - r, y)]
    if fill:
        d.polygon(pts, fill=fill)
    if outline:
        d.line(pts + [pts[0]], fill=outline, width=width, joint="curve")


def label(d, x, y, text, w=3, h=12):
    """Tiny engraved caption made of bars, not a font."""
    for ch in text:
        if ch == " ":
            x += w * 2
            continue
        d.rectangle([x, y, x + w, y + h], fill=GOLD_DIM)
        x += w * 2


def _font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def tracked_text(img, x, y, text, size=18, color=GOLD, tracking=4, font_path=FONT_SANS):
    """Draw letterspaced text; tracking is in output pixels."""
    d = ImageDraw.Draw(img, "RGBA")
    f = _font(font_path, size * SS)
    cx = x * SS
    for ch in text:
        d.text((cx, y * SS), ch, font=f, fill=color)
        w = d.textlength(ch, font=f)
        cx += w + tracking * SS
    return cx


def plate_caption(img, w, h, number, title, micro="NAKSHATRA · CHANDRAGIRI"):
    tracked_text(img, 40, 36, number, 15, (217, 179, 108, 190), 3)
    tracked_text(img, 40, h - 66, title, 17, (242, 232, 213, 210), 2, FONT_DISPLAY)
    d = ImageDraw.Draw(img, "RGBA")
    f = _font(FONT_SANS, 11 * SS)
    tw = d.textlength(micro, font=f)
    d.text((w * SS - 40 * SS - tw, (h - 58) * SS), micro, font=f, fill=(150, 163, 184, 150))


def hatch(img, mask, color=(217, 179, 108, 40), spacing=7, width=1):
    """Clip a set of diagonal hairlines to the given L mask."""
    w, h = img.size
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    step = spacing * SS
    for x in range(-h, w + h, step):
        d.line([(x, 0), (x + h, h)], fill=color, width=width * SS)
    img.paste(layer, (0, 0), mask)


def dashed_arc(d, box, start, end, color, width=2, dash=10, gap=8):
    # approximate dashed arc by stepping angles
    cx = (box[0] + box[2]) / 2
    cy = (box[1] + box[3]) / 2
    rx = (box[2] - box[0]) / 2
    ry = (box[3] - box[1]) / 2
    step = 360.0 / max(1, int((abs(end - start)) / 2.0))
    a = start
    while a < end:
        b = min(a + step, end)
        if int(a / step) % 2 == 0:
            pts = []
            aa = a
            while aa <= b:
                t = math.radians(aa)
                pts.append((cx + rx * math.cos(t), cy + ry * math.sin(t)))
                aa += 1.0
            if len(pts) > 1:
                d.line(pts, fill=color, width=width)
        a = b


def moon_phase(size, phase, bg):
    """phase 0=new, 0.25=first quarter, 0.5=full, 0.75=last quarter."""
    r = size // 2
    disc = Image.new("RGBA", (size + 4, size + 4), (0, 0, 0, 0))
    dd = ImageDraw.Draw(disc)
    dd.ellipse([2, 2, size + 2, size + 2], fill=(10, 16, 28, 255))
    # illuminated region: a half-disc plus/minus the terminator ellipse
    lit = Image.new("L", disc.size, 0)
    ld = ImageDraw.Draw(lit)
    if phase < 0.5:
        ld.pieslice([2, 2, size + 2, size + 2], -90, 90, fill=255)  # right half
    else:
        ld.pieslice([2, 2, size + 2, size + 2], 90, 270, fill=255)  # left half
    e = abs(math.cos(phase * 2 * math.pi)) * r
    if 0.25 < phase < 0.75:
        ld.ellipse([2 + r - e, 2, 2 + r + e, size + 2], fill=255)
    else:
        ld.ellipse([2 + r - e, 2, 2 + r + e, size + 2], fill=0)
    # clip the lit mask to the disc
    clip = Image.new("L", disc.size, 0)
    ImageDraw.Draw(clip).ellipse([2, 2, size + 2, size + 2], fill=255)
    lit = Image.composite(lit, Image.new("L", disc.size, 0), clip)
    disc.paste(Image.new("RGBA", disc.size, CREAM), (0, 0), lit)
    rim = ImageDraw.Draw(disc)
    rim.ellipse([2, 2, size + 2, size + 2], outline=GOLD, width=2 * SS)
    return disc


def plate_moon(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 55, 2)
    # four phases in a row, the way a field guide prints them
    phases = [0.0, 0.25, 0.5, 0.75]
    names = ["NEW", "FIRST Q.", "FULL", "LAST Q."]
    for i, (ph, name) in enumerate(zip(phases, names)):
        mx = 168 + i * 144
        my = 300
        size = 86
        disc = moon_phase(size, ph, (8, 13, 24))
        img.paste(disc, (int(mx * SS - size), int(my * SS - size)), disc)
        tracked_text(img, mx - 26, my + 52, "I II III IV".split()[i], 12, (217, 179, 108, 180), 2)
        tracked_text(img, mx - 30, my + 70, name, 10, (150, 163, 184, 190), 1)
    # the geometry underneath
    cx, cy = 384, 610
    earth_r = 66
    box = [(cx - 250) * SS, (cy - 250) * SS, (cx + 250) * SS, (cy + 250) * SS]
    dashed_arc(d, box, -178, -2, GOLD_DIM, 2 * SS, 12 * SS, 9 * SS)
    d.ellipse([(cx - earth_r) * SS, (cy - earth_r) * SS, (cx + earth_r) * SS, (cy + earth_r) * SS], fill=INK2, outline=GOLD, width=2 * SS)
    for rr in [earth_r * 0.66, earth_r * 0.38]:
        d.arc([(cx - rr) * SS, (cy - rr) * SS, (cx + rr) * SS, (cy + rr) * SS], 20, 200, fill=GOLD_FAINT, width=SS)
    tracked_text(img, cx - 26, cy + earth_r + 8, "EARTH", 11, (150, 163, 184, 200), 2)
    # sun edge and light direction
    d.line([(34 * SS, cy * SS), ((cx - earth_r - 16) * SS, cy * SS)], fill=GOLD_FAINT, width=SS)
    d.ellipse([(20) * SS, (cy - 12) * SS, (44) * SS, (cy + 12) * SS], outline=GOLD, width=2 * SS)
    # the moon on its orbit
    t = math.radians(-64)
    mx = cx + 250 * math.cos(t)
    my = cy + 250 * math.sin(t)
    disc = moon_phase(42, 0.14, (8, 13, 24))
    img.paste(disc, (int(mx * SS - 21), int(my * SS - 21)), disc)
    d.line([(cx * SS, cy * SS), (mx * SS, my * SS)], fill=GOLD_FAINT, width=SS)
    plate_caption(img, w, h, "PLATE 01", "THE MOON'S MASK")
    border(img, w, h)
    return grain(img)


def plate_stars(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 90, 5)
    # nakshatra rim and 28 ticks
    cx, cy, r = 384, 384, 292
    d.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS], outline=GOLD_FAINT, width=SS)
    for i in range(28):
        a = math.radians(i * 360 / 28 - 90)
        x1 = cx + (r - 12) * math.cos(a)
        y1 = cy + (r - 12) * math.sin(a)
        x2 = cx + (r + (12 if i % 7 == 0 else 5)) * math.cos(a)
        y2 = cy + (r + (12 if i % 7 == 0 else 5)) * math.sin(a)
        d.line([(x1 * SS, y1 * SS), (x2 * SS, y2 * SS)], fill=GOLD_DIM if i % 7 == 0 else GOLD_FAINT, width=SS)
    # Saptarishi, enlarged across the field
    pts = [(170, 480), (215, 400), (300, 375), (392, 415), (470, 365), (560, 405), (632, 320)]
    for i in range(len(pts) - 1):
        d.line([(pts[i][0] * SS, pts[i][1] * SS), (pts[i + 1][0] * SS, pts[i + 1][1] * SS)], fill=GOLD_DIM, width=2 * SS)
    for i, (x, y) in enumerate(pts):
        rr = 15 if i in (0, 6) else 10
        diamond(d, x * SS, y * SS, rr * SS, fill=CREAM if i != 2 else VERM, outline=GOLD, width=SS)
        d.ellipse([(x - 2) * SS, (y - 2) * SS, (x + 2) * SS, (y + 2) * SS], fill=GOLD)
    # a second, fainter figure
    faint = [(180, 245), (235, 210), (298, 232), (330, 288), (300, 340)]
    for i in range(len(faint) - 1):
        d.line([(faint[i][0] * SS, faint[i][1] * SS), (faint[i + 1][0] * SS, faint[i + 1][1] * SS)], fill=GOLD_FAINT, width=SS)
    for x, y in faint:
        d.ellipse([(x - 4) * SS, (y - 4) * SS, (x + 4) * SS, (y + 4) * SS], fill=MUTED)
    # cartouche
    d.rectangle([48 * SS, 120 * SS, 250 * SS, 196 * SS], outline=GOLD_DIM, width=SS)
    tracked_text(img, 62, 132, "SAPTARISHI", 16, (217, 179, 108, 210), 3, FONT_DISPLAY)
    tracked_text(img, 62, 160, "THE SEVEN SAGES", 9, (150, 163, 184, 190), 2)
    plate_caption(img, w, h, "PLATE 02", "THREAD THE STARS")
    border(img, w, h)
    return grain(img)


def plate_planets(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 45, 7, 1.6)
    # sun at left
    sx, sy = 150, 360
    for rr in [90, 70, 52]:
        d.ellipse([(sx - rr) * SS, (sy - rr) * SS, (sx + rr) * SS, (sy + rr) * SS], outline=GOLD_FAINT if rr > 52 else GOLD_DIM, width=SS)
    d.ellipse([(sx - 34) * SS, (sy - 34) * SS, (sx + 34) * SS, (sy + 34) * SS], fill=GOLD)
    tracked_text(img, sx - 16, sy + 46, "SUN", 10, (217, 179, 108, 200), 2)
    # orbit arcs
    for i, rr in enumerate([150, 205, 265, 330, 400, 470, 540]):
        dashed_arc(d, [(sx - rr) * SS, (sy - rr * 0.62) * SS, (sx + rr) * SS, (sy + rr * 0.62) * SS], -86, 86, GOLD_FAINT if i % 2 else GOLD_DIM, SS, 8 * SS, 7 * SS)
    rnd = random.Random(11)
    radii = [140, 190, 245, 305, 365, 425, 480, 520]
    sizes = [7, 10, 11, 9, 17, 15, 12, 11]
    for i, (rr, sz) in enumerate(zip(radii, sizes)):
        ang = math.radians(rnd.uniform(-55, 55))
        x = sx + rr * math.cos(ang)
        y = sy + rr * 0.62 * math.sin(ang)
        x = min(max(x, 90), 690)
        y = min(max(y, 120), 560)
        d.ellipse([(x - sz) * SS, (y - sz) * SS, (x + sz) * SS, (y + sz) * SS], fill=CREAM if rr < 500 else MUTED, outline=GOLD, width=SS)
        tracked_text(img, x + sz + 5, y - 6, str(i + 1), 9, (150, 163, 184, 170), 1)
    # scale rule along the bottom
    y = 650
    d.line([(120 * SS, y * SS), (648 * SS, y * SS)], fill=GOLD_DIM, width=SS)
    for i in range(13):
        x = 120 + i * 44
        d.line([(x * SS, (y - (8 if i % 3 == 0 else 4)) * SS), (x * SS, y * SS)], fill=GOLD_DIM, width=SS)
    tracked_text(img, 120, y + 14, "SUN", 9, (150, 163, 184, 160), 1)
    tracked_text(img, 600, y + 14, "EDGE", 9, (150, 163, 184, 160), 1)
    plate_caption(img, w, h, "PLATE 03", "THE LONG ROAD")
    border(img, w, h)
    return grain(img)


def plate_seasons(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 40, 13, 1.5)
    cx, cy = 384, 384
    d.ellipse([(cx - 250) * SS, (cy - 150) * SS, (cx + 250) * SS, (cy + 150) * SS], outline=GOLD_DIM, width=SS)
    d.ellipse([(cx - 42) * SS, (cy - 42) * SS, (cx + 42) * SS, (cy + 42) * SS], fill=GOLD)
    for rr in [54, 66]:
        d.ellipse([(cx - rr) * SS, (cy - rr) * SS, (cx + rr) * SS, (cy + rr) * SS], outline=GOLD_FAINT, width=SS)
    # four earths; axis always parallel
    positions = [(-250, 0, "equinox"), (0, -150, "solstice"), (250, 0, "equinox"), (0, 150, "solstice")]
    for i, (dx, dy, kind) in enumerate(positions):
        x, y = cx + dx, cy + dy
        r = 30
        d.ellipse([(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS], fill=INK2, outline=GOLD, width=2 * SS)
        # lit half toward the sun
        d.pieslice([(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS], 90, 270, fill=(242, 232, 213, 60))
        # axis (gold; the one red accent in this plate is the tilt callout)
        ax = math.radians(-23)
        d.line([(x + math.sin(ax) * (r + 16) * SS, y - math.cos(ax) * (r + 16) * SS),
                (x - math.sin(ax) * (r + 16) * SS, y + math.cos(ax) * (r + 16) * SS)], fill=GOLD_DIM, width=2 * SS)
        d.ellipse([(x - 3) * SS, (y - 3) * SS, (x + 3) * SS, (y + 3) * SS], fill=GOLD)
        if kind == "solstice":
            d.arc([(x - 46) * SS, (y - 46) * SS, (x + 46) * SS, (y + 46) * SS], 200, 340, fill=GOLD_FAINT, width=SS)
    # season marks
    seasons = ["MAR", "JUN", "SEP", "DEC"]
    for i, ang in enumerate([0, 90, 180, 270]):
        t = math.radians(ang)
        x1 = cx + 250 * math.cos(t)
        y1 = cy + 150 * math.sin(t)
        diamond(d, x1 * SS, y1 * SS, 6 * SS, fill=GOLD)
        tracked_text(img, x1 - 12, y1 + (18 if ang in (0, 180) else -30), seasons[i], 10, (150, 163, 184, 190), 2)
    tracked_text(img, cx + 40, cy - 66, "23.4°", 11, (207, 107, 74, 200), 1)
    plate_caption(img, w, h, "PLATE 04", "THE TURNING YEAR")
    border(img, w, h)
    return grain(img)


def plate_flares(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 45, 17, 1.5)
    sx, sy = 250, 430
    d.ellipse([(sx - 120) * SS, (sy - 120) * SS, (sx + 120) * SS, (sy + 120) * SS], fill=(20, 16, 12, 255), outline=GOLD, width=2 * SS)
    # hatched solar surface
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse([(sx - 120) * SS, (sy - 120) * SS, (sx + 120) * SS, (sy + 120) * SS], fill=255)
    hatch(img, mask, (217, 179, 108, 34), 9, 1)
    d = ImageDraw.Draw(img, "RGBA")
    for rr in [132, 148, 168]:
        d.arc([(sx - rr) * SS, (sy - rr) * SS, (sx + rr) * SS, (sy + rr) * SS], 0, 360, fill=GOLD_FAINT, width=SS)
    tracked_text(img, sx - 18, sy + 128, "SUN", 11, (217, 179, 108, 190), 2)
    # magnetic loops
    for i, rr in enumerate([150, 180, 210]):
        d.arc([(sx - rr) * SS, (sy - rr * 1.2) * SS, (sx + rr) * SS, (sy + rr * 0.2) * SS], 190, 350, fill=VERM if i == 1 else GOLD_DIM, width=2 * SS)
    # prominence
    d.arc([(sx + 40) * SS, (sy - 190) * SS, (sx + 230) * SS, (sy + 20) * SS], 180, 300, fill=VERM, width=3 * SS)
    # CME path to earth
    ex, ey = 610, 300
    pts = []
    for i in range(60):
        t = i / 59
        x = sx + 140 + t * 240
        y = sy - 60 - math.sin(t * math.pi) * 150 - t * 20
        pts.append((x * SS, y * SS))
    d.line(pts, fill=GOLD_DIM, width=2 * SS)
    for i in range(0, 60, 8):
        x, y = pts[i]
        d.ellipse([x - 3 * SS, y - 3 * SS, x + 3 * SS, y + 3 * SS], fill=VERM)
    d.ellipse([(ex - 34) * SS, (ey - 34) * SS, (ex + 34) * SS, (ey + 34) * SS], fill=INK2, outline=GOLD, width=2 * SS)
    d.arc([(ex - 22) * SS, (ey - 22) * SS, (ex + 22) * SS, (ey + 22) * SS], 200, 340, fill=GOLD_FAINT, width=SS)
    tracked_text(img, ex - 24, ey + 44, "EARTH", 10, (150, 163, 184, 190), 2)
    tracked_text(img, 510, 180, "CME", 11, (207, 107, 74, 200), 2)
    plate_caption(img, w, h, "PLATE 05", "SOLAR STORMS")
    border(img, w, h)
    return grain(img)


def plate_blackhole(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 80, 23, 2.0)
    cx, cy = 384, 384
    # lensed star rings
    for rr in [250, 210, 175, 150, 130]:
        d.ellipse([(cx - rr) * SS, (cy - rr) * SS, (cx + rr) * SS, (cy + rr) * SS], outline=GOLD_FAINT, width=SS)
    # accretion disk ellipse
    d.ellipse([(cx - 240) * SS, (cy - 80) * SS, (cx + 240) * SS, (cy + 80) * SS], outline=GOLD_DIM, width=2 * SS)
    d.arc([(cx - 240) * SS, (cy - 80) * SS, (cx + 240) * SS, (cy + 80) * SS], 200, 340, fill=VERM, width=4 * SS)
    # photon ring
    d.ellipse([(cx - 78) * SS, (cy - 78) * SS, (cx + 78) * SS, (cy + 78) * SS], outline=GOLD, width=3 * SS)
    d.ellipse([(cx - 66) * SS, (cy - 66) * SS, (cx + 66) * SS, (cy + 66) * SS], fill=(2, 3, 6, 255))
    # probe path
    d.line([(cx + 330 * SS, cy - 260 * SS), (cx + 120 * SS, cy - 100 * SS), (cx + 70 * SS, cy - 40 * SS)], fill=GOLD_DIM, width=SS)
    for t in [0, 0.4, 0.75]:
        x = cx + 330 - t * 260
        y = cy - 260 + t * 220
        d.ellipse([(x - 4) * SS, (y - 4) * SS, (x + 4) * SS, (y + 4) * SS], fill=CREAM)
    # 4 lensed star images
    for ang in [40, 130, 220, 310]:
        t = math.radians(ang)
        x = cx + 165 * math.cos(t)
        y = cy + 165 * math.sin(t)
        d.ellipse([(x - 3) * SS, (y - 3) * SS, (x + 3) * SS, (y + 3) * SS], fill=CREAM)
    # leader labels
    d.line([(cx + 80 * SS, cy + 20 * SS), (cx + 190 * SS, cy + 120 * SS)], fill=GOLD_DIM, width=SS)
    tracked_text(img, cx + 196, cy + 112, "EVENT HORIZON", 10, (217, 179, 108, 190), 2)
    d.line([(cx + 200 * SS, cy - 40 * SS), (cx + 285 * SS, cy - 105 * SS)], fill=GOLD_DIM, width=SS)
    tracked_text(img, cx + 220, cy - 122, "ACCRETION DISK", 10, (217, 179, 108, 190), 2)
    plate_caption(img, w, h, "PLATE 06", "THE EVENT HORIZON")
    border(img, w, h)
    return grain(img)


def plate_quiz(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 55, 29, 1.7)
    # a question mark traced in stars
    pts = [(300, 250), (360, 205), (440, 215), (478, 280), (458, 350), (390, 392), (372, 452), (372, 500)]
    for i in range(len(pts) - 1):
        d.line([(pts[i][0] * SS, pts[i][1] * SS), (pts[i + 1][0] * SS, pts[i + 1][1] * SS)], fill=GOLD_DIM, width=2 * SS)
    for i, (x, y) in enumerate(pts):
        rr = 15 if i in (0, 6) else 10
        diamond(d, x * SS, y * SS, rr * SS, fill=VERM if i == 6 else CREAM, outline=GOLD, width=SS)
    diamond(d, 372 * SS, 560 * SS, 13 * SS, fill=VERM, outline=GOLD, width=SS)
    # 14 answer slots, three marked
    y = 636
    for i in range(14):
        x = 250 + i * 20
        d.rectangle([x * SS, y * SS, (x + 10) * SS, (y + 24) * SS], outline=GOLD_DIM if i not in (3, 9, 11) else VERM, width=SS)
        if i in (3, 9, 11):
            d.line([(x * SS, (y + 24) * SS), ((x + 10) * SS, y * SS)], fill=VERM, width=SS)
    tracked_text(img, 250, y + 34, "FOURTEEN RIDDLES · NO TIMER", 9, (150, 163, 184, 180), 1)
    plate_caption(img, w, h, "PLATE 07", "SKY RIDDLES")
    border(img, w, h)
    return grain(img)


def plate_atlas(w=768, h=768):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 60, 31, 1.6)
    cx, cy = 384, 384
    for rr in [290, 250, 210, 170, 130]:
        d.ellipse([(cx - rr) * SS, (cy - rr) * SS, (cx + rr) * SS, (cy + rr) * SS], outline=GOLD_DIM if rr in (290, 210) else GOLD_FAINT, width=SS)
    for i in range(36):
        a = math.radians(i * 10)
        r1 = 250 if i % 3 == 0 else 270
        d.line([(cx + r1 * math.cos(a) * SS, cy + r1 * math.sin(a) * SS),
                (cx + 290 * math.cos(a) * SS, cy + 290 * math.sin(a) * SS)], fill=GOLD_DIM, width=SS)
    # compass rose
    for a in [0, 45, 90, 135]:
        t = math.radians(a)
        d.line([(cx - 120 * math.cos(t) * SS, cy - 120 * math.sin(t) * SS),
                (cx + 120 * math.cos(t) * SS, cy + 120 * math.sin(t) * SS)], fill=GOLD_FAINT, width=SS)
    diamond(d, cx * SS, cy * SS, 26 * SS, fill=GOLD, outline=None)
    diamond(d, cx * SS, cy * SS, 8 * SS, fill=INK)
    # small constellation overlay, enlarged
    pts = [(250, 330), (312, 276), (392, 308), (458, 250), (530, 306), (566, 386)]
    for i in range(len(pts) - 1):
        d.line([(pts[i][0] * SS, pts[i][1] * SS), (pts[i + 1][0] * SS, pts[i + 1][1] * SS)], fill=CREAM if i % 2 else GOLD, width=SS)
    for x, y in pts:
        diamond(d, x * SS, y * SS, 6 * SS, fill=CREAM, outline=GOLD, width=SS)
    for label, x, y in [("N", 384, 84), ("E", 686, 380), ("S", 384, 676), ("W", 82, 380)]:
        tracked_text(img, x, y, label, 12, (217, 179, 108, 200), 0)
    plate_caption(img, w, h, "PLATE 08", "SKY ATLAS")
    border(img, w, h)
    return grain(img)


def plate_title(w=1200, h=900):
    img = canvas(w, h)
    d = ImageDraw.Draw(img, "RGBA")
    stars(d, w, h, 120, 41, 2.2)
    # big moon
    mx, my, mr = 880, 270, 128
    moon = moon_phase(mr * 2, 0.5, (10, 17, 30))
    img.paste(moon, (mx - mr, my - mr), moon)
    for rr in range(mr, mr + 30, 6):
        d.arc([(mx - rr) * SS, (my - rr) * SS, (mx + rr) * SS, (my + rr) * SS], 0, 360, fill=(217, 179, 108, 24), width=SS)
    # constellation line
    cst = [(170, 190), (250, 150), (330, 178), (300, 250), (220, 268)]
    for i in range(len(cst) - 1):
        d.line([(cst[i][0] * SS, cst[i][1] * SS), (cst[i + 1][0] * SS, cst[i + 1][1] * SS)], fill=GOLD_FAINT, width=SS)
    for x, y in cst:
        d.ellipse([(x - 3) * SS, (y - 3) * SS, (x + 3) * SS, (y + 3) * SS], fill=CREAM)
    # layered hills
    layers = [
        (0.62, (16, 27, 44, 255), GOLD_FAINT),
        (0.70, (13, 23, 38, 255), GOLD_DIM),
        (0.79, (10, 18, 31, 255), GOLD_DIM),
    ]
    for frac, col, line in layers:
        base = h * frac
        pts = [(0, h)]
        for i in range(0, w + 40, 40):
            x = i
            y = base - math.sin(i * 0.011 + frac * 9) * (28 if frac < 0.7 else 18) - math.sin(i * 0.031) * 8
            pts.append((x, y))
        pts.append((w, h))
        d.polygon([(x * SS, y * SS) for x, y in pts], fill=col)
        d.line([(x * SS, y * SS) for x, y in pts[1:-1]], fill=line, width=SS)
    # observatory on the middle hill
    ox, oy = 360, 600
    d.rectangle([(ox - 46) * SS, (oy - 34) * SS, (ox + 46) * SS, oy * SS], fill=(22, 33, 52, 255), outline=GOLD, width=2 * SS)
    d.pieslice([(ox - 52) * SS, (oy - 92) * SS, (ox + 52) * SS, (oy + 12) * SS], 180, 360, fill=(15, 24, 40, 255), outline=GOLD, width=2 * SS)
    d.rectangle([(ox - 8) * SS, (oy - 18) * SS, (ox + 8) * SS, oy * SS], fill=(230, 168, 84, 255))
    # seven lantern posts along the hill
    for i, lx in enumerate([520, 610, 700, 790, 880, 970, 1060]):
        ly = 640 - abs(3 - i) * 6
        d.line([(lx * SS, (ly - 16) * SS), (lx * SS, ly * SS)], fill=GOLD_DIM, width=SS)
        d.ellipse([(lx - 7) * SS, (ly - 30) * SS, (lx + 7) * SS, (ly - 16) * SS], fill=(244, 190, 110, 255))
        d.ellipse([(lx - 16) * SS, (ly - 39) * SS, (lx + 16) * SS, (ly - 7) * SS], outline=(244, 190, 110, 45), width=SS)
    # path
    path = []
    for i in range(50):
        t = i / 49
        x = 380 + math.sin(t * 2.4) * 40 + t * 210
        y = 900 - t * 300
        path.append((x * SS, y * SS))
    d.line(path, fill=(217, 179, 108, 35), width=8 * SS)
    tracked_text(img, 42, h - 58, "CHANDRAGIRI  ·  13° N", 10, (217, 179, 108, 150), 2)
    border(img, w, h, 26)
    return grain(img)


def main():
    os.makedirs(OUT, exist_ok=True)
    plates = {
        "plate_moon": plate_moon,
        "plate_stars": plate_stars,
        "plate_planets": plate_planets,
        "plate_seasons": plate_seasons,
        "plate_flares": plate_flares,
        "plate_blackhole": plate_blackhole,
        "plate_quiz": plate_quiz,
        "plate_atlas": plate_atlas,
        "plate_title": plate_title,
    }
    for name, fn in plates.items():
        img = fn()
        w, h = img.size
        img = img.resize((w // SS, h // SS), Image.LANCZOS)
        path = os.path.join(OUT, name + ".webp")
        img.save(path, "WEBP", quality=92, method=6)
        print("wrote", path, img.size, os.path.getsize(path))


if __name__ == "__main__":
    main()
