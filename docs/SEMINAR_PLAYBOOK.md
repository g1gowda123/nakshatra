# Seminar playbook

> For the person presenting Nakshatra — and for the person holding the clicker.

## At a glance

| | |
|---|---|
| **Format** | 12-slide in-game deck, then live questions |
| **Length** | 10 minutes + 5 minutes Q&A (a 5-minute cut is below) |
| **Audience** | CSE seminar / project review / community-project showcase |
| **Big claim** | A real-time 3D astronomy lab that a school can actually run: free choice, real data, one browser, no server |
| **What they should remember** | *Explain first, then let them touch the sky.* |

The deck is not a video. Every exhibit slide has a button that opens the real
lab, and the deck remembers where you left it, so you can demo, come back, and
carry on.

---

## The three-sentence pitch

> Nakshatra is a free-choice 3D sky lab for Classes 6–9. Seven exhibits turn the
> hardest-to-teach chapter of middle-school science into something a student can
> drag, tilt and break — on a phone or a classroom projector. It is built in
> Godot, exported to the web, uses a real 8,879-star catalogue, and needs no
> account, no server and no internet after the page loads.

Say it once at the start. Do not read it off the slide.

---

## Before the day

### One week before

- [ ] Build and serve the current export on the laptop you will present from.
- [ ] Run the deck once, end to end, with the projector or an external monitor.
- [ ] Open `docs/STATS.md` and update any number you plan to quote.
- [ ] Test in the target browser (Chrome/Edge/Firefox) at **1280 × 720** and on a phone.
- [ ] Make a backup copy of `itch/nakshatra-web.zip` on a USB stick.
- [ ] Confirm the room has an HDMI/USB-C input and working audio.

### The day before

- [ ] Charge the laptop; pack the charger and an HDMI adapter.
- [ ] Open the live build once: `https://g1gowda123.github.io/nakshatra/`.
      The service worker caches it, so the venue Wi-Fi can fail afterwards.
- [ ] Keep the local copy as the fallback:
      `cd nakshatra/build/web && python3 -m http.server 8060`.
- [ ] Test the exact URL in the exact browser you will use.
- [ ] Put the deck URL in a bookmark:
      `https://g1gowda123.github.io/nakshatra/?scene=seminar`.
      A per-slide bookmark is `&slide=8` (1–12); `&demo=1` sets the finale state.
- [ ] Optional: use the browser's **Install** action once. The app manifest adds
      a home-screen icon and shortcuts for the deck and the Sky Lab.
- [ ] If you will show the finale, open **Checks → Set demo state** once, then reset
      it before you hand the laptop to anyone else.

### 30 minutes before

- [ ] Open the deck. Press **D** and confirm every pre-flight row is green.
- [ ] Open the Sky Lab once, then return to the deck. The first hill load
      compiles shaders; after that the `L` jumps are quick.
- [ ] Press **F** for fullscreen. Check that the top bar and footer are visible.
- [ ] Click once on the page so the browser allows audio; confirm the ambient bed.
- [ ] Set the room volume to roughly 30%. The deck is quiet on purpose.
- [ ] Test the clicker: usually it sends **Page Up / Page Down**, which the deck accepts.
- [ ] Put the laptop on mains power. Turn off notifications and sleep.

---

## Pre-flight check (press D)

The deck checks the things that actually break a demo:

| Row | What good looks like |
|---|---|
| Star catalogue | 8,879 stars |
| Constellations | 88 IAU figures |
| Nakshatras | 28 figures |
| Lessons | 7 modules |
| Slide images | 12 / 12 |
| Live scenes | every attached scene resolves |
| Fonts | 5 / 5 |
| Audio cues | 7 / 7 |
| Renderer | Web · GL Compatibility (or your GPU) |
| Viewport | a sane width and height |
| Save | local only, `user://` |
| Network | no runtime calls |

If a row is red, fix it before you start talking. If you cannot, use the
static screenshots in the deck and skip the live jumps.

---

## Run sheet — 10 minutes

