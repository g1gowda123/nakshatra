# Credits, sources and licences

## Sky catalogue and constellation figures

**HYG Database v3** — David Nash, Astronomy Nexus.
<https://astronexus.com/> · CC BY-SA 4.0.
The file `data_src/hyg.csv` is the source; `nakshatra/data/sky/stars.json` is a reduced, derived catalogue of 8,879 naked-eye stars with positions, magnitudes, B–V colours and distances.

**Stellarium skycultures** — modern (88 IAU constellations) and Indian nakshatra line data.
<https://stellarium.org/> · Skyculture data is distributed with Stellarium under GPL-2.0-or-later.
Files: `data_src/modern/index.json`, `data_src/indian/index.json`, `data_src/indian_nakshatras/index.json`.

The combined packaged game is distributed under **GPL-3.0-or-later** to satisfy the Stellarium data licence. The original code and art may also be reused under the same terms. If you reuse only the HYG-derived star data, CC BY-SA 4.0 applies.

## Fonts

- **Cormorant Garamond** — SIL Open Font License 1.1. `nakshatra/assets/fonts/OFL-Cormorant.txt`.
- **Noto Serif**, **Noto Sans**, **Noto Sans Kannada** — SIL Open Font License 1.1, Google Noto Project.

## Art

Most illustrations in `art_raw/` and `nakshatra/assets/art/` were generated for this project with **ComfyUI + Stable Diffusion XL** using original prompts. The seven exhibit plates and the cover plate in `nakshatra/assets/art/plates/` are drawn from scratch by `tools/make_plates.py` (Pillow), in the game palette. The star field, planets, Earth, Moon, Sun, black hole, rings, observatory, trees and lanterns are procedural Godot meshes and shaders.

Two exhibit cards use real astronomical images:

- **`card_flares.webp`** — the Sun in extreme ultraviolet, NASA / Solar Dynamics Observatory (AIA). Public domain. <https://commons.wikimedia.org/wiki/File:Solar_Dynamics_Observatory_Sees_M7.9-Class_Solar_Flare.jpg>
- **`card_blackhole.webp`** — the first image of the black hole in M87, Event Horizon Telescope Collaboration, 2019. CC BY 4.0. <https://commons.wikimedia.org/wiki/File:Black_hole_-_Messier_87_crop_max_res.jpg> Credit: EHT Collaboration.

The Black Hole Lab's 3D scene is an original stylised visualisation built around
the same physics (a black shadow, a photon ring and a lensed accretion disk); it
does **not** texture-map the EHT photograph. The photograph itself is used on
the Field Guide card, with the attribution above.

These images are used for science communication; their inclusion does not imply endorsement by NASA or the EHT collaboration. The in-game lesson credits repeat the attribution.

## Seminar mode

The Seminar mode, its twelve slides, speaker notes, pre-flight checks, figure
zoom and the generated architecture/pull-quote figures are original to this
project. The deck's screenshots are captures of this game; the architecture
figure is drawn by `tools/make_seminar_assets.py`. No new external assets were
introduced for it.

## Audio

All audio in `nakshatra/audio/` was synthesised from scratch by `tools/make_audio.py` (numpy/scipy), including the ambient pad, bells, chimes, clicks, whooshes and the lantern swell. No sampled music or third-party sound effects.

## Science references

- NASA Solar System Exploration — planet facts, sizes, distances, light-time.
- NASA/ESA Hubble and SIMBAD — stellar radii, luminosities and distances used in constellation notes.
- NCERT Class 6 Geography, *Motions of the Earth*; NCERT Class 8 Science, *Stars and the Solar System* — curriculum mapping and vocabulary.
- Stellarium — constellation line geometry and Indian nakshatra names.
- NASA SDO / AIA — solar flare image and space-weather reference.
- Event Horizon Telescope Collaboration — M87* image and black-hole background.
- LIGO/Virgo — gravitational-wave detection (GW150914).
- ISRO Aditya-L1 — India's solar observatory at L1.

## Software

- **Godot Engine 4.7.2** — MIT licence.
- **Python 3**, **numpy**, **scipy**, **Pillow**, **fontTools** — used only for offline asset generation.
- **ComfyUI** — GPL-3.0; used locally to generate the 2D art, not shipped with the game.

## A note on accuracy and scale

Planet sizes and orbit spacing in *The Long Road* are compressed so that all eight planets can share one screen. The numbers printed in the fact cards, the Scale view and the Sizes view are true. The Moon-phase geometry and the seasonal daylight/noon-Sun calculations are physically correct for 13°N; the Moon's orbital distance and the Earth–Moon sizes are compressed for clarity.

Kannada terms were checked against standard textbook vocabulary. If a term or fact needs correction for your classroom, please edit `nakshatra/data/content.json` and rebuild — every lesson is data-driven.
