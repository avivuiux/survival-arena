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

## Current state - Phase 1 (greybox)

- ✅ Godot 4.7 installed (portable) at `C:\Users\Aviv\dev\tools\godot\`
- ✅ Project scaffolded, git initialized
- ✅ **Slice 1 done & verified**: player square moves (WASD / arrows), clamped to arena.
- ✅ **Slice 2 built & verified (headless)**: melee attack (Space) + a dummy that takes
  knockback, flashes, and triggers hit-stop + screen-shake; HP bar + auto-refill on KO.
  ⏳ **NOT yet feel-tested by a human** - that is the open gate (see "the gate" below).

Design contract:
- `DESIGN.md` - one-page design (pillars, core loop, out-of-scope, the combat-feel
  hypothesis Slice 2 tests). Read it before changing combat.

Project structure (reorganized into proper folders at Slice 2):
- `project.godot` - config; main scene = `res://scenes/game.tscn`
- `scenes/game.tscn` - trivial root running `scripts/game.gd`
- `scripts/game.gd` - orchestration: spawns entities, owns arena bounds, provides
  juice services (`hit_stop`, `add_shake`). Uses `preload` (not class_name) so it
  runs headless too.
- `entities/player/player.gd` - movement, facing, melee attack + hitbox
- `entities/dummy/dummy.gd` - HP, knockback, flash, return-to-home, drives the juice

## THE GATE (do this before Slice 3)

Open the editor, press F5, and **play it**. Move with WASD, attack with Space.
Judge the DESIGN.md hypothesis honestly:
- Does landing a hit feel *weighty* and make you want to do it again? -> proceed to Slice 3.
- Does it feel limp / floaty / unclear? -> tune ONLY the feel (hit-stop duration,
  knockback strength, flash, shake) before adding anything. Do not add features to
  paper over a hit that doesn't feel good.

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

1. ~~**Slice 2 - combat feel**~~ ✅ built; awaiting the human feel-test gate above.
2. **Slice 3 - second player, local**: two players, same keyboard (or two windows),
   fighting. First real "is this fun with another human" test. Still no netcode.
3. **Slice 4 - health, win/lose**: HP, a round that ends. The minimal full loop.
4. **Phase 2 - online**: only now bring in networking middleware (Godot's built-in
   multiplayer first; evaluate heavier options if needed) + ai-os scope discipline.

## Opening a dedicated workspace

This project is independent of any IDE window (absolute paths). For day-to-day work,
open a workspace rooted at `C:\Users\Aviv\dev\survival-arena` so files/git/search are
scoped to the game. A fresh AI session should read THIS file first to start warm.
