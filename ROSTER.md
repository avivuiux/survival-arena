# Survival Arena - Roster & Status Index

**Single shared truth for character status across BOTH work tracks** - the mechanics
chat (engine / Godot) and the concept/asset chat (identity / art). Either side updates
this; either side reads it first to know where a character stands. When a stage changes,
update the cell **and** the "last update" note.

> This file is the bridge between the parallel chats. Read it before acting on a character.

## Status key

`⬜ not started` · `🔨 in progress` · `⏸️ blocked / waiting` · `✅ ready`

## Roster

| Character | Archetype | Mechanics | Identity/concept | Assets (ref+pose) | Rigged (Godot) | In-game art |
|---|---|---|---|---|---|---|
| **FANG**   | **rusher** | ✅ | ✅ (bible LOCKED, `concept/characters/fang/FANG.md`) | ✅ (anchor + rig-ready transparent cutout `concept/characters/fang/FANG_rigpose_FINAL.png`) | ⬜ READY TO RIG | ⬜ |
| **ZERO**   | balanced (control / chill) | ✅ | ✅ (bible LOCKED, `concept/characters/zero/ZERO.md`) | ✅ IDENTITY-REF (anchor `zero_final_2.png` + transparent cutout `ZERO_rigpose_FINAL.png`; per DESIGN.md this is IDENTITY REFERENCE, not the in-game asset) | ⬜ (deferred - see DESIGN.md) | ⬜ |
| _(unnamed)_ | tank      | ✅ | ⬜ (no fiction yet - future character) | ⬜ | ⬜ | ⬜ |

_Archetype mapping CORRECTED by the concept chat 2026-06-30: **FANG = rusher** (orange tiger,
lunge = pounce - matches greybox + the whole FANG bible), **ZERO = balanced** (the chill/AoE
controller, blue). The **tank** archetype has mechanics but NO fiction yet - it's an open
future-character slot, NOT FANG._

## Stage definitions

- **Mechanics** - archetype implemented + feel-tested in-game (data row in `ARCHETYPES` + skill).
- **Identity/concept** - fiction / name / role defined in `CONCEPT.md`.
- **Assets (ref+pose)** - style-consistent reference sheet + a rig-ready neutral pose generated.
- **Rigged (Godot)** - cut into parts + Skeleton2D rig + a test animation.
- **In-game art** - rigged character wired into the game, replacing the greybox square.

## Who owns which columns

- **Concept/asset chat** owns **Identity** + **Assets** (it produces them).
- **Mechanics chat** (engine/Godot) owns **Mechanics** + **Rigged** + **In-game art**.
- Either chat: read this first ("is FANG ready to rig yet?") before starting work on a character.

## Later note
- 2026-07-01 (concept chat) - **refined both looks + built the Character Studio.** FANG got a
  serious/determined aura + fire-fists (`fang_v6_serious_1.png`); ZERO got a colder, malevolent
  turn from a cosmic/supernatural merge (`zero_v2_malevolent_2.png`) - both ADOPTED as current
  portraits. New GameOS modules: `concept/CHARACTER-ATTRIBUTES.md` (12-axis schema + roster
  matrix + gap-finder) and `tools/character-studio/` (internal SaaS MVP to browse/tag/explore/
  manage the roster; open `index.html`). FANG & ZERO populated into the Studio as in-progress.

## Session 2026-07-01 close (concept chat) — "ארוז"
- **Art pipeline switched to Magnific MCP** (Nano Banana Pro; OpenAI hit its billing cap). Style
  references + `images_remove_background` + `models3d_generate`(=Tripo, tested→flattens 2D, parked).
- **FANG** ✅ identity + ✅ art (`fang_v6_serious_1.png`: serious/determined + fire-fists) +
  rig-ready cutout (`FANG_rigpose_FINAL.png`). READY TO RIG (mechanics chat).
- **ZERO** ✅ identity + ✅ art **FINAL = `zero_final_2.png`** (cosmic-alien ice being, floats,
  human remnant = half-face+arm+exposed chest, ice "consuming" the face, style-unified to FANG's
  cel). Floating rig-pose still TODO.
- **STYLE-GUIDE locked** (`concept/STYLE-GUIDE.md`) — visual DNA + FANG styleB as the mandatory
  `style` reference for every future character (fixes roster drift).
- **New GameOS modules:** CHARACTER-METHOD **v2** (pitch+9 layers+adversary), CHARACTER-ATTRIBUTES
  (12-axis schema+matrix+gaps), ART-DEPTH (art-mining), STYLE-GUIDE, SYSTEM.md (GameOS index).
