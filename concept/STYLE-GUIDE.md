# STYLE-GUIDE — the visual DNA (every character obeys this)

A GameOS module. Purpose: **roster cohesion = "one game."** This locks the *rendering* so
fighters don't drift into different-artist looks — the exact FANG↔ZERO drift Aviv caught
(FANG bold-flat-cel vs ZERO soft-painterly-glossy). Style was only *verbal* before; now it's
written AND enforced with a reference image on every generation.

## The locked finish
- **Base look:** modern 2D **arcade-fighting-game anime** (Guilty Gear / BlazBlue energy).
  NOT soft/painterly, NOT photoreal-gloss, NOT western-comic.
- **Linework:** bold, clean, confident black outlines; consistent weight; crisp.
- **Shading:** bold **CEL-shading** (hard-edged shadow shapes) + hard rim light; minimal soft
  gradients; must read at small isometric size.
- **Color:** saturated, high-contrast; each character's **identity color dominant** (FANG =
  orange, ZERO = blue); quiet / plain background.
- **Detail level:** clean and readable FIRST, moderate detail. Intricacy is allowed in the
  *design* (e.g. ZERO's cosmic ice) but must be rendered in the SAME cel language — flat color
  blocks + hard highlights, NOT airbrushed realism.
- **Proportions:** heroic athletic anime; full-body; grounded or floating per character.
- **Anchor framing:** full-body, plain light-gray background, dynamic-but-readable pose.

## Enforcement — how we STOP the drift
1. **Canonical style anchor = `concept/characters/fang/fang_styleB_digitigrade_1.png`** — the
   cleanest expression of the finish (bold Guilty-Gear cel, no extra FX to confuse the signal).
2. **Every character generation passes that anchor as a Magnific `style` reference** + this spec
   in the prompt. Never rely on words alone.
3. **Eyeball test after each gen:** same outline weight? same cel-shading model? same finish?
   If it reads like "a different artist," regenerate. (This is the check we were missing.)

## The drift lesson (why this file exists)
FANG and ZERO diverged because the style was verbal, not enforced with a reference. Aviv caught
it and correctly said: lock the base guidelines first. Fix = written DNA + a mandatory
style-reference on every generation, + the eyeball test.

## The SECOND art layer - the in-game fighter (locked 2026-07-02, Aviv)

The two-art-layers decision (ROSTER 2026-07-02) split the art. THIS section governs the
IN-GAME layer; everything above governs the PORTRAIT layer only.

- **In-game look = "Overwatch as sprites":** characters that read like a professional
  stylized-3D game render (soft lighting, bold clean shapes, vibrant) but are produced as
  2D images by AI - NO real 3D pipeline (models/rigging = the scope this project refuses;
  the Tripo test already failed). This is how Survival Project itself looked: drawn
  portraits + 3D-render-looking arena sprites.
- **Camera = ISOMETRIC** (SP-faithful), chosen over the current flat straight-on renderer.
  ⚠️ CROSS-LANE: the arena renderer is mechanics-owned and is currently FLAT - they wrote
  "if we want iso, flag it FIRST." This IS the flag (also logged in ROSTER). No iso asset
  is final until the mechanics lane sets the actual projection/angle.
- **Cost accepted knowingly:** iso means each character eventually needs multiple body
  directions (4-8) instead of one L/R-flipped pose.
- **Style probes vs assets:** until the renderer's real angle exists, any generated iso
  image is a PROBE (style validation), not an asset.
- **✅ QUALITY BAR APPROVED (Aviv, 2026-07-02: "נראה פשוט מעולה ומקצועי, זה הסטנדרט"):**
  the probe pair `concept/characters/fang/fang_ingame_owprobe_1.jpg` / `_2.jpg` IS the
  finish standard for the in-game layer. Approved = finish/quality only - NOT the camera
  angle (mechanics decides) and NOT yet validated on the dark arena floor.
- Rejected for this layer: Little Fighter chunky-2D, portrait-cel-shrunk (tested in-arena
  2026-07-02 as `FANG_arena_v1.png` = kept as baseline/archive only), real-3D-in-engine.

### 🔑 THE GENERATION METHOD - CORRECTED & LOCKED (2026-07-03, Aviv approved)
**The old "shared style-anchor image" method is DEAD.** It caused palette bleed: passing
`fang_ingame_owprobe_2` as the `style` reference on ZERO dragged FANG's ORANGE + fire into
him (probe 1 = orange body/fists; probe 2 = fully-ice, no human remnant). A gray-mannequin
anchor was tried next and bled GRAY into ZERO's skin + ice. **Root cause (the real lesson):
ANY image used as a style-anchor leaks its PALETTE, not just its render-finish.** So a
single shared anchor image for "roster cohesion" is exactly what breaks each character's
color. Cohesion must come from TEXT, not from a shared image.

**The locked method for every in-game asset:**
1. **ONE image reference only = the character's OWN portrait** (`type: image`, e.g. ZERO =
   `zero_final_2.png`). Its palette is already correct, so nothing foreign leaks in.
