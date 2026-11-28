# Art direction — *Nakshatra*

> A night sky is not a screensaver. It is a place you are allowed to walk into,
> carrying one small light.

This document is the visual contract for the game. It exists so that a new
contributor can add an exhibit without turning the hill back into a generic
low-poly demo, and so that the viva panel can see *why* each choice was made.

---

## 1. The north star

**A cassette-futurism console, not a dashboard.**

The screen is a warm analog instrument laid over a dark observatory hill:
charcoal housing, amber keys, mint-phosphor readouts, cream type. The 3D world
stays visible but dimmed behind it. Every control should feel like something you
could physically press — a key, a toggle, a dial — not a floating web chip.

Four rules follow from that:

1. **One warm ground, two accents.** Amber is the hand: buttons, highlights,
   things you touch. Phosphor is the machine: live readouts, selected states,
   CRT glow. Vermilion is reserved for a wrong answer.
2. **Every surface is physical.** Panels carry 2–3 px bezels, corner screws,
   inner keycap edges, and soft shadows. Nothing is a flat rectangle.
3. **One sentence at a time.** A label says what the thing is. A note says what
   to do. Nothing explains the interface; the interface explains itself.
4. **The lesson stays first.** Decoration never sits over the task prompt, the
   answer explanation, or the assessment route.

## 2. Visual grammar

### Palette

| Token | Value | Use |
|---|---|---|
| `Design.BG` | `#12100e` | The night ground. Warm charcoal, never pure black. |
| `Design.PANEL` | `#25231f` | Instrument housings and console panels. |
| `Design.GOLD` | `#f0a860` | The hand: primary buttons, highlights, keycaps. |
| `Design.PHOSPHOR` | `#7dffa8` | The machine: CRT readouts, selected states, live arcs. |
| `Design.CREAM` | `#f2e6d0` | Primary type, labels, and engraved text. |
| `Design.PAPER` | `#e8dcc4` | Menus, notes, the certificate. |
| `Design.INK` | `#15130f` | Keycap text on amber, screws, engraved lines. |
| `Design.VERMILION` | `#ff5a3c` | A wrong answer, a warning. Never decoration. |
| `Design.MUTED` | `#a8a29a` | Secondary copy on the dark field. |
| `Design.BEZEL` | `#2a2723` | Housing shells and recessed wells. |
| `Design.BEZEL_EDGE` | `#4a4238` | Bevel edges, screws, inner keycap lines. |

### Type

- **Michroma** — the wordmark and console labels. Wide, squared, Eurostile-line.
- **Space Mono** — terminal readouts, nav, status text, micro-labels.
- **Noto Sans** — reading copy, task prompts, body text.
- **Noto Sans Kannada** — the Kannada layer, never faux-bold.

### Surfaces

- **Instrument housing:** a warm charcoal panel, 3 px bezel, corner screws, and
  a soft drop shadow. The hub dial sits inside one of these.
- **Buttons:** every Button is a `MechanicalButton` with a top highlight, a
  bottom shadow, an inner keycap edge, and four screws. Round controls get a
  circular bevel; rectangular keys get a square one.
- **The hub dial:** a thick amber bezel, a phosphor hairline, and seven evenly
  spaced arcs that read as tape segments. A completed exhibit lights its arc.
- **The title cassette:** a squarer shell, a “SIDE A” label strip, a tape
  window, two reels, wound tape, and four screws. It sits above the wordmark,
  never behind it.
- **CRT:** one quiet full-screen pass — scanlines, vignette, chromatic split,
  and tape noise — plus a physical bezel around the viewport.
- **The 3D hill:** warm charcoal ground, amber lanterns, and quiet starlight.
  It stays visible behind the console but never competes with the lesson text.

### One file to tweak

Every palette, shape, CRT, and type token lives in `scripts/Design.gd`.
`G.gd` copies those values at startup, so a tweak there propagates to every
screen that still reads `G.GOLD`, `G.CREAM`, or any other legacy token.

---

## 3. The hill

The hub is built **procedurally in code** (`scripts/world/SkyHill.gd`) rather
than assembled from imported assets. That keeps the web build small and every
lantern consistent, and it means the whole place is one readable file.

```
                  moon
        ✦                      ✦        sky lanterns
   ─────────────────────────────────────────────
        pine        observatory        pine
          ╲       (brass dome)        ╱
     01 ●───●───●───●───●───●───● 07     lantern trail
          ╲   stone path   ╱
             bench / cairn
```

### The seven lanterns

Seven paper lanterns on dark poles, numbered **01–07**, matching the seven
lesson cards 1:1. Each has:

- a lathe-turned paper body with bamboo caps and a tassel,
- a warm OmniLight and a ground pool,
- a painted number on the paper **and** a hanging cream tag, so the number
  survives at the distance of the hub camera,
- an `Area3D` for picking, a hover ring, and a title that appears only on hover.

The numbers are not decoration. They are the contract between the 3D place and
the 2D lesson grid. If a learner sees “03” on the hill, card 03 must be the same
exhibit.

### The trail

