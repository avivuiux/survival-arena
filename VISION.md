# Survival Arena - Vision & System Map

The full ambition: a **Survival Project-scale** arena game - many characters, skills,
items, modes, progression, and online play. This doc maps ALL the planned systems so
the complexity is a **map, not a pile**. We build along this map one slice at a time.

> This is a draft for Aviv to react to: cut, add, reorder. It is the big picture;
> `DESIGN.md` is the contract for the combat core we're proving right now.

## The honest framing (keep this in view)

- Survival Project was made by a **studio over years**. Aiming there is legitimate -
  but it is a long road, and the order matters more than the length.
- **AI changes the cost of CONTENT dramatically** (characters, skills, items, maps,
  balance tables) - that's most of the pile, and it's now cheap and parallel.
- **AI does NOT change the WALLS**: real-time netcode + authority model, anti-cheat,
  economy balance, and 24/7 live-ops. These stay hard. We respect them by sequencing
  them late and deliberately - never bolting them on early.

## Status legend

`[x]` done · `[~]` partial · `[ ]` planned · `WALL` = hard system, slow down here

---

## The layers (what the full game is made of)

### Layer 0 - Combat core  `[x] mostly done`
The foundation everything sits on. Proven fun (feel-test passed).
- [x] Movement in an arena (isometric diamond, clamped)
- [x] Melee attack + hitbox/hurtbox
- [x] Knockback, hit-stop, flash, screen-shake ("game feel")
- [x] HP, KO, round reset, winner banner
- [x] Local two-player duel (shared keyboard)

### Layer 1 - Combat depth  `[~] in progress`
What turns one attack into a fighting system.
- [x] Dash / dodge with i-frames (dodge -> punish) - feel-test passed
- [x] Momentum movement (acceleration + glide) - the weighty "hover" feel Aviv wanted
- [~] A resource for skills - cooldowns done (chill); mana/energy still optional
- [~] Character skills - first one done: **"chill"** (AoE slow that catches a group);
      more shapes to come (ranged poke, melee arc, buff)
- [~] Status effects - "slow" (chill) done; stun / knockup still to come
- [ ] Blocking / parry? (decide: does this game reward defense?)

### Layer 2 - Characters (roster)  `[ ]`  ← mostly CONTENT, cheap & parallel
The "variety" pillar - Survival Project's CKs.
- [ ] Character data model (stats + signature skill set), data-driven
- [ ] 1 archetype first, then expand the roster
- [ ] Character select screen
- [ ] Distinct feel per character (speed/range/power trade-offs)

### Layer 3 - Arenas  `[ ]`  ← CONTENT
- [ ] Multiple arena layouts
- [ ] Ring-out / edges as a mechanic (knock enemies out?)
- [ ] Hazards / interactive elements
- [ ] Arena select

### Layer 4 - Match structure & modes  `[ ]`
The wrapper that makes fights into "a match".
- [ ] Best-of-N rounds + score
- [ ] Modes: 1v1 · free-for-all · team battle · survival/boss
- [ ] Round/match flow (countdown, results screen, rematch)
- [ ] Bots / AI opponents (also lets you test without a second human)

### Layer 5 - Progression & economy  `[ ]`  `WALL (balance)`
The "keep playing" loop. Content is cheap; *balancing* it is the hard part.
- [ ] XP / levels
- [ ] Currency earned from matches
- [ ] Unlocks (characters, cosmetics)
- [ ] Items / equipment + inventory
- [ ] In-match item pickups (if desired)
- [ ] Economy balance (sink/source) - this is design judgment, not code

### Layer 6 - Online & meta  `[ ]`  `WALL (the big one)`
This is the real gate. Nothing here is bolted on cheaply.
- [ ] **Netcode + authority model** - server is the source of truth; decide
      prediction/rollback vs lockstep. Start with Godot built-in multiplayer (ENet) 1v1.
- [ ] Accounts / persistence (a database)
- [ ] Lobby + rooms (create/join), matchmaking
- [ ] Friends, chat, (clans/guilds?)
- [ ] Anti-cheat (server-authoritative is the baseline defense)

### Layer 7 - Live & content ops  `[ ]`  `WALL (never-ending)`
Only relevant once it's live with real players.
- [ ] Content pipeline (add characters/skills/items without breaking balance)
- [ ] Telemetry / analytics (what's overpowered, where players quit)
- [ ] Ongoing balancing + events + support

---

## Dependency / build order (the actual path)

```
L0 Combat core  [x]
   │
L1 Combat depth (dash, skills, resource, status effects)
   │
   ├── L2 Characters ─┐   (content, parallel once the data model exists)
   ├── L3 Arenas ─────┤
   │                  │
L4 Match modes + bots ┘   (needs depth + ≥1 char + ≥1 arena)
   │
L5 Progression & economy   (needs match loop to reward)
   │
L6 ONLINE  ── WALL ── design the authority model here, slowly
   │          (everything above was validated LOCALLY first - that's the point)
   │
L7 Live-ops  (only after it ships)
```

Two truths in that diagram:
1. **L2/L3 are parallel content** - once the data models exist, the roster and maps
   grow fast and cheaply with AI. This is where "much more complex" gets affordable.
2. **L6 is the gate everything funnels through.** We validate the whole game LOCALLY
   (bots + shared-keyboard) before we pay the netcode cost - so when we go online,
   we're wiring up a game we already know is fun, not discovering fun over a network.

## Recommended next slice (Layer 1 start)

Pick the first piece of combat depth - a **dash** or a **single character skill** -
because depth is what makes the proven-fun hit into a proven-fun *fighting system*.
Everything in L2+ is more powerful once L1 gives it a vocabulary to build from.
