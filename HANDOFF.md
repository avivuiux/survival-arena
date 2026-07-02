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
| Networking | **Deferred (but it IS the real mode)** | **Single-client multiplayer - you play ALONE vs others online** (like SP). Bots stand in for now. Online is the hard wall; solve it once the single-player game is solid |
| Source-of-truth on SP | **Research, not memory** | Claude fabricated SP "facts" twice early on. Now every SP claim is grounded (namu.wiki, mmos/mmohuts) + confidence-tagged in `SKELETON.md` |
| ai-os / Design OS / deep-spec | **Deferred to phase 2** | Process/scope discipline is valuable for a sustained build, but pure overhead during find-the-fun. Adopt when building structure AROUND a proven core |

## Current state - SP-faithful skeleton COMPLETE (2026-07-01)

Two parallel tracks share this repo:
- **Mechanics chat** (this one) - engine / Godot / gameplay.
- **Concept/asset chat** (separate) - identity / art. See `CONCEPT.md` + `ROSTER.md`.

**Two-chat coordination (read `GLOSSARY.md`):** one repo = the shared truth, NOT chat
memory. Each chat commits **only its own files** - mechanics owns `scripts/ entities/
tools/` + its `.md`s; concept owns `concept/` + assets. `ROSTER.md` is the shared
status-contract, section-owned. Run `git status` and add files by name (never `git add .`)
so you never commit the other track's work-in-progress.

**Read `ROSTER.md` first** for per-character status across both chats, and **`SKELETON.md`**
for the research-grounded SP control/combat model (confidence-tagged).

### Big framing corrections made this session (these were wrong before)
- **Single-client multiplayer - you play ALONE** (one human per client), like SP. NOT
  couch / same-keyboard 2P. Opponent = a **bot, standing in for remote players**.
- **SP controls VERIFIED via namu.wiki**: arrows STEER the heading (turn is not instant -
  선회 momentum), `A` = Booster = RUN (arrows alone = light walk), heavy inertia / "flying"
  glide, **NO mouse**. (An earlier mouse-aim idea was dropped; "rotate" guess dropped.)

### The SP skeleton - all six actions, movement feel-validated ("מרגיש מעולה")
- ✅ **Movement (overhauled session 3, 2026-07-01, feel-tuned by Aviv "מעולה")**: unified
  model - velocity is ALWAYS `facing * magnitude`, so steering bends momentum in every state.
  `A`=Booster **run is ENVELOPE-DRIVEN** (ease-in attack + overshoot), tuned in
  `tools/tuner/movement-tuner.html`. **Continuity**: run seeds from your current speed (no
  snap-to-0); glide follows facing. **Walk = SETTLE (fixed session 4, 2026-07-02, "מעולה")**:
  hold a dir with no A = speed glides gently DOWN to the `WALK_SPEED` floor (same DRAG as free
  glide) or builds UP to it - never brakes below, never sustains run-speed forever (the old
  pure-SUSTAIN kept full run speed while walking; invisible until the momentum trail exposed it).
  Knobs in fighter.gd: `TURN_RATE`, `BOOST_ATTACK_TIME/SHARP`, `BOOST_OVERSHOOT`, `DRAG`,
  `WALK_SPEED`; `speed` per archetype.
- ✅ **Momentum read, slice 1 (session 4, 2026-07-02, Aviv "מעולה")**: procedural visual of the
  tuned movement on the greybox - **body stretch along the velocity axis** (up to 16% at top
  speed; greybox path only for now) + **fading afterimage trail** above walk speed. Knobs:
  `STRETCH_MAX`, `TRAIL_INTERVAL/LIFE/MIN_SPEED`. Per DESIGN.md §function-first: momentum was
  the biggest unmet visual read. Bonus: the trail exposed the walk-sustain bug on first play.
- ✅ **Melee** (S) · **Ranged** aimed projectile (D) · **Magic/skill** (R: chill/lunge/shockwave)
  · **Defense** block + parry window (Space). Juice: hit-stop, flash, shake, sparks.
- ✅ **Dash REMOVED** (SP had none; the Rusher lunge still reuses the burst internally).
- ✅ **3 archetypes** (data-driven `ARCHETYPES`): Rusher(=FANG) · Balanced(=ZERO) · Tank(open).
  Character SELECT, best-of-3 matches, bot opponent, **practice mode (`P` freezes the bot)**.
- ✅ **FANG art in-game**: the Rusher renders `concept/characters/fang/FANG_rigpose_FINAL.png`
  (static sprite; flips by facing; flash on hit). Proves the asset pipeline end-to-end.

