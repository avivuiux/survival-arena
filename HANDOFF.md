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
- ✅ **Action pose, slice 2 (session 4, 2026-07-02, Aviv "מעולה")**: squash & stretch on combat
  beats, visual only, ZERO timing changes - attack = lean-into-the-swing (eases out), taking a
  hit = flatten along the knock direction (~0.14s), perfect parry = uniform "caught it" pop.
  Pose wins over momentum stretch while active. Knobs: `POSE_ATTACK_STRETCH`, `POSE_HIT_SQUASH/
  TIME`, `POSE_PARRY_POP/TIME`. Greybox path only (FANG art untouched).
- ✅ **Attack wind-up (session 4, 2026-07-02, Aviv-approved as a test slice -> "מעולה", LOCKED)**:
  melee now has a ~0.08s committed pre-swing - body cocks BACK (readable anticipation), then the
  hit goes live. No moving/boosting during the wind-up; cooldown counts from the press. The bot
  reads your wind-up and reacts (like a human would) - this is the SP spacing+parry mind-game
  beat. Knob: `WINDUP_TIME` (0.0 = instant attack, full revert). Closes the "weak anticipation"
  flag from COMBAT-FEEL-CHECKLIST.
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

## Current state - THE UNIFIED 3D GAME (2026-07-03, session 7)

**All three engineering walls are proven AND now unified into one game.** This session
closed the last risky assumptions of the 3D pivot and the net stack, then merged everything:

- ✅ **3D combat is FUN** (Aviv "כיף - ננעל"): `scenes/arena3d_fight.tscn` - real melee /
  wind-up / parry / knockback / KO / best-of-3 on the 3D FANG model, iso view. Action reads
  (wind-up=lean-back, attack=lean-in, hit=squash+flash, parry=pop+cyan, KO=tip-over) are
  whole-Node3D transforms ONLY - no bones, no baked animation (the scope guard held). The
  A-pose did NOT block the reads. Structure = the REAL fighter.gd sim in a hidden 2D layer +
  a game-shim + a render-only 3D layer (this IS the integration pattern, not a fork).
- ✅ **Net slice 4 = LATENCY, LOCKED** (Aviv "עובד נדיר" at ALL levels incl. guest @ 200ms
  round-trip, ZERO mitigation): artificial one-way-delay injector in `net_fight.gd`, L cycles
  0/30/60/100ms. **Server-authoritative CONFIRMED at the feel level -> rollback door closes,
  no prediction/interpolation needed at prototype level (a whole layer fell off the plan).**
  Honest caveat: localhost = constant delay only; the LAST net gate is a real two-machine
  test (PC vs Mac) for jitter/loss. See NET.md.
- ✅ **UNIFIED GAME BUILT** (`scripts/game3d.gd` + `scenes/game3d.tscn`, 3 Aviv-checked steps):
  select screen (3 archetypes) -> 3D arena -> **vs bot (Space) OR online (H host / J join,
  each picks own fighter)** -> best-of-3 -> Tab re-pick. Rusher = FANG GLB; balanced/tank =
  colored 3D capsules until their models are locked. Skills (chill ring / shockwave / lunge)
  render + sync. **`project.godot` main scene = game3d.tscn -> F5 opens THE game.** The 2D
  game + throwaway slices stay as fallback/reference.

**Where the parts live:** `game3d` = the product. `game.tscn` (2D) = fallback + feel
reference. `arena3d_test` = movement-in-3D reference. `arena3d_fight` = the 3D-combat
fun-proof. `net_fight` = the net slices 1-4 reference. All kept in git.

## Current state - SESSION 8 (2026-07-04): chibi-plus look wired + net two-machine prep

The concept lane's REWORK converged (see ROSTER): the game look is now **"chibi-plus 3D-toon"**
(locked by Aviv, anchors `concept/rework/fang_styledial_A_attack.jpg` + `zero_chibiplus_cold_2.jpg`).
Both chibi models were generated AND are wired into `game3d`:

- ✅ **FANG-chibi in the game (Aviv-approved live).** Concept committed the handoff (`199c574`):
  Aviv judged `FANG_chibi_3d_v1.glb` live ("נראה מעולה"). `game3d`'s rusher `glb` now points at
  it (was the off-style 6-head `FANG_hero_3d_v1.glb`). Approved live in `game3d` this session.
