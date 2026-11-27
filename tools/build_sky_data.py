#!/usr/bin/env python3
"""Build compact sky data for the Godot game from HYG + Stellarium skycultures."""
import csv, json, math, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data_src")
OUT = os.path.join(ROOT, "nakshatra", "data", "sky")
os.makedirs(OUT, exist_ok=True)

MAG_LIMIT = 6.5

def load_index(cult):
    with open(os.path.join(SRC, cult, "index.json"), encoding="utf-8") as f:
        return json.load(f)

def edges_from(lines):
    out = set()
    for line in lines:
        for a, b in zip(line, line[1:]):
            if a == b:
                continue
            out.add((min(a, b), max(a, b)))
    return sorted(out)

# HIP ids needed by every line drawing must survive the magnitude cut.
line_hips = set()
for cult in ("modern", "indian_nakshatras"):
    for c in load_index(cult)["constellations"]:
        for e in edges_from(c.get("lines", [])):
            line_hips.update(e)

stars = []
by_hip = {}

with open(os.path.join(SRC, "hyg.csv"), newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        try:
            hip = int(row["hip"]) if row["hip"] else None
        except ValueError:
            continue
        if not hip:
            continue
        try:
            ra = float(row["ra"]) * 15.0
            dec = float(row["dec"])
            mag = float(row["mag"])
        except (ValueError, TypeError):
            continue
        if mag > MAG_LIMIT and hip not in line_hips:
            continue
        con = (row["con"] or "").strip()
        proper = (row["proper"] or "").strip()
        bayer = (row["bayer"] or "").strip()
        flam = (row["flam"] or "").strip()
        ci = row["ci"]
        try:
            ci = float(ci)
        except (ValueError, TypeError):
            ci = 0.65
        try:
            dist = float(row["dist"]) * 3.26156
        except (ValueError, TypeError):
            dist = 0.0
        name = proper
        if not name and bayer and con:
            name = f"{bayer} {con}"
        if not name and flam and con:
            name = f"{flam} {con}"
        stars.append({
            "hip": hip, "ra": round(ra, 4), "dec": round(dec, 4),
            "mag": round(mag, 2), "ci": round(max(-0.4, min(2.5, ci)), 2),
            "name": name, "con": con, "dist": round(dist, 1),
        })

stars.sort(key=lambda s: s["mag"])
by_hip = {s["hip"]: s for s in stars}
print(f"catalog stars <= {MAG_LIMIT}: {len(stars)}")

# ---------- constellations ----------
modern = load_index("modern")
modern_out = []
for c in modern["constellations"]:
    abbr = c["id"].split()[-1]
    edges = edges_from(c.get("lines", []))
    hips = sorted({h for e in edges for h in e})
    modern_out.append({
        "id": abbr,
        "name": c.get("common_name", {}).get("native", abbr),
        "english": c.get("common_name", {}).get("english", abbr),
        "edges": edges,
        "stars": hips,
    })
print(f"modern constellations: {len(modern_out)}, edges: {sum(len(c['edges']) for c in modern_out)}")

naks = load_index("indian_nakshatras")
KANNADA = {
    "Ashvini": "ಅಶ್ವಿನಿ", "Bharani": "ಭರಣಿ", "Krittika": "ಕೃತ್ತಿಕೆ", "Rohini": "ರೋಹಿಣಿ",
    "Mrigashira": "ಮೃಗಶಿರ", "Ardra": "ಆರುದ್ರ", "Punarvasu": "ಪುನರ್ವಸು", "Pushya": "ಪುಷ್ಯ",
    "Ashlesha": "ಆಶ್ಲೇಷ", "Magha": "ಮಘ", "Purva Phalguni": "ಪೂರ್ವ ಫಲ್ಗುಣಿ",
    "Uttara Phalguni": "ಉತ್ತರ ಫಲ್ಗುಣಿ", "Hasta": "ಹಸ್ತ", "Chitra": "ಚಿತ್ತಾರ",
    "Swati": "ಸ್ವಾತಿ", "Vishakha": "ವಿಶಾಖ", "Anuradha": "ಅನುರಾಧ", "Jyeshtha": "ಜ್ಯೇಷ್ಠ",
    "Mula": "ಮೂಲ", "Purva Ashadha": "ಪೂರ್ವಾಷಾಢ", "Uttara Ashadha": "ಉತ್ತರಾಷಾಢ",
    "Shravana": "ಶ್ರವಣ", "Dhanishta": "ಧನಿಷ್ಠ", "Shatabhisha": "ಶತಭಿಷ",
    "Purva Bhadrapada": "ಪೂರ್ವಾಭಾದ್ರ", "Uttara Bhadrapada": "ಉತ್ತರಾಭಾದ್ರ",
    "Revati": "ರೇವತಿ", "Abhijit": "ಅಭಿಜಿತ್",
}
naks_out = []
for c in naks["constellations"]:
    cn = c.get("common_name", {})
    en = cn.get("english") or cn.get("pronounce") or c["id"].split()[-1]
    edges = edges_from(c.get("lines", []))
    naks_out.append({
        "name": cn.get("pronounce") or en,
        "english": en,
        "kannada": KANNADA.get(en, ""),
        "native": cn.get("native", ""),
        "edges": edges,
        "stars": sorted({h for e in edges for h in e}),
    })
print(f"nakshatras: {len(naks_out)}")

# ---------- bright named stars ----------
named = [
    {"hip": s["hip"], "name": s["name"], "con": s["con"], "mag": s["mag"]}
    for s in stars if s["name"] and s["mag"] <= 3.2
]

# Ensure all constellation-line stars exist even if fainter than limit
missing = 0
for c in modern_out:
    for h in c["stars"]:
        if h not in by_hip:
            missing += 1
print("missing line stars:", missing)

def dump(name, obj):
    p = os.path.join(OUT, name)
    with open(p, "w", encoding="utf-8") as f:
        json.dump(obj, f, separators=(",", ":"), ensure_ascii=False)
    print(name, os.path.getsize(p) // 1024, "KB")

dump("stars.json", {
    "hips": [s["hip"] for s in stars],
    "ra": [s["ra"] for s in stars],
    "dec": [s["dec"] for s in stars],
    "mag": [s["mag"] for s in stars],
    "ci": [s["ci"] for s in stars],
    "names": [s["name"] for s in stars],
    "cons": [s["con"] for s in stars],
    "dist": [s["dist"] for s in stars],
})
dump("constellations.json", modern_out)
dump("nakshatras.json", naks_out)
dump("named_stars.json", named)

# Quick stats for the game's sky
print("brightest:", [(s["name"], s["mag"]) for s in stars[:8]])
print("mag buckets:", {m: sum(1 for s in stars if s["mag"] <= m) for m in (1, 2, 3, 4, 5, 6, 6.5)})
