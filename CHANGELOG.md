# Changelog

## Unreleased — The almanac edition

### Changed

- **The whole interface is now a printed sky almanac.** `scripts/UI.gd` is the
  single source of truth: ink ground, cream paper modals, gold hairlines,
  near-square corners and one vermilion accent. The old rounded pills, teal
  glows and template cards are gone.
- **Typography carries the hierarchy**: Cormorant Garamond for display and
  numerals, tracked Noto Sans for micro-caps, Noto Sans Kannada for the Kannada
  line. Every modal is a paper sheet over a dimmed scene.
- **The hub is a catalogue shelf**: numbered cards, short catalogue tags, a
  cream colophon card, and a responsive 4/3/1-column grid. Compact layouts get
  shorter cards and a scroll region instead of clipped rows.
- **New engraved plates** replace the generated card illustrations:
  `tools/make_plates.py` draws the moon phases, Saptarishi field, turning year,
  solar storm, black hole, riddles, atlas and title plate as deterministic line
  art. `data/content.json` points at `assets/art/plates/`.
- **New store cover** (`tools/make_store_cover.py`) and a refreshed fourteen-shot
  store set under `itch/`.

### Fixed

- **The Field Guide could not open.** The old QA route awaited a timer on the
  title scene, which was freed before the callback; the hub now owns the
  hand-off through `G.pending_guide`.
- **Compact hub clipping** at 780×437: the seventh card and the colophon fell
  below the fold. Card heights, tags, and the scroll cap were adjusted.
- **Kannada card titles** were appended under the English title and overlapped
  it in the short card. Kannada mode now replaces the title.
- **Tofu glyphs** on the arrow and check characters in tracked micro-caps;
  replaced with `›`, `DONE`, and `LIT`.
- **The 3D Kannada observatory sign** bled faintly through the lesson shelf at
  compact sizes; it is hidden in compact mode and kept on desktop.
- **Briefing plates cropped their engraved captions**; the frame now uses
  contain fit so the whole plate is visible.
- **Season labels** collided with Earth and the right-hand panel; June and
  December now have anchored positions and December has a brighter colour.
- **Solar Storm Lab's satellite** read as a stray blue square; it is rebuilt as
  a small body with angled panels and a `SATELLITE` label.
- **Stale web packs**: `tools/polish_web.py` stamps `mainPack` with a content
  hash so the service worker cannot serve an old build after an update.

## v1.2.1 — Presenter polish · 2026-11-27

### Added

- **Per-slide web deep links**: `?scene=seminar&slide=8` opens the solar-storm
  slide directly; `?scene=seminar&demo=1` marks the seven lanterns and the quiz
  complete so the finale and certificate can be shown immediately.
- **Printable presenter material**: `docs/SPEAKER_NOTES.md` (the same notes as
  the deck, generated from `content.json` by `tools/export_notes.py`) and
  `docs/HANDOUT.md` (a one-page audience takeaway).

### Fixed

- The deck keeps a **16:9 stage** in short landscape windows (for example a
  780×437 browser window) instead of reflowing into a clipped compact layout;
  the whole slide scales, so no bullet is cut off.
- Portrait figures use **contain** fit, so a landscape Sky Note or screenshot
  is never cropped on the left; portrait text keeps its scroll area.
- `?demo=1` now uses `G.unlock_all()`, so it sets the full quiz total rather
  than a partial score.

## v1.2.0 — The hand-made hill · 2026-11-27

### Added

- **A new hub world, built in code** (`scripts/world/SkyHill.gd`): an ink-washed
  hill, a winding flagstone path, a lantern trail, 650 swaying grass blades,
  pines, a bench and cairn, a brass observatory, mist, fireflies, ten rising sky
  lanterns and rare shooting stars.
- **Paper lanterns with readable numbers** (`scripts/Lantern.gd`): lathe-turned
  paper bodies, bamboo caps, tassels, painted numbers and hanging cream tags,
  hover titles, warm ground pools and `Area3D` picking.
- **Six new shaders**: `ground_ink`, `path_ink`, `paper_lantern`, `grass_blade`,
  `dome_panel`, `ridge` — mobile-friendly, named parameters, no screen-space
  effects.
- **A real-sky hunt** (`StarLab.gd`): curated seven-star figures for the five
  constellations, warm target cores, breathing halos, a 16-second idle hint,
  a named Dhruva/Polaris marker and a compass-facing readout.
