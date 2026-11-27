# Speaker notes — Nakshatra, seminar edition

Printable fallback for the twelve-slide deck. The deck itself is the
primary artefact: `http://127.0.0.1:8060/index.html?scene=seminar`
(or **Seminar mode** on the title screen).

Keys: `→` next · `←` back · `N` notes · `A` auto · `D` checks ·
`F` fullscreen · `L` open the attached exhibit · `Backspace` return to the deck · `I` enlarge · `P` pause.

---

## 01 · Nakshatra

**SEMINAR DEMO  ·  3RD SEMESTER CSE** · about **45 s**

Good morning. Nakshatra is a free-choice 3D sky lab for middle school; the name means 'star' in Kannada. Everything you will see runs in a browser: no app store, no account, no internet after the page loads. I will show the design idea, the seven exhibits, the engineering underneath, and how a classroom can actually use it.

**Open:** Enter the Sky Lab (`res://scenes/Lab.tscn`)

**Figure:** The cover art: a papercut hill town waiting for its lanterns.

---

## 02 · The sky is the best classroom. It is also the hardest to book.

**WHY THIS EXISTS** · about **50 s**

Every astronomy teacher meets the same gap: the subject is visual, but the classroom is not. A diagram of the Moon's phases is static; a planetarium visit is rare; we cannot assume a telescope. But we can assume a browser. That constraint shaped the design: one URL, no installation, no account, and no network once it has loaded.

**Figure:** The written Sky Note always comes before the interaction.

---

## 03 · Explain first. Then let them touch the sky.

**THE DESIGN** · about **50 s**

We made two deliberate design choices. First, explanation comes before interaction: each exhibit opens with a short written lesson, so the student knows what they are looking at. Second, there is no forced path — all seven lanterns are open from the first second; the story is a wrapper, not a gate. And the sky is not decorative: the 8,879 stars are real catalogue positions.

**Open:** Open the Sky Lab (`res://scenes/Lab.tscn`)

**Figure:** The Sky Lab: seven lanterns, one observatory, no locked doors.

---

## 04 · Why does the Moon change shape?

**EXHIBIT 01** · about **50 s**

This is the exhibit students reach first. They drag the Moon around Earth and a live inset shows what an observer on Earth would see. The key misconception is that the Moon changes shape. It does not: half of it is always sunlit; the phase is a geometry problem. The four challenges ask them to reproduce a named phase, and every answer explains the geometry they just made.

**Open:** Open the Moon's Mask (`res://scenes/MoonLab.tscn`)

**Figure:** The Moon's Mask: orbit on the left, the view from Earth on the right.

---

## 05 · The same stars, many stories.

**EXHIBIT 02** · about **50 s**

This exhibit is about interpretation. The lines are not in the sky; people drew them. Students hunt five patterns, tapping three stars at a time. Each unlock tells the story and the science: the stars in one pattern can be hundreds of light-years apart, and the pattern itself changes over tens of thousands of years. The nakshatra layer shows the same stars through two astronomical traditions.

**Open:** Open Thread the Stars (`res://scenes/StarLab.tscn`)

**Figure:** Thread the Stars: tap three stars to unlock the pattern and its story.

---

## 06 · Space is mostly nothing.

**EXHIBIT 03** · about **50 s**

Scale is the hardest idea in the solar system chapter. A textbook diagram compresses distance and size at the same time, which accidentally teaches the wrong thing. Here the two scales are separate: true distance, true size, or the data. Light-minutes do the emotional work: sunlight takes eight minutes to reach us, and more than four hours to reach Neptune. The riddles check whether the idea landed.

**Open:** Open The Long Road (`res://scenes/ScaleLab.tscn`)

**Figure:** The Long Road: the inner planets huddle close; Neptune is far out in the dark.

---

## 07 · A tilted planet writes the seasons.

**EXHIBIT 04** · about **50 s**