A narrow stone thread runs behind the lanterns and crosses the main path. It is
there to answer a composition problem: seven poles in a field read as seven
unrelated objects; seven poles on a trail read as one walk. The trail is
deliberately narrower and dimmer than the main path — it is a footpath, not a
road.

### The observatory

A brass-and-ink dome at `(-7.8, ·, -14.2)`, scale 1.32, with:

- a riveted dome (`dome_panel.gdshader`) and an open shutter,
- a telescope and a lens glint,
- a Kannada sign (`ಚಂದ್ರಗಿರಿ ಆಕಾಶ ವೀಕ್ಷಣಾಲಯ`) with an English subtitle,
- a warm doorway that acts as the visual anchor at the top of the path.

It is the destination of the path but **not** a locked door. The seven exhibits
are always open. The building is a promise, not a gate.

### Supporting cast

- **Bench + lamp** at the right edge: a place to sit, and a foreground scale cue.
- **Stone cairn** at the left edge: a hand-made marker, and a quiet asymmetry.
- **Pines and a bare tree**: silhouettes, not detailed models. They frame the
  sky and hide the edge of the ground.
- **Grass**: 650 MultiMesh blades, swaying in the `grass_blade` shader. Enough to
  catch the lantern light; not enough to cost a web frame.
- **Fireflies**: 16 points, slow, warm. They are the only thing allowed to
  twinkle in the foreground.
- **Mist / ridges**: layered `ridge.gdshader` silhouettes and two mist bands.
  They make the horizon feel like weather, not a cut-out.
- **Sky lanterns**: ten paper lights rising, each with its own speed and phase.
- **Shooting stars**: a single tapered ImmediateMesh ribbon, spawned 55–85 units
  ahead of the camera. Rare on purpose.

---

## 4. The sky

The sky is the one place where the game is allowed to be literal.

- **8,879 naked-eye stars** from HYG v3, with real colours and magnitudes.
- **88 IAU constellations**, gold line figures.
- **28 nakshatras**, teal lines, with Kannada names.
- The `sky.gdshader` dome is a painted atmosphere, not a cubemap: a deep navy
  gradient, a soft Milky Way band (`milky_strength 0.85`), no static “star dust”.
- The star sprite is a four-pointed paper glint, scaled per magnitude. In the
  title screen it is deliberately scaled down (`1.18`, intensity `1.02`) so it
  never competes with the headline. In the hunt it is scaled up (`1.9`) so the
  sky feels rich on a phone.
- Constellation labels are set in the serif face, gold, with a dark outline.
  They are allowed to be numerous because only a handful are in view at once.

### The hunt

`Thread the Stars` is a real-sky hunt, not a hidden-object puzzle. The five
hunts use the **classic seven-star figures** (curated HIP lists), so the clue
always matches the sky. The target stars carry a warm core and a soft breathing
halo: enough to reward looking, not enough to replace it. The auto-hint appears
after 16 seconds of stillness, and the manual hint rings three stars in teal for
six seconds. Polaris is named in the Saptarishi hunt because the clue points to
it; a small gold reticle anchors the label to the actual star.

### The Atlas

The Atlas is the “instrument” view: time scrubbing, real sky at 13° N, compass
facing, labels, constellation lines and nakshatra lines. It should feel like
turning a brass setting, not browsing a menu. A “NOW” link returns to the real
clock; the time readout is duplicated next to the slider so the control and the
value are never separated.

---

## 5. Motion

| Element | Motion | Why |
|---|---|---|
| Lanterns | `sin` sway, 0.4–0.8 Hz, amplitude 1–2° | Hand-made, hung paper. |
| Sky lanterns | rise 0.15–0.35 u/s, drift `sin` | The hill is alive at the edges. |
| Fireflies | 8 s lifetime, soft vertical drift | Depth without noise. |
| Shooting stars | one every 8–14 s, 0.5 s ribbon | A reward for looking up. |
| Camera (title) | ±0.22 u, 0.07 Hz | A held breath, not a bob. |
| Postcard (title) | ±0.55°, 5.2 s each way | Paper settles; it does not swing. |
| Certificate | 0.85 s alpha-in after 0.25 s | A page being set down. |
| UI | `UI.fade_in` 0.6–0.9 s; hover 0.12 s | Never pop. |

If a motion is faster than 0.12 s or uses `TRANS_ELASTIC`, it is probably wrong
for this game.

---

## 6. Shaders

All shaders are hand-written, small, and mobile-friendly. No screen-space
post-processing chain beyond the vignette and grain.

