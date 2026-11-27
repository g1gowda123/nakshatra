#!/usr/bin/env python3
"""Zip the web export for itch.io and collect the store assets."""
import os, shutil, zipfile, hashlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "nakshatra", "build", "web")
ITCH = os.path.join(ROOT, "itch")
os.makedirs(ITCH, exist_ok=True)

required = [
    "index.html", "index.js", "index.wasm", "index.pck",
    "index.icon.png", "index.apple-touch-icon.png",
    "index.audio.worklet.js", "index.audio.position.worklet.js",
    "sw.js", "manifest.webmanifest",
]
for f in required:
    p = os.path.join(WEB, f)
    if not os.path.exists(p):
        raise SystemExit(f"missing {p}; build the web export first")

zip_path = os.path.join(ITCH, "nakshatra-web.zip")
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for f in required:
        z.write(os.path.join(WEB, f), f)
    # optional but harmless
    for f in ["index.png"]:
        p = os.path.join(WEB, f)
        if os.path.exists(p):
            z.write(p, f)
    # licence and credits travel with the game
    for f in ["LICENSE", "CREDITS.md", "README.md"]:
        p = os.path.join(ROOT, f)
        if os.path.exists(p):
            z.write(p, f if f != "LICENSE" else "LICENSE.txt")
    # the presenter pack travels with the download too
    for f in ["SEMINAR_PLAYBOOK.md", "DEMO_CARD.md", "SPEAKER_NOTES.md",
              "HANDOUT.md", "VIVA_QA.md", "ARCHITECTURE.md", "STATS.md",
              "QA_REPORT.md", "FEATURE_MATRIX.md", "ART_DIRECTION.md", "README.md",
              "LESSON_PLAN.md", "PUBLISHING.md"]:
        p = os.path.join(ROOT, "docs", f)
        if os.path.exists(p):
            z.write(p, "docs/" + f)
    qr = os.path.join(ROOT, "docs", "img", "qr_live.png")
    if os.path.exists(qr):
        z.write(qr, "docs/img/qr_live.png")

for src, dst in [(os.path.join(ROOT, "README.md"), "README.md"),
                 (os.path.join(ROOT, "CREDITS.md"), "CREDITS.md"),
                 (os.path.join(ROOT, "LICENSE"), "LICENSE")]:
    if os.path.exists(src):
        shutil.copy(src, os.path.join(ITCH, dst))

size = os.path.getsize(zip_path)
with zipfile.ZipFile(zip_path) as z:
    names = z.namelist()
print(f"wrote {zip_path}")
print(f"size: {size/1024/1024:.1f} MB")
print("contents:")
for n in names:
    print("  ", n, f"{os.path.getsize(os.path.join(WEB,n))/1024/1024:.2f} MB" if os.path.exists(os.path.join(WEB,n)) else "")
with open(zip_path, "rb") as f:
    print("sha256:", hashlib.sha256(f.read()).hexdigest())