2. **NO `style`-type reference. NO other character's image. Ever.**
3. **The finish + camera come from TEXT** (paste the same finish description every time =
   "professional stylized 3D game render, Overwatch/hero-shooter quality, soft studio
   lighting, clean PBR, translucent refraction, glossy vibrant, NOT anime lineart / NOT cel
   / NO black outlines; isometric three-quarter camera from slightly above; full body,
   plain light-gray bg, readable when small"). This shared text IS the cohesion mechanism.
4. **Deliver as a clean CUTOUT:** `images_remove_background` on the pick → transparent PNG,
   **shadow stripped.** The baked drop-shadow must NOT ship in the sprite (it's angled for a
   fake floor, fights variable arena lighting, and ZERO floats). The MECHANICS engine draws
   the grounding shadow itself so it matches the real arena floor + light. (Aviv's catch.)
- This SUPERSEDES the "In-game style anchor = fang_ingame_owprobe_2" + "IDENTITY-BLEED
  GUARD / palette-guard-in-prompt" bullets above - no anchor image = no bleed to guard.

## Selection-screen portraits (2026-07-04, concept lane)
The character-select art is produced by **RENDERING the three game-ready GLBs** (concept-owned
throwaway `concept/_tmp_select_render.gd/.tscn`) - NOT by generating new 2D art. Rationale: the
select portrait IS the exact in-game object, so it can never drift from the locked look, and it
costs zero generation credits. Locked by Aviv: **hero angle = 3/4-front (yaw 300°)**, same angle
for all three so the cards match; transparent cutout, MSAA-8x + FXAA, auto-cropped to the figure.
Finals: `concept/characters/{fang,zero,atlas}/{FANG,ZERO,ATLAS}_select_v1.png`.

### ⚠️ KNOWN DRIFT (logged 2026-07-04, Aviv-approved to defer): ATLAS proportions off-style
Seen clearly side-by-side at the same scale: **FANG + ZERO sit at the locked ~3.5-head chibi
("heads tall" = how many times the head fits into total height; ~3.5 = big-head cute-but-fierce
toy). ATLAS came out ~4.5-5 heads = smaller head on a realistic-muscular body**, reading like a
more-serious/realistic game than the toy-box FANG + ZERO share. This is real roster drift, not
just "tank = big" (a tank can be huge AND big-head-chibi). **Aviv's call: register as drift, do
NOT rebuild now** - he intends to change more things in ATLAS later anyway, and rebuilding mid-
flight = the stack-more-art trap while the mechanics full-roster-proof gate is still open. Revisit
ATLAS proportions when he reworks him, AFTER the roster is proven live in game3d.

## Status
- 2026-07-01: guide written. **ZERO re-rendered to this finish + adopted = `zero_final_2.png`**
  (matched to FANG's cel look; fixed the painterly drift). FANG's styleB anchor
  (`fang_styleB_digitigrade_1.png`) is the mandatory `style` reference for the PORTRAIT layer
  (portrait cohesion only - this still holds for portraits, NOT for the in-game layer).
- **2026-07-03: in-game generation method corrected + LOCKED (see box above). ✅ ZERO in-game
  asset FINAL = `concept/characters/zero/ZERO_ingame_v1_cutout.png`** (Aviv "מעולה"; portrait-only
  ref, warm human remnant restored, clean cosmic-ice palette, background+shadow removed).
  Chosen from probe pair 5/6 (kept: `zero_ingame_owprobe_5.jpg` / `_6.jpg`). Probes 1-4 =
  the bleed failures, kept as the cautionary trail.
- **2026-07-03: ✅ FANG in-game asset FINAL = `concept/characters/fang/FANG_ingame_v1_cutout.png`**
  (Aviv's explicit pick: "פשוט קח את התמונה הזאת"). It is the background+shadow-stripped cutout of the
  original approved `fang_ingame_owprobe_2.jpg` (crouched pounce). ⚠️ NOTE: this specific asset
  has the FIRE-FISTS + the stray-color hand-wrap BAKED IN (contradicts the "engine adds VFX / clean
  base" rule 3-4 above) - kept per Aviv's direct call, flagged to him, easy to re-cut clean later.
  The clean portrait-only probes explored this session (`fang_ingame_owprobe_3..8.jpg`: clean
  wraps, no VFX, standing-guard pose in 7/8) are kept as the clean-base alternatives if we revisit.
- **⚠️ Pose inconsistency to resolve when wiring in:** FANG's locked asset = a crouched action-pounce;
  ZERO's = an upright floating idle. If a NEUTRAL idle is needed for both (engine anim base), FANG
  may need re-cutting to a standing guard (probes 7/8 already exist). Not blocking - flagged.

### 🔀 2026-07-03 (later) - PIVOT UNDER EXPLORATION: 3D CHARACTER PIPELINE (Aviv-driven)
The 2D-sprite plan above may be superseded. Trigger: the mechanics lane opened the iso gate and
asked for a **5-drawings-mirror-3** directional set (ROSTER 2026-07-03). Aviv found the fatal flaw:
**mirroring flips asymmetric identity** - ZERO's half-ice face + single human arm would swap sides.
Fix Aviv chose: **make a real 3D character** (consistency + asymmetry solved from every angle).
- **Reverses a HANDOFF locked decision** ("no real 3D pipeline = the scope this project refuses").
  Opened knowingly. Framed as: chase Overwatch's **quality bar on a slice**, NOT its scale.
- **✅ Image-to-3D VALIDATED** (Magnific `models3d_generate`, `tripo-v31` + detailed texture): the
  earlier "Tripo flattens" verdict is OBSOLETE - it now returns a solid, recognizable, **auto-rigged**
  T-pose GLB. Two proofs in `concept/characters/fang/`: `FANG_3d_v2_tripo.glb` (from the clean
  standing probe) and `FANG_hero_3d_v1.glb` (from the new hero concept). Front reads great; back =
  AI-guessed texture, judge in a 3D viewer.
- **✅ FANG HERO REDESIGN LOCKED (Aviv, "concept 1"):** the plain tank-top look → a **designed
  hero** (Overwatch/Paladins language) with a **bone / predator-hunter motif** (bone shoulder plate,
  bone belt buckle, claw-bone gauntlets) over an orange+charcoal fitted combat suit. Concept =
  `concept/characters/fang/fang_hero_concept_1.jpg`. This is the new visual FANG (identity/story in
  FANG.md unchanged - only the LOOK leveled up). `fang_hero_concept_2.jpg` (tech-hero) = rejected.
- **✅ FORK DECIDED (Aviv, 2026-07-03): REAL 3D GAME.** The 3D model is the actual in-game object -
  engine goes 3D + iso camera (the Overwatch-true path). This kills the entire 5-view sprite-switching
  / mirror-asymmetry problem (rotation is free in 3D). **This is the biggest decision in the project's
  history and it is MECHANICS-LANE territory to execute** (their 2D render/motion layer gets rebuilt;
  core logic - positions/velocities/combat/net - survives on a 3D floor). Flagged to them in ROSTER.
  - **⚠️ SCOPE DISCIPLINE (agreed framing):** "3D like Overwatch" = the exact scope-death HANDOFF
    warns of. Guard: **prove the 3D game is FUN with the ROUGH auto-rigged model FIRST** (mechanics
    drops the GLB into a simple 3D iso arena, feel-test the fight) BEFORE investing in Overwatch-quality
    topology/rig/animation. Find-the-fun, applied to the 3D pivot. Fun first, polish later.
- Pipeline map being walked: concept → clean ref → 3D base ✅ → sculpt/cleanup → texture → rig ✅(auto)
  → animate → Godot integration → VFX/polish (fire+shadow = runtime layer, NOT baked).

#### 2026-07-03 (night) - IMAGE-TO-3D ENGINE CHOICE RULE (from the ZERO asymmetry audit)
Audited `ZERO_hero_3d_v1.glb` by rendering 12 angles in Godot (tool: `concept/_tmp_asym_check.gd`).
Result: **Tripo (tripo-v31) SYMMETRIZES ARMS** - ZERO's full cosmic-ice arm became skin+gauntlet on
both sides, in BOTH attempts (portrait source AND open-A-pose `ZERO_rigpose_FINAL.png` source). Face
patch + exposed-pec asymmetry partially survive; whole-limb texture identity does not.
**trellis-2 (res 1024) PRESERVED the full asymmetry** on the first try - but returns an UNRIGGED
mesh (no skins/joints), and `models3d_rig` is not exposed in the Magnific MCP yet.
**RULE for future characters:**
- Near-symmetric character (like FANG) → **tripo-v31** (auto-rigged T-pose GLB, one step).
- Asymmetric identity (like ZERO, and most "human remnant" designs) → **trellis-2 for look-truth**,
  rig as a separate step (external auto-rig / Tripo rig API / Magnific when the rig tool ships).
- Always audit a new GLB with the 12-angle render BEFORE calling it done - the front thumb lies.
ZERO file state: `ZERO_hero_3d_v3_trellis.glb` = identity-proof only (unrigged, **quality
REJECTED by Aviv** - mushy face/melted detail); `ZERO_hero_3d_v1.glb` = rigged-but-identity-broken;
`ZERO_hero_3d_v2.glb` = failed evidence only.

#### 🔄 2026-07-03 (night, later) - VISUAL-DESIGN REWORK DECLARED (Aviv) - THIS SECTION FROZEN
ZERO v3's quality fail triggered a bigger call: **Aviv is reworking the game's entire visual
design and will supply REFERENCES for the target look.** Until those land: no new generations,
no new 3D models, nothing "final" derived from this pipeline section. Open option raised by
Aviv: keep 3D models only as **direction-image exporters** (consistent multi-angle renders
feeding a 2D pipeline) - trellis-2 solves the asymmetry-mirror flaw that killed multi-view
drawing before, so that path is viable again. Lesson locked: single-image 3D generation gives
identity OR crispness, not both - quality was always going to come from a real game-ready pass,
or from a different art direction. Waiting on Aviv's references.

### 🎨 2026-07-03 (night, later) - REWORK v2 BRIEF: Aviv's references landed
Two references, one axis between them:
- **Ref 1 = Survival Project screenshots** (2D chibi anime arena). Aviv KEEPS: anime look, the
  charm, the top-down readable arena, the simplicity ("אין לי בעיה שזה כזה פשוט"). Aviv REJECTS:
  too cute for his taste and for today's games market.
- **Ref 2 = a 3D anime-painterly action game** (cel/flat-shaded character, painterly grass,
  strong flat cast shadow, hand-drawn-style swoosh VFX, saturated but grounded palette).
  Aviv KEEPS: more serious, yet still radiating anime + a hand-painted feel.
- **Target = in between.** Analysis (concept lane): the refs answer different questions -
  Ref 1 gives camera/scale/simplicity, Ref 2 gives the FINISH (painterly cel 3D). The real
  dial between them = **character proportion + tone**: chibi-cute (SP) ←→ serious anime (Ref 2).
  Note: much of Ref 2's "seriousness" comes from VFX + shadow, which in our stack is the
  RUNTIME juice layer (already locked as engine-side, not baked) - so the character can sit
  softer than Ref 2 and the game still reads serious.
- **Method: style-dial probe ladder.** Same scene (FANG in our top-down arena), 3 points on
  the dial: A=SP-adjacent (chibi-plus, ~3.5 heads) · B=midpoint (~4.5-5 heads, heroic-soft)
  · C=Ref2-adjacent (~6 heads, serious anime). Aviv points, the pick becomes the NEW in-game
  style anchor (supersedes `fang_ingame_owprobe_2` and the whole §second-art-layer anchor).
  Probes = look-target images only, NOT assets - the render path (real 3D model vs 3D-as-
  view-exporter vs 2D) is decided AFTER the look is locked, with mechanics.

### ✅✅ 2026-07-05 - IN-GAME LOOK RE-LOCKED (Aviv): "COLLECTIBLE-TOY 3D" (supersedes chibi-plus)

**Aviv's ruling: "אני אחליף את כל הדמויות מעכשיו והלאה לסגנון הזה. התואם את פאנג החדש - לא צ'יבי יותר."**

- **THE STYLE ANCHOR (roster-wide) = `concept/characters/fang/explorations/fang_soulprompt_r2_v4.jpg`**
  (= FANG's new chosen design, "ככה נראה גיבור"). The image is the truth, not a style name.
- What actually moved vs chibi-plus (read off the anchor): still big-head toy proportions
  (~4-4.5 heads, slightly taller than the 3.5 chibi), but the FINISH jumped from flat-cute toon
  to **collectible-figure realism of materials**: real fabric weave/patches/stitching, worn
  leather, rope, metal grommets, fur with actual strands, PBR-like studio lighting on a neutral
  backdrop. Detail-density is the point - "savable as a real toy you could buy."
- **Face rule (UPDATED 2026-07-05 evening):** the full-tiger-face amendment was RESCINDED - Aviv
  confirmed r2_v4 AS-IS including its boyish tiger face. Face register per character = whatever
  the character's chosen design image shows; menace/warmth carried by EXPRESSION either way.
- **SUPERSEDED:** the chibi-plus anchors `fang_styledial_A_attack.jpg` + `zero_chibiplus_cold_2.jpg`
  (2026-07-03 lock below) = archived as design. `fang_styledial_A_attack` keeps NO style role
  anymore (it was already archived as FANG design same day).
- **⚠️ DOWNSTREAM COST (acknowledged):** `ZERO_chibi_3d_*` + `ATLAS_chibi_3d_*` models are now
  OFF-STYLE (stay wired in-game until replacements land - same rule as FANG's old GLB).
- **⚠️ GATE BEFORE MASS-PRODUCTION (GameOS lesson, unchanged):** ROSTER TEST - prove the new
  style carries a cold/menacing character (ZERO probe in the r2_v4 finish) before generating
  the full roster. A hero-warm style that can't do villain-cold fails the lock.
- Generation recipe: soul-prompt (concept/SOUL-PROMPT.md) + this anchor as `image` reference
  for finish/proportions. 12-angle audit + Tripo path per §3D rules still apply.
- **⚠️ ENGINE RULE UPDATE (2026-07-06, FANG r2_v4 conversion - FINAL RECIPE):** for THIS
  detail-dense style, TWO flags are MANDATORY together, proven by elimination on the same A-pose:
  1. `texture_quality: "detailed"` - standard mushed the identity hotspots (amber eyes went
     grey-glass, fangs smeared, patches blurred); detailed restored ALL of them.
  2. `model_version: "v3.0-20250812"` - the direct-API DEFAULT is an older engine and mushes
     even WITH the detailed flag (the failed v3 run). v3.0 + detailed = Magnific-tripo-v31-grade.
  Also proven: `animate_rig` does NOT degrade the texture (pre-rig vs rigged identical), and
  `face_limit` 18000 keeps full quality. Recipe = `tools/tripo/tripo_pipeline.py <image> <out.glb>
  18000 detailed` (v3.0 is its default now; saves a .prerig.glb intermediate for QA).
  The style itself SURVIVES image-to-3D - the old "detail = mush" fear is dead with both flags set.
  Live proof: `fang/FANG_r2v4_3d_v4_rigged.glb` (3.3MB, rigged, wired into game3d).

### ✅ 2026-07-03 (night) - NEW IN-GAME LOOK LOCKED (Aviv): "CHIBI-PLUS 3D-TOON"
**THE TWO STYLE ANCHORS (Aviv-confirmed, final):**
- **FANG = `concept/rework/fang_styledial_A_attack.jpg`**
- **ZERO = `concept/rework/zero_chibiplus_cold_2.jpg`**
These two images ARE the style truth for the whole roster. Every future asset matches their
proportion + finish. (The clean-canonical neutral-pose pass `fang_canonical_*` / `zero_canonical_*`
was REJECTED by Aviv - full-body framing drifted the proportions taller/flatter; kept as evidence
of the drift, NOT anchors.)

**Anchor = `concept/rework/fang_styledial_A_attack.jpg`** (Aviv: "זה הסגנון שאני רוצה").
Round-2 examples (FANG attack + ZERO roster-test in A and B) are in `concept/rework/`.
This SUPERSEDES `fang_ingame_owprobe_2` and the whole "Overwatch as sprites" §second-art-layer
anchor. Characteristics to hold in every future render:
- **Proportions ~3.5 heads**, big expressive head, rounded soft shapes, chunky hands/feet.
- **Finish = glossy 3D-toon render** (Dragon-Quest/Ni-no-Kuni-adjacent), NOT flat 2D cel -
  soft rounded shading, crisp rim highlights, painterly bright arena ground.
- **Palette bright + saturated, cute-but-fierce energy.** Hand-drawn swoosh VFX stays (runtime).
- **⚠️ ZERO GUARD (from the failed A-probe):** chibi proportions must NOT soften ZERO's locked
  identity - cold, unsmiling, malevolent-calm face, ice visibly CONSUMING the half-face, human
  arm + exposed chest asymmetry present. A menacing chibi is achievable (boss-chibi tone) -
  a happy-kid ZERO is a REJECT. `zero_styledial_A_float.jpg` = the recorded failure example.
- **Implication for the 3D pivot (flag to mechanics):** `FANG_hero_3d_v1.glb` (6-heads serious)
  no longer matches the target look - fine for the FUN-TEST (fun is mechanics, not look), but
  the eventual in-game model/asset must be rebuilt to chibi-plus proportions. Do not polish
  the current GLBs toward final art.
- **✅ RENDER-PATH DE-RISKED (2026-07-03 night): the locked chibi look converts CLEANLY to 3D.**
  After the mechanics fun-test passed (3D combat locked), tested whether the new look can become
  a real in-game model. Generated a clean chibi A-pose (`concept/rework/fang_chibi_apose_1.jpg`)
  → Tripo-v31 → **`concept/characters/fang/FANG_chibi_3d_v1.glb` (rigged, skins+joints).**
  12-angle audit = clean from every side, identity + glossy-toy finish held, face crisp. This is
  the OPPOSITE of the detailed-ZERO mush - **chibi rounded forms are exactly what image-to-3D
  handles well.** So: real-3D path is VIABLE for the locked look; this GLB can replace the
  off-style 6-head `FANG_hero_3d_v1.glb` in mechanics' `game3d`. (⏳ Aviv approval on the model.)
  ZERO's asymmetry, once redone in chibi, should also convert far better than the detailed v1 did.
- **✅ ZERO CHIBI ALSO CONVERTS CLEAN - AND ASYMMETRY SURVIVED TRIPO THIS TIME.** Generated a
  chibi A-pose FROM the locked `zero_chibiplus_cold_2` anchor (NOT the tall portrait - first
  A-pose attempt off the portrait drifted adult/tall; using the chibi anchor fixed it) →
  `zero_chibi_apose_3.jpg` → Tripo-v31 → `concept/characters/zero/ZERO_chibi_3d_v1.glb`.
  12-angle audit: ice-side vs human-arm/exposed-chest asymmetry + half-ice face HELD. **Why Tripo
  held it here but symmetrized the detailed portrait: the chibi image has BOLD solid asymmetry
  cues (solid blue-ice half vs solid flesh half) - Tripo reads those; subtle detailed asymmetry
  it averages away.** REFINES the engine rule: for asymmetric chibi with bold blocked cues,
  Tripo can work - audit to confirm. **Known downstream gaps (not blockers): this GLB is UNRIGGED
  (Tripo returned model.glb, no auto-rig) and HEAVY (~57MB) - needs external auto-rig + decimation
  before game-ready.** FANG's chibi GLB is rigged + light (1.4MB); ZERO needs those two steps.
- **✅ ZERO rig+decimate SOLVED via the Tripo API directly (2026-07-03, Aviv supplied a key,
  stored in `.env.local` = gitignored).** The Magnific MCP wrapper hid Tripo's rig/decimate; the
  raw API exposes them. Flow that gives a game-ready asset in one pass:
  `POST /task image_to_model` with `face_limit` (e.g. 18000) → `animate_prerigcheck` →
  `animate_rig` (out_format glb) → download. Result `ZERO_chibi_3d_v2_rigged.glb`: **rigged
  (skins+joints), ~1MB (was 57MB), asymmetry INTACT.** The heavy unrigged v1 was removed.
  **ENGINE RULE UPDATE: for a game-ready chibi model, use the Tripo API (face_limit + animate_rig),
  not the Magnific wrapper** - same quality, controllable poly budget, real rig. Magnific still
  fine for quick look-probes. (Animations NOT applied - see the deferred-animation scope note.)
- **NEXT (Aviv, "clean the look first"):** before touching the render-path/3D question, produce
  CLEAN CANONICAL anchors of FANG + ZERO in this locked style - full-body readable stance,
  minimal ground, background-removable - as the definitive style reference set. Generated per
  the anti-bleed method (each from its OWN identity portrait + text finish, NO shared image
  style-anchor). Working set in `concept/rework/`.
