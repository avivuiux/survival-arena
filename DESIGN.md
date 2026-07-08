# Survival Arena - One-Page Design

A lightweight design contract for the prototype. Inspired by **Survival Project**
(2001): real-time, isometric arena skirmishes with friends - readable, punchy, social.

## ⚠️⚠️ VISION LOCKED (Aviv, 2026-07-07) - ACTION-MOBA, NOT A 1v1 FIGHTER

**The game is a fast, punchy, team-based arena brawler at the crossroads of Survival Project
(fast / punchy / lots happening) and DOTA 2 (tactical / team / hero roles). Closest existing
reference: BATTLERITE** (MOBA hero-combat depth, no farming, fast and team-based).
- **Two layers, not opposites:** MICRO = SP's twitch, punchy, readable moment-to-moment feel.
  MACRO = DOTA's team roles, positioning, skill-combos, coordination.
- **Take / drop:** TAKE from SP = punch, pace, accessibility, readable chaos. TAKE from DOTA =
  hero identity/kits, team roles, tactical positioning. DROP from DOTA = farming, itemization,
  40-min matches, lane creeps (the slow macro that fights the pace).
- **The roster IS the tactical layer:** the archetypes are MOBA team roles - FANG=rusher
  (carry/assassin), ZERO=control (support/mage), ATLAS=tank (initiator). A team comp already.
- **⚠️ Correction of a drift:** the built 1v1 best-of-3 prototype was a SCAFFOLD to prove the
  hit-feel first (per "the one fun moment" below), NOT the destination. The mechanics lane's
  target is the multi-player SP-like arena, not a 1v1 duel. Do not re-narrow to 1v1.
- Pillar #1 "readable chaos" is exactly the discipline this genre needs. All character/art/style
  work carries over 100% regardless of mode.

Thinking frame: **MDA** (Mechanics -> Dynamics -> Aesthetics). We design the
*feeling* (aesthetics) first, then the rules that produce it. This doc is a hypothesis,
not a build-spec - the combat feel is **proven by playing, not by writing**.

---

## The one fun moment

> You read your opponent, commit to an attack, land it, and the hit *lands hard* -
> they get knocked back, you feel the impact, and you immediately want to do it again.

Everything else (characters, modes, online) is scaffolding around this moment.
If this moment isn't fun against a single dummy, no feature list saves the game.

## Design pillars (every decision checks against these 3)

1. **Readable chaos** - even with several players and effects on screen, you always
   understand what's happening and what just hit you. Clarity beats spectacle.
2. **Satisfying impact** - the moment-to-moment *feel* of a hit IS the product:
   knockback, hit-stop, clear feedback. Weight over flash.
3. **Easy to grab, fun with friends** - low skill floor, pick up in 30 seconds, the
   joy is social. Depth is allowed, but never at the cost of the first 30 seconds.

## Core loop

**Moment-to-moment:** approach -> read opponent -> commit to attack/skill ->
land hit + knockback -> reposition -> repeat -> KO.

**Match:** spawn in arena -> fight -> someone wins the round -> rematch.

## MDA at a glance

- **Mechanics** (rules): move, one melee attack, knockback, HP, arena bounds.
  *Later:* skills, ring-out, characters.
- **Dynamics** (what emerges): spacing duels, cornering, reading commitment, punishing whiffs.
- **Aesthetics** (target feelings): *fast, readable, punchy, fun-with-friends.*

## Explicitly OUT of scope (the anti-scope contract)

- No persistent world, leveling, economy, or any MMO progression.
- No online netcode yet - **local first** (two players, one machine).
- No art - greybox (colored shapes) until the mechanic is proven.
- No character roster yet - one archetype first.
- No lobby / matchmaking / menus yet.

If a task isn't on the path to "is the hit satisfying?", it is out of scope right now.

## The hypothesis Slice 2 will test

> A single melee attack with visible **knockback + a brief hit-stop** on a stationary
> dummy will feel satisfying enough to be the seed of fun.

- **Success signal:** after hitting the dummy, you *want* to hit it again. It feels weighty.
- **Failure signal:** the hit feels limp, floaty, or unclear. -> tune feedback (hit-stop,
  knockback curve, screen-shake, flash) BEFORE adding anything else.

This is the gate. We do not build Slice 3 (second player) until the hit feels good.

