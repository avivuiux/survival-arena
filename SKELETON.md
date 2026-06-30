# Survival Arena - SP-Faithful Mechanics Skeleton

Goal: rebuild the mechanics to be **as faithful to Survival Project as possible**, then
iterate. This is the analysis/characterization - **NOT a build order to execute without
Aviv's approval.** Every claim is tagged by confidence so we don't repeat the fabrication.

## Sources read (2026-06-30)

| Source | Gave | Reliability |
|---|---|---|
| [mmos.com review](https://mmos.com/review/survival-project) | A/S/D/R/space actions, aimed magic, modes, card system | **SOLID** (direct quotes) |
| [mmohuts review](https://mmohuts.com/review/survival-project) | "attacks aimed by direction + spacing; success = timing/positioning, not level" | **SOLID** |
| [SP:GENERATIONS wiki - Keyboard Controls](https://www.spgenerations.com/wiki/index.php/Keyboard_Controls) | control CATEGORIES (Booster/Melee/Ranged/Magic/Walking/Defense); exact bindings missing | **SOLID for structure** |
| WebSearch auto-summaries | the "rotate + forward/back" claim | **WEAK - NOT trusted, dropped** |
| Wikipedia / Fandom Gameplay | almost nothing / blocked (402) | thin |

Tags: `[CONFIRMED]` multiple solid sources · `[LIKELY]` Aviv-recalled + consistent with sources · `[OPEN]` not pinned

## CRITICAL framing - single-client multiplayer (Aviv 2026-07-01)

This is **NOT a couch / same-keyboard 2-player game.** It's **multiplayer - you play
ALONE** (one human per client), like SP. This corrects a wrong assumption baked into the
current code (P1-vs-P2-on-one-keyboard).

Implications:
- **One comfortable control scheme** for the single local player. Drop the 2nd-keyboard player.
- The opponent is a **bot for now = placeholder for REMOTE players** (the netcode wall, deferred).
- **Unlocks mouse-aim**: move with keys, aim/fire toward the mouse. This cleanly answers
  the "separate aim from movement" `[OPEN]` item (Aviv leaned this way) - only clean in a
  single-client setup, which is what we have.
- Controls stop being cramped: one player holds the full 6-action kit (keys + mouse).

## The skeleton

### Action toolkit - SIX parts `[CONFIRMED]`
From the SP:GENERATIONS control categories + the reviews. Every fighter has:
1. **Walk** - move.
2. **Booster** - **sustained acceleration / RUN** (hold `A` to run faster), NOT a
   momentary dash (Aviv 2026-06-30). Different from our current burst-dash + i-frames.
3. **Melee** - short-range attack.
4. **Ranged** - long-range attack.
5. **Magic** - a special burst that must be **aimed**.
6. **Defense** - block / parry, **distinct from the booster/dash**.

### Movement & aim
- **Free directional movement** (arrows), NOT rotate-and-move. `[LIKELY]` - Aviv + consistent
  with sources; the "rotate" idea came from a weak auto-summary and is dropped.
- **Aiming is directional** - attacks fire in an aimed direction; spacing matters. `[CONFIRMED]`
- **Aim may be steerable separately from movement** (walk one way, attack another). `[OPEN]` -
  Aviv leaned this way; a search hint said ranged shots steer with the arrow keys.

### Hit model
- Basic attacks (melee / ranged / magic) are **aimed / directional - skill-based**, NOT
  auto-hit-on-overlap. `[CONFIRMED]`
- Some skills are **AoE** (Aviv: chill is area, no aiming). So: aimed attacks + a few AoE skills.

### What made it FEEL like SP (Aviv)
**The unique movement · range & spacing (poking) · the defense/parry mind-game.**
(Character variety mattered but was NOT named as core to the *feel*.)

## Gap: current greybox vs the SP skeleton

Have: free move ✅ · dash/booster ✅ · melee ✅ · AoE skills (chill/shockwave) ✅ · char stats ✅.

**Missing for SP-faithfulness:**
- ❌ **Ranged attack** as a core part of every kit (long-range, aimed).
- ❌ **Defense / block (parry)** - a distinct defensive action, not the dash.
- ❌ **Directional aiming** - our attacks auto-hit on overlap; SP attacks are aimed by
  direction + spacing. **This is the biggest feel-changer** and the root of "timing/positioning".
- ❓ **Separate aim-from-move** - depends on the `[OPEN]` item above.

## Recommended build order (FOR APPROVAL - not yet building)

1. **Directional aiming first** - the foundation the whole SP feel rests on. Convert melee
   (and the aimed skills) from auto-overlap to fired-in-an-aimed-direction.
2. **Ranged attack** - add the long-range aimed attack to every fighter's kit.
3. **Defense / block (parry)** - the distinct defensive action + the mind-game.
4. Iterate feel from there (then map to characters).

## Open items to resolve (with Aviv) before/while building

- **Movement model** - confirm free-directional (Aviv leans free; sources don't contradict).
- **Aim model** - is facing locked to movement, or steered separately? (big control difference).
- **Exact control layout** - we adapt sensibly, not copy literally.
- **Booster vs our dash** - SP's Booster is a *sustained run* (hold `A`); our current
  "dash" is a *momentary i-frame dodge*. Different mechanic - reconcile later (keep both?
  replace dash with a run? both, on different keys?). NOT part of the aiming slice.
