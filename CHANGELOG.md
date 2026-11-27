# Changelog

## v1.4.0 — The true sky · 2026-11-27

### Fixed

- **The Sky Atlas horizon was 12 hours out of phase and mirrored.** The old
  `set_sidereal` built its rotation as `tilt × spin` with the wrong signs, so
  a south-facing 21:00 view showed the south celestial pole and the wrong
  constellations. It now uses the textbook hour-angle rotation (`+X` east,
  `+Y` up, `−Z` south). A south-facing view at 21:00 shows Fomalhaut, Grus,
  Phoenix and the autumn horizon, with Orion rising in the east.
- **The time slider is real clock time, not a seasonal guess.** `set_hour`
  derives Julian date and GMST from today's date, the local UTC offset and
  78° E, then sets local sidereal time. 21:00 now means 21:00 tonight.
- **The default camera looks 28° above the southern horizon**, so the first
  frame contains sky rather than the below-horizon pole.
- **The title screen prints the live version**, not the stale `V 1.2.1`.

### Added

- **Tonight at 13° N** (`TONIGHT` or `T`): four bright stars that are 20°–85°
  above the horizon, with altitude and compass direction, plus a short
  observing note. Excludes the Moon and planets, and says so.
- **`TestSky`** locks Polaris, Capella, Sirius, Fomalhaut and Arcturus to
  their textbook altitudes and asserts the south celestial pole is below the
  horizon, so the transform cannot silently mirror again.

## v1.3.2 — The studio pass · 2026-11-27

### Fixed

- **The Moon lab now moves in the direction its labels describe.** Drag,
  Earlier/Later and the hint all use one `ORBIT_SIGN`; stepping later from a
  waning crescent crosses new moon into waxing with the lit fraction rising.
  A headless `TestMoonFlow` locks the five cardinal phases and the direction.
- **Correct answers explain the geometry.** `_check` was passing a missing
  `p["target"]` to `_why`; it now passes the challenge target, the `full`
  branch is reachable, and the explanation stays on screen instead of being
  erased after one second.
- **The phase name is hidden during a challenge.** The student reads the inset
  and the prompt, not a label that already contains the answer. The black-hole
  option that said gravity is the same "for the same size" now says "same
  mass", matching its own explanation.
- **The quiz cannot be beaten by a key pattern.** Options are shuffled at
  render time and the index is remapped, so A/B/C/D cycling no longer scores.
  Wrong answers offer a one-tap **Revise** link to the exhibit that teaches
  them, and a repeat attempt shows the change since last time.
- **The star hunt no longer pre-highlights its targets.** Hint still glows
  three stars when asked; the hunt itself is a search again.
- **The scale riddles ask about light-time**, not just planet trivia: Saturn
  at ~80 light-minutes and Neptune at ~4 light-hours.
- **The seasons lab shows distance from the Sun** every month, and the no-tilt
  check now requires June so the student sees distance unchanged while the
  seasons vanish. The equinox check requires a real tilt.
- **Phone back control is 56×44, not 4×32.** The compact app bar labels it
  `‹ LAB` and reserves a real hit area.
- **Solar Storm Lab's lesson page no longer overflows 390 px.** The kicker
  ellipsizes, the page keeps its gutter, and the image credit wraps.
- **Lesson pages lead with "What you'll do"** before the long paragraphs, and
  body text aligns with the header (16 px, not 0).
- **Small paper labels meet contrast**: `GOLD_DARK` is now `#6f5228`, faded
  secondary labels are full-opacity, and Kannada labels get vertical room.
- **Sound off means silence.** The ambient bed is stopped and restarted with
  the setting instead of ignoring it.
- **Keyboard access works.** Buttons opt into focus with a gold focus ring;
  the first Tab seeds focus, and Router scenes keep the chain.
- **Reduced motion is a setting.** It stops sky drift, camera parallax,
  lantern sway/flicker, fireflies and festival motion while keeping every
  tap/hover/verdict transition. On the web it follows
  `prefers-reduced-motion` by default.
- **The certificate can be saved** as a PNG from the finale, with the action
  row hidden for the capture and the image cropped to the certificate itself.
  The file never leaves the device.
- **Returning to the hill lights one lantern.** `G.last_completed` is consumed
  by the hub: that lantern warms up from unlit over 1.4 s, its ring and glow
  come up, a soft success cue plays, and a restrained "… · LIT" line names it.
- **Quiz pages reset to the top** when the next riddle opens.
- **A teacher can keep the attempt**: the results screen names the score by
exhibit (`The Long Road 2/4`) and exports one CSV row per riddle — chosen
answer, correct answer, result, explanation and revise topic — with no
account, server or upload.

### Changed — seminar

- **The rehearsal timer survives the demo.** It is saved with the deck and
  restored on return; it turns vermilion after 8:30 and `Home` resets it.
- **One key back to the deck.** Opening an exhibit sets `G.seminar_return`;
  labs show a gold **PRESENT · DECK** link and accept **Backspace**.
- **Slide budgets total 600 s** (45 + ten 50 s slides + 55), matching the run
  sheet instead of overrunning it by 55 s.
- **Every slide has a stat row** above the bullets (7 exhibits, 8,879 stars,
  1 draw call, 2.95 km/M☉, the live URL). The closing slide opens the finale,
  not the hub, and the last-slide clicker press is a silent no-op.
- **Pre-flight checks exact numbers**: 8,879 stars, 88 constellations, 28
  nakshatras, plus a deck-copy row for stats and bullet length.
- **N is now a projector-safe cue**, not the full script: one sentence in a
  small strip. **Shift+N** opens the full speaker notes for rehearsal.
- **Portrait slides cap the figure at 24%** and add a "scroll for more" cue;
  the note column can no longer collapse to a one-character wrap.
- **Slide 11's pipeline is a three-stage 1200×750 diagram** with 28–34 px
  labels, readable at slide size instead of only on ENLARGE.
- **Slide 12 carries a scannable QR** to `?scene=seminar` on the certificate
  figure, beside the URL pill.
- **Deck copy fixes**: 27 nakshatras (28 drawn figures), Saptarishi as the
  seven-star asterism inside Ursa Major, and Cassiopeia is not a nakshatra.

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
- **Title modals** keep their action row outside the scroll and the story text
  uses the full sheet width, so the CTA is never sliced at the bottom edge.
- **Quiz results** print `14 / 14` on one line; the compact header drops the
  redundant status label instead of clipping it.
- **Atlas labels** are culled against the panel and bottom safe area, so no
  constellation or star name is sliced at an edge.
- **Credits** correct the HYG catalogue URL to `astronexus.com`.
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
- **Installable offline PWA**: `polish_web.py` now writes `sw.js` and a web app
  manifest. After the first load the browser caches the HTML, WASM, PCK,
  worklets and icons; the manifest adds Seminar deck and Sky Lab shortcuts.
- **One-command build**: `tools/build_web.sh` exports, brands, packages and
  refreshes the stats with an absolute path, so it works from the repo root.

### Fixed

- The deck keeps a **16:9 stage** in short landscape windows (for example a
  780×437 browser window) instead of reflowing into a clipped compact layout;
  the whole slide scales, so no bullet is cut off.
- Portrait figures use **contain** fit, so a landscape Sky Note or screenshot
  is never cropped on the left; portrait text keeps its scroll area.
- `?demo=1` now uses `G.unlock_all()`, so it sets the full quiz total rather
  than a partial score.
- **Scene changes show a status card** (“Opening the Sky Lab”) instead of a
  black void, and a failed scene change reports the error instead of leaving
  the fade covering the screen.

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
