# Survival Arena - Concept (creative identity)

The **creative-identity** track: world, tone, character fiction, art direction, name.
SEPARATE from the mechanics track (`DESIGN.md` = combat feel, `VISION.md` = systems).
This is a living doc - it evolves as the game grows. Do NOT lock a full world-bible
up front; capture directions, decide as we go.

Why now: the core combat is proven fun (greybox), so giving it an identity is legitimate
(not "decorating before it's fun"). Concept also feeds character design and motivation.

## What exists so far (mechanics only - greybox, no fiction yet)

- Isometric arena fighter inspired by **Survival Project** (2001): fast, readable, punchy,
  social. Session-based PvP, not an MMO.
- Pillars (from DESIGN.md): **readable chaos · satisfying impact · easy-to-grab / social**.
- Characters so far (mechanical, no fiction yet):
  - **Balanced** - control archetype, skill = chill (AoE slow). Greybox color: blue.
  - **Rusher** (working name נמר / Tiger) - fast, fragile, hard-hitting, skill = lunge.
    Greybox color: orange.

## Open concept questions (to develop)

- **World / setting** - where/when? real, fantasy, sci-fi, abstract, toon?
- **Tone** - cute & light (Survival Project was cute)? gritty? comedic? stylish?
- **The fighters' fiction** - who are they? animals (tiger...), people, robots, mascots?
- **Art direction** - visual style, palette, shapes that replace the greybox.
- **Name** - the game's name.
- **Identity hook** - the one thing that makes it memorable / "ours", not a generic brawler.

## Asset pipeline & tools (DECIDED 2026-06-30)

**Critique that drives this:** the real wall is NOT "prettiest tool" - it's **consistency
+ animation**. One-off key-art (the moodboards) is the easy 5%; a consistent, animatable
roster is the hard 95%. Frame-by-frame AI sprites = a trap (the character flickers /
changes between frames). Video AI (start/end frames) = beautiful for trailers, useless
for clean looping gameplay animation.

**Decisions:**
- **Animation approach: cutout / bone-rig** (draw the character once - AI's strength -
  cut into parts, attach bones, animate like a puppet). Consistency solved (same drawing),
  fits the game's philosophy (readable, juice-over-flash, not ultra-fluid hand-drawn).
- **Facings: start small - 2-4 directions + mirror** (the iso camera hides a lot); expand
  toward 8 later. NOTE: true 8-directional is the threshold where pure cutout gets
  expensive (8 rigs/char) and the industry trick is **3D model -> render to 2D sprites**
  (model once, 8 camera angles). Kept on the table for when 8-dir becomes non-negotiable.

**The 6-step pipeline:**
1. **The "profile" / style bible = the consistency anchor.** A locked reference set: the
   style (`A_sports-anime-clean`) + a per-character reference sheet (front, profile, the
   2-4 facings, neutral pose). EVERY future generation runs against this. This is the
   roster engine - it's what makes a big roster look like one game.
2. **Generate a RIG-READY pose** (NOT key-art): neutral pose, limbs away from body, flat
   even lighting, full body, transparent/plain background, so it cuts cleanly into parts.
   Key-art (dramatic light, overlapping limbs) is for marketing, not rigging.
3. **Cut into parts** (head/torso/arms/hands/legs/hair). Tools: Photopea / Krita / GIMP
   (free, manual) + `rembg` for background removal.
4. **Rig + animate.** Tools: **Godot built-in** (Skeleton2D, free, no export) to start ·
   **DragonBones** (free, friendlier) · **Spine** (paid, industry standard, best mesh
   deform) when rigging becomes the bottleneck.
