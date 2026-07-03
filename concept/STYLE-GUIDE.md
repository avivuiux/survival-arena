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
ZERO file state: `ZERO_hero_3d_v3_trellis.glb` = look-truth (unrigged, ⏳ Aviv approval);
`ZERO_hero_3d_v1.glb` = rigged-but-identity-broken; `ZERO_hero_3d_v2.glb` = failed evidence only.
