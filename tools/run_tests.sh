#!/usr/bin/env bash
# Run every headless contract test. Fails if a scene does not print TEST PASS.
set -u
cd "$(dirname "$0")/.."

fail=0
for t in TestContent TestSeminar TestSolarFlow; do
  echo
  echo "== $t =="
  log="$(mktemp)"
  timeout 180 godot --headless --path nakshatra "tests/$t.tscn" 2>&1 | tee "$log"
  if ! grep -q "TEST PASS" "$log"; then
    echo "FAILED: $t"
    fail=1
  fi
  rm -f "$log"
done

if [ "$fail" -eq 0 ]; then
  echo
  echo "ALL TESTS PASS"
else
  echo
  echo "TESTS FAILED"
fi
exit "$fail"
