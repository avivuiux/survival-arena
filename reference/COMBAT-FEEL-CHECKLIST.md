# Combat-Feel Checklist (for the next tuning pass)

> A hand-check list for "does this action feel alive?" - use it when we tune melee / ranged /
> parry / skills, add a new character, or a move feels flat. NOT a process to run every session;
> a reference to skim during a feel pass. Distilled + adapted to our arena brawler from two MIT
> sources (evaluated 2026-07-02): fagemx/gstack-game `feel-pass/references/feedback-chains.md`
> and abagames/claude-one-button-game `maximize-game-feel.md`.

## The 4-beat model - every satisfying action has all four

```
ANTICIPATION → ACTION → IMPACT → RESOLUTION
  (wind-up)     (do it)  (feel it)  (recover)
```
Durations are in **frames @60fps**. If a beat is missing or mistimed, the move feels wrong.

| Beat | Job | Frames | Missing feels like | Too long feels like |
|---|---|---|---|---|
| Anticipation | "something's coming" | 2-10 | move pops out of nowhere, no weight | sluggish, unresponsive |
| Action | input becomes reality | 1-5 (shortest) | input got eaten | unwanted slow-mo |
| Impact | confirm the hit - **feel lives here** | 3-8 | hitting air, "did that work?" | screen illegible, noise |
| Resolution | return to neutral, breathe | 5-15 | machine-gun, no rhythm | "let me move already" |

## Our moves vs the model (what we HAVE, what to eyeball)

- **Melee (S):** `ATTACK_ACTIVE=0.12s` action + `hit_stop(0.06)` + flash + `add_shake(7)` + sparks.
  - **Soul = the hitstop.** Remove it and melee swings through fog. We have 0.06s - check it reads.
  - **Weak beat = anticipation.** We have ~zero wind-up (attack is instant). SP is about
    reading spacing/commitment; a 2-4f telegraph could make poking feel more deliberate. *Candidate.*
- **Ranged (D):** projectile + sparks on hit. **Soul = the hit marker** - at distance the player
  needs unambiguous "I connected." Eyeball whether the spark burst alone confirms it.
- **Parry (Space):** `PARRY_WINDOW=0.18s`, cyan arc, sparks, shake on success. Soul of a defensive
  move = the i-frames/confirmation. We flash + short i-frame on parry - check it's legible at
  the bot's closing speed (the exact thing the gestalt retest passed).
- **Damage taken:** flash + knockback + shake + `spawn_sparks`. **Soul = i-frames** so the player
  isn't trapped in a damage loop. We have a brief `_iframe` on parry; regular hits have none -
  fine for a duel, worth remembering if stun-lock ever feels bad.

## Dead-time flag (frames where nothing engaging happens)

| Duration | Verdict |
|---|---|
| 0-5f | normal rhythm |
| 5-15f | ok between meaningful actions |
| 15-30f | suspicious - why is the player waiting? |
| 30f+ (0.5s+) | **flag** - forced wait / missing content |
| 60f+ (1s+) | **escalate** - player disengages |

## Juice checklist (applies to ALL objects - fighters, projectiles, later enemies)

1. **Squash & stretch** - stretch on launch/dash, squash on impact; subtle idle breathing.
2. **Dynamic tilt** - lean into the direction of velocity/acceleration. (We have envelope-run
   momentum; a slight lean would sell the "flying/glide" feel we tuned.)
3. **Eyes / facing expression** - a face/marker that always points the movement direction
   (we have a facing line; a stronger cue reads better on the greybox).
4. **Particles** - dust/fragments on impact, spawn, death, wall-hit. (We have sparks + KO burst.)
5. **Afterimages/trails** - faded copies along fast trajectories. (We have a dash trail; could
   extend to the envelope-run at high speed and to projectiles.)

**Rule:** apply consistently across the player AND the bot AND projectiles - consistency is what
makes the whole screen feel alive, not just the hero.

## Bot behavior (design it for the player's fun, not to win)

From Game-Studios `ai-programmer` (MIT). The bot exists to make the PLAYER's fight fun - it is a
sparring partner standing in for remote players, not an opponent trying to win.

- **Fun, not optimal.** A perfectly-optimal bot is not fun to fight. Aim for "a good rival."
- **Predictable enough to learn, varied enough to stay interesting.** The player must be able to
  read a pattern and beat it - then the bot mixes it up so it doesn't get stale.
- **Telegraph intent.** Before the bot attacks/lunges, it should give a readable wind-up so the
  player has reaction time. An un-telegraphed hit feels cheap, not hard. (This is the fix lens for
  our known "bot too aggressive" note - not "make it slower," but "make it readable + spaced.")
- **Every knob data-tunable.** Aggression, spacing, dodge-rate, reaction-delay - all constants we
  can dial, never hardcoded deep in logic.
- **Cheap.** Bot AI must be a trivial per-frame cost - a reactive state check, not a search.
