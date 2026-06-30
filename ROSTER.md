# Survival Arena - Roster & Status Index

**Single shared truth for character status across BOTH work tracks** - the mechanics
chat (engine / Godot) and the concept/asset chat (identity / art). Either side updates
this; either side reads it first to know where a character stands. When a stage changes,
update the cell **and** the "last update" note.

> This file is the bridge between the parallel chats. Read it before acting on a character.

## Status key

`⬜ not started` · `🔨 in progress` · `⏸️ blocked / waiting` · `✅ ready`

## Roster

| Character | Archetype | Mechanics | Identity/concept | Assets (ref+pose) | Rigged (Godot) | In-game art |
|---|---|---|---|---|---|---|
| **FANG**   | **rusher** | ✅ | 🔨 (bible LOCKED, see `concept/characters/fang/FANG.md`) | 🔨 (v5_2 design candidate; rig-ready pose pending) | ⬜ | ⬜ |
| **ZERO**   | balanced (control / chill) | ✅ | ⬜ (bible next) | ⬜ | ⬜ | ⬜ |
| _(unnamed)_ | tank      | ✅ | ⬜ (no fiction yet - future character) | ⬜ | ⬜ | ⬜ |

_Archetype mapping CORRECTED by the concept chat 2026-06-30: **FANG = rusher** (orange tiger,
lunge = pounce - matches greybox + the whole FANG bible), **ZERO = balanced** (the chill/AoE
controller, blue). The **tank** archetype has mechanics but NO fiction yet - it's an open
future-character slot, NOT FANG._

## Stage definitions

- **Mechanics** - archetype implemented + feel-tested in-game (data row in `ARCHETYPES` + skill).
- **Identity/concept** - fiction / name / role defined in `CONCEPT.md`.
- **Assets (ref+pose)** - style-consistent reference sheet + a rig-ready neutral pose generated.
- **Rigged (Godot)** - cut into parts + Skeleton2D rig + a test animation.
- **In-game art** - rigged character wired into the game, replacing the greybox square.

## Who owns which columns

- **Concept/asset chat** owns **Identity** + **Assets** (it produces them).
- **Mechanics chat** (engine/Godot) owns **Mechanics** + **Rigged** + **In-game art**.
- Either chat: read this first ("is FANG ready to rig yet?") before starting work on a character.

## Last update

- 2026-06-30 - index created (mechanics chat). FANG = characterizing + front/side assets done;
  rusher & balanced = mechanically done, no identity/assets yet.
- 2026-06-30 (concept chat) - archetype map corrected: FANG=rusher, ZERO=balanced, tank=open
  future slot (was wrongly "FANG=tank?"). FANG bible LOCKED (6-layer deep-dive,
  `concept/characters/fang/FANG.md`). FANG art iterated v1->v5 via gpt-image-1 (human face +
  tiger features + beast paws + banner-wraps, orange). v5_2 = design candidate; true digitigrade
  legs hit a generator wall + don't read at gameplay scale, so deferred to hero-art. Next:
  lock v5_2 -> rig-ready neutral pose -> hand to mechanics chat for Godot rigging.
