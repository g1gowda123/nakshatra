# Viva & Q&A

Thirty questions a seminar panel is likely to ask, with answers that match the
implementation. If you only memorise five, memorise the ones marked ★.

---

## Five answers to memorise

### ★ 1. What is Nakshatra?

A free-choice 3D sky lab for Classes 6–9. Seven interactive exhibits, a real
8,879-star catalogue, fourteen explained questions, and Kannada key terms —
built in Godot and exported to the web so it runs on a school laptop, projector
or phone with no install, account or server.

### ★ 2. Why a game instead of a video or a slide deck?

Because the misconceptions are spatial. “Why does the Moon change shape?” cannot
be answered by a sentence; it needs the student to move the Moon and see the
phase from Earth. The interaction is the explanation, not decoration.

### ★ 3. What is the strongest technical decision?

Baking the heavy data at build time. The HYG catalogue and Stellarium line
figures become compact JSON; the browser only loads packed arrays. The star field
is one MultiMesh, the renderer is GL Compatibility, threads are disabled, and
there is no server. That is what makes it work on cheap hardware and static
hosting.

### ★ 4. What is the strongest learning decision?

Explanation before interaction. Every exhibit opens with a written Sky Note —
the big idea, context and key words — and only then unlocks the manipulation.
The quiz follows the same rule: every answer, right or wrong, gets an
explanation.

### ★ 5. How do you know the facts are right?

Every number is traceable. Star data is HYG v3; line figures are Stellarium
skycultures; planet facts and light-times are NASA Solar System Exploration;
curriculum vocabulary is NCERT/State; black-hole formulas are in the code
(`Rs = 2.953 km × M☉`, `1/√(1 − Rs/r)`); and the credits name every source. The
game says where it compresses scale, so the drawing is never mistaken for data.

---

## Design and pedagogy

### 6. Who is the audience?

Classes 6–9, their teachers, and a classroom with a projector or a set of phones.
The UI assumes touch first, a portrait phone as the primary layout, and a
projector as the large-screen layout.

### 7. Why free choice? Don’t students need a sequence?

A fixed sequence is useful for a lesson plan; it is a poor fit for a lab. The
Moon, stars, planets and seasons are independent entry points, and a student who
came for black holes should not have to light six lanterns first. The story is a
wrapper; every exhibit is open from the first second. Teachers can still impose
an order in class.

### 8. Where does the story fit?

It is a four-panel lantern-festival wrapper on the title screen. It explains why
there are seven lanterns and gives the finale a meaning. It never gates a lesson.

### 9. How is assessment designed?

Fourteen hand-written questions, no timer, one explanation per answer. The same
set can be used before and after a lesson; the score is a learning check, not an
exam. The teacher note describes a suggested flow. The best score is stored
locally, and the certificate is a finish line rather than a grade.

### 10. What about students without a phone or with a slow device?

The build is a static page; the teacher can run it on one classroom laptop and
project it, or serve it from a school LAN. Portrait layouts and content scaling
mean the same build works on a low-end phone. There is no account and no
network dependency.

### 11. Why Kannada, and how deep does it go?

The project is set in Karnataka; the sky chapter is local, and the language
should be too. Kannada module names and key terms sit beside the English, and a
Kannada mode switches the module titles. It is **not** a full UI translation —
that is an honest limitation and a clear next step.

### 12. Is this usable by a teacher who is not technical?

The teacher note explains the flow; every screen has one clear action; the
seminar deck has speaker notes and a pre-flight check. A teacher can open the
URL, press Present, and use the deck without editing anything.

---

## Technical

### ★ 13. Why Godot?

It is small, open source, script-driven, and its web export works without a
server-side runtime. The scenes are thin and the logic is in GDScript, which is
easy for a student team to read and for a viva panel to inspect. Unreal’s web
story is not there; Unity’s WebGL build is much heavier for this scope.

### 14. Why export to the web instead of an APK or desktop build?

One URL is the lowest-friction distribution channel for a classroom. It works on
a laptop, a projector and a phone; there is no app store, no install permission,
and no platform-specific build. The same export can be copied to a school server.

### 15. How does “offline” work if it is a web page?

The page is loaded from a local server or the itch.io page and then makes **no
network calls**. All data, fonts, images, audio and the WASM/PCK are served once
and cached by the browser. On a school LAN, the whole folder can be copied to a
static server. There is no API, no CDN and no telemetry.

### 16. Why are threads disabled?

Threads on the web require `SharedArrayBuffer`, which requires COOP/COEP
headers. Many static hosts and itch.io do not provide them. Disabling threads
costs some loading parallelism but buys a build that runs anywhere, including
cheap phones. It is a deliberate compatibility trade.

### 17. How real is the sky?

Positions, magnitudes and B–V colours come from the HYG v3 catalogue (8,879
naked-eye stars). Constellation and nakshatra line figures come from Stellarium
skycultures. The sky is not a photograph or a decorative texture: it is a
rendered catalogue. The Atlas lets you move the time slider and see the sky
change.

### 18. How is the star field drawn efficiently?

The stars are a single `MultiMeshInstance3D` of quads. Each instance carries its
position, colour and a size/twinkle custom value. The whole catalogue is one
draw call plus the line meshes. That is why 8,879 stars are affordable on
integrated graphics.

### 19. How are the Moon phases computed?

`MoonLab._phase()` computes the angle between the Sun direction and the Moon’s
position around Earth. Illumination is `(1 − cos θ) / 2`; the inset and the
labels use the same angle. The four challenges accept a range around the named
phase, not a single exact pixel.