- **Atlas micro-affordances**: a “NOW” clock link, a facing compass, a live time
  value beside the slider, a selected-star reticle and all 88 constellation
  names.
- **A festival horizon for the finale** (`FinaleHorizon.gd`): layered ink hills,
  a warm ridge, town lanterns and a certificate that arrives like a page.
- **`docs/ART_DIRECTION.md`** — the visual contract for the hill, the sky, the
  shaders, the motion and the QA set.

### Changed

- `Lab.gd` now delegates the whole world to `SkyHill`; the seven lanterns are
  the same seven exhibits, numbered 01–07 on the hill and in the cards.
- The title screen keeps the sky quieter (`star_scale 1.18`, intensity `1.02`)
  so the headline and plate lead; the postcard sways ±0.55° and the 3D camera
  floats by 22 cm.
- Sky labels are larger, with deeper outlines; constellation lines are warmer
  and more present; `star_dust` is off so the sky no longer looks static.
- Tests are excluded from the Web export (`exclude_filter="tests/*,tests/**"`).

### Fixed

- **Moon lab**: the Moon now orbits on a slightly inclined plane, so it no
  longer hides behind Earth at the starting phase; it is larger and carries a
  soft glow. The inset camera sits on the Earth surface facing the Moon.
- **Seasons lab**: the month-to-orbit mapping was 30° out; June now sits on the
  June-solstice label and the equinoxes line up with their labels.
- **Solar lab**: the Sun's glow no longer swamps the scene; “Release flare” is
  disabled below 70 % magnetic stress, with a tooltip explaining why.
- **Black hole lab**: removed the hard-edged polar jets that read as a rendering
  artefact; the disk and photon ring carry the silhouette.
- **Scale lab**: inner-planet labels are staggered so Mercury/Venus and
  Earth/Mars no longer collide.
- **Title plate**: the postcard image now fills its frame (the old
  `PanelContainer` collapsed the `TextureRect`).
- **Finale**: the lower third is filled by the festival horizon, the certificate
  is narrower, and the topic list breaks on purpose instead of orphaning a word.

## v1.1.0 — Seminar edition · 2026-11-27

### Added

- **Seminar mode** — a twelve-slide presenter deck built into the game
  (`scenes/Seminar.tscn`). Speaker notes, elapsed timer, per-slide auto-advance,
  pre-flight checks, demo-state / reset controls, figure zoom, and one-click
  jumps into every live exhibit.
- **Deck resume** — the slide index is stored in the local save, so opening an
  exhibit and returning via **Present** resumes where you stopped.
- **Pre-flight** — checks the star catalogue, constellation/nakshatra counts,
  modules, slide images, live scenes, fonts, audio, renderer, viewport, save and
  network design.
- **Demo state** — `G.unlock_all()` lights all seven lanterns and sets the quiz
  best to 14 for showing the finale.
- **Figure zoom** — click any slide figure or press `I`; the architecture
  diagram becomes readable on a projector.
- **Seminar assets** — `tools/make_seminar_assets.py` builds screenshots, crops,
  the pull-quote card and the architecture figure.
- **Documentation** — `docs/SEMINAR_PLAYBOOK.md`, `DEMO_CARD.md`,
  `ARCHITECTURE.md`, `FEATURE_MATRIX.md`, `VIVA_QA.md`, `STATS.md`, `README.md`.
- **Tests** — `TestContent`, `TestSeminar`, updated `TestSolarFlow`, and
  `tools/run_tests.sh`.
- **Stats** — `tools/project_stats.py`.

### Changed

- `content.json` now carries the seminar chapter (12 slides, notes, captions,
  lab links).
- `Boot` and `Lab` expose **Seminar mode / Present** entry points.
- `G` stores `seminar_index` and exposes `unlock_all()`.
- The README, itch description and credits describe the deck and the accurate
  EHT wording (the lab is built around the physics; the Field Guide card uses
  the real image).

### Fixed

- README claim that the Black Hole Lab itself uses the EHT image; it is the
  Field Guide card, and the lab visualises the same physics.
- README typo in the “Phones first” note.
- Headless tests now print a clear `TEST PASS` / `TEST FAIL` and exit non-zero.

## v1.0.0 — The Sky Weavers · 2026-11-25

Initial release: the Sky Lab, seven exhibits, Sky Atlas, Field Guide, story,
certificate, Kannada terms, web export and itch.io package.
