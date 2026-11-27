"""Compose the itch.io cover from the code-drawn title plate + game type."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ITCH = os.path.join(ROOT, "itch")
PLATE = os.path.join(ROOT, "nakshatra", "assets", "art", "plates", "plate_title.webp")
DISPLAY = os.path.join(ROOT, "nakshatra", "assets", "fonts", "CormorantGaramond-Variable.ttf")
SANS = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSans-Medium.ttf")
KAN = os.path.join(ROOT, "nakshatra", "assets", "fonts", "NotoSansKannada-Regular.ttf")

INK = (6, 9, 16)
CREAM = (242, 232, 213)
GOLD = (217, 179, 108)
MUTED = (174, 184, 202)


def tracked(d, xy, text, font, fill, tracking=3):
    x, y = xy
    for ch in text:
        d.text((x, y), ch, font=font, fill=fill)
        x += d.textlength(ch, font=font) + tracking


def make(w=630, h=500):
    img = Image.new("RGB", (w, h), INK)
    # right-hand plate, cover-fit and bleeding off the edge
    plate = Image.open(PLATE).convert("RGB")
    pw = 360
    scale = h / plate.height
    scaled_w = int(plate.width * scale)
    plate = plate.resize((scaled_w, h), Image.LANCZOS)
    left_src = max(0, scaled_w - pw)
    crop = plate.crop((left_src, 0, left_src + pw, h))
    img.paste(crop, (w - pw, 0))
    # fade the plate into the page on its left edge
    fade = Image.new("L", (pw, h), 0)
    fd = ImageDraw.Draw(fade)
    for x in range(pw):
        fd.line([(x, 0), (x, h)], fill=int(255 * min(1.0, x / (pw * 0.35))))
    black = Image.new("RGB", (pw, h), INK)
    left = img.crop((w - pw, 0, w, h))
    img.paste(Image.composite(left, black, fade), (w - pw, 0))

    d = ImageDraw.Draw(img)
    # frame
    d.rectangle([14, 14, w - 14, h - 14], outline=(217, 179, 108, 255), width=1)
    d.rectangle([19, 19, w - 19, h - 19], outline=(217, 179, 108, 90), width=1)

    # brand
    d.text((34, 40), "✦", font=ImageFont.truetype(DISPLAY, 20), fill=GOLD)
    tracked(d, (58, 44), "NAKSHATRA", ImageFont.truetype(SANS, 11), GOLD, 3)

    # title
    d.text((32, 82), "Nakshatra", font=ImageFont.truetype(DISPLAY, 66), fill=CREAM)
    tracked(d, (35, 168), "THE SKY WEAVERS", ImageFont.truetype(SANS, 11), GOLD, 5)
    d.text((35, 190), "ನಕ್ಷತ್ರ  /  ಆಕಾಶ ನೇಯುವವರು", font=ImageFont.truetype(KAN, 13), fill=(217, 179, 108, 180))
    d.line([(35, 222), (292, 222)], fill=(217, 179, 108, 110), width=1)
    d.text((35, 238), "Seven lanterns on a hill.", font=ImageFont.truetype(DISPLAY, 22), fill=CREAM)
    d.text((35, 266), "One real sky.", font=ImageFont.truetype(DISPLAY, 22), fill=CREAM)
    d.text((35, 300), "A free-choice astronomy lab for Classes 6–9.", font=ImageFont.truetype(SANS, 11), fill=MUTED)
    d.text((35, 318), "Moon phases · nakshatras · scale · seasons ·", font=ImageFont.truetype(SANS, 11), fill=MUTED)
    d.text((35, 334), "solar storms · black holes · sky riddles.", font=ImageFont.truetype(SANS, 11), fill=MUTED)

    # footer
    d.line([(35, 440), (292, 440)], fill=(217, 179, 108, 70), width=1)
    tracked(d, (35, 450), "7 EXHIBITS  ·  13° N  ·  OFFLINE", ImageFont.truetype(SANS, 8), (174, 184, 202), 2)
    tracked(d, (35, 466), "PLAYS ON A PHONE OR A PROJECTOR", ImageFont.truetype(SANS, 8), (120, 130, 150), 2)
    return img


if __name__ == "__main__":
    os.makedirs(ITCH, exist_ok=True)
    cover = make()
    cover.save(os.path.join(ITCH, "cover.png"))
    cover.resize((315, 250), Image.LANCZOS).save(os.path.join(ITCH, "cover_small.png"))
    print("wrote", os.path.join(ITCH, "cover.png"), cover.size)