## In-game character: function-first (Aviv, 2026-07-02)

**Decision:** the generated concept art (FANG/ZERO PNGs) is IDENTITY REFERENCE, not the in-game
asset. How a character looks/moves in the game is **derived from what the FIGHT needs to read at
speed** - not from a picture. We pick the technical form (sprite / frames / rig / procedural) only
after we know what must be communicated. This defers "the look" until the game earns real art.

**What an in-game character MUST communicate, ranked by gameplay need** (with what the greybox
already does, and the gap):

1. **Facing / heading** - THE core read (steering is the whole movement model). *Have:* the white
   facing line. *Gap:* thin, but functional.
2. **Action state** - attacking / blocking + parry-window / hit / KO / skill-casting /
   moving-vs-idle. This is what the spacing + parry mind-game runs on. *Have:* attack telegraph
   rect, block/parry arc, hit flash, chill tint, KO darken. *Gap:* **no attack anticipation/
   wind-up** (the attack is instant) - flagged in `reference/COMBAT-FEEL-CHECKLIST.md`.
3. **Momentum / speed** - the "flying / glide" SP feel we tuned to "מעולה". *Have:* **nothing
   visual** (only the F3 debug vector). *Gap:* **the biggest unmet read** - the movement we're
   proudest of has zero visual expression.
4. **Identity** - me vs opponent, which archetype. *Have:* body color + name label. *Gap:* fine.

