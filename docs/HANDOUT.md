# Nakshatra — the sky weavers

**A free-choice 3D sky lab for Classes 6–9. One URL, no install, no account.**

Nakshatra turns the astronomy chapter into seven small interactive exhibits. A
student can start anywhere, read a one-page sky note, touch the thing, and leave
with a certificate. The whole project runs in a school browser — including on a
low-end phone — and keeps working after the first load.

## Try it

```text
https://g1gowda123.github.io/nakshatra/
```

![QR code to the live sky lab](img/qr_live.png)

*Scan to open the live sky lab. The deck is at `?scene=seminar`; the first load
needs a network, then the service worker keeps it offline.*

On the title screen choose **Seminar mode** for the twelve-slide deck, or
**Enter the Sky Lab** to explore. The deck is also at
`?scene=seminar`. The first load needs a network; after that the service worker
keeps it running offline. No login, no tracking.

## Five things to notice

1. **The Moon does not change shape.** Drag it around Earth; the inset shows the
   phase an observer would see. Half the Moon is always lit.
2. **The lines between stars are ours.** The 8,879 stars are real catalogue
   positions; the 88 constellation figures and 28 nakshatras are cultural
   overlays, drawn as stories rather than borders.
3. **Space is mostly nothing.** A light-minute scale turns the orrery into a
   patience test: sunlight takes 8:20 to reach us, and 53 minutes to reach
   Saturn at this scale.
4. **The seasons are a tilt, not a distance.** Turn the 13°N tilt off and the
   year stops making sense; turn it on and the solstices return.
5. **A solar storm is a delay, not a flash.** Light arrives in 8:20; the flare's
   particles take hours to days. That gap is the forecast window.

## The numbers

| | |
|---|---|
| Stars in the catalogue | 8,879 |
| IAU constellation figures | 88 |
| Nakshatras | 28 |
| Exhibits | 7 |
| Pre/post questions | 14 |
| Seminar slides | 12 |
| Scenes | 12 |
| Custom shaders | 16 |

## Built with

Godot 4.7 (GL Compatibility renderer), GDScript, the HYG star catalogue, and
Stellarium skyculture lines. Code, UI, deck and audio are original. The sky
data and fonts are credited in `CREDITS.md`; the project is
GPL-3.0-or-later because the skyculture data is GPL.

**Repository:** open `README.md` for the build, test and export commands.
**Presenter:** `docs/SEMINAR_PLAYBOOK.md`; **one-page card:** `docs/DEMO_CARD.md`.
