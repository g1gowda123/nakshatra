#!/usr/bin/env python3
"""Generate Nakshatra's handcrafted papercut art set through ComfyUI."""
import json, os, shutil, time, urllib.request, urllib.error, urllib.parse, random

HOST = "http://127.0.0.1:8188"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art_raw")
os.makedirs(OUT, exist_ok=True)
WF = json.load(open(os.path.expanduser("~/.hermes/skills/creative/comfyui/workflows/sdxl_txt2img.json")))
WF = {k: v for k, v in WF.items() if not k.startswith("_")}

STYLE = ("handcrafted layered papercut illustration, deep indigo midnight blue and warm gold palette, "
         "tactile paper texture, delicate gold linework, glowing amber accents, storybook art, "
         "rich detail, soft cinematic light, full bleed composition, edge to edge, no frame, no border")
NEG = ("text, letters, words, watermark, signature, people, human figures, faces, photo, 3d render, "
       "frame, border, white background, cream background, low quality, blurry, cropped, deformed")

JOBS = [
    ("card_moon", 1024, 1024,
     "a luminous golden Moon in eight phases arranged in a circle around a small indigo Earth, thin gold orbit line, stars, "
     "educational wonder, " + STYLE, 11),
    ("card_stars", 1024, 1024,
     "the seven stars of the Saptarishi constellation connected by fine gold lines above dark Indian hills, a small brass telescope, "
     "deep star field, " + STYLE, 22),
    ("card_planets", 1024, 1024,
     "the Sun and eight planets strung along a sweeping golden arc across indigo space, tiny orbit rings, glowing sun, "
     "sense of vast distance, " + STYLE, 33),
    ("card_seasons", 1024, 1024,
     "a tilted indigo Earth with a golden axis line orbiting a warm glowing Sun, four seasonal positions, crescent light, "
     "elegant diagram-like beauty, " + STYLE, 44),
    ("card_quiz", 1024, 1024,
     "five glowing paper lanterns hanging in a row under an indigo starry sky, tiny golden constellations, festive and inviting, "
     + STYLE, 55),
    ("story_festival", 1216, 832,
     "a hilltop town in India at night, flat rooftops and small houses, hundreds of paper lanterns being released into a deep indigo sky full of stars, "
     "warm gold windows, the Milky Way, festival of lights, cinematic wide view, " + STYLE, 66),
    ("finale_lanterns", 1216, 832,
     "a river of glowing paper lanterns rising into a vast starry night sky above dark hills, gold constellation lines awakening among the stars, "
     "magical, hopeful, cinematic, " + STYLE, 77),
    ("icon_lantern", 1024, 1024,
     "a single ornate golden paper lantern glowing at the centre of a deep indigo starry square, minimal iconic composition, "
     "bold silhouette, " + STYLE, 88),
    ("card_atlas", 1024, 1024,
     "an antique Indian star chart, gold constellation figures and nakshatra lines on deep indigo paper, brass astrolabe in the corner, "
     "hand-painted, " + STYLE, 99),
    ("card_flares", 1024, 1024,
     "the Sun as a huge glowing orange sphere with dark sunspots, towering golden magnetic loops and a brilliant solar flare arcing into space, "
     "a tiny blue Earth in the distance with a green aurora ring, deep indigo starry sky, " + STYLE, 111),
    ("card_blackhole", 1024, 1024,
     "a black hole with a brilliant swirling orange and gold accretion disk, a thin glowing photon ring, starlight bent into arcs around it, "
     "deep indigo space, awe and mystery, " + STYLE, 122),
]


def submit(prompt, w, h, seed):
    wf = json.loads(json.dumps(WF))
    wf["6"]["inputs"]["text"] = prompt
    wf["7"]["inputs"]["text"] = NEG
    wf["5"]["inputs"].update(width=w, height=h)
    wf["3"]["inputs"].update(steps=26, cfg=7.0, seed=seed)
    req = urllib.request.Request(HOST + "/prompt",
                                 data=json.dumps({"prompt": wf, "client_id": "nakshatra"}).encode(),
                                 headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=60))["prompt_id"]


def wait(pid, timeout=900):
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(4)
        try:
            h = json.load(urllib.request.urlopen(f"{HOST}/history/{pid}", timeout=20))
        except Exception:
            continue
        if pid in h:
            st = h[pid]["status"]
            if st.get("completed"):
                for node in h[pid].get("outputs", {}).values():
                    for img in node.get("images", []):
                        return img
            if st.get("status_str") == "error":
                raise RuntimeError(json.dumps(st)[:1000])
    raise TimeoutError(pid)


def download(img, dst):
    url = HOST + "/view?" + urllib.parse.urlencode(
        {"filename": img["filename"], "subfolder": img.get("subfolder", ""), "type": img.get("type", "output")})
    with urllib.request.urlopen(url, timeout=60) as r, open(dst, "wb") as f:
        f.write(r.read())


for name, w, h, prompt, seed in JOBS:
    dst = os.path.join(OUT, name + ".png")
    if os.path.exists(dst):
        print("skip", name, flush=True)
        continue
    try:
        pid = submit(prompt, w, h, seed)
        print("queued", name, pid, flush=True)
        img = wait(pid)
        download(img, dst)
        print("saved", name, os.path.getsize(dst), flush=True)
    except Exception as e:
        print("FAIL", name, repr(e)[:500], flush=True)
        # server may have died; wait for it to come back
        time.sleep(10)
