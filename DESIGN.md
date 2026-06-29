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
