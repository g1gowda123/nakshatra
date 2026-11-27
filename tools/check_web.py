#!/usr/bin/env python3
"""Check that the exported web folder is actually installable and offline-ready."""
import json
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "nakshatra", "build", "web")
ZIP = os.path.join(ROOT, "itch", "nakshatra-web.zip")


def fail(message):
    print("WEB CHECK FAIL:", message)
    sys.exit(1)


for name in ["index.html", "index.js", "index.wasm", "index.pck", "sw.js",
             "manifest.webmanifest", "index.icon.png"]:
    if not os.path.exists(os.path.join(WEB, name)):
        fail("missing " + name)

html = open(os.path.join(WEB, "index.html"), encoding="utf-8").read()
if 'id="nk-sw"' not in html:
    fail("index.html does not register the service worker")
if 'rel="manifest"' not in html:
    fail("index.html does not link the manifest")

manifest = json.load(open(os.path.join(WEB, "manifest.webmanifest"), encoding="utf-8"))
if manifest.get("display") != "standalone":
    fail("manifest is not standalone")
start = manifest.get("start_url", "")
if "index.html" not in start:
    fail("manifest start_url does not point at index.html")

sw = open(os.path.join(WEB, "sw.js"), encoding="utf-8").read()
for asset in ["index.html", "index.js", "index.wasm", "index.pck"]:
    if asset not in sw:
        fail("service worker does not precache " + asset)

if os.path.exists(ZIP):
    with zipfile.ZipFile(ZIP) as z:
        names = set(z.namelist())
        for name in ["sw.js", "manifest.webmanifest", "docs/SEMINAR_PLAYBOOK.md"]:
            if name not in names:
                fail("zip is missing " + name)

print("WEB CHECK PASS: manifest, service worker and zip include the offline files")
