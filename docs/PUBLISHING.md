# Publishing — source, Pages, itch

The project has three outputs. They are deliberately separate so a large build
never bloats the source repository.

| Output | Where | Contains |
|---|---|---|
| Source | https://github.com/g1gowda123/nakshatra | Godot project, tools, tests, docs, compact sky data |
| Playable | https://g1gowda123.github.io/nakshatra/ | Only the exported Web build, on the `gh-pages` branch |
| Store | `itch/nakshatra-web.zip` | The same Web build plus licence/README, ready to upload |

## 1. Push source

```bash
cd "/home/g1/projects/idt game"
git add -A
git commit -m "Describe the change"
git push origin main
```

The source `.gitignore` excludes `nakshatra/.godot/`, `nakshatra/build/`,
`itch/*.zip`, `.venv/` and Python caches. Do not commit the built PCK/WASM to
`main`; the Pages branch is the place for binaries.

## 2. Update the playable build

```bash
cd "/home/g1/projects/idt game"
bash tools/build_web.sh
```

The build lands in `nakshatra/build/web/` and includes `sw.js` plus
`manifest.webmanifest`; `tools/check_web.py` verifies both and that the zip
carries them. Publish the whole folder to `gh-pages`:

```bash
tmp="$(mktemp -d)"
cp -r nakshatra/build/web/. "$tmp/"
touch "$tmp/.nojekyll"
cd "$tmp"
git init -q
git config user.name "g1gowda123"
git config user.email "jeevangowdagm101@gmail.com"
git add -A
git commit -m "Nakshatra web build"
git remote add origin https://github.com/g1gowda123/nakshatra.git
git push origin HEAD:gh-pages
```

GitHub Pages is already configured for the `gh-pages` branch at `/`. The public
URL is https://g1gowda123.github.io/nakshatra/. A push to `gh-pages` rebuilds the
site automatically; wait for `status: built` with:

```bash
gh api repos/g1gowda123/nakshatra/pages --jq '.status'
```

## 3. Package for itch.io

```bash
cd "/home/g1/projects/idt game"
python3 tools/package_itch.py
```

This writes `itch/nakshatra-web.zip` and refreshes the store screenshots. Upload
the zip as an **HTML** project on itch.io, with **“This file will be played in the
browser”** checked. The build has threads disabled, so it does not need
cross-origin isolation headers.

## 4. Pre-publish gate

```bash
bash tools/run_tests.sh
```

Do not publish if this does not print `ALL TESTS PASS`. Then check:

- title at 1280×720 and 390×844,
- the hub’s seven numbered lanterns,
- three taps in the star hunt and the story card,
- the Atlas time slider and `NOW`,
- the 7/7 finale (`?scene=finale&demo=1` for a quick state),
- the Seminar deck slide 1 and one live-exhibit jump.

The detailed matrix and known limits are in [`QA_REPORT.md`](QA_REPORT.md).