### Roster (live status in ROSTER.md)
- **FANG** = Rusher (orange tiger, lunge). Identity ✅ · art ✅ · **rig-ready cutout done → READY TO RIG**.
- **ZERO** = Balanced (control/chill, blue). Concept chat building next.
- **Tank** = open future-character slot (mechanics only, no fiction yet).

Docs: `SKELETON.md` (SP model) · `DESIGN.md` (combat-feel + greybox-polish principle) ·
`VISION.md` (8-layer map) · `CONCEPT.md` + `ROSTER.md` (concept/asset track).

Code: `scripts/game.gd` (orchestration, archetypes, projectiles, juice, rounds, select) ·
`entities/fighter/fighter.gd` (one combatant via an **intent layer** - human keys OR
`_bot_think()` - so bot and player share identical rules). Runs headless (uses `preload`).

## How to play (single player vs bot)

**Arrows** steer (+ walk-sustain when no A) · **A** run (Booster, envelope) · **S** melee ·
**D** ranged · **R** skill · **Space** block/parry · **Tab** re-pick · **P** practice (freeze bot) ·
**F3** debug overlay (velocity-vs-facing vectors + live readout) · **F4** slow-mo (25%).
Pick your fighter on the select screen (A/D or arrows; Space to start). First to 2 round wins.

**Dev tools:** `tools/tuner/movement-tuner.html` (open in a browser) - shape the run envelope
live (attack/sharpness/overshoot/release + walk floor), auto-saves, paste-import a config, exports
Godot-ready JSON. Aviv's current run: speed 325, attack 1.08, sharpness 0.7, overshoot 7%, release 2s.

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

## Next steps

0. **(Session 3 done)** Movement feel overhauled + tuned by Aviv (envelope run, continuity,
   walk-sustain, whole-screen arena, F3/F4 debug, tuner tool). **Movement now feels right.**
   The remaining feel-tune is the RUN CURVE via the tuner if Aviv wants to keep dialing.
1. ~~**Retest the combat GESTALT on the new movement**~~ **✅ DONE (session 4, 2026-07-01,
   Aviv "מעולה")**: melee/ranged/parry/skills were built BEFORE the movement overhaul +
   whole-screen arena. Retested by Aviv on the new envelope-run + walk-sustain + full-screen
   arena. **The predicted friction (drive-by melee / overshoot past the foe) did NOT bite** -
   the combat sits clean on the new movement, no tuning needed. Gestalt LOCKED.
