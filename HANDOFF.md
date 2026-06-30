# Survival Arena - Handoff

A prototype inspired by the old isometric arena brawler **Survival Project** (2001):
session-based PvP combat in small arenas - NOT a persistent MMORPG.

> Read this first when opening a fresh workspace. It is the source of truth for
> decisions and current state. Update it at the end of each session.

---

## Why this shape (the core bet)

Survival Project's genre dodges the thing that kills MMOs - **scope**. There is no
persistent world, no economy, no 24/7 live-ops, no thousands of content pieces.
What remains is **one focused engineering wall**: fun, responsive real-time combat.
So the whole strategy is: prove the combat is fun first, expand later.

**Guiding principle: scope is the killer, not code. Build the one fun moment, then grow.**

## Locked decisions

| Decision | Choice | Why |
|---|---|---|
| Engine | **Godot 4.7** (GDScript, not C#) | Free, light (portable), great 2D/isometric, AI-friendly, no build step |
| Methodology | **Vertical slice + find-the-fun** | Build one complete fun moment end-to-end before widening anything |
| Art | **Greybox** (colored shapes) | Zero art investment until the mechanic is proven fun |
| Networking | **Deferred to phase 2** | Prove combat is fun LOCALLY first (two players, one machine). Real online netcode is the hard wall - solve it only once the core is proven |
| ai-os / Design OS / deep-spec | **Deferred to phase 2** | Process/scope discipline is valuable for a sustained build, but pure overhead during find-the-fun. Adopt when building structure AROUND a proven core |

## Current state - Phase 1 (greybox). Layer 0 done, Layer 1 mostly done.

A genuinely playable greybox arena fighter. Every step was feel-tested live by Aviv.

- ✅ Godot 4.7 installed (portable) at `C:\Users\Aviv\dev\tools\godot\`
- ✅ **L0 combat core**: isometric arena, melee attack, satisfying hit
  (knockback + hit-stop + flash + screen-shake), HP, KO, winner banner, round reset.
  Combat-feel hypothesis **PASSED** ("feels good").
- ✅ **Local two-player duel** (shared keyboard).
- ✅ **L1 dash** with i-frames (dodge -> punish). PASSED.
- ✅ **L1 momentum movement**: gradual acceleration + glide-to-stop - the weighty
  "hover" feel Aviv specifically remembered from Survival Project. PASSED ("מעולה").
  Two tunable knobs in fighter.gd: `ACCEL` (ramp) and `DRAG` (glide).
- ✅ **L1 first skill - "chill"**: AoE slow that catches a group (expanding ice ring;
  caught enemies slowed + can't dash). PASSED. Built the skill+status foundation.
- ✅ **Bot opponent**: reactive AI on P2 (chase, attack, dodge with cooldown, retreat
  spacing, chill). Tuned to be beatable. Toggle P2 bot/human with **B**.
- ✅ **L2 start - data-driven archetypes + 2nd character "Rusher"** (fast/fragile/
  hard-hitting, `lunge` skill). Feel-test passed. P1 = Rusher (you play it), P2 bot = Balanced.

**Concept track** (creative identity: world/tone/character-fiction/art/name) is being
developed in a SEPARATE chat - see `CONCEPT.md`. Keep mechanics (this track) and concept
separate so neither floods the other.

**`ROSTER.md` = the shared status index across BOTH chats.** Read it first to know any
character's state (ready / in progress / not started) per pipeline stage. Update the cell
when a stage changes. This is how each chat stays aware of the other without re-asking.

**Aviv's stance: "I already know this game is fun - progress beyond."** Moving fast on
local content. The ONE thing we deliberately do NOT rush is networking (Phase 2 / L6) -
the real wall for this genre.

Docs: `DESIGN.md` (combat-feel contract) · `VISION.md` (full 8-layer system map + build
order; "chill" and other skill ideas logged there).

Project structure:
- `project.godot` - config; main scene = `res://scenes/game.tscn`
- `scenes/game.tscn` + `scripts/game.gd` - orchestration: spawns 2 fighters, arena
  bounds, juice (`hit_stop`/`add_shake`), round flow, AoE `apply_chill`, bot toggle.
  Uses `preload` (not class_name) so it runs headless.
- `entities/fighter/fighter.gd` - one configurable combatant driven by an **intent
  layer** (human keys OR `_bot_think()`), so bot and human share the exact same rules.

## How to play

P1: **WASD** move · **Space** attack · **Shift** dash · **E** chill.
P2: **Arrows** move · **Enter** attack · **/** dash · **.** chill.
**B** toggles P2 between BOT and HUMAN. First to KO wins; auto-resets.
(Cheap keyboards may "ghost" on many simultaneous keys in 2-human mode - irrelevant online.)

## How to run it

**Editor (to see/play it):** open the Godot editor and import this folder:
```
C:\Users\Aviv\dev\tools\godot\Godot_v4.7-stable_win64.exe --path "C:\Users\Aviv\dev\survival-arena" --editor
```
Then press F5 (Play). Move with WASD or arrow keys.

**Quick headless sanity check (catches script errors, no window):**
```
C:\Users\Aviv\dev\tools\godot\Godot_v4.7-stable_win64_console.exe --headless --path "C:\Users\Aviv\dev\survival-arena" --quit-after 5
```

## Next steps (in order - one slice at a time)

1. ~~L0 combat + L1 dash/momentum/chill + bot~~ ✅ all done & feel-tested.
2. **Next local options** (pick one - all cheap/safe to move fast on):
   - **A second character archetype** with different stats + skill - starts the
     "variety" pillar; the systems now exist so it's cheap. (Strong candidate.)
   - **More skills / status effects** (ranged poke, knockup, stun) on the chill foundation.
   - **Best-of-3 score** so a match has an arc; or a juice/readability polish pass.
   - **Bot tuning** if it ever feels off (knobs: dodge chance/cooldown, retreat, ranges).
3. **Phase 2 - ONLINE (the wall - do NOT rush)**: bring in networking. Start with
   Godot's built-in high-level multiplayer (ENet) for 1v1; only escalate to heavier
   options (rollback) if the feel demands it. THIS is where we slow down, design the
   authority model, and where ai-os scope discipline starts paying off.

## Opening a dedicated workspace

This project is independent of any IDE window (absolute paths). For day-to-day work,
open a workspace rooted at `C:\Users\Aviv\dev\survival-arena` so files/git/search are
scoped to the game. A fresh AI session should read THIS file first to start warm.
