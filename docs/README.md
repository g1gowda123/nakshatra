# Nakshatra — documentation

This folder is the paper trail for the project: how to present it, how it is
built, what it claims, and how those claims are checked.

**Live build:** <https://g1gowda123.github.io/nakshatra/> · **deck:**
<https://g1gowda123.github.io/nakshatra/?scene=seminar>

| Document | Read it when | Length |
|---|---|---|
| [`SEMINAR_PLAYBOOK.md`](SEMINAR_PLAYBOOK.md) | You are presenting, or you are the person holding the clicker. | ~10 min read |
| [`DEMO_CARD.md`](DEMO_CARD.md) | You need one printable page beside the laptop. | 1 page |
| [`SPEAKER_NOTES.md`](SPEAKER_NOTES.md) | The deck cannot run and you need the exact words on paper. | 12 short pages |
| [`HANDOUT.md`](HANDOUT.md) | You need a one-page takeaway for the audience. | 1 page |
| [`LESSON_PLAN.md`](LESSON_PLAN.md) | A teacher wants to run a 45-minute class with the lab. | 2 pages |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Someone asks how the game works, or you need to change it. | ~15 min read |
| [`FEATURE_MATRIX.md`](FEATURE_MATRIX.md) | You need to map a feature to a syllabus topic or a demo moment. | ~8 min read |
| [`ART_DIRECTION.md`](ART_DIRECTION.md) | You are adding an exhibit, shader or lantern, or explaining the look. | ~10 min read |
| [`QA_REPORT.md`](QA_REPORT.md) | You need the tested matrix, known limits and re-run commands. | ~5 min read |
| [`PUBLISHING.md`](PUBLISHING.md) | You are updating the GitHub Pages build or the itch zip. | ~5 min read |
| [`VIVA_QA.md`](VIVA_QA.md) | You are preparing for questions after the demo. | ~12 min read |
| [`STATS.md`](STATS.md) | You need real numbers (stars, lines of code, build size). | 1 min read |

## The short version

Nakshatra is a free-choice 3D sky lab for Classes 6–9. Seven interactive
exhibits, a real HYG star catalogue, a 14-question pre/post test, Kannada key
terms, and a web export that runs offline after the first load. The **Seminar
mode** is a twelve-slide presenter deck built into the same build: speaker
notes, a timer, auto-advance, a pre-flight check and one-click jumps into any
exhibit.

## Conventions

- All commands run from the repository root unless stated otherwise.
- The Godot project is in `nakshatra/`; the web export is in
  `nakshatra/build/web/`.
- Paths in the game use `res://`, which maps to `nakshatra/`.
- `docs/STATS.md` is generated; do not hand-edit it. Run
  `python tools/project_stats.py --write docs/STATS.md` after a build.

## Where things live

```text
.
├── nakshatra/              # the Godot project
│   ├── scenes/             # Boot, Sky Lab, 7 exhibits, Atlas, Finale, Seminar
│   ├── scripts/            # GDScript (autoloads + one script per scene)
│   ├── shaders/            # sky, star, planet, Earth, Moon, Sun, disk, lines
│   ├── data/               # content.json + compact sky catalogue
│   ├── assets/             # art, fonts, seminar screenshots, FX
│   ├── audio/              # synthesised ambience and interface sounds
│   ├── tests/              # headless smoke tests + capture harness
│   └── build/web/          # exported static site
├── tools/                  # data, art, audio, build and stats scripts
├── itch/                   # store page assets and the packaged zip
├── docs/                   # this folder
├── README.md               # the front door
├── CREDITS.md              # external data, fonts, images and licences
└── CHANGELOG.md            # what changed, and when
```
