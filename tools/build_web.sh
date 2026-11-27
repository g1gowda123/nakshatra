#!/usr/bin/env bash
# Build the web export, brand the loader, package the itch zip and refresh stats.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT_BIN="${GODOT:-godot}"
mkdir -p nakshatra/build/web

echo "== import =="
"$GODOT_BIN" --headless --path nakshatra --import

echo "== export =="
# Godot resolves a relative export path against the project directory. Use an
# absolute path so the command works from the repository root too.
"$GODOT_BIN" --headless --path nakshatra \
  --export-release "Web" "$ROOT/nakshatra/build/web/index.html"

echo "== polish =="
python3 tools/polish_web.py

echo "== package =="
python3 tools/package_itch.py

echo "== stats =="
python3 tools/project_stats.py --write docs/STATS.md

echo "done: nakshatra/build/web and itch/nakshatra-web.zip"
