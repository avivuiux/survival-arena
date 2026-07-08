# Survival Arena - Roadmap to a High-Level Game

> Created 2026-07-04 (mechanics chat), at Aviv's request: "what else do we need to bring
> this to a high level of game - explore all the methods and what's missing."
> This is the strategic gap-map. `HANDOFF.md` stays the live source of truth for state;
> this file is the longer-horizon picture. Cut from the repo, not memory.

## The framing

The **core is already good**: fun 3D combat, tuned momentum movement, 6-action combat with
juice (stretch/squash/wind-up/hit-stop/shake/sparks/flash), 3 chibi archetypes, best-of-3,
and a server-authoritative net stack proven at latency (localhost/LAN). What separates a
"fun prototype" from a "high-level game" from here is **almost entirely presentation +
content + real online** - NOT more core combat mechanics.

## The gap-map (by system: HAVE vs MISSING)

### 1. Arenas / maps  ("beautiful battle maps" - Aviv)
- HAVE: one arena, greybox floor + gradient sky + low walls + surrounding ground.
- MISSING: a **map SYSTEM** (pick/load multiple arenas), 3-5 designed maps with identity
  (temple / ice / ruins...), per-map lighting + mood, in-arena elements. Mechanics builds the
  system; concept delivers the skin.

### 2. Character animation
- HAVE: procedural whole-model juice (stretch/squash/wind-up).
- MISSING: **real skeletal animation** (idle/walk/attack) - the single biggest jump in
  "alive" feel. Deliberately deferred to last in scope, BUT it is gap #1 for visual quality.
  (In progress 2026-07-04: Aviv + concept building FANG anims in Blender.)

### 3. VFX
- HAVE: flash / sparks / screen-shake / hit-stop.
- MISSING: real particles (dust, metal sparks, skill energy), screen effects (bloom, colour
  grade, vignette), attack trails, impact frames.

### 4. Audio  (started)
- HAVE: full combat SFX (swing/hit/parry/KO/shot/cast/block, synthesized in-engine).
- MISSING: **music** (background + dynamic tension), ambient, UI sounds, announcer ("KO!",
  "Round 2").

### 5. UX shell  (the menus that make it a product)
- HAVE: functional select -> fight -> best-of-3 -> re-pick.
- MISSING: real **main menu**, designed character-select, post-match screen (win / stats),
  settings (audio/video/controls), pause, tutorial. This is what reads as "a game" on open.

### 6. Real online  (the north-star)
- HAVE: server-authoritative net proven at latency (localhost/LAN), LAN connect + RTT/loss HUD.
- MISSING: **real internet connect** (rooms / invite code / matchmaking / relay), the
  two-machine test (Mac-gated), lobby, reconnect, spectators.

### 7. Content / modes
- HAVE: 3 characters, 1v1 vs bot / online.
- MISSING: more characters, modes (2v2, free-for-all, survival), combat depth (combos /
  a resource meter / statuses beyond chill).

### 8. Production / technical
- MISSING: controller support, fullscreen / resolutions, settings persistence, player profile
  / stats, packaging for distribution (itch.io / Steam), crash handling.

## Priority spine - the 4 things that actually move us to high-level, in order

1. **Map system + one beautiful map** - most visible, joins mechanics + concept, non-blocked.
   Mechanics builds load/select + a second greybox arena with a different identity; concept skins.
2. **UX shell** (menu / select / post-match / settings) - turns "demo" into "product",
   non-blocked, all mechanics.
3. **Minimal skeletal animation** - the big "alive" jump; art-dependent, was deferred to last,
   now being started by Aviv + concept (Blender). Mechanics prepares the playback path (see ROSTER
   animation-integration contract).
4. **Real online** - the north-star, but the two-machine test gates the next step (Mac).

## Notes
- Mechanics owns systems (map loader, UX flow, anim playback, net); concept owns skins
  (map art, character models/anims). Coordinate via `ROSTER.md`.
- Everything stays greybox-then-art: build the SYSTEM in neutral greybox, concept skins later.