### 20. How are the seasons computed?

`SeasonLab` uses the axial tilt and the orbital month to compute solar
declination, then noon-Sun altitude and day length for 13°N. The “no tilt”
control sets the tilt to 0°, which makes every day about 12 hours and removes
the seasons. The point is to isolate the cause, not to simulate every weather
effect.

### 21. How is the black-hole clock computed?

The Schwarzschild radius is `Rs = 2.953 km × mass in solar masses`. The probe’s
clock ratio is `1 / sqrt(1 − Rs / r)`. At 10 solar masses the horizon is about
30 km; at 4 Rs one hour near the hole is about 1.2 hours on Earth. The visual is
stylised, but the numbers and the formula are real.

### 22. Why is the orrery not to scale?

Because a true-scale orrery cannot share a screen with eight visible planets.
The project keeps the numbers real and compresses the drawing; the scale view
uses true distances, the size view uses true sizes, and the fact cards print the
real values. The game says this explicitly.

### 23. How do you handle performance on a low-end phone?

GL Compatibility renderer, no post-processing, no shadow maps on most lights,
one MultiMesh for stars, small textures, threads off, content-scale instead of
giant textures, and a web export that caches after first load. The deck also
checks the renderer and viewport in pre-flight.

### 24. How does the responsive layout work?

`G._apply_content_scale()` reads `window.innerWidth/Height` in the browser and
sets the Godot content scale, clamping the logical width to phone or desktop
ranges. `UI.is_portrait()` and `UI.is_compact()` switch layouts. The seminar deck
is a special case: in portrait it stacks the figure and a scrolling text column,
while landscape keeps a 16:9 1280×720 stage and scales the whole slide, so a
short browser window never clips a bullet. `G.refresh_content_scale()` restores
the responsive game scale when the deck opens a live exhibit.

### 25. Where is progress stored?

In `user://nakshatra_save.json` — IndexedDB on the web. It stores visited
modules, quiz best/last, language, sound, name and the seminar slide index. No
account, no server, no analytics.

### 26. How do you test a game UI?

Headless contract tests for the data and scene wiring, plus a capture harness
for visual work. `TestSeminar` checks 12 slides, every image and lab path,
speaker notes, pre-flight, figure zoom and number formatting. `TestSolarFlow`
drives the flare/shield sequence. `Capture.tscn` saves a real rendered frame at
1280×720 or portrait so layout changes can be reviewed.

### 27. What was the hardest bug?

Two examples. First, responsive scaling: a high-DPI phone was shrinking the
logical canvas, so 16 px text became unreadable; the fix was to read the CSS
viewport and set `content_scale_size` explicitly. Second, GL Compatibility
shader limits: some effects that work in Forward+ do not compile or look right
on the compatibility renderer, so the sky, star and disk shaders were simplified
and checked on the target renderer.

### 28. What is the licence?

The combined work is GPL-3.0-or-later because the Stellarium skyculture data is
GPL-2.0-or-later. The HYG-derived star data is CC BY-SA 4.0. The art is original
(ComfyUI + SDXL, generated for this project); the fonts are SIL OFL; the EHT and
NASA images used in two cards are credited in `CREDITS.md`. The code is intended
to be shareable with schools under the same terms.

### 29. Can a school deploy this tomorrow?

Yes, if it has a laptop or a static server. Copy `nakshatra/build/web/` to the
server, or use the itch.io zip. No database, no credentials, no maintenance
beyond replacing the folder. The only first-load requirement is that the browser
can download the page — the current export is about 55 MB uncompressed, cached
after the first load.

### 30. What would you do with another month?

Full Kannada/Hindi UI, an offline teacher dashboard that exports class results,
a “tonight’s sky” timeline, audio narration for the Sky Notes, and two more
exhibits (eclipses and tides). The architecture is ready for all five: content
is data-driven and the deck is a scene, not a separate app.

---

## Numbers to know

| Number | Meaning |
|---:|---|
| **8,879** | naked-eye stars in the HYG-derived catalogue |
| **88** | IAU constellations with line figures |
| **28** | nakshatras with line figures |
| **7** | learning modules / lanterns |
| **14** | Sky Riddles questions |
| **8** | Field Guide cards |
| **5** | constellation hunts |
| **8** | planets with fact sheets |
| **4** | scale riddles |
| **12** | seminar slides |
| **23.4°** | Earth’s axial tilt used in the seasons lab |
| **13°N** | latitude used for the sky, seasons and Atlas |
| **2.953 km** | Schwarzschild radius per solar mass |
| **8 min 20 s** | light travel time from Sun to Earth |

---

## If you do not know

Say: “I don’t know — I would check that against NASA/NCERT and update
`content.json`, then rebuild.” Then write it down. A panel prefers an honest
boundary to a confident wrong number. The project is deliberately data-driven so
a correction is a content edit, not a code rewrite.

---

## Team contribution template

Fill this in with your own names and evidence. Do not claim work you did not do.

| Area | What was built | Evidence |
|---|---|---|
| Gameplay / 3D | Sky Lab, Moon, Star, Scale, Season labs | commits, scene scripts, screenshots |
| Content / curriculum | Sky Notes, quiz, planet facts, teacher note | `content.json`, source list |
| Engineering / build | data pipeline, shaders, web export, seminar mode | `tools/`, `Seminar.gd`, `build/web/` |
| Testing / docs | headless tests, capture harness, playbook | `tests/`, `docs/` |

A useful sentence for each member: “I built X, which does Y, and the evidence is
Z.” The panel can then ask about the part you actually know.
