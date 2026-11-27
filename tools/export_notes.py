#!/usr/bin/env python3
"""Export the deck's speaker notes to a printable Markdown document.

The deck is the primary artefact; this file is the fallback. If the projector
or the browser fails, the presenter can still read the same script from paper.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "nakshatra", "data", "content.json")
DST = os.path.join(ROOT, "docs", "SPEAKER_NOTES.md")


def main():
    with open(SRC, encoding="utf-8") as f:
        data = json.load(f)
    slides = data.get("seminar", {}).get("slides", [])
    lines = [
        "# Speaker notes — Nakshatra, seminar edition",
        "",
        "Printable fallback for the twelve-slide deck. The deck itself is the",
        "primary artefact: `http://127.0.0.1:8060/index.html?scene=seminar`",
        "(or **Seminar mode** on the title screen).",
        "",
        "Keys: `→` next · `←` back · `N` notes · `A` auto · `D` checks ·",
        "`F` fullscreen · `L` open the attached exhibit · `Backspace` return to the deck · `I` enlarge · `P` pause.",
        "",
        "---",
        "",
    ]
    for i, s in enumerate(slides, 1):
        title = str(s.get("title", "")).replace("\n", " ")
        kicker = s.get("kicker", "")
        seconds = s.get("seconds", 50)
        note = s.get("note", "").strip()
        lab = s.get("lab", "")
        lab_label = s.get("lab_label", "")
        caption = s.get("caption", "")
        lines += [
            f"## {i:02d} · {title}",
            "",
            f"**{kicker}** · about **{seconds} s**",
            "",
            note,
            "",
        ]
        if lab:
            label = lab_label or lab.rsplit("/", 1)[-1].replace(".tscn", "")
            lines += [f"**Open:** {label} (`{lab}`)", ""]
        if caption:
            lines += [f"**Figure:** {caption}", ""]
        lines += ["---", ""]
    lines += [
        "## Before you start",
        "",
        "- [ ] Open the deck early; the timer resumes where you left it. **Home** resets it.",
        "- [ ] Press **D** — every row green.",
        "- [ ] Press **F** — fullscreen.",
        "- [ ] Click once — audio allowed.",
        "- [ ] If showing the finale: **D → Set demo state**.",
        "- [ ] Keep this file or `docs/DEMO_CARD.md` on paper.",
        "",
    ]
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    with open(DST, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"wrote {DST} ({len(slides)} slides, {os.path.getsize(DST)} bytes)")


if __name__ == "__main__":
    main()
