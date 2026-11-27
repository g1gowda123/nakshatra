#!/usr/bin/env bash
# Capture fresh figures for Seminar mode from the current build.
# Requires a real display (not --headless); the capture harness quits itself.
set -u
cd "$(dirname "$0")/.."
OUT="art_raw/shots_new"
mkdir -p "$OUT"
GODOT="${GODOT:-godot}"

shot() {
  local scene="$1" name="$2" wait="${3:-3.0}" w="${4:-1280}" h="${5:-720}"
  shift 5 || true
  echo "== $name =="
  timeout 120 "$GODOT" --path nakshatra tests/DeckCapture.tscn -- \
    "$scene" "$PWD/$OUT/$name.png" "$wait" "$w" "$h" "$@" 2>&1 |
    grep -E '\[DeckCapture\]|SCRIPT ERROR|Parse Error' || true
}

shot res://scenes/Boot.tscn        boot        8.0 1280 720 --skip-briefing
shot res://scenes/Lab.tscn         hub         8.0 1280 720 --skip-briefing --reset
shot res://scenes/Lab.tscn         hub_phone   8.0  780 1688 --skip-briefing --reset
shot res://scenes/MoonLab.tscn     moon        8.0 1280 720 --skip-briefing
shot res://scenes/StarLab.tscn     stars       8.0 1280 720 --skip-briefing
shot res://scenes/ScaleLab.tscn    scale       8.0 1280 720 --skip-briefing
shot res://scenes/SeasonLab.tscn   seasons     8.0 1280 720 --skip-briefing
shot res://scenes/SolarLab.tscn    solar       8.0 1280 720 --skip-briefing --flare
shot res://scenes/BlackHoleLab.tscn blackhole  8.0 1280 720 --skip-briefing
shot res://scenes/QuizLab.tscn     quiz        8.0 1280 720 --skip-briefing --quiz
shot res://scenes/Atlas.tscn       atlas       8.0 1280 720 --skip-briefing
# Finale is captured through the simpler harness so the certificate page is
# rendered after the demo state is written.
"$GODOT" --path nakshatra tests/DeckCapture.tscn -- unlock --demo-only >/dev/null 2>&1 || true
timeout 120 "$GODOT" --path nakshatra tests/Capture.tscn -- \
  res://scenes/Finale.tscn "$PWD/$OUT/certificate.png" 8.0 1280 720 2>&1 |
  grep -E 'CAPTURE|SCRIPT ERROR|Parse Error' || true

# Leave the local save fresh for whoever runs the game next.
"$GODOT" --path nakshatra tests/DeckCapture.tscn -- reset --reset-only >/dev/null 2>&1 || true

echo "shots in $OUT"