| Time | Slide | Beat | Transition |
|---:|---|---|---|
| 0:00 | 1 · Nakshatra | Hook + one-sentence pitch | “Let me show you why this needed to be built.” |
| 0:45 | 2 · Why | The visual subject / non-visual classroom gap | “So the constraint became the design.” |
| 1:35 | 3 · Design + hub | Explain first, free choice, real sky; seven lanterns | “Here is what that looks like.” |
| 2:25 | 4 · Moon | Drag the Moon, live phase inset | “The Moon does not change shape.” |
| 3:15 | 5 · Stars | Saptarishi, nakshatras, real distances | “The lines are not in the sky.” |
| 4:05 | 6 · Scale | Orrery, light-minutes, Venus riddle | “Space is mostly nothing.” |
| 4:55 | 7 · Seasons | Tilt on/off at 13°N | “The tilt is the cause.” |
| 5:45 | 8 · Solar storm | Flare → CME → aurora, shield | “The delay is the forecast window.” |
| 6:35 | 9 · Black hole | Horizon, clock, EHT physics | “Gravity slows time.” |
| 7:25 | 10 · Classroom | Pre/post test, certificate, Kannada, offline | “This is how a school uses it.” |
| 8:15 | 11 · Engineering | Data pipeline, web export, one static folder | “Under the hood…” |
| 9:05 | 12 · Close | Invitation + roadmap | “The lab is open. Questions?” |
| 10:00 | — | Q&A | “What would you like to try first?” |

The slide counter says **12**. The budgets total 600 s, including both live-demo
jumps. If you are running late, use the literal cut order below; do not improvise it.

---

## Slide-by-slide script

The in-game **speaker notes** (press **Shift+N**) contain a shorter version of each
script; **N** alone shows only a one-sentence cue. This is the full version, with stage directions.

### 1 · Nakshatra (0:00–0:40)

**Do:** stand still. Let the star field move behind you.

**Say:** “Good morning. Nakshatra is a free-choice 3D sky lab for middle school.
The name means ‘star’ in Kannada. Everything you are about to see runs in a
browser: no app store, no account, no internet after the page loads. I want to
show you the design idea, the seven exhibits, and the engineering that makes
them work on a school laptop.”

**If short:** skip the list of exhibits; go straight to slide 2.

### 2 · Why this exists (0:40–1:30)

**Do:** point at the pull-quote card.

**Say:** “Astronomy is the most visual chapter in the syllabus and the least
visual in the classroom. A blackboard can draw a circle; it cannot show why the
Moon changes shape. A planetarium trip is rare, a telescope is expensive, and
the weather does not cooperate. But almost every student already has a browser.
That became the brief: no install, no login, no network, and it has to work on a
low-end phone.”

**If short:** one sentence — “The subject is visual; the classroom is not; the
browser is the one device we can assume.”

### 3 · The design and the Sky Lab (1:30–2:20)

**Do:** gesture at the hub screenshot, then the room.

**Say:** “Two deliberate choices. First, explanation comes before interaction:
every exhibit opens with a one-page Sky Note, so the student knows what they are
looking at before they touch it. Second, there is no forced path: all seven
lanterns are open from the first second. The story is a wrapper, not a gate. And
the sky is not decorative — the 8,879 stars are real catalogue positions, and
the constellation lines are the official IAU figures.”

**Then the hub.**

**Do:** if you are demoing live, click **Enter the Sky Lab**. Drag to look
around, then click a lantern. Come back with the `‹` button and **Present**.

**Say:** “This is the hub: a hilltop at night, seven lanterns, an observatory,
fireflies, and rising sky lanterns. Each lantern lights when its lesson is
finished. Light all seven and the town releases its lanterns — that is the
finale and the certificate. But nothing is locked, so a student can start with
black holes if that is what they came for.”

### 4 · The Moon’s Mask (2:20–3:10)

**Do:** click **Open the Moon’s Mask**. Drag the Moon a quarter of the way
around Earth. Point at the live inset. Do not try to finish the challenge.

**Say:** “The Moon is always half lit. It does not change shape; we see different
amounts of its sunlit half. Students drag the Moon around Earth, and the inset
shows the phase from Earth in real time. The four challenges ask them to make a
named phase — waxing crescent, first quarter, full moon, waning crescent — and
after every attempt the note explains the geometry they just created.”

**Killer line:** “The far side of the Moon is not dark. It is just far.”

### 5 · Thread the Stars (3:10–4:00)

**Do:** click **Open Thread the Stars**. Tap three bright stars of Saptarishi
(or let a volunteer tap). Let the pattern unlock.

**Say:** “A constellation is a pattern people agreed to see. The stars in one
pattern can be hundreds of light-years apart; they look close only because they
happen to line up from Earth. Students hunt five patterns — Saptarishi, Mriga,
Sharmishtha, Vrishchika and Hamsa — and each unlock tells the story and the
science. The same sky carries the 27 nakshatras and the 88 IAU constellations.”

