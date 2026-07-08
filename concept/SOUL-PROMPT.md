# SOUL-PROMPT - design exploration from idea-only prompts

GameOS module. Born 2026-07-05 (FANG regen experiment, Aviv: "אחלה פרומפטים... למד ממה שעשית").
Purpose: generate FRESH character-design ideas by feeding the generator the character's SOUL
(bible layers) with ZERO visual prescriptions - so the model invents looks we wouldn't.
This is an EXPLORATION tool, not canon production (canon generation = anchor-reference pipeline,
see SYSTEM.md + STYLE-GUIDE).

## The recipe (what made it work)

1. **Distill the bible, don't summarize it.** Pull the emotional engine from the character's
   locked layers: the seed/contradiction, the wound, the register, how they fight, ONE
   story-bearing object. 3-4 short paragraphs max.
2. **Zero visual language.** No colors, no hair, no outfit, no body-type adjectives. Species/
   nature stays (it's identity, not design). End with an explicit freedom clause + anti-cliche
   nudge: "His look is entirely yours to invent: silhouette, build, outfit, materials, colors,
   styling - all open. Avoid the obvious choices. Surprise me."
3. **Lock ONLY the style register** (one opening paragraph): "chibi-plus 3D-toon style:
   cute-proportioned (~3.5 heads tall) collectible-toy-like 3D render, bold rounded forms, clean
   vivid colors, single character on a simple neutral studio background, standing pose showing
   the whole design."
4. **Write emotion as physical instructions the model can draw.** The big lesson. Abstract traits
   ("dangerous but warm") do little; render-able sentences do everything:
   - "the level, unblinking stare of a predator sizing you up"
   - "the grin shows real fangs and reads as a warning as much as a welcome: the smile of
     something that chooses, every second, not to bite"
   - "anyone looking at him should feel a small instinctive step backward even inside the
     toy-like style"
   - "everyone who looks at him should feel what happens if he stops choosing"
5. **Iterate with a reference, not a rewrite.** When Aviv likes a variant but wants a shift
   ("too cute -> more menacing"): pass the liked image as an `image` reference + rewrite ONLY the
   register paragraph ("keep the overall design direction of the reference - but fix the face:
   ..."). Keeps the design, moves the one dial. Worked round-1 #1 -> round-2 in one shot.
6. **4 variants per round, 3:4, contact-sheet + critique per image** (what worked / what leaked /
   what's off-style), findings called out explicitly. Deliver as a browser gallery page.

## SOURCE OF TRUTH (locked with Aviv 2026-07-06): the Character Studio, via whitelist

The soul-prompt is built FROM `tools/character-studio/characters.json`, NOT free-authored from
memory/bible prose (that's how the ZERO round-1 leak happened - the author knows too much).
**Whitelist (soul fields, feed these):** nature, powerSource, element, archetype, tempo,
temperament, era, storyRole, vibe, seed, want, signatureObject.
**Blacklist (design fields, never feed):** movement, size, colorIdentity, portrait, gallery -
plus any body/material sentence that snuck into a soul field (fix the DATA, then generate).
The pendant/story-object content is asked for as a silhouette/ghost-glow, never a literal
portrait (toy-scale kitsch guard).

## ⚠️⚠️ STYLE IS CARRIED BY AN IMAGE, NOT BY WORDS (locked with Aviv 2026-07-06)

The biggest method fix of the session. Describing the roster style in PROSE ("collectible-toy 3D,
~4.5 heads, premium finish...") DRIFTS every run - it silently slid ZERO round-1 into generic
figures and round-3 into painterly-realistic fantasy concept art (a different game from FANG).
**FIX: the style is locked by passing FANG's canon image as a `style` REFERENCE** (Magnific
`references:[{type:"style", identifier:<FANG r2_v4 creation>}]`), with a short instruction:
"use the reference ONLY as the visual style/finish/proportion/world anchor - do NOT copy its
character (tiger/colors/outfit); design a different character in that identical style." The soul
TEXT then carries only the soul. Proven on ZERO 2026-07-06: same-game finish locked instantly,
character fully free. **RULE: never author the style in words again - reference FANG's image.**
(This is what STYLE-GUIDE meant by "FANG as mandatory style ref" all along.)

## ⚠️⚠️⚠️ CONCEPT-FIRST, STYLE-SECOND PIPELINE (locked with Aviv 2026-07-07)

The character-creation flow, decided by Aviv, that DECOUPLES creativity from style:
1. **CONCEPT (any style):** generate the character from a SIMPLE prompt with NO style anchor -
   whatever finish the model returns is fine. The point is a maximally creative, un-flattened
   design. (Anchoring the style in step 1 fights the creativity and pulls everything toward the
   known look - that was the drift we kept hitting.)
2. **RESTYLE into our look:** take the chosen concept image and convert it into our collectible-toy
   3D style via image-to-image, using FANG (+ZERO) as the `style` reference and the concept as the
   content/character to keep. Identity preserved, finish swapped to the roster look.
   ⚠️ verify per character - restyle can nudge details.
3. **CONTINUE:** A-pose -> Tripo (detailed recipe) -> rig -> game3d (the existing pipeline).
This SUPERSEDES "always anchor FANG's style in the first generation." Style-anchoring moves to
step 2. The dry-catalog / MMO-stat-sheet method below still applies to writing the step-1 concept
prompt (kept lean, essence-first, no visual prescriptions).

## ⚠️⚠️ DRY KEYWORD CATALOG, NOT PROSE (locked with Aviv 2026-07-06, evening)

The final method shift. Aviv: "we just need to know the TERMS, to catalog, to give drier keyword
inputs and let the AI do its thing on creativity." Prose sentences over-constrain and drift;
**precise cataloged keywords give the model a sharp anchor while leaving the visuals fully open.**
The prompt is now a TAG DUMP of the Studio card (label: value lines), not paragraphs.
- **Terminology source = the Superpower Wiki** (powerlisting.fandom.com) for powers, and
  fighting-game vocabulary for combat. Use the exact catalog names, not descriptions:
  ice-> `Cryokinesis` / `Cold Manipulation`; cosmic ice-> `Cosmo-Cryokinesis`; frozen-for-years->
  `Cryostasis`; freeze-to-nothing-> `Absolute Zero Inducement`; control/keepaway-> `Zoner`
  (keepaway, stage control, deceleration/stasis debuffs, bait-and-punish); float-> `Levitation`.
  These live in the new `powers` array on each Studio character.
- **Format:** style-anchor line (FANG image ref) + `CHARACTER TAGS` block (Nature / Powers /
  Composition / Aesthetic / Combat archetype / Range / Movement / Tempo / Temperament /
  Silhouette / Story role / Era / Element / Moral vibe / Signature object) + one closing line:
  "design one original character embodying these tags, invent all visual specifics, avoid the
  obvious cliches."
- **Two high-leverage fields (added 2026-07-06 eve, Aviv's idea):**
  - `Composition` = a WEIGHTED BLEND of what the character IS, in percentages - the sharpest
    "spike" you can hand the AI. ZERO = "65% cosmic-ice entity, 35% human remnant." The Studio
    has a picker UI for it. In the prompt: "Composition: 65% cosmic-ice entity, 35% human remnant."
  - `Aesthetic / aura` = dry adjective tags for TONE (noble, elegant, sexy, cold-beautiful...).
    In the prompt: "Aesthetic: noble, elegant, cold-beautiful, imposing, otherworldly."
- **Studio structure (locked):** the character page is TABBED - Dossier (dry catalog only:
  vitals, composition, powers, aesthetic, 12 axes) + Story & Art (natureNote, seed, want,
  gallery). Prompts read ONLY the Dossier fields; Story never enters a design prompt.
- Proven format on ZERO 2026-07-06 evening. The prose-assembly section below is SUPERSEDED by
  this - keep it only as the fallback when a field has no clean catalog term.

## PROMPT = MECHANICAL ASSEMBLY OF THE CARD (SUPERSEDED 2026-07-06 eve by the dry-catalog method above)

Aviv's correction: earlier ZERO prompts were BLOATED with my own prose ("his answer is stillness:
'the worst already happened'", invented world-belonging paragraphs). **The prompt must be a
faithful assembly of the Studio card fields - nothing invented on top.** Each sentence traces to
a field. Assembly order (skip empties):
1. Role + era: `storyRole` + `era` -> one clause ("a displaced veteran / gatekeeper").
2. Nature: `natureNote` verbatim-ish (the how/why of the nature - e.g. transformed = what he was
   + how he changed). This replaces free backstory prose.
3. Seed: `seed` (the contradiction).
4. Power: `element` + `extraElements` + `powerSource` -> "his power is ice, touched by cosmic."
   NOTE: elements are DISCRETE now (ice + cosmic), never a fused "ice/cosmic" value.
5. Fighting temperament: `archetype` + `tempo` + `temperament` -> physical bearing.
6. Want: `want`.
7. Story-object: `signatureObject` (as silhouette/ghost-glow, not a literal picture).
8. Freedom clause (fixed): "his look is entirely yours to invent - build, age, features, clothing,
   materials, colors, how his power shows, how he stands - all open. Avoid the obvious choices."
Style is NOT written - it rides on the FANG `style` reference (see the section above).

## Template

```
Full-body character concept for an arena-fighting game, in a chibi-plus 3D-toon style:
cute-proportioned (~3.5 heads tall) collectible-toy-like 3D render, bold rounded forms, clean
vivid colors, single character on a simple neutral studio background, standing pose showing the
whole design.

The character's soul (design everything else yourself): [SEED - who they are + the contradiction,
2-3 sentences, in "his answer is..." voice]. [WOUND/WANT - 1-2 sentences]. [HOW THEY FIGHT +
register, written as render-able physical cues]. [ONE story-bearing object: "One detail must
exist somewhere: ..."].

His look is yours to invent within the chibi-toy style: silhouette, build, hair, outfit,
materials, color palette - all open. Avoid the obvious choices. Surprise me.
```

Menace/register dial (append when needed): "His resting expression is not cute and not friendly:
[predator-stare sentence]. The warmth is real, but it sits on top of something genuinely
dangerous - [leash sentence]. [warning-smile sentence]."

## Findings log

- **2026-07-05 FANG round 1:** all 4 variants chose a FULL tiger face -> our locked human-face
  FANG is a differentiator the generator never reaches alone (it's what creates "scary body /
  warm heart"). / "scrappy street self-made" always = patched denim vest + cargo + sneakers
  (generator cliche corner). / The banner-fist-wraps translated beautifully in all 4 (one wrote
  CHAMPION on the wraps) - strongest story-object we have.
- **2026-07-05 FANG round 2 (menace push):** register rewrite + round-1 winner as reference =
  design preserved, face shifted in one round. Physical-instruction sentences (stare/fangs/
  step-backward) did the work.
- **2026-07-06 ZERO round 1 (+ a METHOD correction):** the first ZERO "roster-test" run was done
  WRONG - old-anchor + style-ref conversion, which just re-dressed the old design. Aviv caught it
  ("אנחנו אמורים לייצר פרומפט נשמה... EXPLORATION אמיתי"). Rule: a DESIGN REFRESH always starts
  at station 1 (pure soul-prompt, zero image references); conversions are only for style-carry
  tests. / Register paragraph now = collectible-toy 3D, ~4-4.5 heads (r2_v4 register) - the
  template's chibi-plus paragraph is superseded by whatever STYLE-GUIDE currently locks. /
  Findings: 3 of 4 variants clung to the ICE-CROWN cliche despite an explicit avoid-clause - only
  the variant that also aged the character escaped it (the generator's "ice ruler" corner is
  strong). / Literal photo-like faces INSIDE the frozen pendant read kitsch/uncanny at toy scale -
  next rounds: ask for the pendant's content as a silhouette/ghost-glow, not a portrait. /
  "somewhere a remnant is still flesh - you decide where" produced 4 different remnant layouts
  (arm / arm+chest / face-half+chest) - the freedom clause works on anatomy too.
- **2026-07-06 ZERO round-1 LEAK AUDIT (Aviv: "יותר מדי דומה ל-ZERO שייצרנו... מה זלג?").**
  Line-by-line diagnosis of why all 4 converged on the old look - the four leaks:
  (1) "living cosmic ice body with a galaxy inside" = a 2026-07-01 DESIGN decision smuggled in
  as identity. The soul is only "a man mastered-and-imprisoned by a cosmic cold power"; HOW it
  shows on the body is design space. (2) "he floats" = the roster-float direction, also design.
  (3) "frost + ice fragments orbiting him" = direct visual prescription. (4) "crown or no crown"
  = naming an item in the freedom clause PLANTS it (3/4 grew crowns; FANG's clause named nothing).
  Also: "ice + galaxy" implies the blue-violet palette even unnamed. **RULE SHARPENED: identity =
  species/nature + the POWER's nature + the story-object. Every bodily/material/motion/palette
  expression of the power = design, leave open. Never name a concrete item anywhere in the
  prompt, including inside "X or no X" clauses.**
