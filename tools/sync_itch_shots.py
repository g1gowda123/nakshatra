#!/usr/bin/env python3
"""Copy the fresh DeckCapture screenshots into the itch.io store shots.

Run after `bash tools/capture_deck_shots.sh`. It only replaces the screens that
were recaptured; the Sky Note, question and Field Guide shots remain as they are.
"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_raw", "shots_new")
DST = os.path.join(ROOT, "itch")

MAP = {
    "boot.png": "01_title.png",
    "hub.png": "02_sky_lab.png",
    "moon.png": "03_moon_phases.png",
    "stars.png": "04_constellations.png",
    "scale.png": "05_solar_system.png",
    "seasons.png": "06_seasons.png",
    "quiz.png": "07_quiz.png",
    "certificate.png": "08_certificate.png",
    "hub_phone.png": "09_mobile_hub.png",
    "solar.png": "11_solar_storm.png",
    "blackhole.png": "12_black_hole.png",
}


def main():
    for src, dst in MAP.items():
        path = os.path.join(SRC, src)
        if not os.path.exists(path):
            print("missing", path)
            continue
        im = Image.open(path).convert("RGB")
        if im.width > 1280:
            im = im.resize((1280, round(im.height * 1280 / im.width)), Image.LANCZOS)
        im.save(os.path.join(DST, dst), optimize=True)
        print("wrote", dst, im.size)


if __name__ == "__main__":
    main()
