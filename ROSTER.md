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
| **FANG**   | tank?      | ✅ | 🔨 (characterizing now) | 🔨 (front + side done) | ⬜ | ⬜ |
| _(rusher)_ | rusher     | ✅ | ⬜ | ⬜ | ⬜ | ⬜ |
| _(balanced)_ | balanced | ✅ | ⬜ | ⬜ | ⬜ | ⬜ |

_Archetype mapping (which identity = which mechanical archetype) is owned by the concept
chat - correct the table if FANG is not the tank._

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
