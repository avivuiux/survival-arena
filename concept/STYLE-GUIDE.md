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
  finish standard for the in-game layer. **In-game style anchor = `fang_ingame_owprobe_2`
  (Aviv's explicit pick)** (pass as reference on every in-game-layer generation, same
  enforcement as the portrait anchor). Approved = finish/quality only - NOT the camera angle (mechanics decides) and
  NOT yet validated on the dark arena floor. Known fix for next round: the fist hand-wraps
  rendered with stray colors - prompt "clean orange hand-wraps".
- Rejected for this layer: Little Fighter chunky-2D, portrait-cel-shrunk (tested in-arena
  2026-07-02 as `FANG_arena_v1.png` = kept as baseline/archive only), real-3D-in-engine.
- **✅ ROSTER COHESION PROVEN (2026-07-02): the look holds on ZERO** (`concept/characters/zero/
  zero_ingame_owprobe_2.jpg`) - translucent cosmic ice in the same finish, reads as one game.
- **⚠️ IDENTITY-BLEED GUARD (learned on ZERO probe 1, discarded):** passing another character's
  probe as the `style` reference can leak that character's IDENTITY (probe 1 came out with
  FANG's orange body + fists). On every non-FANG generation, add an explicit palette guard to
  the prompt (e.g. "only icy blue/white/silver palette, NO orange") and eyeball for bleed.
- Known identity fixes for ZERO's next round: restore the human ARM remnant + the exposed
  human CHEST (bible: remnant = half face + one arm + chest; probe 2 has face only).

## Status
- 2026-07-01: guide written. **ZERO re-rendered to this finish + adopted = `zero_final_2.png`**
  (matched to FANG's cel look; fixed the painterly drift). FANG's styleB anchor
  (`fang_styleB_digitigrade_1.png`) is the mandatory `style` reference for all future characters.