- **Character Studio built + code-reviewed + jsdom-verified** (`tools/character-studio/`): dashboard/
  roster/detail/tag-explorer/**create-wizard**; FANG+ZERO populated as in-progress.
- ⚠️ **OWNERSHIP FLAG for mechanics chat:** per GLOSSARY, `tools/` + `SYSTEM.md` are yours; the
  concept chat built `tools/character-studio/` + `SYSTEM.md` (Aviv-directed). **Decide:** reassign
  in GLOSSARY (to concept or shared) OR hand off. Committed together for now to save state.
- **Next:** ZERO floating rig-pose → both ready to rig · OR character #3 (Studio shows the gaps) ·
  OR resolve ownership. (Movement/booster tuning notes are the mechanics chat's, not here.)

## Last update

- 2026-07-02 (mechanics chat, session 4 close "ארוז") - **CONVERGED with the concept lane's
  two-art-layers decision.** Both lanes independently reached "the detailed PNGs are identity
  reference, not the in-game asset" (mechanics via `DESIGN.md` §function-first; concept via the
  in-arena paper-doll test). Acknowledged: **HANDOFF next-step-#2 "rig FANG_rigpose_FINAL.png"
  is SUPERSEDED and dropped.** Mechanics this session: all procedural-greybox-motion locked
  (momentum stretch + speed trail, walk=settle, squash&stretch on combat beats, attack wind-up -
  all Aviv "מעולה") + **online slice 1 (ENet pipe proven, two windows see each other move)**.
  **ANSWER to the concept lane's request (the in-arena render spec, for designing the in-game
  fighter):**
  - **View = FLAT, STRAIGHT-ON 2D. NOT isometric.** The ROSTER decision above says "iso-angled",
    but the actual renderer (`fighter.gd` `_draw` + `game.gd` flat floor rect) has ZERO iso
    projection - sprites are drawn straight-on. **Iso art would look wrong.** If we actually want
    iso, that is a rendering change to discuss FIRST (flag it, don't assume).
  - **Facings = horizontal flip only (left / right).** No up/down/diagonal - the sprite mirrors on
    `facing.x`. The in-game fighter needs ONE pose that reads well mirrored L/R.
  - **Scale:** sprite drawn **116px tall in a 1152x648 viewport** (~18% of screen height); the
    greybox square is 30px. Anchor: centered horizontally, top at ~0.62*height above the origin.
  - **Arena:** full-screen dark floor (RGB ~0.15,0.17,0.22) + thin border. Must read against dark.
  - Want a pixel screenshot for exact reference? Say so and I'll script a capture next session
    (F5 in the editor -> pick RUSHER -> start also gets you one live).
  **Net: design FANG's in-game fighter as a simple, small-readable, STRAIGHT-ON, L/R-mirrorable,
  dark-bg-legible sprite. Not iso.**
- 2026-07-02 (concept chat) - **ZERO floating rig-pose DONE -> Assets ✅, READY TO RIG.**
  Generated per `concept/RIGPOSE-STANDARD.md` (Magnific Nano Banana Pro + `zero_final_2.png` as the
  anchor `image` reference), adapted for a FLOATER: hovering neutral A-pose, no planted feet / no
  ground shadow, crystal robe-drapes swept clear of the legs. Two candidates rendered; Aviv picked
  the more rig-ready one (legs shoulder-width, hands open+separated). Background removed ->
  transparent RGBA cutout = `concept/characters/zero/ZERO_rigpose_FINAL.png` (the cut source).
  Flat rig-pose (pre-cutout) kept = `zero_rigpose_B.png`. **HANDOFF TO MECHANICS CHAT: BOTH FANG
  AND ZERO ARE READY TO RIG.** (Minor: a few loose ice shards drift near ZERO's feet - drop them
  when cutting.) **DRIFT CORRECTION (2026-07-02): DO NOT RIG THESE YET.** The "READY TO RIG" flags
  above (set 06-30) are SUPERSEDED by the mechanics chat's `DESIGN.md` decision (also 07-02, Aviv):
  **the FANG/ZERO PNGs are IDENTITY REFERENCE, NOT the in-game asset.** The in-game character is
  "function-first" (derived from what the fight must read: facing / action-state / momentum /
  identity), and the technical form (sprite vs rig) + the actual in-game look are DEFERRED until the
  game "earns real art." The next step is MECHANICS-lane **procedural motion on the greybox** (lean
  into velocity, squash & stretch, attack wind-up) - code-only, no art. So: rig-poses = done + shelved
  as identity/portrait reference; nothing to rig now; concept lane is genuinely idle until the game
  earns real art. Character #3 (tank) also parked. (This note reconciles the two chats - the concept
  lane had trusted this stale ROSTER over the newer DESIGN.md; DESIGN.md wins.)
- 2026-07-02 (concept chat, later - after mechanics session 4) - **UPDATE: the game has now EARNED
  real art, and the path is set.** Mechanics core is fun-proven + all procedural-greybox-motion
  slices are locked ("מעולה"): movement, combat gestalt, momentum stretch+trail, squash&stretch,
  attack wind-up. FANG's detailed PNG is wired in as a STATIC-SPRITE placeholder (flips by facing) -
  and front-facing portrait in the iso arena reads wrong (paper-doll), which confirmed Aviv's "this
  isn't the game's art." **DECISION (Aviv, this session): TWO ART LAYERS.** (1) detailed PNGs =
  PORTRAIT / select-screen / identity ref (done). (2) a SEPARATE in-game fighter = simpler,
  iso-angled, readable-small = to be designed by the concept lane. **This SUPERSEDES the mechanics
  HANDOFF "next step = rig FANG_rigpose_FINAL.png" - rigging the PORTRAIT is now obsolete.** Next
  concept-lane step: design FANG's IN-GAME fighter, to the REAL arena view (need a screenshot of
  FANG's current in-arena sprite for exact camera-angle + scale + facings before generating). Then
  produce ONE in-game FANG -> drop in -> Aviv judges. (Mechanics chat: please note HANDOFF next-step
  #2 is superseded; the in-game fighter is separate art, not the rigged portrait.)
- 2026-06-30 - index created (mechanics chat). FANG = characterizing + front/side assets done;
  rusher & balanced = mechanically done, no identity/assets yet.
- 2026-06-30 (concept chat) - archetype map corrected: FANG=rusher, ZERO=balanced, tank=open
  future slot (was wrongly "FANG=tank?"). FANG bible LOCKED (6-layer deep-dive,
  `concept/characters/fang/FANG.md`).
- 2026-06-30 (concept chat, later) - **ART DIRECTION CHANGED**: soft sports-anime dropped ->
  **"Guilty Gear / arcade-fighter 2D"** (Aviv chose from 4 rendered styles; cutout animation
  unchanged - he disliked the drawing, not the motion). See CONCEPT.md Round 7. **FANG visual
  anchor LOCKED = `concept/characters/fang/fang_styleB_digitigrade_1.png`** (Aviv: "מושלם") -
  full tiger legs+paws, human face. Identity ✅. **Next: neutral rig-ready A-pose of FANG in
  style B -> then FANG is ready for mechanics chat to cut + Skeleton2D-rig.** Then ZERO (same
  method + same style). All art via gpt-image-1 (OPENAI_API_KEY in repo env; Higgsfield not used).
- 2026-06-30 (concept chat, FANG DONE) - generation switched to **Magnific MCP** (claude.ai
  connector; OpenAI hit its billing cap). Nano Banana Pro + the anchor as an image-reference
  solved character consistency. **FANG rig-ready transparent cutout finished =
  `concept/characters/fang/FANG_rigpose_FINAL.png`** (Assets ✅). Wrote
  `concept/RIGPOSE-STANDARD.md` (rig-pose checklist + reusable prompt template). **HANDOFF TO
  MECHANICS CHAT: FANG is READY TO RIG** (cut into parts + Skeleton2D in Godot). Next in concept
  chat: ZERO (same 6-layer method + same style B + same rig-pose template).
- 2026-07-01 (concept chat) - **ZERO designed + LOCKED.** Bible via CHARACTER-METHOD **v2**
  (added layers 0/7/8/9 + a right-sized adversary gate). Art via Magnific Nano Banana Pro. Aviv
  authored an **inversion**: ZERO = almost-entirely cosmic-alien ICE (galaxy inside) with a small
  human-flesh remnant (half face + one arm), intricately interwoven; unified etched-crystal
  garment + crown; **FLOATS**. Anchor = `zero_cosmic_1.png`. New roster direction: **most
  characters float** (FANG stays grounded). Also new GameOS modules this session: `SYSTEM.md`,
  `concept/ART-DEPTH.md`-style art-mining pass (folded into CHARACTER-METHOD v2). **Next: ZERO
  floating rig-pose -> bg removal -> both FANG & ZERO ready to rig.**
