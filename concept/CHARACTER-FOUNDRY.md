# CHARACTER FOUNDRY - the character-to-animation pipeline (GameOS module)

Locked with Aviv 2026-07-05 ("יאללה"). One pipeline, six stations: from an empty character slot
to accurate in-game animation - with Aviv's time spent on TASTE DECISIONS (picking from images,
dialing in words), never on production labor. Blender appears only at the very end, as polish.

**The accuracy doctrine (why the first draft comes out close):**
1. **The bible IS the animation spec.** CHARACTER-METHOD Layer 6b maps every engine action
   (idle/move/wind-up/attack/skill/block/hit/knockback/win/lose) to described motion flavor,
   with reasons. Station 4-5 derive from it - they never invent.
2. **The engine owns the timings.** Clip timings come from the game's combat constants
   (fighter.gd: wind-up 0.08s, swing 0.12s, lunge 0.20s...) so animation is born synced to
   gameplay feel - studio practice, and it kills a whole class of "feels off" iterations.
3. **Aviv chooses from pictures, never from parameters.** Style-dial proved it; poses and
   motion previews work the same way (galleries + gifs, dial in words).
4. **Every station's output is a saved, reusable file.** Character N+1 starts from character
   N's specs. FANG paves for ZERO; by character 5 the foundry is mostly editing.

## The stations

**1. SOUL -> DESIGN** (exists: `concept/SOUL-PROMPT.md`)
Bible seed -> soul-prompt (idea-only, style-register locked) -> gallery -> Aviv picks ->
iterate with liked-image reference. Output: chosen design image (canon direction).
Proven: FANG r2_v4. Gate: roster-test a new STYLE before mass production (STYLE-GUIDE).

**2. DESIGN -> RIGGED MODEL** (exists: STYLE-GUIDE §3D engine rules)
Chosen design -> clean A-pose render (from the chibi... now toy-3D anchor, per style) ->
12-angle audit -> Tripo API (face_limit + animate_rig) -> rigged GLB.
Output: `<CHAR>_3d_vN.glb` rigged. Known: symmetric->tripo, asymmetric->trellis+rig path.

**3. RIG-DOCTOR** (TO BUILD - half exists as session scripts)
Automated rig QA + repair after Tripo, because auto-rig is never clean:
- **Coverage audit:** find mesh regions with no matching bone (FANG's tail had NONE - Tripo
  rigs humanoids only). Auto-build missing chains (tail/ears/cape) + proximity weights with
  smooth root-blend. (Done by hand 2026-07-05: Tail01-03, 325 verts, seam-free.)
- **Weight audit:** vertices far from their dominant bone = mis-binds (FANG's "black splinter
  foot" = tail verts bound to foot bones). Auto-reassign + verify.
- **Proof renders:** worst-case frames before/after, auto-compared.
Output: `<CHAR>_3d_vN_fixed.blend` + audit report. Build trigger: ZERO's model (57MB, unrigged,
asymmetric - the perfect hard case).

**4. POSE-CAST** (TO BUILD - the creative station)
The A-pose -> signature-stance gap, solved as a CASTING, not sculpting:
- Read the character's stance language from bible Layer 6b (FANG: "low, coiled, pounce-ready,
  tail up, ears forward" - his signature silhouette).
- Claude builds 2-3 stance variants as pose-dial JSONs (like the crouch iterations 2026-07-05),
  renders stills, Aviv PICKS FROM IMAGES (exactly like style-dial).
- Chosen stance = the character's `base_pose` spec, feeding every clip in station 5.
Output: `tools/anim-forge/specs/<char>_stance.json` + the losing variants kept as spice.

**5. ANIM-FORGE v2** (v1 exists: `tools/anim-forge/`)
v1 = base_pose + oscillator layers -> living idle (proven on FANG's crouch).
v2 adds **pose sequences** for walk/attack/hit: keyed poses at beats, with beat timings PULLED
FROM THE ENGINE'S COMBAT CONSTANTS (doctrine #2). An attack clip = stance -> wind-up pose
(0.08s, from Layer 6b: "weight coils onto the back leg, tail lashes up") -> strike pose
(0.12s) -> recover. The clip is born matching the sim.
Output: named clips per the mechanics contract (`idle`/`walk`/`attack`, lowercase, in-place,
same rig) + GLB export. Build trigger: first walk/attack rework (post style refresh).

**6. GATE -> POLISH -> HANDOFF** (exists, proven all day 2026-07-05)
Preview gif auto-opens on Aviv's screen -> dial in words (cheap rounds) -> ONLY when right,
Aviv opens Blender for taste polish (the file is normal keyframes) -> GLB lands in the repo ->
ROSTER ping to mechanics. Live-judge in game3d stays the final gate - a gif approves a draft,
only the game approves a clip.

## Status (2026-07-05)

| Station | State |
|---|---|
| 1 Soul->Design | ✅ proven (FANG r2_v4) |
| 2 Design->Model | ✅ recipe locked (STYLE-GUIDE §3D) - rerun needed for new-style FANG |
| 3 Rig-Doctor | 🔨 half-built (tail-chain + weight-audit scripts exist ad-hoc) - formalize on ZERO |
| 4 Pose-Cast | ⬜ method defined - first run: FANG stance variants (crouch spec = variant #1) |
| 5 Forge v2 | 🔨 v1 shipped - sequences on first walk/attack rework |
| 6 Gate->Handoff | ✅ proven (crouch idle end-to-end) |

Next real-world run of the foundry: **ZERO in the new style** (after the roster-test gate) -
it exercises stations 1-3 hard (asymmetric, floating, unrigged model) and will force-build
Rig-Doctor properly.
