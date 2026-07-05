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
- `concept/SOUL-PROMPT.md` - design-exploration prompts from the character's SOUL only (zero
  visual language, style-register locked, emotion written as render-able physical cues, iterate
  via liked-image reference). Aviv-validated on FANG 2026-07-05.
- `ROSTER.md` - cross-chat character status bridge (who owns what, what stage each char is at).
- `tools/anim-forge/` - animation blocking pipeline: Aviv briefs a motion in words -> JSON spec ->
  forge builds the clip in Blender headless -> preview gif auto-opens -> dial in words -> Blender
  only for taste-polish. Proven on FANG's crouch idle 2026-07-05. (brief template in its README)
- **Generation pipeline** - Magnific MCP: Nano Banana Pro + the character's anchor as an image
  reference = consistency; `images_remove_background` -> transparent cutout. Fallback: gpt-image-1.
- `CONCEPT.md` / `DESIGN.md` / `VISION.md` - world+identity / combat-feel / systems (pre-existing).

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
- **AI-3D (Tripo via Magnific `models3d_generate`) tested on FANG (2026-06-30):** it produces a
  recognizable, auto-RIGGED 3D model fast and keeps the character's identity well - BUT it
  **flattens the locked 2D Guilty-Gear style** into a generic smooth AI-3D look. Verdict: NOT a
  fit for our 2D cutout pipeline (it would only make sense under a 3D-rendered art direction).
  Tripo IS available now (it's the `models3d_generate` backend) - park it for possible pose/prop
  reference or a future 3D pivot, not for the current look. Test files:
  `concept/characters/fang/FANG_3d_test.glb` + `FANG_3d_preview.png`.

## How it grows
End of any work: if a pattern repeated, a fix worked, or a mistake taught something -> fold it into
a module above or add a line to the lessons log. When a new asset type appears (a map, a VFX, an
animation set), write its standard+template the first real time, then reuse forever.
