# Feature matrix

Use this when you need to connect a feature to a syllabus topic, a demo moment
or a technical claim.

## 1. What the player can do

| Feature | What it does | Why it matters in a seminar | Where it lives |
|---|---|---|---|
| **Free-choice Sky Lab** | Seven lanterns, all open from the first second; no locks or forced order | The strongest design argument: the story wraps the learning, it does not gate it | `Lab.gd`, `content.json` |
| **The Moon’s Mask** | Drag the Moon; a live “from Earth” inset shows the phase; four named-phase challenges | Turns the most common misconception (the Moon changes shape) into a physical demonstration | `MoonLab.gd` |
| **Thread the Stars** | Tap three stars to thread Saptarishi, Mriga, Sharmishtha, Vrishchika and Hamsa | Connects Indian nakshatra heritage to the same real sky as the IAU constellations | `StarLab.gd` |
| **The Long Road** | Orrery with scale/size/data views, light-minutes, four planet riddles | Separates distance from size; makes “space is empty” felt rather than asserted | `ScaleLab.gd` |
| **The Turning Year** | Tilt Earth, orbit it, read noon-Sun altitude and day length at 13°N; “no tilt” experiment | Isolates axial tilt as the cause of seasons — the cleanest experiment in the chapter | `SeasonLab.gd` |
| **Solar Storm Lab** | Build magnetic stress, release a flare, race a CME, protect a satellite | Shows the light/CME delay that makes space-weather forecasting possible | `SolarLab.gd` |
| **Black Hole Lab** | Change mass, lower a probe, read the event horizon and gravitational time dilation | Makes an abstract extreme tangible with real formulas and four misconception checks | `BlackHoleLab.gd` |
| **Sky Riddles** | 14 questions with shuffled options, no timer, an explanation after every answer, a **Revise** link to the exhibit that teaches it, and a **CSV export** of the attempt | Works as a pre-test and post-test; a wrong guess has a next step, and a teacher can keep the evidence offline | `QuizLab.gd`, `content.json` |
| **Field Guide** | Eight written cards on nebulae, supernovae, pulsars, galaxies, gravitational waves, exoplanets | Gives the curious student somewhere to go after the seven lanterns | `FieldGuide.gd` |
| **Sky Atlas** | Real sky at 13° N with 88 IAU constellations and 28 nakshatras, live local sidereal time, slide-to-time control, star labels, and a **Tonight** short list with altitude and compass direction | Students can go outside and find the same stars; the sky is not decorative | `Atlas.gd`, `SkyDome.gd`, `TestSky` |
| **The Finale** | Certificate, rising lanterns and a one-tap **Save certificate** PNG | A finish line that is optional, not a gate; a take-home artifact that stays on the device | `Finale.gd` |
| **Kannada layer** | Kannada module names and key terms beside the English | Localisation is part of the design, not a translation afterthought | `G.KANNADA`, `content.json` |
| **Portrait-first UI** | Every screen has a portrait and landscape layout; content scale follows the browser; compact back controls are 56×44 | Works on the device a student already owns | `UI.gd`, `G._apply_content_scale` |
| **Offline static build** | One folder; no runtime network calls | A school lab can copy it to a local server or run it from a laptop | `build/web/`, `export_presets.cfg` |
| **Installable offline PWA** | A generated service worker precaches the HTML, JS, WASM, PCK, worklets and icons; a manifest adds home-screen shortcuts for the deck and Sky Lab | Venue Wi-Fi can fail after the first load; the second visit still works | `tools/polish_web.py`, `sw.js`, `manifest.webmanifest` |
| **Local save** | Lanterns, quiz best/last/previous, language, sound, reduced motion, seminar slide and elapsed time in `user://` | Progress survives a reload without an account | `G.gd` |
| **Seminar mode** | 12-slide presenter deck inside the same build | A teacher or student can present the project without a separate slide file | `Seminar.gd`, `content.json` |
| **Speaker notes** | A bottom sheet with a script for each slide; `N` toggles | The presenter does not have to memorise the deck | `Seminar.gd` |
| **Timer + auto-advance** | Elapsed time that survives exhibit jumps; per-slide auto timing; `P` pauses, `A` toggles, `Home` resets | Rehearsal and a hands-free attract loop | `Seminar.gd` |
| **Pre-flight checks** | Catalogue, lines, modules, images, scenes, fonts, audio, renderer, viewport, save, network | Catches the failures that actually ruin a live demo | `Seminar.preflight_results()` |
| **Demo state** | Light all seven lanterns and set the quiz best to 14 | Show the finale and certificate in one click | `G.unlock_all()` |
| **Figure zoom** | Click any slide figure or press `I` to enlarge it | Makes the dense architecture diagram readable on a projector | `Seminar._show_figure()` |
| **Deep links + resume** | Open any exhibit from its slide; the deck remembers the slide index and timer, and **Backspace** returns to it | Demo the real thing, come back, carry on | `Seminar._open_lab()`, `G.seminar_elapsed` |
| **Headless tests** | Contract tests for the deck, solar flow, content and the Moon-phase model/direction | A UI-heavy project still has something a CI can run | `tests/` |
| **Written docs** | Playbook, architecture, feature matrix, viva Q&A, stats, demo card | The project can be handed over and defended | `docs/` |

