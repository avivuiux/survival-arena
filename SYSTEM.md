# GameOS (working name) - our system for making games

Inspired by **ai-os** and **Design OS**, but for **building games**. The idea Aviv set as a
standing directive (2026-06-30): every repeatable thing we figure out - a method, a standard, a
prompt template, a fix, a hard-won lesson - becomes a reusable **module** here, so the next
character / map / feature is faster and better. It's part fun (a potential project of its own),
part leverage (it compounds). **Claude proactively proposes and builds expansions to this system,
at the highest level, whenever an opportunity, a learning, or a mistake appears.** Portable: meant
to outgrow this one game.

## Principles (the spine)
- **Vertical slice + find-the-fun** - prove ONE before scaling (from DESIGN/VISION).
- **Depth first** - every choice traces to a reason (CHARACTER-METHOD's iron rule).
- **Standards + templates over one-offs** - reusable, roster-consistent (RIGPOSE-STANDARD).
- **Human gates on direction/taste** - never decide a creative direction or burn credits alone;
  show pictures, not jargon, when Aviv doesn't think in style-names.
- **Show before spend; live-validate before "done."**
- **One shared truth across the parallel chats** (ROSTER bridges concept <-> mechanics).

## Modules (what exists now)
- `concept/CHARACTER-METHOD.md` - character deep-dive **v2** (pitch + 9 layers + adversary gate).
- `concept/CHARACTER-ATTRIBUTES.md` - classification schema (12 tag-axes) + roster matrix for
  uniqueness / consistency / variety / gap-spotting.
- `concept/ART-DEPTH.md` - art-mining pass (10 buckets) to extract rich, detailed visual ideas.
- `concept/RIGPOSE-STANDARD.md` - rig-ready pose checklist + the reusable rig-pose PROMPT TEMPLATE.
- `concept/CHARACTER-FOUNDRY.md` - THE character-to-animation pipeline (6 stations: soul->design
  -> model -> rig-doctor -> pose-cast -> forge-v2 -> gate/handoff). Accuracy doctrine: bible
  Layer-6b = the animation spec, engine combat constants = the timings, Aviv picks from images.
  Locked 2026-07-05; stations 3-5 get built against ZERO's rework.
- `concept/SOUL-PROMPT.md` - THE prompt method (matured 2026-07-06/07): **style locked via a
  FANG/ZERO image reference, NOT words** · **dry tag catalog, not prose** (Superpower-Wiki terms) ·
  **concept-first pipeline** (free concept image -> restyle to our look -> 3D) · **IRON RULE: show
  the prompt + get Aviv's explicit go before ANY generation.**
- `GDD.md` - the full game design (action-MOBA, Stages 0-6). Design-lane owned; mechanics reads it.
- `ROSTER.md` - cross-chat character status bridge. `GLOSSARY.md` - two-chat rules + vocabulary.
- `tools/character-studio/` - the roster/design workspace (tabbed dossier / live prompt-builder /
  story; powers/composition/aesthetic fields; Prompt Lab word-swap tool; create wizard).
- `tools/tripo/tripo_pipeline.py` - direct Tripo API: A-pose image -> rigged GLB (v3.0 + detailed
  texture). For ORNATE characters, Magnific `models3d_generate` **tripo-v31 + detailed** beats it
  (rigged + light in one pass).
- `tools/anim-forge/` - animation blocking (words -> spec -> Blender clip -> gif). ANIMATION NEXT:
  mocap pipeline = unified skeleton (Mixamo) -> base clips (Mixamo) -> signature moves (AI
  video-mocap) -> Blender = polish only.
- `CONCEPT.md` / `DESIGN.md` / `VISION.md` - world+identity / combat-feel one-pager / systems.

## Modules to build (as they become needed - not before)
- Arena / environment pipeline (maps). · VFX + juice standard (skill effects, impact). ·
  Animation-set standard (which clips every rig needs). · Audio/SFX. · UI/HUD kit.
  Each gets a standard + template the first time we do it for real, then is reused.

## Lessons log (grows every session - the "learn from cases & mistakes" engine)
- **gpt-image-1 won't draw true digitigrade legs on a humanoid from text** (failed ~5x) ->
  use a reference image (`images.edit`) or Nano Banana Pro with the anchor.
- **Character consistency** = generate WITH the locked anchor as an `image` reference, never from
  text alone. Nano Banana Pro nailed what gpt-image couldn't.
- **Validate one full character end-to-end before building the roster** (we did FANG; ZERO tests
  whether the system generalizes to a different kind of being).
- **Reopening a "locked" decision is cheap if the deep design is style-agnostic** - the bible
  survived the art-style pivot; only the "skin" changed.
- **When the user can't judge style-names, render the SAME subject in N styles and let them react
  to pictures** (that's how the Guilty-Gear direction got chosen).
- **Always keep a backup generator wired** - OpenAI hit its billing cap mid-session; Magnific
  saved it. Don't depend on one vendor.
- **⚠️ SUPERSEDED (the 2D->3D pivot happened):** the old lesson "Tripo flattens our 2D
  Guilty-Gear style, not a fit" is DEAD. **The game is now full 3D** (real-3D-game pivot, Aviv
  2026-07-03). Tripo / Magnific-tripo-v31 image-to-3D is THE core asset pipeline, not a parked
  option. The 2D-cutout / Skeleton2D pipeline no longer exists.
- **3D conversion lessons:** detailed characters need `texture_quality: detailed` + a recent engine
  (direct API v3.0, or better: Magnific tripo-v31) or the identity mushes. Translucent/thin geometry
  (ice, wings) is the hard case - avoid it in the design or expect cleanup. Style stays coherent by
  restyling the concept to FANG/ZERO's look BEFORE the 3D step, and locking style via image reference.
- **Concept-first beats style-anchored generation for creativity:** generate the concept FREELY
  (any style), THEN restyle into our look. Anchoring style in the first pass flattens the idea.
- **Reference the source honestly:** Survival Project itself was a proto-MOBA (validated our
  action-MOBA vision); its pay-to-win + slippy controls are anti-lessons (see `GDD.md`).

## How it grows
End of any work: if a pattern repeated, a fix worked, or a mistake taught something -> fold it into
a module above or add a line to the lessons log. When a new asset type appears (a map, a VFX, an
animation set), write its standard+template the first real time, then reuse forever.
