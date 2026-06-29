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

## Current state - Phase 1 (greybox), LOCAL milestone reached

- ✅ Godot 4.7 installed (portable) at `C:\Users\Aviv\dev\tools\godot\`
- ✅ **Slice 1**: movement in an isometric arena.
- ✅ **Slice 2**: melee attack + satisfying hit (knockback + hit-stop + flash + shake).
  **Feel-test PASSED by Aviv** ("feels good") - the core combat-feel hypothesis is validated.
- ✅ **Slice 3+4**: local two-player duel. Two fighters share one keyboard, hit each
  other, KO -> winner banner -> auto-reset. Verified headless (exit 0).

**Aviv's call after the feel-test: "I already know this game is fun - progress beyond."**
So we are moving faster on local content. The ONE thing we deliberately do NOT rush is
networking (phase 2) - that is the real wall for this genre.

Design contract:
- `DESIGN.md` - one-page design (pillars, core loop, out-of-scope, combat-feel hypothesis).

Project structure:
- `project.godot` - config; main scene = `res://scenes/game.tscn`
- `scenes/game.tscn` - trivial root running `scripts/game.gd`
- `scripts/game.gd` - orchestration: spawns 2 fighters, owns arena bounds, juice
  services (`hit_stop`, `add_shake`), round flow (KO/banner/reset). Uses `preload`
  (not class_name) so it runs headless.
- `entities/fighter/fighter.gd` - one configurable combatant (key set, color, HP,
  knockback, attack). Two instances = the duel.

## How to play

P1: **WASD + Space**.  P2: **Arrows + Enter**.  First to KO the other wins; auto-resets.
(Note: cheap keyboards may "ghost" when many keys are pressed at once - a known local-2P
limitation, irrelevant once we go online.)

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

1. ~~**Slice 2 - combat feel**~~ ✅ feel-test PASSED.
2. ~~**Slice 3+4 - local duel + win/lose**~~ ✅ done.
3. **Next local options** (pick one, still cheap/safe to move fast on):
   - A second attack / a skill (e.g. a dash or a ranged poke) - adds combat depth.
   - A second character archetype with different stats - the "variety" pillar.
   - Better juice / readability pass (telegraphs, hit sparks, KO pop).
   - A simple best-of-3 score so a match has an arc.
4. **Phase 2 - ONLINE (the wall - do NOT rush)**: bring in networking. Start with
   Godot's built-in high-level multiplayer (ENet) for 1v1; only escalate to heavier
   options (rollback) if the feel demands it. THIS is where we slow down, design the
   authority model, and where ai-os scope discipline starts paying off.

## Opening a dedicated workspace

This project is independent of any IDE window (absolute paths). For day-to-day work,
open a workspace rooted at `C:\Users\Aviv\dev\survival-arena` so files/git/search are
scoped to the game. A fresh AI session should read THIS file first to start warm.
