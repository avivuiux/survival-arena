# Survival Arena - Game Design Document (living)

The deep-spec of the game. `DESIGN.md` is the one-page contract + find-the-fun discipline;
this is the full design. **Discipline (locked with Aviv 2026-07-07): we spec the FRAME here -
vision, modes, roles, structure - but the CORE-LOOP FUN stays "proven by play," never decided on
paper.** Anything tagged `[PROVE]` is a hypothesis to test in a prototype, not a settled fact.

Built as a staged spec (like deep-spec): each stage = Claude drafts -> Aviv decides (a gate).

## ⚠️ WORK SPLIT BETWEEN THE TWO CHATS (2026-07-07)
To avoid both chats touching the same thing:
- **MECHANICS lane (engine/Godot chat)** = IMPLEMENT the locked match structure (Stage 2 below):
  the 3v3 arena match loop - teams, respawn, score, timer, the center orb - replacing the old
  1v1 best-of-3 in `game3d`. Owns all `scripts/` code. Reads Stage 2 as the contract.
- **DESIGN/CONCEPT lane (this chat)** = keep DESIGNING ahead of them: GDD Stages 1, 3, 4, 5, 6
  (feelings, roles, combat verbs, modes, risks) + characters/art/animation. Does NOT touch
  `scripts/`.
- **Contract = this file (GDD.md).** Mechanics implements what's LOCKED; design lane extends the
  OPEN stages. Neither edits the other's stages. (Same rule as ROSTER.md for characters.)

---

## STAGE 0 - THE FRAME (locked)

- **Vision:** a fast, punchy, team-based arena brawler at the crossroads of Survival Project
  (fast / punchy / lots happening) and DOTA 2 (tactical / team / hero roles). Closest reference:
  **BATTLERITE** (MOBA hero-combat depth, no farming, fast + team-based). See `DESIGN.md §VISION`.
- **Pillars (every decision checks these):** (1) Readable chaos, (2) Satisfying impact,
  (3) Easy to grab, fun with friends.
- **The one fun moment:** read your opponent, commit, land the hit, it lands HARD (knockback +
  hit-stop), you immediately want to do it again. `[PROVE]` - already proven in 1v1; must survive
  the team context.

## STAGE 1 - THE FEELINGS (MDA aesthetics-first) - LOCKED

The emotional north-star, in priority order (you cannot max all; this ranks where we invest):
1. **"That hit felt AMAZING"** - visceral impact / sensation (LOCKED #1, Aviv). The proven core.
   Invest first in juice, hit-feedback, weight, knockback.
2. **"We pulled off something epic together"** - team fellowship / clutch coordinated moments
   (combos, comebacks, orb steals). The new team layer. Invest in skill-combos + readable teamfights.
3. **"I read them and won the exchange"** - mastery / correct reads. Invest in clear telegraphs +
   counterplay.
Design tie-breaks resolve toward #1 (if a choice trades impact for something else, keep impact).

## STAGE 2 - THE LOOPS - IN PROGRESS

### Match structure
- **Team size: 3v3 arena** (LOCKED 2026-07-07, Aviv). Battlerite-shaped: enough for a role
  triangle (carry / support / initiator = FANG / ZERO / light-knight) and real team tactics,
  still readable.
- **Objective / win condition: elimination + center power-orb** (LOCKED 2026-07-07, Aviv). Win a
  round by eliminating the enemy team; a **power-orb spawns at center periodically** and forces
  teams to contest the middle (breaks passive turtling). Battlerite's proven anti-stall solution.
- **Respawn: YES, within the round** (LOCKED 2026-07-07, Aviv - leans the SP side: continuous,
  fast, forgiving; a dead player is back in ~3-4s, never sidelined watching). **This changes the
  win condition** (you cannot wipe a respawning team), so:
- **Win condition = SCORE at the timer, not team-wipe (LOCKED shape 2026-07-07, Aviv; numbers
  are `[PROVE]`-by-play starting values):**
  - **Respawn: 10s** after death (Aviv). Starting value - leans tactical (a kill = a real numbers
    window). Watch dead-time-feel vs the accessibility pillar; tune down (~5s) if it drags.
  - **3 rounds x 3 minutes, best-of-3** (win 2 rounds; Aviv). Starting value - long for the genre
    (Battlerite rounds ~30-60s); tune down if 3 min of continuous fight drags/tires the read.
  - **Each round runs the full 3 min; the team with the higher SCORE when the timer ends wins the
    round.** (Fixed-length rounds -> no early score-target needed.) Match ~9 min.
  - **Score = kills + center-orb bonus.** The **center orb, when grabbed, gives the team BOTH
    points AND a short power spike** (a few seconds of extra damage/shield) - LOCKED 2026-07-07,
    Aviv. Two reasons to contest center: score + power. This is the anti-stall engine.

### ✅ STAGE 2 IS LOCKED - ready for the mechanics lane to IMPLEMENT.
Summary of the match the engine should build: **3v3 arena. 3 rounds x 3 min, best-of-3. Respawn
10s. Each round runs full 3 min; higher SCORE at the timer wins the round. Score = kills + orb
bonus. A center power-orb spawns periodically; grabbing it gives points + a short power spike.**
(All numbers are `[PROVE]`-by-play starting values.) This replaces the old 1v1 best-of-3 loop.

### Moment-to-moment (from DESIGN.md, holds)
approach -> read opponent -> commit to attack/skill -> land hit + knockback -> reposition -> repeat.

## STAGE 3 - ROLES & ROSTER - IN PROGRESS
The role triangle: FANG = rusher/carry, ZERO = control/support, light-knight = tank/initiator.
- **Team composition: FREE PICK** (LOCKED 2026-07-07, Aviv). Any player picks any character, no
  role-queue (Battlerite-style, grab-and-play). Roster designed so a balanced comp rewards itself
  (soft encouragement, not a rule). Duplicates: allowed by default, `[PROVE]`.
- **Counter depth: SOFT counters** (LOCKED 2026-07-07, Aviv). No hard rock-paper-scissors; every
  character is viable into every character, but each archetype has a natural lean (rusher pressures
  a squishy support, tank locks a rusher, support out-sustains a tank). Tactics without
  "doomed at the pick screen" - protects accessibility.
- **Roster north-star: start 3 (one per role), grow toward ~6 (two per role)** so free-pick has
  real variety. Flexible target, not locked.

### ✅ STAGE 3 essentials LOCKED. (Free pick · soft counters · role triangle · ~6-char north-star.)

## STAGE 4 - COMBAT VERBS + READABLE-CHAOS RULES - LOCKED (design level; tuning = `[PROVE]`)

### Kit structure per character (LOCKED 2026-07-07, Aviv): "lean + ultimate"
- **1 primary attack** - spammable, the bread-and-butter (maps to SP melee/ranged).
- **2 identity skills** on cooldown - the character's signature moves (FANG's pounce, ZERO's
  freeze, light-knight's shield-slam).
- **1 charged signature / ultimate** - the "money moment," charges over the round.
- **1 defensive / mobility option** - dodge / parry / block (maps to the SP parry + booster).
Enough depth + identity, still readable and buildable. Sits on the existing 6-action SP skeleton.

### Readable-chaos rules (design principles, from pillar #1 - the discipline for 3v3 fights)
- **Identity color owns effects:** each character's abilities read in their color (FANG orange,
  ZERO blue, light-knight gold) so you always know whose ability just hit you.
