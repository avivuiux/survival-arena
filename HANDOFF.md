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
- ✅ **Slice 1 done & verified**: one orange player square moves (WASD / arrows),
  clamped inside an isometric diamond arena. Runs clean (headless exit 0).

Files:
- `project.godot` - minimal config (gl_compatibility renderer, window size)
- `main.tscn` - single Node2D root running `main.gd`
- `main.gd` - the whole slice (arena draw + player move + clamp). Everything is
  code-driven on purpose to keep .tscn trivial during greybox.

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

1. **Slice 2 - combat feel**: add an attack (button), a stationary dummy, and a
   visible hit (knockback + flash). This is the first slice that can actually be
   *fun*. Stop and ask: "is the hit satisfying?"
2. **Slice 3 - second player, local**: two players, same keyboard (or two windows),
   fighting. First real "is this fun with another human" test. Still no netcode.
3. **Slice 4 - health, win/lose**: HP, a round that ends. The minimal full loop.
4. **Phase 2 - online**: only now bring in networking middleware (Godot's built-in
   multiplayer first; evaluate heavier options if needed) + ai-os scope discipline.

## Opening a dedicated workspace

This project is independent of any IDE window (absolute paths). For day-to-day work,
open a workspace rooted at `C:\Users\Aviv\dev\survival-arena` so files/git/search are
scoped to the game. A fresh AI session should read THIS file first to start warm.
