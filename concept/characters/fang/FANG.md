# FANG - character bible

Built via the Character Deep-Dive method (`concept/CHARACTER-METHOD.md`). Iron rule:
every trait traces to a reason (`trait <- because`). LOCKED = Aviv decided; DRAFT = derived,
awaiting his reaction.

One-liner: **the hot-blooded tiger beast-kin rookie - built like a monster, with the warmest
heart in the Circuit.** Signature color: orange (locked since greybox). Mechanics: fast,
hard-hitting, reckless lunge.

**Archetype: RUSHER** (confirmed 2026-06-30, corrected ROSTER's "tank?"). His muscular build
reads big but he plays as a **fast heavyweight** - trades durability for speed, a glass-cannon
bruiser, NOT a slow damage-sponge tank. The lunge = a literal pounce. (ZERO = balanced; the
tank archetype is a future character, not FANG.)

**VISUAL ANCHOR (LOCKED 2026-06-30): `fang_styleB_digitigrade_1.png`** - Aviv: "מושלם".
**CURRENT PORTRAIT (adopted 2026-07-01): `fang_v6_serious_1.png`** - the refined look: serious /
determined stare + a leashed-brutal aura shown as warm fire on the fists (same design, deeper aura).
- **Art style = "Guilty Gear / arcade-fighter 2D"** (bold clean cel-shading, hard rim light,
  sharp confident outlines, saturated high-contrast). Chosen over the old soft `sports-anime`
  after Aviv reviewed FANG rendered in 4 styles (A SF / B Guilty Gear / C comic / D toon).
  See `fang_style_compare.png`. This SUPERSEDES the old Round-5 art direction.
- **Legs = full tiger legs + clawed paws** (furred, striped, athletic/slim below the knee),
  not human-legs-with-paws. (True reverse-joint digitigrade fought the generator for 5 rounds;
  this dynamic-stance render is the one Aviv approved.)
- Human face + tiger ears/fangs/markings, two-tone hair, tail, orange tank, banner-wraps. Orange.
- NOTE: this anchor is a DYNAMIC fighting pose (key-art-ish). The neutral rig-ready pose is DONE:
  **`FANG_rigpose_FINAL.png`** (transparent RGBA cutout, made via the RIGPOSE-STANDARD template +
  Magnific Nano Banana Pro + background removal) = the file the mechanics chat cuts + rigs.
- In-game = this SAME style, cut + rigged as a 2D cutout puppet, seen small from the iso camera.

---

## DESIGN REFRESH (LOCKED, Aviv 2026-07-05 - via the animation/Blender lane)

**New chosen design direction: `explorations/fang_soulprompt_r2_v4.jpg`** ("ככה נראה גיבור") -
picked from a soul-prompt exploration round (see `concept/SOUL-PROMPT.md`; round 1 = idea-only
prompt, round 2 = menace push on round-1 #1 via image reference).

**BIBLE AMENDMENT - THE FACE (supersedes Layer 4's "human face"):** FANG now has a **FULL TIGER
FACE** (beast head, real muzzle, fangs) - Aviv ruled this explicitly when the conflict with the
old "human face + tiger ears/fangs/markings" line was flagged. The imposing-body-vs-warm-soul
tension now lives in EXPRESSION (predator stare + the warning-grin: "the smile of something that
chooses, every second, not to bite") instead of human features. Amber predator eyes stay.
Everything else in r2_v4 rides along: scrappy patched street gear, banner fist-wraps, rope/patch
materials, chibi-plus toy-3D register.

**Downstream (concept lane):** generate the new canonical anchor + A-pose from r2_v4 -> 12-angle
audit -> Tripo (per STYLE-GUIDE §3D engine rules) -> swap the in-game GLB. The current
`FANG_chibi_3d_v1*` assets = the OLD face, still live in-game until the refresh lands.

---

## Layer 1 - THE SEED (LOCKED)

**Built as a monster, heart of gold - and PROUD of the beast.** FANG is a muscular tiger
beast-kin - his body reads *dangerous* at a glance, and most of the world fears him, sees a
monster. But he has the warmest heart in the league. Crucially (Aviv, Layer-2 refinement):
his answer to being feared is NOT "please see I'm not a beast" (that's self-rejection) - it's
**"I AM a beast, I'm proud of it, and I'll make you cheer for one."** He fights loud and warm
to prove a beast can be the hero, not to apologize for being one. The Circuit is the one place
where "being a beast" makes you a star instead of an outcast. (= Naruto's outcast fuel, matured
into self-acceptance. The feral grin is pride, not menace.)

**Refinement (Aviv 2026-07-01) - add weight:** FANG is NOT a clown. Under the warmth is **serious
determination and a genuinely dangerous, brutal power** he keeps leashed. The optimism and his
principles are the leash - he *chooses* to fight with an open heart, but everyone can feel what he
could unleash if he stopped choosing. So his register = warm + principled + optimistic ON TOP of
a real, heavy resolve and latent ferocity. (Makes him read serious and threatening-when-needed,
not just a happy underdog.)

**Why this is the engine:** the whole design is the tension *imposing body vs warm soul* -
"not too scary, not too cute." Scary comes from the build/beast features; warmth comes from
the face/energy/motion. Every later layer serves that tension.

## Layer 2 - THE WOUND & THE WANT (LOCKED)

- **The wound:** feared and shunned his whole life for being a beast-kin - people crossed the
  street, saw a monster before they saw him. He learned to be loud and warm precisely because
  silence let people fill in "monster." <- because Layer 1.
- **The want (LOCKED, Aviv):** not validation ("see me as human") but **self-acceptance + pride
  + lifting his kind.** He wants to make the world *celebrate* beast-kin instead of fear them -
  by being unapologetically, proudly himself. The deeper message = "be proud of what you are."
- **His wish (if he tops the Circuit):** something that uplifts beast-kin / proves one belongs
  at the very top - a collective win, not a personal trophy. <- because the want above.
- **Plot hook (Aviv's note):** this want is built to *anchor other characters and the story* -
  other beast-kin, those who fear them, and FANG's relationship to the legend can all hang off
  "is a beast allowed at the top?" Keep it as a story spine, not a closed personal arc.
- **The fear:** that the fearful are right - that pride is just a mask over the monster. A loss
  threatens this; this is why getting up grinning matters. <- because Layer 1.

## Layer 3 - THE WAY HE FIGHTS (LOCKED)

**Street-polished feral instinct.** Raw predator instinct (pounce, claws, the lunge) sharpened
in hundreds of street fights - not pure-wild, not formally trained. Nobody taught him; the
street did. <- because the runt-of-nobody / self-made underdog and the beast-kin nature.

- **Closes the stance question:** the low, coiled, pounce-ready stance is now *justified* -
  it's predator pounce-readiness, refined by street survival. It directly feeds the existing
  **lunge** mechanic (the lunge IS a literal pounce). <- because Layer 3.
- Combos read scrappy / improvised, never clean kata. <- because street, not dojo.
- What a fight means to him: the one arena where the thing people fear is the thing that wins -
  so every fight is him saying "look at me." <- because Layer 1.

## Layer 4 - THE BODY (LOCKED - derived from 1+3, accepted)

- **Build:** tall, broad, genuinely muscular - a heavyweight predator frame. NOT the runt.
  <- because Layer 1 (the body must read "dangerous" so the warm face can subvert it).
- **Tiger ears** - expressive, pin flat when hurt/angry, swivel to the crowd. <- because
  beast-kin + feeds motion tells (Layer 6).
- **Tail** - reads emotion, lashes when hyped, drops when down. <- because beast-kin + tells.
- **Real oversized canines** visible even neutral - the literal "fang." <- because the name +
  the predator read.
- **Heavy clawed knuckles / hands.** <- because beast + street; explains hard-hitting + a
  raking lunge.
- **Eyes:** amber/gold slit predator eyes, but kept *wide and open* (not narrowed). <- because
  beast (slit) subverted by heart-of-gold (open, warm).
- **Natural orange-black tiger fur-markings** on face/forearms (NOT dye). <- because beast-kin
  replaces the old "dyed stripe"; carries the locked orange identity.
- **Honest scars** (brow, knuckles), not pristine. <- because hundreds of street fights.
- **Silhouette test:** big predator outline + ears + tail = instantly "the tiger guy" at a
  glance. <- because pillar #1 readable.

## Layer 5 - THE SURFACE (LOCKED)

- **Gear = self-made / scavenged street**, practical, layered, worn - deliberately NOT a clean
  sports kit (that look belongs to ZERO's polished world). <- because mixed-world + "made his
  own gear" + underdog with no sponsor.
- **Drop the plain tank + "FANG" text.** Identity now lives in the body, not a logo. <- because
  text warps on a deforming mesh + Layer 1 (identity is who he is).
- **Signature story-bearing object (LOCKED, Aviv):** **hand-wraps torn from a discarded
  champion's banner.** A nobody literally wrapping his fists in the dream he's chasing - and
  it doubles as the wrapping on his fighting fists. <- ties straight to "topple the legend,
  claim the wish" + the self-made/scavenged street gear. This is the detail people remember.
- **Default expression:** a grin a hair too wide - warmth worn loud. <- because Layer 1.
- **Palette:** orange + black (tiger), warm-orange impact-glow on lunges only (glow in motion,
  per Round 5). <- because locked identity + readability.

## Layer 6 - THE VIBE IN MOTION (LOCKED - derived, accepted)

### 6a. Original vibe beats (kept)
- **Plays to the crowd:** grins, points, salutes. <- because he wants to be *seen* (Layer 1/2).
- **On a big hit / win:** roars, fist to chest. <- because beast joy unleashed.
- **On a loss / hurt:** ears pin flat, tail drops - then gets up grinning anyway. <- because
  this is the tell that subverts the monster; vulnerability + heart (Layer 1, the fear).

### 6b. MOTION CHARACTERIZATION - per real engine action (deepened 2026-07-04)
Mapped to the action vocabulary the engine ALREADY runs (`entities/fighter/fighter.gd`), so this
is an animation/VFX brief, not fiction. Each character inherits the same PROVEN generic procedural
juice (momentum stretch ~16%, overshoot pop, speed-trail, attack wind-up 0.08s, hit-squash ~20%);
this layer is FANG's **flavor on top**. Tag key: **[VFX]** = runtime layer, mechanics-owned, can
ship now, no rig. **[ANIM]** = needs per-character animation, DEFERRED per the scope gate. **[RIG]**
= needs the ears/tail/paw rig specifically.

**Locomotion**
- **Idle:** can't stand still - weight shifts foot to foot, a low restless bounce, cracks
  knuckles, tail flicking, ears swivel-tracking the crowd. Never fully settles. **[ANIM][RIG]**
  <- because restless predator + showman heart.
- **Move / run:** low forward-leaning lope, digitigrade paws eat ground, tail streams as a
  counterweight. The generic velocity-stretch reads as a predator *surging*. **[VFX]** trail =
  warm dust kick, no fire (fire is lunge-only). <- because Layer 3 pounce-readiness + orange-glow-
  in-motion rule (Layer 5).

**Offense**
- **Attack wind-up (0.08s):** the pounce-crouch - drops low, weight coils onto the back leg,
  tail lashes up, ears flatten forward (predator lock-on). **[ANIM]** **[VFX]** faint heat-shimmer
  + ember flecks pool at the wrapped fists. <- because ties stance -> mechanic readably; this is
  his SIGNATURE tell.
- **Attack active / swing (0.12s):** a raking claw-strike, whole body thrown forward behind it
  (the generic 20% forward-lean reads as commitment). **[VFX]** short orange claw-arc streak.
  <- because scrappy street combos + heavy clawed hands (Layer 3/4).
- **Skill = LUNGE / the pounce (0.20s travel):** the money move - a literal predator pounce, full
  extension, claws leading. **[ANIM][VFX]** THIS is where the warm-orange impact-glow fires: a
  comet-trail of fire off the fists, ember burst on connect. <- because "the lunge IS a literal
  pounce" (Layer 3) + glow-on-lunges-only (Layer 5). The one moment his leashed ferocity shows.
- **Ranged (aimed, shared kit):** scrappy, not clean - a hurled improvised strike / short thrown
  claw-slash, thrown with a grunt. **[VFX]** small orange slash, weaker than the lunge glow.
  <- because street-improvised, never a trained projectile; ranged is his weakest expression.

**Defense / reaction**
- **Block:** reluctant - crosses forearms and hunches, ears back, clearly *wants* to be attacking
  instead. Impatient shield, not a comfortable wall (that read belongs to ATLAS). **[ANIM]**
  <- because a rusher who chooses restraint hates it; contrast to ATLAS's vow-to-guard.
- **Take a hit (0.14s squash):** the generic 20% flatten along the hit direction; FANG's flavor =
  ears snap flat + a bared-fang wince, absorbs it and stays up. **[VFX][RIG]** <- because
  heavyweight who trades durability but refuses to fold.
- **Knockback / stagger:** planted, skids back on his heels rather than flying - digs claws in to
  arrest it, growl. **[ANIM]** <- because muscular heavyweight frame (Layer 4).

**Round beats**
- **Win:** roars, fist to chest, then a crowd-salute - beast joy, unleashed and shared.
  **[ANIM][RIG]** <- because he wants the beast *cheered* (Layer 1/2).
- **Lose / KO:** ears pin flat, tail drops, goes down hard - then plants a fist and gets up
  grinning anyway (even in defeat). **[ANIM][RIG]** <- because the get-up-grinning beat is THE
  tell that subverts the monster (Layer 2, the fear).

**Signature gesture (LOCKED):** the pounce-crouch wind-up. It doubles as his readable attack tell
AND his identity silhouette - low, coiled, tail up, ears forward. <- because one pose carries
stance + mechanic + identity at once.

---

## Reason-chain summary (what feeds downstream)
- Generation prompt: muscular tiger beast-kin, ears+tail+fangs, amber eyes (open/warm),
  natural orange-black fur stripes, scavenged street gear, fists wrapped in torn champion's
  banner, scarred, wide warm proud grin, orange. (No "FANG" text.)
- Animation tells: ears + tail + the get-up-grinning beat (Layer 6).
- Moveset: pounce-stance -> lunge; scrappy improvised combos; claw-rakes (Layer 3).
- Story hooks: feared-as-monster, the wish (Layer 2), the fear-of-being-right (Layer 2).
