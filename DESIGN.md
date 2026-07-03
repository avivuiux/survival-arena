# Survival Arena - One-Page Design

A lightweight design contract for the prototype. Inspired by **Survival Project**
(2001): real-time, isometric arena skirmishes with friends - readable, punchy, social.

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