- **Telegraph before impact:** big moves have a visible wind-up (already proven). No un-read one-shots.
- **Silhouette + color over particle spam:** read abilities by shape and color, not screen-filling FX.
  Cap simultaneous full-screen effects.
- **Every hit is legible:** knockback + hit-stop make each hit land clearly (also serves feeling #1).
- **Ultimates get a distinct "big" cue** (audio + visual) so the money-moments read over the noise.

## STAGE 5 - MODES - LOCKED
- **3v3 only, for now** (LOCKED 2026-07-07, Aviv). Full focus: 3v3 vs bots (single-client, bots
  fill the other 5 players - our proven model) + 3v3 online. Prove ONE mode great before adding
  others (1v1 duel / survival are candidates for later, not now).

## REFERENCE LESSONS - Survival Project (from a 2026 retro-review, Aviv-sourced)
- **VALIDATION:** the reviewer explicitly says SP "fits more into what MOBAs became (LoL / Dota /
  HotS)" and was a **lobby-based, session PvP, hero-based** game - NOT an open MMO. Our action-MOBA
  re-vision is FAITHFUL to the source, not a departure. (12 heroes classified by 4 elements;
  PvP was the bread-and-butter; PvE was "boring.")
- **ANTI-LESSON (monetization):** SP fell partly to **pay-to-win** - premium characters with better
  stats + cash-shop power (equipment cards, boosters) = a free-vs-paid power gap. **Rule if we ever
  monetize: cosmetics / unlocks only, NEVER power.**
- **Thematic tie:** SP's subtitle = "Search for the Legendary Orb." Our center power-orb echoes it.

## STAGE 6 - RISKS / RISKIEST ASSUMPTION - LOCKED
- **THE riskiest assumption (prove first):** can we keep SP's momentum / slip FEEL while being
  ACCESSIBLE? The reviewer named SP's tank-controls as the top frustration ("takes a lot to get
  used to, sliding all over, hard to turn"). We want the momentum feel WITHOUT the frustration -
  readable, forgiving turning. `[PROVE]` by play; this is the make-or-break of the whole feel.
- Other assumptions to prove by play: (a) the hit-feel (#1 feeling) survives the 3v3 team context;
  (b) a 3v3 fight stays READABLE (pillar 1); (c) 10s respawn + 3-min rounds feel right (tune).
- Monetization: if ever, cosmetics only (SP anti-lesson). Progression: deferred; if added, never
  power-that-buys-wins.

---
## ✅ GDD DEEP-SPEC COMPLETE (Stages 0-6, 2026-07-07). Core loop numbers stay `[PROVE]`-by-play.

---

## DECISION LOG
- 2026-07-07: Vision = action-MOBA (Battlerite crossroads). [DESIGN.md §VISION LOCKED]
- 2026-07-07: Team size = **3v3 arena**. (The role triangle needs 3; still readable.)
