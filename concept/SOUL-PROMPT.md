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
