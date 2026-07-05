# ANIM-FORGE - animation blocking pipeline (GameOS module)

Born 2026-07-05. Goal: **minimize Aviv's Blender time.** Aviv describes a motion in words;
Claude turns it into a spec; the forge builds the clip, exports per the mechanics contract,
and opens a preview gif on Aviv's screen. Iterate in words until close - Blender is only for
the final taste-polish on a base that is already ~90% right.

Mirrors how studios work: **brief -> blocking -> preview -> polish.** The forge owns blocking.

## The pipeline

1. **BRIEF (Aviv, in words)** - fill the template below (or just say it in chat; Claude fills it).
   Write feeling as PHYSICAL, drawable/animatable cues - same principle as
   `concept/SOUL-PROMPT.md` ("weight coils onto the back leg", not "looks ready").
   `concept/<CHAR>.md` Layer 6b (motion characterization) is the source for per-character flavor.
2. **SPEC (Claude)** - translate the brief to a JSON spec in `specs/` (see schema below).
3. **FORGE (automatic)** - `python run.py specs/<name>.json`:
   builds the clip in the .blend -> saves -> exports GLB (if set) -> renders preview ->
   assembles a gif -> **opens it on Aviv's screen.**
4. **DIAL (Aviv, in words)** - "deeper crouch", "tail slower", "head lower" -> Claude edits
   numbers in the spec -> rerun. Cheap, fast, no Blender.
5. **POLISH (Aviv, in Blender)** - only when the base is right. Open the .blend, Pose Mode,
   adjust keys by taste. The clip is normal keyframes - fully editable.

## Brief template (fill what you know, skip the rest)

- **Character + clip:** (FANG / idle)
- **The one sentence:** what is this motion saying? ("coiled predator, never fully still")
- **Body attitude:** low/high? leaning? where is the weight?
- **Head + eyes:** where do they point? (predator = locked forward)
- **Signature parts:** tail/ears/fists - what are they doing?
- **Tempo:** slow breath? restless? explosive?
- **Loop or one-shot:** idle/walk loop; attack = one-shot.
- **Reference feeling:** "like a sprinter in the blocks", "like a cat before a jump" - one image.

## Spec schema (specs/*.json)

- `blend` - the character's .blend (armature + mesh + existing clips).
- `clip` - action name. MECHANICS CONTRACT: exact lowercase names `idle`/`walk`/`attack`
  (loops, attack=one-shot), IN-PLACE (no root translation - the sim moves the character).
- `length` (frames), `fps`, `keys_every` (sample step; 6 = smooth enough).
- `base_pose` - "Bone": [x,y,z] euler degrees. "Bone_loc": [x,y,z] location (e.g. Hip_loc
  lowers the body). Missing bones are reported, not fatal.
- `oscillators` - living-motion layers on top of the base: {bone, axis, amp(deg), period(frames),
  phase(rad), loc:true for location channels}. Phase-lag a chain (tail 0 / -0.9 / -1.8) to make
  a wave TRAVEL - that's what reads as alive.
- `export_glb` - GLB for the game (all named clips export together).
- `preview` {dir, frames, cam: side|front|threeq, size} + `deliver_dir` (an Aviv-reachable
  folder; the gif lands and auto-opens from there).
- `keep_old_as` - archive the current clip under a new name instead of replacing.

## Run

```
cd tools/anim-forge
python run.py specs/fang_idle_crouch.json
```
Blender path override: env `BLENDER_EXE` (default: dev/tools/blender-4.2.3-windows-x64).

## Proven

- 2026-07-05: `specs/fang_idle_crouch.json` = FANG's pounce-ready crouch idle (Aviv-directed),
  rebuilt end-to-end by the forge: clip -> blend -> repo GLB -> gif. Matches the hand-built one.

## Known limits (honest)

- Oscillator layers = idle/breathing-class motion. Walk cycles and attack one-shots need
  keyed pose SEQUENCES (pose A at frame N) - next forge feature when we hit that wall.
- Base rig comes from Tripo auto-rig (41 bones + our Tail01-03). No fingers/ears bones yet.
- Preview gif ~= in-game look, but the real gate stays: judge it in game3d.
