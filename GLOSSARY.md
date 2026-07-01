# Survival Arena - Glossary & Two-Chat Rules

Shared truth for BOTH work tracks - the **mechanics chat** (engine / Godot) and the
**concept/asset chat** (identity / art). Read it so terms and boundaries don't drift.
This is a coordination doc, not a design doc.

## Rules of engagement (two chats, one repo)

**The repo is the shared reality - NOT either chat's memory.** Read the repo before acting;
the other chat can't hear you, so the files are the only channel.

1. **Ownership - each chat edits & commits ONLY its own files:**
   - **Mechanics chat:** `scripts/`, `entities/`, `project.godot`, `tools/`,
     `HANDOFF.md`, `DESIGN.md`, `SKELETON.md`, `VISION.md`, `GLOSSARY.md`, `SYSTEM.md`.
   - **Concept chat:** `concept/`, `CONCEPT.md`, and all asset PNGs.
   - `ROSTER.md` is **shared but section-owned** (see the contract below) - edit only your columns.
2. **Commit small & often; never stage the other track's files.** Run `git status` first
   and add files by name, not `git add .`.
3. **Handoffs are written, not live:** flip the `ROSTER.md` status + leave a one-line note.
4. **If a term or decision changes, update it HERE first,** then everywhere else.

## Locked vocabulary

- **Archetype** - a mechanics data-row (hp / speed / damage / skill). Three exist:
  `rusher`, `balanced`, `tank`.
- **Character** - a fiction / identity (name, story, art) MAPPED onto an archetype.
- **FANG** = the **rusher** archetype (orange tiger, lunge = pounce). **NOT** the tank.
- **ZERO** = the **balanced** archetype (control / chill, blue).
- **tank** = an archetype with **no character yet** (open future slot). NOT FANG.
- **Booster / Run** - hold `A`; the thrust along your facing. Envelope-driven (see `tools/tuner/`).
- **Walk** - light arrow-move. **Removed for now**; will return without trampling the run.
- **Steer** - arrows rotate your facing (heading) with turn momentum. No mouse.
- **Rig-ready / "ready to rig"** - a transparent A-pose PNG meeting `concept/RIGPOSE-STANDARD.md`.
- **Rigged** - cut into parts + Skeleton2D + a test animation in Godot.
- **In-game art** - a rigged character wired in, replacing the greybox square.

## The contract between the chats = `ROSTER.md`

`ROSTER.md` is the per-character **status bridge + acceptance criteria**. Column ownership:

- **Concept chat owns:** Identity/concept, Assets (ref+pose).
- **Mechanics chat owns:** Mechanics, Rigged (Godot), In-game art.

A cell only flips to ✅ once the criterion in ROSTER's "Stage definitions" is actually met.
