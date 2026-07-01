# OVERTHRONE — GameOS Character Studio

An internal, SaaS-quality web tool for managing the character roster of **OVERTHRONE**
(the Survival-Project-like isometric arena fighter). It gives the studio a single dashboard
over the roster: who's built, how complete they are, which corners of the design space are
still empty, and a way to sketch new fighters that fill the gaps.

It's part of **GameOS** (see `../../SYSTEM.md`) — a reusable module, not a one-off.

## How to open it

Just **double-click `index.html`**. It opens in any modern browser on Windows — no server,
no build step, no install. Everything (HTML + CSS + JS + the roster data) is self-contained
in that one file, so it works straight off the disk (`file://`).

Portraits are referenced with relative paths (`../../concept/characters/...`), so keep the
tool inside `tools/character-studio/` in the repo and the images resolve automatically.
If an image is ever missing, the card falls back to the character's initial — nothing breaks.

> Tip: if you'd rather serve it (e.g. `python -m http.server` from this folder), the tool
> will additionally read the on-disk `characters.json` and prefer it over its baked-in copy.

## What's inside

| File | Purpose |
|---|---|
| `index.html` | The whole app — inline CSS + JS. Double-click to run. |
| `characters.json` | The **canonical data model** — the 12 axes + their value-sets, and the roster (FANG, ZERO). |
| `README.md` | This file. |

## The five things it does

1. **Dashboard** — roster count, per-character completion (bible · art · rig), saved-stub count,
   and an **attribute coverage view across all 12 axes** that highlights **gaps** (values no
   fighter carries yet — e.g. *alien, construct/tech, spirit, mage, small-nimble, tank,
   grappler, long-range, future*). This is the "synopsis of the creation set."
2. **Roster** — character cards (portrait, name, tagline, key tags, status), colored by each
   fighter's identity color. Click a card to open the detail view.
3. **Character detail** — big portrait, tagline, all 12 tags, the seed/contradiction and the
   want, plus editable status toggles. "Only 1" marks a tag unique to that fighter.
4. **Tag Explorer** — filter the roster by any axis value and read the full live matrix table.
5. **New Character** — pick tag values across the axes, or hit **Surprise me** to auto-build a
   combo anchored on current gaps. The stub card shows exactly which gaps it fills; **save** it
   to the roster (stored in your browser). Stubs are meant to be handed back to Claude to design.

Plus **inline editing**: change a character's tags or status in the UI (saved to your browser),
then hit **Export JSON** to download an updated `characters.json`.

## How to add a character

You have two easy paths and one manual one.

**A. From the tool (fastest for sketching):**
1. Open **New Character**, pick a combo (or **Surprise me**), and **Save concept stub**.
2. Hand the stub's combo to Claude to run the Character Deep-Dive (`concept/CHARACTER-METHOD.md`).
3. Once designed, add the finished character to `characters.json` (path B) and drop the portrait
   into `concept/characters/<id>/`.

**B. By editing `characters.json` (the canonical source):**
Add an object to the `characters` array following this exact shape:

```json
{
  "id": "newguy",
  "name": "NEWGUY",
  "tagline": "One-liner from the bible.",
  "archetypeSummary": "How they play, in a sentence.",
  "colorIdentity": "#RRGGBB",
  "portrait": "../../concept/characters/newguy/newguy_anchor.png",
  "status": { "bible": true, "art": false, "rig": false },
  "tags": {
    "nature": "…", "powerSource": "…", "archetype": "…", "range": "…",
    "movement": "…", "tempo": "…", "temperament": "…", "size": "…",
    "storyRole": "…", "era": "…", "element": "…", "vibe": "…"
  },
  "seed": "The seed / contradiction (short).",
  "want": "The want (short)."
}
```

Every `tags` value should come from the enumerated `axes` value-sets at the top of
`characters.json` (add a new value there if the roster genuinely needs one). Portrait paths are
relative to this folder.

## Data model notes

- **Source of truth for tags & gaps:** `../../concept/CHARACTER-ATTRIBUTES.md` (the 12 axes +
  roster matrix). `characters.json` mirrors it.
- **Source of truth for lore (seed / want / tagline):** each character's bible in
  `../../concept/characters/<id>/`.
- The tool's baked-in copy inside `index.html` and `characters.json` are kept identical. If you
  edit one, mirror the other (or use **Export JSON** to regenerate `characters.json`).

## Assumptions / follow-ups

- Added a couple of enum values the bibles use that weren't spelled out in the axis lists:
  `size: large-agile` (FANG), `element: cosmic` (ZERO). They're in `characters.json` → `axes`.
- Browser edits/stubs live in **localStorage** (per-browser). They are **not** written back to
  the JSON automatically — use **Export JSON** and commit the file to persist across machines.
- ZERO's art status is `false` per ROSTER.md (anchor locked, floating rig-pose still pending).
