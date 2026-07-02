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