5. **Effects + juice separately** - skill VFX + impact flash on top of existing
   hit-stop/shake. (Already Aviv's strength.)
6. **Video AI (Seedance / Higgsfield / Kling) = trailers + character-intro cinematics
   ONLY**, never gameplay. (Where start/end frames are relevant.)

**Reference generation tools:** gpt-image-1 (supports reference images; already wired in
this repo's workflow) / Midjourney (`--cref` character, `--sref` style).

**Bookmarked catalogs (for later):** ai-game-devtools (Yuan-ManX) - curated AI tools for
art / 3D / texture / animation / audio / music.

**Available MCP tools - CORRECTED 2026-06-30 (Aviv): only Higgsfield is wired.**
Higgsfield (image: GPT Image 2 + video). **NO Tripo AI, NO Magnific.** This removes the
"image -> 3D" route entirely - which actually SIMPLIFIES the plan: there is no 3D->2D
branch left to test or decide. (gpt-image-1 is also available in the repo workflow and
made the FANG assets.)

### FANG profile assets - built 2026-06-30 (step 1 started)
Generated with gpt-image-1 (the MCPs aren't wired to the design session). In
`concept/characters/fang/`:
- `fang_front_clean.png` - clean full-body front, neutral A-pose, flat light, plain bg =
  the **Tripo input**.
- `fang_turnaround_front_side.png` - front + side, consistent = **rig / profile reference**.
- Notes: came out genuinely rig-ready (neutral pose, flat light, consistent across views).
  Model printed "FANG" on the tank - cute identity touch but remove for the rigged
  game version (text warps on a deforming mesh).

### Pipeline LOCKED 2026-06-30: cutout / bone-rig
(UPDATE 2026-06-30: Tripo IS available after all - it's Magnific's `models3d_generate` backend.
Tested on FANG: keeps identity + auto-rigs, but FLATTENS the locked 2D Guilty-Gear style into
generic AI-3D. So the cutout lock now holds for a stronger reason - not "no tool" but "3D loses
our look." Parked for pose/prop reference or a future 3D pivot only. See SYSTEM.md lessons log.)
With no image->3D tool, the 3D->2D-sprite branch is gone. The primary plan is now the
only plan:
- **Cutout / bone-rig** is THE animation approach (draw once, cut, rig, puppet).
- **Facings: 2-4 + mirror to start** (the iso camera hides a lot). Extra facings come from
  **2D turnaround generation** (Higgsfield / gpt-image with the reference sheet - FANG
  already has a front+side turnaround), each rigged as a cutout. NOT via 3D.
- **8 directions: deferred** until genuinely non-negotiable (revisit a 3D route then).
- **Next concrete step (show-before-spend): rig FANG in Godot (Skeleton2D)** - prove ONE
  generated character cuts + rigs + animates well BEFORE generating a roster. This is
  hands-on editor work (cut parts -> Skeleton2D -> a test animation).

## Method

Develop by drafting **2-3 distinct concept directions to react to** (Aviv's preference),
then converge. Keep it lightweight and living. Update this doc as decisions land.

---

## Round 1 - three concept directions (2026-06-29, awaiting Aviv's reaction)

**Framing critique:** don't paste a theme on top ("cute mascots") - it goes generic.
The mechanics already whisper a fiction: the **glide** says "the floor is slippery /
frictionless", the **knockback** says "the whole point is to shove". A good direction
DERIVES from that. So the three below differ exactly in *how they explain glide + shove*.

### Direction A - "Bumper toys" (cute, party, social)
Direct heir to Survival Project's cuteness. Small round creatures on a slick floor -
they glide *because they're slippery*, and knockback (shove the friend off the arena,
ring-out) is the whole joy. Best serves the "easy to grab, fun with friends" pillar.
Tiger -> chubby tiger cub; chill-controller -> a snow creature. Palette: saturated,
bright pastel. Names: *BONK / Tumble / Bopworld*.
- Risk: cute = most crowded space (Fall Guys, Gang Beasts), easy to get swallowed.

### Direction B - "Zero-gravity sport" (cool, stylish, broadcast tournament)
Glide explained literally: **the floor is space**. Fighter-athletes in an orbital ring;
knockback pushes you toward the edge, ring-out = floating off into space. Clean,
futuristic, e-sport-broadcast energy. Tiger = a speed athlete in a G-suit; chill =
a control player who freezes a zone. Palette: space-black + neon. Strong identity hook:
"the floor is space" explains the physics AND looks unique. Names: *DRIFT / Orbital / Ringfall*.
- Risk: clean-futuristic can read cold / personality-less without characters with soul.

### Direction C - "Spirits on a frozen lake" (atmospheric, mythic, quiet-stylish)
Glide = **skating on ice**, and chill is already here - the only direction where an
existing skill IS the theme. Masked champions / animal-spirits duel on a frozen lake;
a shove slides the enemy across the ice toward an ice-hole. Tone: folklore, restrained,
beautiful. Tiger = a tiger spirit; chill = a winter-keeper. Palette: ice-white, deep
blue, a touch of gold/red. The most visually distinctive / "ours". Names: *Frostfell /
Whitecap / Permafrost*.
- Risk: atmospheric clashes a bit with "fast, punchy, social" - must stay light/funny,
  not heavy.

**Open question to Aviv:** which pulls you instinctively, and where does the gut say
"no"? Mixing is fine (e.g. "A with B's physics").

---

## Round 2 - direction chosen + reframe (2026-06-30)

**Reframe (corrects "everything comes from a rich story/world first"):** in this genre
(and in SP itself) cohesion does NOT come from a deep lore-bible. It comes from two
cheap things: (1) one consistent **character + art DNA** = the anime style Aviv loves;
(2) one simple **"frame"** = the single in-world reason all the wild characters meet in
an arena. The story stays thin and grows per-character. Building a world-bible up front
is the trap this doc already warns against.

**Aviv's choices (via AskUserQuestion):**
- **Art / character DNA = shonen-action** (Naruto / MHA energy): dynamic, bold, signature
  moves, sharp silhouettes, rivalries. Skills map perfectly to "signature moves". Cooler
  than cute, less crowded.
- **Frame = a broadcast battle-show / fighting circuit**: fighters are stars/contestants
  in the world's biggest televised fighting league.

### The unified concept seed - "The Circuit"
A world obsessed with a **televised fighting league** - its biggest entertainment.
Shonen-style fighters enter to become stars: rookies, veterans, rivals, champions.
Every match is broadcast - announcers, crowd, sponsors, slow-mo replays of big KOs.
**The arena floor is a slick broadcast stage** (this is what explains the glide); the
**knockback / ring-out are the show's money-shots.** The circuit IS the world, so it
unifies a wild roster, justifies arenas (different studios), seeds progression (climb
the rankings), and gives the whole UI one personality (the show's branding).

The two existing characters snap in with a built-in rivalry:
- **Rusher / Tiger** -> a hot-blooded rookie speedster, crowd favorite, reckless lunges.
- **Chill-controller** -> a cool veteran / champion who controls tempo and freezes the
  stage - the "boss" every rookie wants to topple.

### Master tone - DECIDED: sincere shonen heart
Spectacle is the stage; the rivalries are real (MHA-like). The show is the surface, the
fighters genuinely care. Chosen over satirical-spectacle (ages better, fits "social fun
with soul").

---

## Round 3 - the emotional fuel (2026-06-30, awaiting Aviv's reaction)

**Critique that drives this:** sincere shonen collapses into "just a ranked tournament"
unless the climb has a *personal* emotional reason. "Be the champion" is a trophy, not a
heart. So we must decide: **what's at the top of the Circuit that actually matters?**
Three options offered (each reshapes the whole roster):
- **One wish to the champion** (Dragon Ball tournament-arc): winner gets a single wish.
  Gives every character a personal "why" - a great content engine (each new character =
  a new wish = a small story). Most flexible for a growing roster.
- **The Circuit is the way out** (grounded / class stakes): the only path up from the
  bottom; winning = escape for you and yours. Warmest, but narrows the world to class.
- **Surpass the legend** (rival/mentor energy): an undefeated legend sits at the top;
  everyone fights to reach and surpass them. Snaps perfectly onto the existing chars -
  **the chill veteran IS the legend the rookies chase.**

**Claude's recommendation: combine #1 + #3** - "one wish" gives each character a personal
why (content engine), "an undefeated legend at the top" gives one unified target everyone
chases. #2 is warm but narrows the world.

**DECIDED: combo #1 + #3.** Synthesis that resolves the knot: **the wish has never been
claimed.** No one has beaten the undefeated legend at the top, so the biggest prize in
the world hangs there - mythic and untouched for a generation. The legend is the wall
between every fighter and their dream. That IS the shonen fuel: not "win a tournament"
but "topple the untoppable and claim what no one ever has."

---

## LOCKED CONCEPT SPINE (2026-06-30)

> **OVERTHRONE** - shonen-action. The world's biggest entertainment is a **televised
> fighting league**; the arena floor is a slick broadcast stage (that's where the glide
> comes from), and the knockback is the show's money-shot. At the top sits an
> **undefeated legend**, and the champion is promised **one wish** - never claimed,
> because no one has beaten him. Every fighter enters with a burning personal "why"; the
> legend is the wall between them all and their dream.

- **Name:** OVERTHRONE (throne + overthrow; the title = the league's brand, so the whole
  UI gets one identity. Foregrounds the heart - topple the legend - over the spectacle.)
- **Art / character DNA:** shonen-action (Naruto / MHA energy; signature moves = skills).
- **Frame / world:** a televised fighting league / circuit.
- **Master tone:** sincere shonen heart (spectacle is the stage, rivalries are real).
- **Emotional fuel:** one unclaimed wish, guarded by an undefeated legend.

---

## Round 4 - the two starter fighters (2026-06-30, awaiting Aviv's reaction)

**Critique / correction:** earlier I said the chill-controller IS the legend. Running it
forward, that's wrong - a starter you pick and play casually can't also be the unbeatable
endgame legend (it burns the most mythic role on a starter and leaves the rookie with no
real opponent to fight NOW). **Fix:** the two starters are both *contenders* - the
hot rookie vs the cool veteran pro - a perfect eye-level rivalry. The undefeated legend
at the very top stays a FUTURE boss character. The veteran is the first wall the rookie
must pass.

### FANG - the hot-blooded rookie (was Tiger / Rusher; orange; fast/fragile/hard-hitting, lunge)
- A street kid from a forgotten town; entered the circuit with no sponsor, nothing.
  Fast, fragile, hits hard, reckless lunges. Crowd favorite - plays with an open heart.
- **Wish:** put his town on the map - prove a nobody from nowhere can reach the top.
- **Look:** lean, bruised, taped fists, second-hand gear, reckless grin, orange tiger
  stripe. The underdog.
- Alt names: BLITZ / WILDCAT / COMET.

### ZERO - the cool veteran pro (was Balanced / chill-controller; blue; control, AoE chill)
- A composed, calculating veteran who controls tempo and freezes the stage. The
  gatekeeper every rookie must get past. Sponsored, polished - FANG's exact opposite.
- **Wish:** has chased the wish for years and keeps falling short of the legend; his wish
  ties to something he lost along the way (this links the veteran to the future boss).
- **Look:** calm eyes, composed, tailored blue-white gear, frost motif. Polish vs FANG's
  scrappiness.
- Alt names: FROST / GLACIER / WINTER.

**Why it works:** fire vs ice · reckless vs calculating · heart vs control - which is
exactly their mechanics (fast/fragile/aggressive vs slow/zone/defensive). Fiction and
mechanics reinforce each other.

---

## Round 5 - ART DIRECTION (DECIDED 2026-06-30)

**Critique that drives this:** beauty serves readability, not the other way around.
DESIGN.md pillar #1 ("readable chaos") is the master constraint for an isometric brawler
with knockback + flying effects. Conveniently, the broadcast frame pushes the same way -
TV sports graphics are built for instant readability (clear team colors, clean arenas,
bold UI). So we don't choose "pretty vs readable" - we choose a *readable* anime look.

**Process:** generated moodboard key-art with gpt-image-1 (same two fighters / arena,
only the style varied) so Aviv could choose visually. Three flavors (A clean sports-anime,
B gritty-ink shonen, C arcade-Y2K neon), then blend rounds adding glow (D/E). Aviv liked
A's character design + serious complex shading; liked C's flashiness; we tested blends.

**DECIDED: `A_sports-anime-clean` is the art direction.**
- Clean modern sports-anime: crisp clean linework, bold cel-shaded color with rich,
  serious shading, bright high-contrast TV-broadcast energy. Readable first.
- **Flashiness / glow is NOT baked into the base look** - it lives in MOTION: rim-light
  and energy glow on impact moments and skills only, not constant. (Aviv loved C's glow;
  this is where it goes without hurting readability.)

**Locked visual non-negotiables (derived from pillar #1, not taste):**
- Bold silhouette read at a glance - each character's body shape is identifiable instantly.
- **Signature color = identity:** FANG = orange, ZERO = blue (already true in greybox - keep it).
- Quiet backgrounds so fighters pop.
- Effects are color-coded and instantly legible (ZERO's ice = blue-white, FANG's lunge = warm orange).

**Visual anchor files:** `concept/moodboards/` - `A_sports-anime-clean.png` is THE anchor.
(B/C/D/E kept as exploration record: B = marketing/poster key-art only, never in-game.)

---

## Round 6 - CHARACTER DEPTH (2026-06-30, awaiting Aviv's reaction)

**Critique that drives this:** the first rig-ready `fang_front_clean.png` came out generic
(plain tank + jeans + sneakers, single-tone hair, bland symmetric face, "FANG" text as the
only identity). Root cause: we never *designed* FANG - we wrote a line of adjectives and the
model filled in defaults. Depth in character design comes from three things, none of which
are adjectives: (1) **specificity** (not "second-hand gear" but *which* item and why),
(2) a **story-bearing signature detail** you remember, (3) an **internal contradiction**
that makes a person, not an archetype.

**Aviv's anchoring choices (via AskUserQuestion):**
- **Nature of fighters = beast-kin AND beyond.** Not just animals: creatures, powered
  beings, people from other eras / the future / who made their own gear. FANG specifically
  is a **tiger beast-kin** (real ears/fangs/feral eyes, maybe tail).
- **FANG's energy = Naruto** (loud outcast, heart over talent, "watch me" charisma; his
  beast-motif maps perfectly - the tiger-kid nobody believed in).
- **World texture = deliberately mixed** (leans gritty-street + retro-arcade, but "could be
  all of them" - time-travelers, future-fighters, self-made gear).

**KEY UNLOCK - the world has no single setting, on purpose.** The Circuit pulls fighters
from every place and every era into one arena. That justifies a wild roster (beast-kin +
creatures + powered beings + cross-era people) without the game falling apart. Cohesion
comes NOT from a shared setting but from the two already-locked anchors: the **art DNA**
(`sports-anime-clean`) and the **broadcast frame** (one league branding / studio lighting /
identity colors). This is the moat vs a generic brawler.

### FANG - design spec (draft, beast-kin tiger rookie)
**The contradiction (his heart):** a tiger beast-kin is *built* to be an apex predator -
everyone expects a killer. FANG is the **runt of his kind**: he has the fangs and claws but
not the size or the bloodline. So he fights loud and reckless to prove a "broken" predator
still belongs at the top. The feral grin is armor, not confidence. (= Naruto's outcast fuel,
and it makes the tiger ironic instead of generic.)

**Concrete visual anchors (replace the adjectives):**
- **Silhouette hook:** lean, wiry, *small* frame - NOT buff (he's the runt, that's the point).
  Coiled, low, ready-to-pounce stance even at rest. A tail that reads emotion (lashes when
  hyped). One **notched / torn ear** - a tell that he's survived fights he shouldn't have.
- **Hair = a messy two-tone tiger-mane** (dark roots -> orange tips, the moodboard look that
  the clean version lost), spiky/Naruto-energy but reads as a mane.
- **Face:** bright amber/gold predator eyes; oversized real canines (the literal "fang");
  natural orange-black tiger **fur-markings** (not dye anymore - he's beast-kin); a scar
  through one brow. Grin that's a hair too wide - bravado covering the runt.
- **Color identity:** orange (locked) - tiger-orange fur + black stripes; warm-orange
  impact-glow on lunges only (glow lives in motion, per Round 5).
- **Drop "FANG" text on the shirt** (warps on a deforming mesh; identity now lives in the
  body, not a logo).

**OPEN CHOICE for Aviv - the one signature story-bearing object** (pick / react; this is the
detail people will remember him by):
- (a) **Hand-wraps torn from a discarded champion's banner** - a nobody literally wrapping
  himself in the dream he's chasing. (Strongest tie to "topple the legend, claim the wish".)
- (b) **A single mismatched / scavenged glove or gauntlet** - self-made gear, the only thing
  he owns; the asymmetry IS the silhouette tell.
- (c) **A cracked, too-big championship-style belt** worn as a sash/scarf - found/stolen, way
  above his rank, pure underdog audacity.

### ZERO - to do next (mirror of FANG)
Once FANG locks, design ZERO as the deliberate opposite on every axis above (cool veteran,
blue, control). His "nature" likely a *different* kind of being than beast-kin (reinforces
the mixed roster) - decide when we get there.

---

## Round 7 - ART DIRECTION CHANGED (DECIDED 2026-06-30) - SUPERSEDES Round 5

**What happened:** we generated FANG full-body and Aviv reacted - the soft `sports-anime-clean`
look (Round 5) felt generic/wrong to him. He couldn't choose from style *names* ("I don't know
styles"), so we rendered the SAME locked FANG design in 4 styles and let him react to pictures
(`concept/characters/fang/fang_style_compare.png`): A Street Fighter, B Guilty Gear, C western
comic, D bold toon.

**DECIDED: art direction = "Guilty Gear / arcade-fighter 2D" (style B).**
- Bold clean cel-shading, hard rim lighting, sharp confident outlines, saturated high-contrast,
  slick and edgy - arcade-fighter energy, cooler/sharper than soft anime, not cute.
- Chosen for: matches Aviv's pull (he picked the Street-Fighter / arcade-fighter feel), the bold
  clean outlines read best at small isometric scale AND cut cleanest as a 2D cutout puppet.
- **Animation approach UNCHANGED** - Aviv clarified it was the *drawing* he disliked, not the
  motion, so cutout / bone-rig stays (Round-5 pillars + the pipeline section above all hold).
- **New style anchor: `fang_styleB_digitigrade_1.png`** replaces `A_sports-anime-clean.png` as
  THE look. (A_sports-anime-clean kept only as history.)

**FANG body, finalized:** full tiger legs + clawed paws (athletic, slim below the knee), NOT
human-legs-with-paws. gpt-image-1 resisted true reverse-joint digitigrade for ~5 rounds; the
reference-image `images.edit` route plus the approved dynamic-pose render got it acceptable.

**Tooling note:** all FANG art is gpt-image-1 via the repo's `OPENAI_API_KEY` (Higgsfield MCP
needs auth we don't have in this session; OpenAI is already wired). Use `images.edit` with a
reference image for things text alone won't do.

### Next concrete steps
1. Generate a NEUTRAL rig-ready A-pose of FANG in this exact style B (the anchor is a dynamic
   pose; rigging needs neutral, limbs apart, flat light) -> hand to mechanics chat for Godot.
2. Design ZERO via the same 6-layer method, rendered in the SAME style B.

---

## Round 8 - ROSTER MOVEMENT: FLOATING + ZERO locked (2026-07-01)

**New roster-wide direction (Aviv):** **most characters FLOAT / hover** off the ground (not all -
FANG stays a grounded rusher with planted paws). Fits the game's slick-floor / glide feel and
gives the roster an otherworldly range. Floating characters need a hovering neutral rig-pose
(adapt RIGPOSE-STANDARD per-character - a GameOS note).

**ZERO - LOCKED** (`concept/characters/zero/ZERO.md`, anchor `zero_cosmic_1.png`):
an intricate **cosmic-alien ice being** who **floats**. The design went through an **inversion**
Aviv authored: not "a man with some ice" but **almost entirely living cosmic ice (galaxy +
constellations inside), with a small human-flesh remnant** (half the face + one arm), the ice
intricately interwoven into the flesh at the seams. Unified etched-crystal cosmic garment + ice
crown (the earlier tattered look was rejected). The perfect foil to FANG: grounded wild fire vs
floating cosmic ice.