**What function-first tells us to build FIRST:** momentum (#3) is the top unmet read, and #2 has one
weak spot (no wind-up). Both are **procedural motion on the greybox** - lean/tilt into velocity,
squash & stretch on action, a speed trail, a short attack wind-up pose. This is **code-only,
asset-independent, headless-testable, and reversible** - it obeys the greybox-polish principle
(timing/mechanism/readability = allowed; final art magnitude = still deferred). It expresses the
tuned movement without committing to any art style.

**Still deferred (not now):** the actual look (pixel / vector / hand-drawn) and the technical form
(sprite-sheet vs skeletal rig). Those get decided when the game earns real art, not before.

## In-arena view: REAL ISO (Aviv, 2026-07-03) - facing count decided by PLAY

**Decision (Aviv, mechanics session 5.5, after a plain-language cost walkthrough):** the in-arena
view = **real isometric** - characters have a separate drawing per facing direction (SP-faithful),
NOT one 3/4 pose mirrored L/R. Costs were presented and accepted: 4-8 art sets per character,
AI-consistency risk across angles, and body rotation becomes angle-SNAPPING (fights the smooth
continuous-steer read we locked). Aviv chose SP-fidelity.

**Open sub-decision: 4 vs 8 directions - NOT decided on paper.** Per find-the-fun: build a
presentation-only greybox slice where the facing SNAP is toggleable live (off / 4 / 8), Aviv
plays and locks the count by feel.

**Iso slice 1 SPEC (presentation-only, sim untouched):**
- The SIMULATION does not change: steering stays continuous, hitboxes/combat/net identical.
  Only what is DRAWN changes. Fully reversible (snap off = today's look).
- **Iso floor** (`game.gd _draw`): the dark floor gets an isometric diamond-grid so the eye
  reads a tilted ground plane. Same bounds, same clamp.
- **Facing snap, display-only** (`fighter.gd`): `facing_snap` = 0/4/8. Snaps the body pose
  rotation, facing line, and block arc to the nearest of N directions. The attack telegraph
  stays at the TRUE facing (the hitbox does not lie) - any visible mismatch between snapped
  body and true telegraph is DATA for the 4-vs-8 call, not a bug.
- **F6** cycles snap off -> 4 -> 8 in the main game (label shows the mode).
- **Deferred, revisit after the facing test:** y-foreshortening of the play space (vertical
  distances drawn shorter), depth draw-order, and whether the SIM facing itself should snap.
- **Pass =** Aviv plays vs the bot, flips F6 live, and locks 4 or 8 (or flags that real-iso
  snapping kills the movement read - that door stays open until he locks).

**LIVE VERDICT (2026-07-03, same evening): crude snap REJECTED -> pro view-model -> then
SUPERSEDED by a full 3D PIVOT.** The trail (kept because it explains WHY 3D won):
1. Aviv rejected the raw snap ("the direction must not snap").
2. We locked a pro 5-view sprite model (front/back/side/¾-front/¾-back, mirror 3 -> 8 headings).
3. The concept lane then caught a FATAL flaw in mirroring: **it flips asymmetric identity** -
   ZERO's half-ice face + single human arm would swap sides on mirrored headings. Mirroring
   only works for near-symmetric characters. And AI can't hold pose/detail across 8 hand-drawn
   angles anyway.
4. Meanwhile image-to-3D got VALIDATED (Tripo via Magnific -> a real rigged GLB; the old
   "Tripo flattens 2D" verdict is dead). Both lanes independently arrived at 3D.

**DECISION (Aviv, 2026-07-03): the in-game character is a real 3D MODEL, rotated live by the
engine.** This deletes the entire snap / mirror / asymmetry problem at once - a 3D model rotates
continuously to any heading, from one asset, correct from every angle. **This REVERSES the
locked "no 3D" bet** - accepted knowingly because it turns out to be SIMPLER than 8-view
sprite-switching, not more complex, and it is the only thing that satisfies "no snap."

- **PROVEN via a throwaway slice (2026-07-03, Aviv "נראה מעולה"):** `scenes/threed_test.tscn`
  + `scripts/threed_test.gd` - the real FANG GLB rotates smoothly on a dark iso floor, reads
  well at scale. NOT wired into the game; it proved the PRINCIPLE only.
- **LOCKED model = `concept/characters/fang/FANG_hero_3d_v1.glb`** (the leveled-up hero design:
  combat suit, harness, digitigrade tiger legs, mask). Aviv picked it over the tank-top v2.
- **The 5-view sprite model above is DEAD** (kept as the record of why). No sprite-switching,
  no mirroring, no per-direction art.

**Still OPEN (the real integration work, not yet built - next session):**
1. **3D-in-2D integration:** the arena renderer is 2D canvas (`fighter.gd _draw` + `game.gd`).
   Render the rotating model into it (SubViewport->texture billboard, or move the fighter layer
   to 3D). Model yaw follows `facing` continuously. First real slice.
2. **The A-pose / stance gap:** the GLB is a neutral A/T-pose. A fighter needs a combat stance
   (and ideally idle/attack motion). The GLB is auto-rigged (per concept lane) - so posing is
   POSSIBLE, but authoring animation is the scope line to watch. Decide the minimum (static
   combat-stance pose? a few baked clips?) WITH Aviv - do not slide into a full animation pipeline.
3. **Procedural juice in 3D:** momentum stretch / squash&stretch / wind-up are 2D-canvas
   transforms today. Re-express them on the 3D model (scale on the Node3D) or on the composited
   sprite - decide during integration.

### 3D COMBAT slice SPEC (2026-07-03, before build) - "is the 3D FIGHT fun?"

**✅ LOCKED (2026-07-03, same evening, Aviv played it live: "כיף - ננעל").** The 3D fight IS
fun with the rough auto-rigged GLB - the last risky assumption of the 3D pivot is closed.
The A-pose did not block the reads (wind-up/parry/hit read via whole-model transforms alone).
Also added on Aviv's ask: **F6 directional-view toggle** (smooth -> 8 -> 4 headings, display
only, fighter.gd's sticky hysteresis reused on the model yaw) - Aviv deferred the call
("אפשר לשנות אחר כך"), all three modes stay live in the slice. Spec below as built:

The remaining risky assumption. Movement-in-3D is proven (`arena3d_test`); this slice puts the
REAL combat in the 3D iso view: player-FANG vs bot-FANG, melee / wind-up / parry / spacing /
knockback / KO / best-of-3, with readable action states on the 3D model.

- **New scene** `scenes/arena3d_fight.tscn` + `scripts/arena3d_fight.gd`. `arena3d_test`
  stays untouched (the locked movement-feel reference).
- **THE SIM IS THE REAL GAME - nothing is copied.** Two real `fighter.gd` instances (player +
  bot, both rusher/FANG mirror-match) run in a HIDDEN 2D layer; the scene root is a game-SHIM
  providing the same services `game.gd` provides (clamp / shake / hit-stop / sparks / burst /
  projectiles / chill / shockwave / KO+rounds), re-expressed in 3D. The 3D layer is RENDER-ONLY:
  it mirrors sim position/facing/action-state onto the GLB every frame. (arena3d_test copied
  movement verbatim - acceptable for a throwaway; copying COMBAT+bot would fork the game rules
  and make the fun-verdict worthless. This structure is also the integration pattern itself.)
- **Action reads on the model = whole-Node3D transforms ONLY** (pitch-lean + non-uniform scale
  on a facing-aligned pivot + material overlay). NO bones, NO baked animation - that is the
  scope guard. The locked 2D pose grammar, re-expressed: wind-up = lean-BACK (readable
  anticipation) · attack = lean-IN · hit = squash + white flash · perfect parry = pop + cyan ·
  momentum stretch along motion · block = shield plate w/ parry-window color · KO = the model
  TIPS OVER. Attack telegraph = a floor quad at the TRUE hitbox (the hitbox does not lie).
  Known approximation: hit-squash is vertical, not knock-axis-aligned like 2D - if it reads
  weak that is DATA, not a bug.
- **A-pose stays for now.** Stance is a look problem, not a fun problem - the minimum gets
  decided WITH Aviv only if the live test says the reads are illegible in A-pose.
- **HUD:** HP + skill bars projected above heads + score + banner. `P` practice (freeze bot) ·
  `F4` slow-mo · `Esc` quit.
- **OUT:** chill/shockwave visuals (mirror-match = lunge only), net, latency, stance/rig work,
  any model/topology polish, wiring into the main game.
- **Pass =** Aviv fights a real best-of-3 vs the bot in the 3D iso view and answers THE
  question: is the 3D fight fun, and do wind-up/parry/hit read on the model?

## THE UNIFIED 3D GAME (2026-07-03, Aviv approved) - step ladder, one Aviv-check per step

All three walls are proven but live in three separate scenes (2D main game / 3D bot fight /
2D net fight). Unification = ONE game from the locked parts, ZERO new mechanics. New
`scripts/game3d.gd` + `scenes/game3d.tscn` - the 2D game stays untouched as fallback.

1. **✅ Step 1 DONE (2026-07-03, Aviv "המשך" = approved) - the main game in 3D:** select
   screen (all 3 archetypes) -> 3D arena vs bot -> best-of-3 -> Tab re-pick. Rusher = FANG
   GLB. Balanced/tank = colored 3D greybox capsules (ZERO's GLB exists but is NOT locked -
   concept lane owns its asymmetry check; drops into the same slot later). Practice/slow-mo/
   F6 view carry over. `scripts/game3d.gd` + `scenes/game3d.tscn`.
2. **✅ Step 2 DONE (2026-07-03, Aviv "עובד") - online in the same game:** host/join from the
   select screen (H/J), each player picks their own fighter, net_fight's locked
   server-authoritative core rendered by the same 3D layer, incl. the L lag toggle. Skills +
   lunge now sync to the guest too (the lag test had FANG-only). Real best-of-3 across two
   windows in 3D, scores agree.
3. **✅ Step 3 DONE (2026-07-03) - it IS the game:** `project.godot` main scene = game3d.tscn
   (F5 opens the unified game). The 2D game (game.tscn) + throwaway 3D slices stay in the
   repo as fallback / feel reference. Headless boot of the default scene = clean.

**RESULT: the three proven walls (3D combat / server-auth net / latency) are now ONE game.**
No new mechanics were added - pure unification from locked parts. The scattered scenes
(game / arena3d_test / arena3d_fight / net_fight) remain as reference; game3d is the product.

## Greybox polish principle (learned the hard way, twice)

While in greybox, only polish things that are **asset-independent**:
- ✅ **Information / readability** - what you NEED to play (cooldown bars, names, states).
- ✅ **Timing / mechanism feel** - hit-stop length, when feedback fires, shake timing.
- ✅ **Balance numbers** - stats that change how it PLAYS.

DEFER anything whose final form depends on art/animation/audio - it will be re-made,
per character, in the content/asset phase:
- ❌ **Visual magnitude** - explosion size, particle look, the actual art. (Sparks now
  are a placeholder that only proves the feedback channel + its timing exist.)
- ❌ **Sound** - the SFX are assets; also not needed to playtest or balance. Defer to the audio phase.

Test: "if the real art/audio will change this number, don't tune it now." Aviv caught
this on explosion intensity AND on sound - so it's a rule, not a one-off.