### 6 · The Long Road (4:00–4:50)

**Do:** show the orrery. Switch to the size view. Ask the audience: “Which is
hotter, Mercury or Venus?” Let them answer before you reveal it.

**Say:** “A textbook diagram compresses distance and size at the same time, and
accidentally teaches the wrong thing. Here the two scales are separate: true
distance, true size, or the data. Light-minutes do the emotional work: sunlight
takes eight minutes to reach us, and more than four hours to reach Neptune. The
riddles check whether the idea landed — including why Venus is hotter than
Mercury.”

### 7 · The Turning Year (4:50–5:40)

**Do:** orbit Earth. Then switch the tilt off and let the seasons disappear.

**Say:** “The seasons are not caused by distance from the Sun. They are caused by
axial tilt. Students tilt the planet, orbit it, and read the consequences:
noon-Sun altitude, day length, the solstices and equinoxes. Then they switch the
tilt off and the seasons vanish. That one experiment isolates the cause. The
latitude is set to 13 degrees north, so the numbers match the students’ own sky.”

### 8 · Solar Storm Lab (5:40–6:30)

**Do:** release a flare. Point at the light travel time, then the CME, then the
satellite. If you have 20 seconds, switch the shield on and release another.

**Say:** “The Sun’s magnetic field can snap and release a flare. Light arrives in
eight minutes twenty; the coronal mass ejection follows hours later. That delay
is why space weather can be forecast at all. Students protect a satellite with a
shield, and then discover the same chain behind auroras, grid blackouts and
India’s Aditya-L1 mission. This is the exhibit that surprises people.”

### 9 · Black Hole Lab (6:30–7:20)

**Do:** lower the probe below 1.1 Rs. Read the clock out loud. Then read the
horizon radius.

**Say:** “A ten-solar-mass black hole has an event horizon about thirty
kilometres in radius. Lower a probe toward it and its clock slows. One hour near
the hole is not one hour on Earth. The exhibit computes the dilation live, and
the four challenges separate the physics from the movie myths. The visual is
built around the same physics as the Event Horizon Telescope image of M87*: a
black shadow, a photon ring, and a lensed accretion disk.”

### 10 · The classroom (7:20–8:10)

**Do:** show the quiz screenshot. Open **Sky Riddles** if you have 30 seconds;
answer one question wrong on purpose and read the explanation.

**Say:** “We did not want another quiz that ranks students. The same fourteen
questions work as a pre-test and a post-test, and an explanation appears after
every answer, right or wrong. That turns assessment into teaching. The teacher
note explains a suggested flow; the certificate gives the class a finish line.
Progress stays on the device, and there is no account, no analytics and no
network call — which matters for a school lab.”

### 11 · Under the hood (8:10–9:00)

**Do:** click the architecture figure to enlarge it (or press **I**). Point at
the data → runtime → browser chain. Do not read the small boxes.

**Say:** “Under the hood this is a real-time 3D application, not a slide deck.
The sky is a custom shader with an 8,879-instance MultiMesh, so the whole star
field is one draw call. Positions and colours are baked from HYG and Stellarium
at build time, so the browser does no heavy data work. The web export uses the
GL Compatibility renderer with threads disabled: a deliberate trade for
compatibility, because it runs on itch.io and cheap phones without special
server headers.”

**If asked “why not Unity/Unreal?”:** “Godot’s web export and scene model fit
the constraint. Unreal’s web story is not there; Unity’s WebGL build is much
heavier for this scope. We needed one small static folder.”

### 12 · Close (9:00–9:45)

**Do:** leave the closing slide up. Invite people to the laptop.

**Say:** “The measure of this project is not how it looks on a gaming laptop. It
is whether it works on the phone a student already owns, the projector a
classroom already has, and a school network with no internet. That is why the
export is one static folder, why the layout is portrait-first, and why Kannada
terms sit beside the English. The lab is open — come and try it.”

---

## Live demo routes

### A. Deck only (safest)

Never leave the deck. Use the screenshots and the speaker notes. This is the
right choice if the projector is slow, the browser is unfamiliar, or time is
tight. It still shows the product and the engineering.

### B. Deck + two exhibits (recommended)

1. Slide 4 → **Open the Moon’s Mask**.
2. Drag the Moon; point at the inset; press **Backspace** (or the gold
   **PRESENT · DECK** link) to return to the same slide.
