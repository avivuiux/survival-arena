# Rig-ready pose - the STANDARD (every character follows this)

The **rig-ready pose** is the neutral full-body drawing we actually cut into parts and rig as a
2D cutout puppet (Skeleton2D) in Godot. It is NOT the hero/key-art pose. Every character gets one,
to the same spec, so the whole roster cuts + rigs the same way.

**Reference exemplar (THE bar):** `concept/characters/fang/fang_rigpose_clean_2.png` (FANG) -
generated with the template below, neutral A-pose, limbs cleanly separated, tail clear.
**Final rigging source = `concept/characters/fang/FANG_rigpose_FINAL.png`** (same pose, background
removed -> transparent RGBA PNG, the file you actually cut into parts).

## The checklist (a pose passes only if ALL are true)

1. **Neutral & symmetric, front-facing.** A relaxed A-pose: arms held ~30-45° away from the
   torso, elbows soft. Legs ~shoulder-width, roughly parallel, weight even. Aim MORE neutral
   than a fighting stance (caveat #1 on FANG: his is a touch too wide/dynamic).
2. **Hands OPEN.** Fingers relaxed and spread, NOT fists - each finger/hand must cut cleanly.
3. **Every part separated, nothing overlapping.** Clear visible gap between each limb and the
   body, and between limbs. Legs don't cross. **Tail fully out to one side, clear of the legs**
   (caveat #2 on FANG: his tail crosses behind a leg). Dangling bits (banner straps) shouldn't
   lie across other limbs.
4. **All parts fully visible / unoccluded.** Both hands, both feet/paws, both arms, both legs,
   ears, tail, face - each shown complete so it can be cut as one whole piece.
5. **Flat even neutral lighting.** No dramatic rim/cast shadows baked in. The style's cel-shading
   is fine (it travels with each cut part), but keep it soft and consistent. Ground shadow OK
   only if easy to remove.
6. **Full body, centered, straight-on.** Head-to-paws, nothing cropped, minimal
   foreshortening/perspective.
7. **Plain solid background** -> then run `images_remove_background` for a transparent cutout PNG.
8. **Locked style + identity.** Exact art style (Guilty Gear / arcade-fighter 2D) and the
   character matches their bible + visual anchor.
9. **Generated WITH the character's visual anchor as a reference** (Magnific Nano Banana Pro,
   `references:[{type:image}]`) so it stays consistent across poses and across the roster.

## THE PERFECT RIG-POSE PROMPT TEMPLATE (reuse for every character)

**Settings:** Magnific `images_generate` · `mode: imagen-nano-banana-2` (Nano Banana Pro) ·
`references: [{type:"image", identifier: <character's visual-anchor creation>}]` ·
`aspectRatio: 2:3` · `resolution: 2k` · `count: 2`.

**Prompt** — fill ONLY the `{CHARACTER}` line from the character's bible; keep the rest verbatim:

```
Using the referenced character, keep them EXACTLY identical: same face, body, build, colors,
markings, outfit, signature items and the SAME art style. This is the SAME character — only the
pose changes.

{CHARACTER}: <one line from the bible — species/features, hair, eyes, outfit, signature object,
full-body traits (e.g. beast legs/paws/tail), identity color, and the locked art style>

Redraw them in a clean NEUTRAL RIG-READY reference pose for 2D cutout animation:
- Relaxed straight A-pose, facing forward, symmetric. Arms held about 30-45 degrees out from the
  torso (NOT a wide action or fighting stance), elbows soft.
- HANDS fully OPEN, fingers relaxed and slightly spread - never fists.
- Legs roughly parallel, about shoulder-width, standing straight, weight even on both feet/paws.
- EVERY limb clearly separated from the body and from each other - visible gaps, nothing
  overlapping or crossing.
- Any tail / cape / long hair / straps: extended fully to ONE side, clear of the legs and body,
  NOT crossing any limb, hanging cleanly.
- Even flat neutral lighting, minimal hard shadows.
- FULL BODY head to feet, centered, nothing cropped, straight-on with minimal perspective.
- Plain solid light-gray background. No text, no logos.
```

**Then:** `creations_wait` -> download -> `images_remove_background` -> transparent cutout PNG ->
hand to the mechanics chat for cutting + Skeleton2D rigging.

## How it's produced (tooling, 2026-06-30)
Magnific MCP (claude.ai connector), model `imagen-nano-banana-2` (Nano Banana Pro) - best for
reference-guided character consistency. Flow: upload anchor (`creations_request_upload` -> PUT ->
`creations_finalize_upload`) -> `images_generate` with the anchor as an `image` reference + the
rig-pose prompt -> `creations_wait` -> download -> `images_remove_background`. This replaced
gpt-image-1 (OpenAI billing cap) and solves the character-consistency problem gpt-image couldn't.
