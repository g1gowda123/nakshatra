# A 45-minute lesson with Nakshatra

**Audience:** Classes 6–9 · **Group size:** 1–40 · **Devices:** one per pair, or
one teacher laptop and a projector · **Network:** none after the first load.

## Learning outcomes

By the end of the lesson a student can:

1. Explain a Moon phase as geometry, not a changing shape.
2. Point to Saptarishi and explain that constellation lines are a human overlay.
3. Order the planets by distance and give one consequence of the scale.
4. Explain the seasons as axial tilt, not distance from the Sun.
5. Describe the light/CME delay in a solar storm and why it matters.
6. Explain why a black hole's clock runs slower, in one sentence.

## Before class (5 minutes)

- [ ] Open `index.html` once so the service worker caches the build.
- [ ] Open the Sky Lab once so the hill's shaders are warm.
- [ ] Project the **Seminar deck** if you want a ready-made hook.
- [ ] Decide whether students will use **free choice** or a set route. The game
      does not lock anything; the route below is a suggestion, not a gate.
- [ ] Have the **Sky Riddles** page ready for the exit ticket.

## The lesson

### 0–5 min · Hook: make the Moon move

Project the **Sky Lab**, open **The Moon's Mask**, and drag the Moon one quarter
of the way around Earth. Ask: *"Is the Moon changing shape?"* Take three answers
before revealing the Earth-view inset. The target misconception is stated in the
first minute, not at the end.

### 5–15 min · Pairs: Moon + one constellation

Each pair opens **The Moon's Mask** and completes the four phase challenges. Then
they choose **Thread the Stars** and find Saptarishi. Circulate and ask:

- *"Where is the Sun in this picture?"*
- *"Why can you see only one side of the Moon?"*
- *"Are the stars in a line, or did we draw the line?"*

### 15–25 min · The scale of the solar system

Open **The Long Road** together. Switch to true distance. Read the light-time
values aloud: **8:20** to the Sun, **53 minutes** to Saturn at this scale. Ask
students to stand up and represent the planets; the gap is the lesson.

### 25–32 min · Seasons, then a storm

Open **The Turning Year**, set the latitude to **13°N**, and run the tilt
on/off experiment. Then open **Solar Storm Lab** and release one flare: light
arrives in **8:20**, the CME takes hours to days. Ask why a forecast is possible
at all.

### 32–40 min · Sky Riddles as a pre/post test

Students answer the **14 questions** individually. The game explains every answer
immediately — this is assessment as teaching, not a grade. If you need a number,
record the best score before and after the lesson.

### 40–45 min · Certificate and exit ticket

Students who finish all seven lanterns reach **The Lantern Festival** and can
write their name on the certificate. Close with one exit-ticket sentence:

> *"One thing I can now explain that I could not explain 45 minutes ago."*

## Free-choice variant

If the class is already confident, give each pair one exhibit and five minutes
to prepare a 60-second explanation for another pair. The game has no locks, so
pairs can start anywhere; the jigsaw is the route.

## No-device variant

Use the seminar deck on the projector and ask students to predict the result
before each demo. The deck's speaker notes include the explanation for every
slide, and `docs/SPEAKER_NOTES.md` is a printable fallback.

## Assessment

| Evidence | What it shows |
|---|---|
| Four Moon phase challenges | Can they construct a phase, not just name it? |
| Saptarishi hunt | Can they find a pattern in a real star field? |
| Light-minute readings | Can they distinguish distance from travel time? |
| Tilt on/off | Can they isolate a cause? |
| 14 Sky Riddles | Pre/post gain, with an explanation for every answer |
| Exit-ticket sentence | One transferable idea in the student's own words |

## Curriculum links

- **Moon phases, stars and the solar system** — Classes 6–8 science.
- **Light, shadows and time** — the scale and black-hole exhibits.
- **Earth's tilt and seasons** — the Turning Year exhibit.
- **Space weather** — a current-events hook (Aditya-L1, auroras, grid safety).
- **Data and models** — the star catalogue is real data, not an illustration.

## Teacher notes

- The game is **free choice by design**. A student who opens the black hole first
  is still learning; the story is a wrapper, not a gate.
- The **Kannada** layer covers key terms and module names. It is a starting point
  for the language of the classroom, not a full translation.
- Progress is stored only in the browser (`user://`, IndexedDB on the web). There
  are no accounts and no class list. For a whole-class record, use the quiz
  scores on paper or the certificate screenshot.
- If the venue Wi-Fi fails after the first load, the service worker keeps the
  build running. Test this once with the network off before relying on it.