3. Slide 9 → **Open Black Hole Lab**; lower the probe; **Backspace** back.
4. Finish the deck.

The deck stores its slide index *and its timer* in the local save, so the
return lands where you stopped and the clock keeps counting. **Home** restarts
the deck and resets the timer.

### C. Free roam (after the talk)

Press **Sky Lab**. Hand the laptop to the audience. Every exhibit is
open. Press **Present** in the Sky Lab to return to the deck.

---

## Keyboard and touch

| Input | Action |
|---|---|
| `→` `Space` `PageDown` | Next slide |
| `←` `PageUp` | Previous slide |
| `Home` / `End` | First / last slide |
| `N` | One-sentence cue (projector-safe) |
| `Shift+N` | Full speaker notes |
| `A` | Auto-advance (uses each slide’s own timing) |
| `D` | Presenter checks, shortcuts, demo state, reset |
| `F` | Fullscreen (browser fullscreen on the web build) |
| `L` | Open the live exhibit attached to this slide |
| `I` | Enlarge the current figure |
| `P` | Pause / resume the rehearsal timer |
| `Backspace` | From a live exhibit: return to the deck at the same slide |
| `Esc` | Close a figure/check overlay, then return to the Sky Lab (from the last slide: title screen) |
| Click the figure | Enlarge it |
| Click a footer dot | Jump straight to that slide |
| Footer buttons | Back / Next / Open exhibit / Sky Lab |

**On a clicker:** most send Page Up/Page Down, which map to previous/next. If
yours sends arrow keys, it works too.

**On touch:** the top bar collapses to **Menu**; the footer becomes two rows.
Tap the figure to enlarge it. Speaker notes become a bottom sheet.

---

## Demo state and reset

Open **Checks (D)**:

- **Set demo state** — marks all seven lanterns complete and sets the quiz best
  to 14, so the finale and certificate are ready. This changes the local save.
- **Open the finale** — shows the certificate after **Set demo state**; without it,
  the finale explains which lanterns are still unlit.
- **Reset progress** — clears lanterns, quiz scores and the seminar index.
  Use this before handing a school laptop to the next student.

The deck never changes progress unless you press **Set demo state**. Advancing
slides only stores the slide index.

---

## Failure playbook

| Symptom | Fix |
|---|---|
| Blank page | Are you serving over HTTP, not `file://`? `python3 -m http.server` inside `nakshatra/build/web`. |
| WebGL / renderer error | Use the native Godot build, or project the screenshots in the deck. |
| No audio | Click once on the page (browser gesture rule); check **Sound: On** on the title screen. |
| Projector is 4:3 | Use browser fullscreen; the deck’s safe margins hold. Prefer 16:9. |
| Laptop is slow | Close other tabs; keep the browser window at 1280×720; disable screen mirroring. |
| No internet | The build is local and makes no runtime calls. That is the point. |
| You overrun | Jump to slide 11, then 12. The exhibits are the value; the engineering slide can be one sentence. |
| Something crashes | Reload the page. Progress is saved locally. If it still fails, switch to `docs/DEMO_CARD.md` and use the static deck. |
| A question you cannot answer | “I don’t know — I would check it against NASA/NCERT and update `content.json`.” Then note it. |

---

## The 5-minute cut

Run **1 → 2 → 4 → 8 → 11 → 12** in 5:00:

1. **1 · Nakshatra** — 20 s.
2. **2 · Why** — 40 s.
3. **4 · Moon** — 80 s, live if possible.
4. **8 · Solar storm** — 80 s.
5. **11 · Engineering** — 60 s, one sentence on the data pipeline.
6. **12 · Close** — 40 s, then Q&A.

Technical rooms: swap **8** for **9 · Black hole**. Younger rooms: drop **11**
and give the Moon another minute. The order is literal; there is no second
skip list.

---

## After the talk

- If you used **Set demo state**, reset it unless the next presenter wants it.
- Save the questions you could not answer; add them to `docs/VIVA_QA.md`.
- If you changed content, re-run:
  `godot --headless --path nakshatra --import` and the tests.
- Share `itch/nakshatra-web.zip`, not a folder of loose files.
- Run `python tools/project_stats.py --write docs/STATS.md` if the build changed.

---

## One-page version

Print [`DEMO_CARD.md`](DEMO_CARD.md) and keep it beside the laptop. It has the
pitch, the six-step route, the keys and the fallback in one page.
