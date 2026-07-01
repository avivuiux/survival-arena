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

## Status
- 2026-07-01: guide written. **ZERO re-rendered to this finish + adopted = `zero_final_2.png`**
  (matched to FANG's cel look; fixed the painterly drift). FANG's styleB anchor
  (`fang_styleB_digitigrade_1.png`) is the mandatory `style` reference for all future characters.