The seasons are usually taught with a diagram of a tilted Earth, but the diagram does not move. Here students tilt the planet, orbit it, and read the consequences: noon-Sun altitude, day length, the solstices and equinoxes. Then they switch the tilt off and watch the seasons vanish. That single experiment isolates the cause. The latitude is set to 13 degrees north, so the numbers match the students' own sky.

**Open:** Open The Turning Year (`res://scenes/SeasonLab.tscn`)

**Figure:** The Turning Year at 13°N, with the noon Sun and day length live.

---

## 08 · The Sun can reach across 150 million kilometres.

**EXHIBIT 05** · about **50 s**

This is the enrichment exhibit, and the one that surprises people. Students build magnetic stress on the Sun, release a flare, and watch two things travel to Earth at different speeds. Light arrives in eight minutes twenty; the coronal mass ejection takes much longer. That delay is why space weather can be forecast at all. They then protect a satellite with a shield, which makes the engineering stakes concrete. Aditya-L1, India's solar observatory, watches the same chain from L1.

**Open:** Open Solar Storm Lab (`res://scenes/SolarLab.tscn`)

**Figure:** Solar Storm Lab: the flare, the CME, and the satellite in the path.

---

## 09 · Where time itself slows down.

**EXHIBIT 06** · about **50 s**

Black holes are where the textbook runs out of analogies. This exhibit lets students change the mass, lower a probe, and read two numbers that are easy to say and hard to feel: the horizon radius and the clock rate. At ten solar masses the horizon is about thirty kilometres in radius. Near it, one hour for the probe is not one hour on Earth. The visual follows the physics of the EHT image: a black shadow, a photon ring, and a lensed accretion disk.

**Open:** Open Black Hole Lab (`res://scenes/BlackHoleLab.tscn`)

**Figure:** Black Hole Lab: event horizon, photon ring and a clock that tells the truth.

---

## 10 · A pre-test and a post-test that teach.

**THE CLASSROOM** · about **50 s**

We did not want another quiz that only ranks students. The same fourteen questions work as a pre-test and a post-test; the explanation appears after every answer, right or wrong. That turns assessment into teaching. The teacher note explains a suggested flow, and the certificate gives the class a finish line. Progress stays on the device, and there is no account, no analytics and no network call, which matters for a school lab.

**Open:** Open Sky Riddles (`res://scenes/QuizLab.tscn`)

**Figure:** Sky Riddles: fourteen questions, an explanation after every answer.

---

## 11 · A real-time game, on a school browser.

**UNDER THE HOOD** · about **50 s**

Under the hood this is a real-time 3D application, not a slide deck. The sky is a custom shader with an 8,879-instance MultiMesh, so the whole star field is one draw call. Positions and colours are baked from HYG and Stellarium at build time, so the browser does no heavy data work. The web export uses the GL Compatibility renderer with threads disabled: a deliberate trade for compatibility, because it runs on itch.io and cheap phones without special server headers.

**Open:** Open the Sky Atlas (`res://scenes/Atlas.tscn`)

**Figure:** The build pipeline: catalogue to browser, with no server in the loop.

---

## 12 · The sky is open. Come and look.

**THE POINT** · about **55 s**

The measure of this project is not how it looks on a gaming laptop. It is whether it works on the phone a student already owns, the projector a classroom already has, and a school network with no internet. That is why the export is a static folder, why the layout is portrait-first, and why Kannada terms sit beside the English. The next step is a teacher dashboard that can export class results without a server, and a “tonight’s sky” mode that tells a student what to look for after the seminar.

**Open:** Light the lanterns (`res://scenes/Finale.tscn`)

**Figure:** The finale: a certificate, rising lanterns, and a class that read the sky.

---

## Before you start

- [ ] Open the deck early; the timer resumes where you left it. **Home** resets it.
- [ ] Press **D** — every row green.
- [ ] Press **F** — fullscreen.
- [ ] Click once — audio allowed.
- [ ] If showing the finale: **D → Set demo state**.
- [ ] Keep this file or `docs/DEMO_CARD.md` on paper.
