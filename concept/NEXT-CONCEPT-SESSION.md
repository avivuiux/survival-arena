# Next concept/design session - continuation prompt

Continue the concept/design lane of survival-arena (repo: `dev\survival-arena`).
Read first: `GDD.md` (the full game deep-spec + §WORK SPLIT) · `ROSTER.md` (Last update) ·
`concept/SOUL-PROMPT.md` (the finalized prompt method) · `concept/STYLE-GUIDE.md §engine-rule` ·
`concept/characters/lightknight/` (the new tank).

## State (2026-07-07 "ארוז")
- **Vision = action-MOBA** (Battlerite x Survival Project). Full GDD complete (Stages 0-6). The
  mechanics chat is implementing the 3v3 match loop from GDD Stage 2 (they own `scripts/`; we do
  NOT touch it). Contract = `GDD.md`.
- **Roster (all wired in game3d, live-approved):** FANG (rusher, `FANG_r2v4_3d_v4_rigged.glb`),
  ZERO (control, `ZERO_r2_3d_v1_rigged.glb`), **light-knight (tank, replaced ATLAS,
  `LIGHTKNIGHT_3d_v2_magnific.glb`)**.
- **Prompt method locked** (SOUL-PROMPT.md): FANG/ZERO image = style anchor (not words); dry tag
  catalog; concept-first (free prompt -> restyle to our look -> 3D); **IRON RULE: always show the
  prompt and get Aviv's explicit go before ANY generation.**
- **3D recipe:** ornate characters -> Magnific `models3d_generate` tripo-v31 + detailed (beats the
  direct-API pipeline; returns rigged + light). Simple ones -> `tools/tripo/tripo_pipeline.py`.

## Open threads (pick per Aviv, prioritize don't enumerate)
1. **Animation (Aviv films himself for mocap ~2026-07-08):** pipeline = unified skeleton (Mixamo)
   -> base clips (Mixamo) -> signature moves (AI video-mocap: Rokoko/Move.ai/DeepMotion) ->
   Blender = polish only. game3d still plays transform-juice; needs a clip-playback layer (that's
   mechanics-lane when clips land).
2. **Arena lighting upgrade** - reflection probe + rim + bloom so materials pop (whole roster).
   Proven in a throwaway render; not yet in game3d's environment.
3. **Light-knight Studio card + bible** - she replaced ATLAS but has no card/bible yet.
4. GDD is complete; extend only if a new design question opens.

Source of truth = the repo (GDD.md / SOUL-PROMPT.md / ROSTER.md / STYLE-GUIDE.md). Cut from there.
