# Character Deep-Dive - the method (the core of how we build OVERTHRONE)

This is the ritual. Before a character gets generated, rigged, or given moves, we run them
through this. Aviv's principle, locked: *depth is not decoration - it's the base, the
knowledge, the inspiration, and the depth for everything downstream* (art, animation,
moveset, story, UI, marketing). A shallow character poisons all of it; a deep one feeds all
of it.

## The iron rule

> **Every visible trait must trace back to a story-reason. A trait with no "why" is
> decoration - and decoration gets cut.**

We write it literally: `trait <- because <story-reason>`. No orphan traits. If we can't say
why FANG crouches, why his ear is torn, why he wears what he wears - we don't draw it yet.
(This rule is why "crouched stance" alone wasn't good enough: it needed a reason - predator
pounce-instinct - which then also explains his lunge mechanic. Reasons compound.)

## How we run it (the loop, per layer)

For each layer below, in order:
1. **Claude proposes + critiques** - a sharp draft, and what's generic/weak about the easy answer.
2. **Claude asks Aviv the canon questions** - only the calls that are genuinely his (taste,
   story-truth, what feels right). Structured questions when there's a real choice. Claude
   never decides canon alone, never burns generations before the spec is locked.
3. **Lock it, write the reason-chain, move on.** Earlier layers constrain later ones - surface
   is *derived* from essence, never invented free-floating.

Lightweight and living, like CONCEPT.md - we don't fill 50 blank fields; we interrogate until
the character is a person, then stop. Output per character = a bible at
`concept/characters/<name>/<NAME>.md`. CONCEPT.md stays world-level; bibles are per-fighter.

## The 6 layers (essence -> surface)

1. **THE SEED** - one sentence: who they are + the **contradiction** (the heart). The single
   tension that makes them a person, not an archetype. Everything hangs here.
2. **THE WOUND & THE WANT** - compressed backstory: what happened to them, what they're chasing
   (their OVERTHRONE "wish"), what they fear. The emotional engine that drives every choice.
3. **THE WAY THEY FIGHT** - *how* and *why* they fight: origin of their skill (raw instinct /
   self-taught street / trained / disciplined art), their fighting philosophy, what a fight
   *means* to them. This is the bridge to mechanics - the moveset must express this, not
   contradict it. (Stance, lunge, tells all live here.)
4. **THE BODY** - build, silhouette, signature physical features - each justified by 1-3
   (e.g. muscular <- because; torn ear <- because; tail <- because).
5. **THE SURFACE** - costume, palette, the one signature story-bearing object, face & default
   expression - each traced back to 1-3. The most-cuttable layer if it's not earned.
6. **THE VIBE IN MOTION** - how they idle / celebrate / lose, attitude & voice, the one gesture
   that's only theirs. Feeds animation and juice directly.

## Why this is the moat

A generic brawler has skins. OVERTHRONE has people. The art DNA (`sports-anime-clean`) + the
broadcast frame keep a wild roster (beast-kin, creatures, powered beings, cross-era fighters)
looking like one game; this method keeps each fighter feeling like someone you'd pick *because
of who they are*. That's the difference between a tech demo and a game people love.