2. **FANG rigging (collaborative, hands-on - the "in-game art" milestone)**: cut
   `FANG_rigpose_FINAL.png` into parts + Skeleton2D + a test animation. Needs a LIVE editor
   session with Aviv (can't be done headless).
3. **More characters**: ZERO + others, once concept produces their art (cheap via `ARCHETYPES`).
4. **Phase 2 - ONLINE (the wall, the REAL mode)**: single-client multiplayer. Start with
   Godot built-in multiplayer (ENet); design the authority model. Only once the
   single-player game is solid.

## External tooling evaluated (session 4, 2026-07-02) - "adopt nothing, lift 2 docs"

Evaluated 5 Claude-Code-game-dev GitHub repos (Aviv-supplied) for adoption, in parallel,
against a hard bar: *does it move the needle NOW without process overhead?* **Result: adopt
NO framework** - every one IS the process/ceremony this project deferred (confirms our
anti-scope instinct). Verdicts: game-development (HermeticOrmus) = **skip** (no Godot at all);
Game-Studios (Donchitos) / gstack (fagemx) = **lift-parts**; OpenGame (CUHK) / one-button
(abagames) = **reference-only** (Phaser/web, wrong engine).

**Lifted (the only real value) → `reference/`:**
- `reference/GODOT-4x-API-NOTES.md` - post-cutoff Godot 4.4→4.6 API delta (deprecated calls,
  new syntax, the `rg *.gd`→`gap` gotcha). Correctness aid for writing GDScript. From
  Game-Studios (MIT). Pinned at 4.6; we're 4.7 → verify load-bearing calls.
- `reference/COMBAT-FEEL-CHECKLIST.md` - 4-beat feedback model + dead-time table + juice list,
  mapped to our melee/ranged/parry. For the next feel-tuning pass. From gstack + one-button (MIT).
- `reference/SCOPE-CREEP-RUBRIC.md` - a quantified check that turns "scope is the killer" from
  slogan into a net-% verdict (PASS/CONCERNS/FAIL + cut/defer/keep/flag), baselined on HANDOFF +
  git-log (not GDDs). Rubric lifted from Game-Studios `scope-check` (MIT).

**Correction (Aviv pushback, same session):** first pass stopped à-la-carte mining too early -
treated "don't adopt the framework" as "nothing else usable." Re-looked at Game-Studios deeper:
the *skills* (vertical-slice, team-combat) ARE genuinely coupled to a GDD/sprint/gate pipeline we
don't have (verdict holds), but the **rubrics inside them** are portable - hence the scope rubric
above. Still un-mined but available if wanted: `vertical-slice`'s playtest-observation techniques
(silent-obs / think-aloud / Wizard-of-Oz) and the `godot-gdscript-specialist` style persona.
**Lesson: the unit to lift from a coupled framework is the rubric/knowledge, not the whole skill.**

**Full deep-read (Aviv "read everything, think again"):** mined ALL of Game-Studios - 73 skills
+ 49 agents + infra - in parallel. **Verdict CONFIRMED at full scale:** ~all 122 items are
coupled to the GDD/sprint/ADR/gate/multi-agent pipeline we reject. The deep read changed the
OUTPUT, not the verdict - it surfaced a curated set worth taking. Lifted 3 more (economically:
1 new doc + 2 folded sections):
- `reference/FIND-THE-FUN-DECISIONS.md` (NEW) - build/keep/kill gate: falsifiable hypothesis,
  riskiest-assumption-first, 3-PIVOTs->KILL, engine-not-browser-for-feel, + a **GRAVEYARD** of
  killed mechanics (ring-out / dash / mouse-aim now recorded). From `prototype`/`prototyper` (MIT).
- Folded into `COMBAT-FEEL-CHECKLIST.md` -> a **Bot-behavior** section (fun-not-optimal, telegraph
  intent, data-tunable knobs) - the fix-lens for our "bot too aggressive" note. From `ai-programmer`.
- Folded into `GODOT-4x-API-NOTES.md` -> a **style/perf idioms** section (no-signals-in-_process,
  @onready caching, set_process(false), pooling, StringName). From `godot-gdscript-specialist`.

**Top GameOS-future asset (logged, NOT built): the CCGS Skill Testing Framework** - a deletable,
zero-dependency skill-QA layer (catalog -> 5-case behavioral spec -> a **static 7-check linter** +
a **score-delta keep-or-revert loop** via git checkout). This is the ready-made answer to "how do
we author + validate GameOS skills well." Plus the file-is-memory state machine (pre-compact/
session-stop hooks + `<!-- STATUS -->` breadcrumb) and per-agent MEMORY.md pattern.

**Catalogued, real-but-premature (available on request, NOT lifted):** test-helpers/test-flakiness/
test-setup (GDUnit4 code+CI - premature, no tests yet), soak-test (fun-fatigue + orphan-node leak
protocol), perf-profile, playtest-report structure, quick-design tuning ladder, smoke-check,
settings.json safety deny-list + crash-recovery hooks, prototype-throwaway path rule. All decoupled
and genuinely usable, but lifting them into a greybox prototype now would itself be scope creep.

**reference/ now holds 4 docs:** GODOT-4x-API-NOTES, COMBAT-FEEL-CHECKLIST, SCOPE-CREEP-RUBRIC,
FIND-THE-FUN-DECISIONS. All MIT-attributed, no framework machinery imported.

**Logged for GameOS-future (NOT built - phase 2):** two patterns worth re-authoring for Godot
if/when GameOS is real - (1) a **self-evolving debug protocol** (lessons log that promotes
recurring fixes into proactive pre-build checks; OpenGame `debug-skill`), and (2) a
**simulation "fun-gate"** (prove skilled play beats mashing; one-button's GA-ratio idea). Both
map onto the SYSTEM.md + lessons-log ambition. Reference-only; no code taken.

## Working method that worked this session

Build a small slice -> verify headless (`--quit-after N`, exit 0) -> launch the window
(Claude opens it) -> Aviv plays & judges -> lock or tune. **Recommend ONE next step, don't
enumerate a menu; a recommendation is NOT permission - get a yes before direction changes
or new mechanics** (ring-out was built unapproved and reverted). Don't fabricate facts -
verify with sources. See memory `feedback_prioritize-not-enumerate`.

## Opening a dedicated workspace

This project is independent of any IDE window (absolute paths). For day-to-day work,
open a workspace rooted at `C:\Users\Aviv\dev\survival-arena` so files/git/search are
scoped to the game. A fresh AI session should read THIS file first to start warm.