## 2. Curriculum map

| Exhibit | Middle-school topic | A little above the textbook | Seminar line |
|---|---|---|---|
| The Moon’s Mask | Moon phases; Earth–Moon–Sun geometry (Class 8 Science, *Stars and the Solar System*) | terminator, 29.5-day synodic month, why the far side is not “dark” | “The Moon does not change shape — we do.” |
| Thread the Stars | Constellations; nakshatras (same chapter) | star distances, red/blue supergiants, line-of-sight patterns changing over millennia | “The lines are not in the sky; people drew them.” |
| The Long Road | The solar system; planet order and scale (Classes 6–8) | light-minutes, why Venus is hotter than Mercury, 1,300 Earths inside Jupiter | “Space is mostly nothing.” |
| The Turning Year | Motions of the Earth; seasons and day length (Class 6 Geography) | axial tilt vs distance, noon-Sun altitude at 13°N, solstices/equinoxes | “A tilted planet writes the seasons.” |
| Solar Storm Lab | The Sun; magnetism and space weather (enrichment) | magnetic reconnection, CME travel time, auroras, the Carrington Event, Aditya-L1 | “The delay is the forecast window.” |
| Black Hole Lab | Gravity, light and time (enrichment) | event horizon radius, accretion disks, gravitational time dilation, EHT and LIGO | “Where time itself slows down.” |
| Sky Riddles | Revision | explanations, not just scores; pre/post-test use | “A wrong guess becomes a lesson.” |
| Field Guide | Deep-sky enrichment | nebulae, supernovae, neutron stars, galaxies, gravitational waves, exoplanets | “Some ideas do not need a whole exhibit.” |

## 3. Claims and how they are checked

| Claim | Evidence |
|---|---|
| 8,879 naked-eye stars | `StarDB.hips.size()` at startup; pre-flight row; `data/sky/stars.json` |
| 88 IAU constellation figures | `StarDB.constellations.size()`; pre-flight row |
| 28 nakshatra figures | `StarDB.nakshatras.size()`; pre-flight row |
| 7 learning modules | `G.MODULES.size()`; pre-flight row |
| 14 Sky Riddles | `content.json → quiz`; pre-flight indirect |
| 10 solar-mass horizon ≈ 30 km | `BlackHoleLab._update_ui`: `2.953 × mass_suns` |
| Time dilation | `1 / sqrt(1 − Rs/r)` in `BlackHoleLab._update_ui` |
| Light takes 8 min 20 s to Earth | `SolarLab` timeline and lesson text |
| Seasons come from tilt, not distance | `SeasonLab` tilt experiment and readouts |
| Orrery is compressed | Stated in `CREDITS.md`, `README.md` and the game credits |
| Star field is one MultiMesh | `SkyDome._build_stars` creates one `MultiMeshInstance3D` |
| No threads / no COOP-COEP | `export_presets.cfg` `variant/thread_support=false` |
| No runtime network calls | No HTTP client in the codebase; the only external references are in credits |
| Progress stays local | `G.save_game` writes `user://nakshatra_save.json` |
| Build is one static folder | `nakshatra/build/web/`; `tools/package_itch.py` zips it |
| Kannada is a term layer, not full translation | `G.KANNADA` plus `content.json` `kannada` fields; stated in docs |
| Licence | `CREDITS.md`; GPL-3.0-or-later for the combined work, CC BY-SA 4.0 for the HYG-derived data |

## 4. Accessibility and inclusion

- **Language:** Kannada key terms and module names; a Kannada mode switches
  module titles. Not a full UI translation.
- **Input:** every action has a large button; no keyboard required for play.
  The seminar deck adds keyboard shortcuts for a presenter.
- **Device:** portrait-first layouts, content scale based on CSS size, no
  dependence on hover.
- **Sound:** all audio is optional; the ambient bed is quiet; the game is fully
  usable muted.
- **Reading:** the written lesson is a full page, not a cramped modal; body text
  is 15–19 px at the logical scale, with larger headings.
- **Offline:** no account, no tracking, no ads, no network at runtime.

## 5. Deliberate omissions

| Not included | Why |
|---|---|
| Accounts / cloud saves | Unnecessary for a classroom; adds privacy and infrastructure risk |
| Analytics / telemetry | The project should not need to know who is playing |
| Multiplayer | The learning is individual or teacher-led; no server budget |
| Full Kannada translation | Scope; key terms were the useful first layer |
| A ray-traced black hole | The stylised visual + real formulas teach the idea; GL Compatibility is the constraint |
| Open-world exploration | The hub is a menu with atmosphere, not a game world to traverse |
| Generated quizzes | The 14 questions are hand-written and explained; quality over volume |

## 6. What we would build next

1. **Full Kannada and Hindi UI** with a translation file, not code strings.
2. **Offline teacher dashboard** — export class pre/post results as CSV from the
   local save, still with no server.
3. **“Tonight’s sky” timeline** — set the Atlas to the current date/time and
   suggest three things to look for after the seminar.
4. **Audio narration** — a read-aloud mode for the Sky Notes, useful for
   low-vision students and noisy classrooms.
5. **More exhibits** — eclipses, tides, the life cycle of a star, the scale of
   the galaxy.
