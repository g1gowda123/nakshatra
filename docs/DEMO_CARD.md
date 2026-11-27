# Demo card — print this

**Nakshatra — The Sky Weavers** · free-choice 3D sky lab · Classes 6–9
`https://g1gowda123.github.io/nakshatra/?scene=seminar`

## 30-second pitch

> A free-choice 3D sky lab for middle school. Seven exhibits turn the
> hardest-to-teach chapter into something a student can drag, tilt and break — on
> a phone or a classroom projector. Real 8,879-star catalogue, no install, no
> account, no server, offline after the first load.

## The six-step demo

1. **Title / Seminar mode** — “Everything here runs in a browser.”
2. **Design + Sky Lab (slide 3)** — seven lanterns, no locks. Open it if the projector is good.
3. **Moon (slide 4)** — drag the Moon; point at the “view from Earth” inset.
4. **Solar storm (slide 8)** — release a flare; light 8:20, CME hours later, aurora after.
5. **Black hole (slide 9)** — lower the probe below 1.1 Rs; read the clock aloud.
6. **Close (slide 12)** — “The lab is open. Questions?”

## Keys

| | |
|---|---|
| `→` `Space` `PgDn` | next |
| `←` `PgUp` | back |
| `N` | speaker notes |
| `A` | auto-advance |
| `D` | checks · shortcuts · demo state · reset |
| `F` | fullscreen |
| `L` | open this exhibit |
| `I` | enlarge figure |
| `P` | pause timer |
| `Home` | back to slide 1 |
| `Esc` | close overlay / exit to Sky Lab |

## Before you start (30 seconds)

- [ ] Press **D** — every row green.
- [ ] Press **F** — fullscreen, top bar and footer visible.
- [ ] Click once — audio allowed.
- [ ] If showing the finale: **D → Set demo state**.
- [ ] Open the deck **just before** you speak; the timer resumes from the last run. Press **Home** to reset it.

## If it breaks

| Problem | Do this |
|---|---|
| Blank page | Serve over HTTP, not `file://` |
| WebGL error | Use native build or the deck screenshots |
| No audio | Click once; check Sound On |
| Slow laptop | Close other tabs; 1280×720 |
| Overrun | Jump to slide 11, one sentence each, then 12 |
| Total failure | Use the static screenshots in `docs/` and the pitch above |
| Lost your place | Reload with `?scene=seminar&slide=8`; the deck resumes at that slide |
| Need the certificate now | Reload with `?scene=seminar&demo=1`, then **D → Open the finale** |

## Reset before handing over

**D → Reset progress** — clears lanterns, quiz scores and the seminar index.
Do not leave a school device with your demo progress on it.

## Three Q&A one-liners

- **Why Godot?** Small, open source, script-driven, and its web export needs no server runtime.
- **How real is the sky?** HYG v3 positions, magnitudes and colours; Stellarium constellation and nakshatra lines.
- **Why free choice?** Because the misconceptions are spatial. The interaction is the explanation; the story is a wrapper, not a gate.

Full script: `docs/SEMINAR_PLAYBOOK.md` · Questions: `docs/VIVA_QA.md`