- 🔨 **ZERO-chibi dropped into the balanced slot (pending Aviv's live facing check).**
  `ZERO_chibi_3d_v1.glb` (on-style, asymmetry intact, but UNRIGGED + ~57MB) now fills balanced.
  game3d renders via whole-model transforms (no bones), so unrigged is fine to SHIP - the rig is
  only needed for the deferred animation. `yaw_off` is now **per-archetype** (both = PI*1.5, a
  Tripo-orientation guess for ZERO) so ZERO can be re-aimed without touching FANG. Loads clean
  headless; a small load-hitch is possible from the 57MB. **Aviv still to judge ZERO's facing/scale live.**
- **⚠️ SCOPE DECISION (Aviv + concept, in `199c574`): skeletal ANIMATION is the LAST polish, not
  next.** Agreed order: (1) FANG-chibi in game [done] → (2) ZERO + a 3rd character = roster complete
  → (3) ONLY THEN minimal animation (breathing/walk/attack), never a full anim pipeline. So the old
  "A-pose → combat stance" candidate is formally re-ordered to LAST.
- ✅ **Net two-machine prep (built + headless-verified, NOT yet live two-machine).** `game3d`'s
  online path was localhost-only; the LAST net gate (NET.md) is a real PC↔Mac test. Built for it:
  (a) **LAN connect** - host prints its LAN IP; the guest gets an on-screen IP field (click to type,
  default localhost so the single-machine test is unbroken) + cmdline `++ join <ip>`; (b) **measured
  link quality** - the HUD shows real ENet-measured **RTT + packet-loss %** when online, so Aviv's
  two-machine verdict is data-backed, not a vibe. Both verified via two-process localhost connect
  (match starts, stats read clean); **Aviv has a Mac but not available now** - he runs the real test later.

## Current state - SESSION 10 (2026-07-07): ⚠️ VISION PIVOT to 3v3 ACTION-MOBA + Stage-2/4 IMPLEMENTED

**The game was re-specced from 1v1-best-of-3 to a 3v3 action-MOBA (Battlerite-style) - Aviv's
decision, locked in `GDD.md` + `DESIGN.md §VISION LOCKED` by the DESIGN lane.** The two-chat split
is now formalised (`GDD.md §WORK SPLIT`): **DESIGN lane** owns the GDD stages + characters/art;
**MECHANICS lane (this one)** implements the locked structure in `scripts/`. Contract = GDD.md.

**Also this session (before the pivot): a big batch of `game3d` polish (all Aviv-approved live):**
per-archetype size/hover (tank looms, ZERO floats), **smooth-locked rotation** (F6 removed, `const`),
**synthesized combat SFX** (swing/hit/parry/KO/shot/cast/block in `audio/`, edge-detected), the
**KO-only-loser fix**, the **arena as a place** (gradient sky + low walls + surrounding ground +
shadows), **bigger characters + a dynamic follow-camera**, an **F8 live look-tuner** (camera/
lighting/atmosphere/post sliders + PRINT VALUES), and the **skeletal-animation playback layer**
(plays idle/walk if the model has clips; FANG is now the r2_v4 collectible-toy model, no clips yet
-> procedural-juice fallback). All in `ROADMAP.md` (the full game gap-map, Aviv-requested).

**IMPLEMENTED THIS SESSION (GDD Stage 2 + first slice of Stage 4) - headless-verified, live-tested:**
- ✅ **3v3 match loop** (`game3d`): 6 fighters, **teams 0/1** (you = team-0 human + 2 bot allies vs
  3 bot enemies), team spawns, **no friendly fire** (melee/projectile/skills skip teammates), bots
  target nearest ENEMY. Single-client (bots fill the other 5), per the standing method.
- ✅ **Respawn 10s** (dead -> back at team spawn). **Score = kills** (credit to last-hitter's team)
  **+ orb bonus**. **Round = 3 min; higher score at the timer wins; best-of-3.** Tie = replay.
- ✅ **Center power-orb** (spawns every 20s, grab within 60u = +2 team points + a 6s team damage
  buff +35%). The anti-stall engine.
- ✅ **Camera** now frames the centroid of ALL active fighters (readable-chaos for 6). **HUD** =
  team scores + round timer + round-wins + [POWER] + team-tinted names.
- ✅ **Stage-4 ULTIMATE system (first kit slice):** a charge meter (fills over ~75s + on dealing
  damage), **Q** casts when full. **FANG = Frenzy** (5s berserk: attack-cd x0.5 + dmg x1.3),
  **ZERO = Chill Nova** (big AoE freeze), **tank = Quake** (big shockwave). Bots ult when charged.
  Player ult meter drawn bottom-centre. All numbers = GDD `[PROVE]` starting values.
- **Online is PAUSED** (H/J show "online returns for 3v3"): the old 1v1 net path is dormant since
  the pivot. Single-client only for now; online 3v3 is a later step.

**Files (mechanics-owned, committed this session):** `scripts/game3d.gd`, `entities/fighter/
fighter.gd`, `HANDOFF.md`, `ROADMAP.md`, `audio/`. **NOT touched (design-lane-owned, their WIP in
the shared tree):** `GDD.md`, `DESIGN.md`, `ROSTER.md`, `concept/`, `tools/character-studio/`.

## Next steps

**TOP OF THE STACK (session 11 candidates - post 3v3-pivot; run each through the principles, recommend ONE):**
- **Tune the 3v3 by play** (all GDD numbers are `[PROVE]`): respawn 10s (drops?), round 3 min (too
  long?), orb interval/buff, score balance, camera zoom for 6. This is the find-the-fun on the new loop.
- **Finish the Stage-4 kits** (GDD §Stage 4, LOCKED structure = 1 primary + 2 identity skills +
  ultimate + defensive). Ultimate is DONE for all 3; the **2nd identity skill** per character is next
  (e.g. FANG "Rake" claw-sweep). Build one, live-test, replicate.
- **Smarter bots for 3v3** (currently each bot 1v1-thinks vs nearest enemy - readable but no team
  play): focus-fire / peel / contest-the-orb behaviour.
- **Online returns for 3v3** (currently PAUSED): the net stack is server-authoritative + proven at
  latency, but it packs 2 fighters - needs a 6-fighter sync. Bigger; after the loop is fun.
- ~~old 1v1 candidates below are SUPERSEDED by the 3v3 pivot~~ (kept for history):

**TOP OF THE STACK (session 9 candidates - SUPERSEDED by the 3v3 pivot):**
- **Aviv live-judges ZERO-chibi's facing/scale in game3d** (pick BALANCED, vs bot). If it faces
  wrong, one-line fix `balanced.yaw_off`. This closes the roster's 2nd model. START HERE.
- **Real two-machine net test** (PC vs Mac): the LAST net gate - the pipe + LAN connect + RTT/loss
  readout are BUILT; this is now pure logistics (same Wi-Fi/subnet, allow Godot through the PC
  firewall). Localhost only proved constant delay; real internet adds jitter/loss.
- **3rd character (tank)**: concept-lane deliverable - no fiction/model yet, stays a capsule until
  concept designs it in chibi-plus. Completes the roster (step 2 of the agreed order).
- ~~**A-pose -> combat stance**~~ **RE-ORDERED TO LAST** (concept scope decision `199c574`):
  skeletal animation is the FINAL polish, only after the game is proven + roster is full, and even
  then minimal (breathing/walk/attack). Do NOT pick this next - it is the scope-death line.
- ~~**F6 directional-view decision**~~ **✅ LOCKED SMOOTH (Aviv 2026-07-04): "המשחק צריך להיות
  חלק ולעשות הרגשה של חלקות."** The 8/4 directional-stepping option is rejected outright - the
  F6 toggle is removed from game3d.gd and `_view_snap` is now a `const 0` (stepping is impossible).
  The model's yaw already follows the momentum-smoothed facing (TURN_RATE) exactly, so rotation
  is continuous. This was the last small open decision; nothing else non-Mac remains for the core.

0. **(Session 3 done)** Movement feel overhauled + tuned by Aviv (envelope run, continuity,
   walk-sustain, whole-screen arena, F3/F4 debug, tuner tool). **Movement now feels right.**
   The remaining feel-tune is the RUN CURVE via the tuner if Aviv wants to keep dialing.
1. ~~**Retest the combat GESTALT on the new movement**~~ **✅ DONE (session 4, 2026-07-01,
   Aviv "מעולה")**: melee/ranged/parry/skills were built BEFORE the movement overhaul +
   whole-screen arena. Retested by Aviv on the new envelope-run + walk-sustain + full-screen
   arena. **The predicted friction (drive-by melee / overshoot past the foe) did NOT bite** -
   the combat sits clean on the new movement, no tuning needed. Gestalt LOCKED.
2. ~~**FANG rigging**~~ **SUPERSEDED (2026-07-02, both chats converged).** The FANG/ZERO PNGs are
   IDENTITY REFERENCE, not in-game assets (see DESIGN.md §function-first). Aviv's **two-art-layers**
   decision (logged by the concept chat in ROSTER): (1) detailed PNG = portrait / select-screen /
   identity; (2) the in-game fighter = a SEPARATE, simpler, small-readable sprite the CONCEPT lane
   designs. So mechanics does NOT rig the portrait. When concept delivers an in-game FANG sprite,
   mechanics just drops it into the existing `art_path` slot. **The current in-arena render spec
   (flat straight-on 2D - NOT iso - L/R flip only, 116px tall) is written for the concept lane in
   ROSTER's latest note.** Until then, the greybox + procedural motion is the in-game look.
3. **More characters**: ZERO + others via `ARCHETYPES`, once concept delivers in-game sprites.
4. **Phase 2 - ONLINE (the wall, the REAL mode)**: single-client multiplayer. See `NET.md`
   for the model + slice ladder + the deferred authority-model decision.
   - ✅ **Slice 1 - pipe proven (2026-07-02, Aviv "עובד")**: two Godot windows connect over
     ENet localhost and see each other move in real time. Throwaway test (`scripts/net_test.gd`
     + `scenes/net_test.tscn`), NOT wired into the game. The transport wall is breached.
   - ✅ **Slice 2 - real fighters synced (2026-07-02, Aviv "מעולה")**: the REAL `fighter.gd`
     (untouched) runs in two windows - position + facing + momentum velocity + action state
     (wind-up/attack/block) synced every frame, so the whole motion read (stretch, trail,
     wind-up, parry color) appears on the remote fighter. `scripts/net_fight.gd` +
     `scenes/net_fight.tscn`, auto host/join via `++ host` / `++ join`. Damage deliberately
     OFF (hurtboxes disabled) - "who really hit" IS the slice-3 question.
   - ✅ **Slice 3 LOCKED (built 2026-07-02, judged LIVE by Aviv 2026-07-03 "מעולה"): SERVER-
     AUTHORITATIVE** - Aviv chose the model after a plain-language feel walkthrough (reasons in
     NET.md: scope, generous 0.18s parry window = latency tolerance, rollback door stays open).
     `net_fight.gd` evolved in place - the HOST window is the referee (simulates BOTH fighters,
     real damage/HP/KO/best-of-3), the guest sends inputs (`fighter.gd` got a minimal
     `remote_driven` intent hook) and renders the host's state; guest juice derived from HP
     drops. Aviv fought a real best-of-3 across two windows and locked it.
   - **Then: slice 4 = latency handling** (prediction/interpolation - the hardest; a 0ms local
     slice CANNOT validate it. Only after slice 3 is locked).
5. **IN-ARENA RENDER - ✅ DECIDED (2026-07-03, WITH Aviv): FULL 3D PIVOT.** The night's path
   (snap rejected -> 5-view sprite model -> mirroring flips ZERO's asymmetric identity, fatal ->
   image-to-3D validated -> both lanes land on 3D). **The in-game character is a real 3D model
   rotated live by the engine** - deletes snap/mirror/asymmetry at once, one asset correct from
   every angle. **REVERSES the "no 3D" bet, knowingly** (turns out simpler than 8-view switching).
   - ✅ **Principle PROVEN via throwaway slice (Aviv "נראה מעולה"):** `scenes/threed_test.tscn`
     + `scripts/threed_test.gd` - real FANG GLB rotates smoothly on a dark iso floor. Not wired in.
   - ✅ **LOCKED model = `concept/characters/fang/FANG_hero_3d_v1.glb`** (hero design w/ combat
     suit; Aviv picked it over tank-top v2 via the slice's Tab toggle).
   - **5-view sprite model is DEAD** (recorded in DESIGN.md §In-arena view as the why-3D-won trail).
   - **NEXT (the real work, not built):** (a) 3D-in-2D integration - render the rotating model
     into the 2D arena, yaw follows `facing`; (b) the A-pose->combat-stance gap (GLB is auto-rigged,
     so posing is possible - decide the MINIMUM with Aviv, do NOT slide into a full anim pipeline);
     (c) re-express the procedural juice (stretch/squash/wind-up) on the 3D model. See DESIGN.md.
   - **F6 in the main game** still toggles the old greybox view-wedge - now vestigial; harmless.

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
