# QA report — 27 November 2026

Build: `v1.3.2 — studio pass`
Engine: Godot 4.7.2 · GL Compatibility · Web export

## Studio pass gate

```bash
cd nakshatra
godot --headless --path . --import
cd ..
bash tools/run_tests.sh
```

Result: **ALL TESTS PASS** — content, seminar (13 pre-flight rows), solar flow
the new **moon flow** contract (five phases, travel direction, feedback,
hidden readout) and the **quiz flow** contract (30 reshuffles, index remap,
scoring, revise topics). Visual checks were re-run at 1280×720 and 390×844 for the
Moon lab, hub, quiz, Solar lesson, Seasons lab, star hunt, finale and seminar
slides 1/11.

New in this pass: shuffled quiz options with **Revise** links, a saveable
cropped certificate, keyboard focus, reduced motion, a lantern light-up on
return, a persistent seminar timer, a one-key return to the deck, `N` as a
projector-safe cue, stat pills on every slide, a readable pipeline diagram, a
QR on the closing figure, exact pre-flight counts, a by-exhibit quiz breakdown
and an offline CSV of the attempt. The earlier report below remains the v1.2.1 baseline.

---

Build: `v1.2.1 — presenter polish`
Engine: Godot 4.7.2 · GL Compatibility · Web export
Reviewer: creative-direction pass (in-engine captures + real browser)

## Build gate

```bash
cd nakshatra
godot --headless --path . --import
godot --headless --path . --export-release "Web" build/web/index.html
cd ..
bash tools/run_tests.sh
```

Result: **ALL TESTS PASS** (content, seminar, solar flow). Export is clean; the
only runtime notes are the engine's cosmetic “resources still in use at exit”
messages from headless teardown.

The Web pack excludes `tests/*` and `tests/**`; the dev capture harness does not
ship.

## Screen matrix

| Screen | 1280×720 | 390×844 | Notes |
|---|---|---|---|
| Title | Pass | Pass | Plate visible, CTA above the fold, no star behind headline. |
| Sky Lab hub | Pass | Pass | Seven tags 01–07 readable; trail continuous; bottom cards all reachable. |
| Moon's Mask | Pass | Pass | Moon separated from Earth; earthshine + label make it legible. |
| Thread the Stars | Pass | Pass | Three taps register; story card appears; clue wraps on phone. |
| The Long Road | Pass | Pass | Inner labels staggered; sun glow no longer washes them out. |
| The Turning Year | Pass | Pass | June sits on the June-solstice label; 12.8 h / 80° still correct. |
| Solar Storm Lab | Pass | Pass | Release flare disabled below 70 %; sun glow contained. |
| Black Hole Lab | Pass | Pass | Jet artefact removed; disk + photon ring clean. |
| Sky Riddles | Pass | Pass | Intro card and index card fit; CTA reachable. |
| Sky Atlas | Pass | Pass | Labels legible; time value beside slider; LIST no longer clipped on phone. |
| Finale 1/7 | Pass | Pass | Softer copy; horizon fills the lower third. |
| Finale 7/7 | Pass | Pass | Certificate, stats, topic list, horizon; Chrome + 390×844 checked. |
| Seminar deck | Pass | Pass | Slide 1 fits; ENLARGE button no longer clipped; controls reachable. |
| Offline reload | Pass | Pass | After first load, network off; deck and direct `?scene=lab` render from Cache Storage. |

## Functional checks

- **Star hunt** — entered from the lesson page, pressed three gold-core stars.
  Feedback changed to `1 of 3`, then `2 of 3`, then `You found Saptarishi.`;
  the three pips filled; the story modal opened with art, story, science and
  Kannada. Next advances to the next constellation.
- **Story modal** — the old vertical one-letter-per-line Kannada bug was caused
  by a `ScrollContainer` with no horizontal fill; removed in favour of a
  wrapping label.
- **Atlas** — time slider updates both the header and the new `9:00 PM` value;
  `NOW` returns to the real clock; labels toggle; facing compass updates.
- **Moon lab** — the Moon no longer hides behind Earth at the starting phase;
  the orbit is inclined and the Earth-surface inset camera tracks it.
- **Seasons lab** — June is on the June solstice after fixing the month-angle
  formula (it was 30° out).
- **Solar lab** — the release button is disabled at 35 % stress and explains
  why; raising the slider above 70 enables it.
- **Finale** — the 7/7 certificate shows the score (`14/14` after **D → Set
demo state**), the seven-topic line, the name field and the festival horizon.
- **Offline / PWA** — loaded the deck and the direct `?scene=lab` route, set
  DevTools to Offline, and reloaded: both rendered from the service-worker
  cache (`nakshatra-<pck-stamp>`). A hard reload that bypasses HTTP cache still
  needs the service worker's own cache, which is the intended path.

## Known limitations (honest)

1. **Web save is separate from the native save.** The browser starts at 0/7
   even if the desktop save is complete. Use **Seminar → Checks → Demo state**
   to light all lanterns for a browser finale demo.
2. **Finale “Sky Atlas”** is a dark secondary button on a dark sky; it is
   readable but intentionally quieter than “Return to the hill”.
3. **Constellation labels near the viewport edge** can clip (`Elnath` at the
   bottom in one Atlas view). This is normal for a pannable sky; a future pass
   could fade labels within 24 px of an edge.
4. **Seminar mode has two actions on slide 1** (Next and Enter the Sky Lab).
   Next is the filled primary; Enter is the escape hatch. It is documented in
   the playbook rather than removed.
5. **Performance was not profiled on low-end phones.** The web build is 18 MB
   PCK + 38 MB WASM; the hill uses 650 grass instances and no shadows from
   lanterns. The shaders are GL Compatibility-safe. In headless software WebGL
   the first Lab build can take tens of seconds; the deck now shows an
   **Opening the Sky Lab** status card and the playbook asks the presenter to
   warm the hill once before the talk.

## Art QA checklist (what was actually looked at)

- Seven lanterns: body, number tag, ground pool, no clipping with the dome.
- Trail: continuous from the near path to the observatory; no slabs floating.
- Sky: title stars do not sit on the headline; hunt target cores are visible;
  Atlas labels do not collide.
- Labs: no object clipping; sun glows do not touch labels; inner planet labels
  are staggered.
- Finale: certificate does not bury the sky; horizon is visible; no orphaned
  word in the topic list.
- Phone: no horizontal overflow; primary actions above the fold; panels do not
  cover their own buttons.

## Re-running the visual review

In-engine (native, 1920×1200 review size):

```bash
cd nakshatra
XDG_DATA_HOME=/home/g1/.hermes/cache/scratch/nak_userdata \
  godot --path . --fullscreen tests/Capture.tscn -- \
  res://scenes/Lab.tscn /tmp/lab.png 8.0
```

Browser (true target sizes):

```bash
cd nakshatra/build/web
python3 -m http.server 8060
# open http://127.0.0.1:8060/index.html?scene=lab
```

Use a 1280×720 viewport for projector review and 390×844 for phone review.
