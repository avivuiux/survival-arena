# Survival Arena - Glossary & Two-Chat Rules

Shared truth for BOTH work tracks - the **mechanics chat** (engine / Godot) and the
**concept/asset chat** (identity / art). Read it so terms and boundaries don't drift.
This is a coordination doc, not a design doc.

## Rules of engagement (two chats, one repo)

**The repo is the shared reality - NOT either chat's memory.** Read the repo before acting;
the other chat can't hear you, so the files are the only channel.

1. **Ownership - each chat edits & commits ONLY its own files (REVISED 2026-07-07, Aviv - reflects
   the 3D game, the GDD, and the design-lane tools):**
   - **Mechanics chat:** `scripts/`, `entities/`, `project.godot`, `tools/tuner/`,
     `HANDOFF.md`, `DESIGN.md`, `SKELETON.md`, `VISION.md`, `ROADMAP.md`. IMPLEMENTS the game from
     the GDD. Owns all game code.
   - **Concept / design chat:** `concept/`, `CONCEPT.md`, all character assets (PNG + GLB),
     **`GDD.md`** (the full game design - mechanics READS it, design extends it),
     **`tools/character-studio/`, `tools/tripo/`, `tools/anim-forge/`** (design-lane tools),
     **`SYSTEM.md`** (the GameOS - it documents design/character modules).
   - **Shared (either may update, "update here first" rule): `GLOSSARY.md`, `ROSTER.md`**
     (section-owned per the contract below).
   - ⚠️ **If one chat must cross into the other's file** (e.g. concept wiring a new GLB into
     `scripts/game3d.gd` to test the roster), do it as a flagged STOPGAP + a ROSTER note, and the
     owning chat verifies/adopts. Prefer a written handoff over crossing.
2. **Commit small & often; never stage the other track's files.** Run `git status` first
   and add files by name, not `git add .`.
3. **Handoffs are written, not live:** flip the `ROSTER.md` status + leave a one-line note.
4. **If a term or decision changes, update it HERE first,** then everywhere else.

## Locked vocabulary (REFRESHED 2026-07-07 to the 3D + action-MOBA reality)

- **The game** = a **3v3 action-MOBA** (Battlerite x Survival Project). Full spec = `GDD.md`.
  (Superseded: the old 1v1 best-of-3 + 2D-cutout framing - both dead.)
- **Archetype** - a mechanics data-row (hp / speed / damage / skill) = a MOBA team role. Three:
  `rusher` (carry), `balanced`/control (support), `tank` (initiator).
- **Character** - a fiction / identity MAPPED onto an archetype.
- **FANG** = **rusher/carry** (tiger, lunge = pounce). **ZERO** = **control/support** (cosmic-ice
  prince, blue). **Light-knight** = **tank/initiator** (ascended knight of light, gold; REPLACED
  ATLAS, who is retired).
- **The 3D pipeline** - characters are **3D models (GLB)**, not 2D cutouts. Concept-first: free
  concept image -> restyle to our look (FANG/ZERO as style reference) -> **A-pose -> Tripo /
  Magnific tripo-v31 = rigged GLB** -> wired into `game3d`. Full method = `concept/SOUL-PROMPT.md`.
- **Rig-ready / A-pose** - a clean neutral A-pose IMAGE of the character (per the A-pose template
  in `RIGPOSE-STANDARD.md`), the input to the 3D model step.
- **Rigged** - an auto-rigged 3D GLB (Tripo/Magnific skeleton), light + game-ready.
- **In-game** - the rigged GLB wired into `game3d` (transform-juice today; skeletal clips later).
- **Booster / Walk / Steer / Momentum** - the SP-skeleton movement feel (hold `A` = run, arrows =
  steer with momentum, walk settles to a floor). Still the movement DNA; `tools/tuner/` tunes it.
  The one riskiest assumption (GDD Stage 6): keep this momentum FEEL without SP's control frustration.

## The contract between the chats = `ROSTER.md`

`ROSTER.md` is the per-character **status bridge + acceptance criteria**. Column ownership:

- **Concept chat owns:** Identity/concept, Assets (ref+pose).
- **Mechanics chat owns:** Mechanics, Rigged (Godot), In-game art.

A cell only flips to ✅ once the criterion in ROSTER's "Stage definitions" is actually met.