| Shader | What it does | Where |
|---|---|---|
| `sky.gdshader` | Painted dome, Milky Way, star dust, horizon gradient | every scene |
| `star.gdshader` | Four-point paper glint, magnitude colour/size | `SkyDome` |
| `line.gdshader` | Additive constellation/nakshatra lines | `SkyDome` |
| `ground_ink.gdshader` | fbm ink wash, warm lantern pools | hill |
| `path_ink.gdshader` | Flagstones, mortar, gilt dust, warm emission | hill path + trail |
| `paper_lantern.gdshader` | Ribbed paper, belly light, flicker | every lantern |
| `grass_blade.gdshader` | Swaying tapered blade, warm tip | hill |
| `dome_panel.gdshader` | Riveted brass meridian seams | observatory |
| `ridge.gdshader` | Layered hill/mist silhouettes | horizon |
| `planet.gdshader` | Banded/rocky planet surfaces | orrery |
| `earth.gdshader` | Day/night terminator, city lights | Moon lab, Solar lab |
| `moon.gdshader` | Phase-lit regolith | Moon lab |
| `sun_surface.gdshader` | Granulation + sunspots + stress | Solar lab |
| `accretion_disk.gdshader` | Turbulent disk + Doppler-ish warmth | Black hole lab |
| `vignette.gdshader` | Edge falloff, no colour shift | every UI |
| `crt_futurism.gdshader` | Scanlines, phosphor tint, vignette, chromatic split, tape noise | every frame via the `Crt` autoload |

Shader rules:

- Every shader must compile in the GL Compatibility renderer; no compute, no
  screen texture unless it is the vignette or the CRT pass.
- Every shader gets a **named parameter** rather than a magic number in the
  material setup. If a number matters to the art direction, it belongs in the
  shader header.
- No `TIME`-driven high-frequency noise. Slow is the brand.

---

## 7. Readability and access

- **Minimum body size**: 14 px at 1280×720; 13 px on compact.
- **Minimum contrast**: body copy is cream or >70 % muted on `#060910`. Gold is
  reserved for labels at 9 px or larger with an outline.
- **Phone first**: every screen is checked at 390×844 portrait. The hub wheel scales to phone width; node labels hide, the note narrows and wraps to three lines. The sky hunt panel stacks; the atlas panel becomes a sheet.
- **Tap targets**: 44 px minimum; lantern `Area3D` radius is generous.
- **Reduced motion**: the game does not require motion to understand any lesson.
  If a device is slow, the shaders degrade to flat colours before the layout
  changes.
- **No colour-only meaning**: done/locked is a check and a lit lantern, not just
  green.

---

## 8. What is deliberately *not* here

- No photoreal textures, no HDRIs, no imported 3D models. The hill is code and
  shaders; the sky is real data.
- No lens-flare post chain. The four-point glints are sprites/shader work, not a
  screen effect.
- No loot, streaks, badges or confetti. The reward is the sky and the
  certificate.
- No fake “AI” voice. Every label is written by a person and checked against the
  content.

---

## 9. Extending the hill

1. **Add a lantern**: append a spot to `SPOTS` in `SkyHill.gd`, add a module to
   `G.MODULES`, and add its card to the lesson grid. The number is derived from
   `G.MODULES`, so it stays in sync.
2. **Add a shader**: put it in `shaders/`, expose named parameters, and preview
   it in `tests/WorldPreview.tscn` before wiring it into `Lab`.
3. **Add an exhibit**: one scene, one script, one content entry. Keep the 3D
   scene readable at 1280×720 and 390×844; use `UI.app_bar`, `UI.panel`,
   `UI.button`, `UI.micro`.
4. **Add a hunt**: add the constellation to `StarDB` and a curated HIP list to
   `MAIN_STARS` in `StarLab.gd`. Do not rely on “brightest seven”; curate the
   figure.

---

## 10. QA set

The art pass is considered complete when these frames have been inspected at
1280×720 landscape and 390×844 portrait:

- Title (postcard visible, CTA readable, no star behind the headline)
- Hub (seven numbers readable, trail continuous, no lantern clipping the dome)
- Each of the seven labs (no object clipping; labels not overlapping)
- Star hunt (the figure findable in under 30 s without the hint)
- Atlas (labels legible; time value next to the slider)
- Finale 1/7 and 7/7 (the certificate does not bury the sky; the horizon fills
  the lower third)
- Seminar slide 1 and a figure slide (no tooltip overlap; one primary CTA)

The current reference captures live in `docs/img/` and
`build/web/` after `godot --export-release "Web"`.

The public playable build is at
https://g1gowda123.github.io/nakshatra/ and the source is at
https://github.com/g1gowda123/nakshatra.

---

## 11. Reference frames

These are captured from the build, not mockups. They are the visual baseline for
future work.

![Title screen](img/title.png)
*The title: a quiet sky, a cream plate, one clear invitation.*

![Lantern hill](img/hub.png)
*The hub: seven numbered lanterns, a continuous trail, the observatory as anchor.*

![Star hunt](img/star_hunt.png)
*The hunt: seven warm cores, a named Dhruva, no drawn answer until asked.*

![Sky Atlas](img/atlas.png)
*The Atlas: real sky, readable labels, the time value next to the slider.*

![Finale](img/finale.png)
*The finale: a certificate, seven lights, and a horizon that belongs to the hill.*

![Moon lab](img/moon_lab.png)
*The Moon lab: an inclined orbit and a Moon that stays visible.*

![Seasons lab](img/seasons_lab.png)
*The Turning Year: June on the June-solstice mark, the axis leaning sunward.*

