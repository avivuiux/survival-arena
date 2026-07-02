# Godot 4.4→4.7 API Notes (post-training-cutoff)

> **Why this file exists.** An AI assistant's training data covers Godot up to ~4.3.
> Versions 4.4 / 4.5 / 4.6 (and our 4.7) changed things the model does NOT know. This is a
> curated cheat-sheet so we don't write deprecated or wrong GDScript. **Read it before
> suggesting any Godot API you're not 100% sure survived to 4.7.**
>
> **Caveat:** distilled from a reference pinned at **Godot 4.6 (Jan 2026)**. Our project runs
> **4.7**, so treat these as a strong starting point, not gospel - verify anything load-bearing
> against the official 4.7 docs. Source (MIT): Donchitos/Claude-Code-Game-Studios
> `docs/engine-reference/godot/`. Evaluated + lifted 2026-07-02.

## The gotcha that bites first (tooling)

- **ripgrep has no `gdscript` type.** `*.gd` is registered under `gap`. `rg --type gdscript`
  is a hard error and the search silently never runs. Always use `rg --glob "*.gd"` (shell)
  or `glob: "*.gd"` (Grep tool). *(This project is 2D, so most 3D changes below don't apply -
  but this one always does.)*

## Deprecated → use instead (will silently work-then-break or fail)

| Deprecated | Use instead | Since | Relevant to us? |
|---|---|---|---|
| `instance()` / `PackedScene.instance()` | `instantiate()` | 4.0 | yes (if we ever spawn scenes) |
| `yield()` | `await <signal>` | 4.0 | yes - we already use `await` for timers |
| `connect("sig", obj, "method")` | `signal.connect(callable)` | 4.0 | yes - use Callable form |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | 4.0 | yes - note `Date.now()`-style time |
| `TileMap` | `TileMapLayer` (one node per layer) | 4.3 | if we add tilemaps |
| `get_world()` | `get_world_3d()` | 4.0 | 3D only |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` | 4.0 | if we cull offscreen |
| `YSort` node | `Node2D.y_sort_enabled` property | 4.0 | if we do iso depth-sort |
| `Navigation2D` | `NavigationServer2D` | 4.0 | if we add pathfinding |
| `duplicate()` on nested resources | `duplicate_deep()` | 4.5 | if we copy nested Resources |

**Pattern-level (not just renames):**
- Prefer **typed** `Array[Type]` / typed vars - enables compiler optimizations.
- Cache node refs with `@onready var`, never `$NodePath` inside `_process()` (per-frame lookup).
- Typed signal connections over string-based (refactor-safe).

## New language features we could actually use (GDScript 4.5+)

- **Variadic args:** `func log_values(prefix: String, values: Variant...) -> void:` then iterate `values`.
- **`@abstract`** classes/methods - enforceable base classes. Could formalize a `BaseFighter`
  if the roster grows, but **not needed now** (our `ARCHETYPES` data-row approach is lighter).
- **Script backtracing** - detailed call stacks even in Release builds (free, no code change).

## Style & performance idioms (how to write GDScript, not just what's new)

From Game-Studios `godot-gdscript-specialist` (MIT) - orthogonal to the version delta above
(that's "what changed"; this is "how to write it well"). The ones that matter for a real-time game:

- **Never connect signals inside `_process()`** - it re-connects every frame and leaks massively.
  Connect once in `_ready()`.
- **Cache node refs with `@onready var`** - never `get_node()` / `$Path` inside a hot loop.
- **`set_process(false)` when a node is idle** - don't run `_process` on things that aren't doing
  anything (dead fighters, spent projectiles).
- **Pool projectiles / short-lived objects** - reuse instead of `new()`+`queue_free()` every shot,
  in a game that fires a lot. (We spawn projectiles as plain dicts in `game.gd` - already cheap;
  keep it that way if we move to nodes.)
- **`StringName` (`&"name"`) for frequently-compared strings** - e.g. animation/state names in a
  per-frame compare; cheaper than `String`.
- **Type everything** - `Array[Type]`, typed vars, typed signal params. Enables compiler speedups
  and catches bugs.
- **Signals up, calls down** - a child emits a signal to its parent; a parent calls a method on its
  child. Don't reach across the tree with long node paths.

## 2D-relevant engine changes (4.4-4.6)

- **`FileAccess.store_*` now return `bool`** (was `void`) - `store_line`, `store_string`,
  `store_var`, `store_buffer`, etc. If we ever save configs/replays, check the return.
- **Dedicated 2D navigation server** (4.5) - smaller export for 2D-only games; no API change for us.
- **`CPUParticles2D.restart()`** got an optional `keep_seed` param (4.4).
- **Shader param/return types** changed `Texture2D` → `Texture` base type (4.4) - only if we write shaders.

## Mostly-ignore for us (3D / desktop-GL, listed so we don't chase them)

Jolt physics default (3D only - our physics is 2D), D3D12 default on Windows (rendering
backend; no code impact), glow-before-tonemapping, IK restored, AgX tonemapper, SSR overhaul,
visionOS/SDL3/Android page-size. None touch a 2D greybox arena brawler.
