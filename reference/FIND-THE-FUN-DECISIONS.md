# Find-the-Fun Decisions - build / keep / kill a mechanic

> Our methodology is "vertical slice + find-the-fun." That tells us HOW to build (one fun moment,
> greybox) but not WHEN to stop, pivot, or kill an idea. This is the decision gate. Use it before
> committing real time to a new mechanic, and after a play-test to decide its fate. Pairs with
> `COMBAT-FEEL-CHECKLIST.md` (that judges how a built mechanic FEELS; this decides whether to
> build/keep/kill it at all).
>
> Distilled + adapted from Donchitos/Claude-Code-Game-Studios `prototype` skill + `prototyper`
> agent (MIT), stripped of their GDD/sprint machinery. Lifted 2026-07-02.

## Before building: frame a falsifiable hypothesis

Don't start with "let's add a parry." Start with a claim that can be PROVEN WRONG:
> *"If [mechanic] works, then a player will [specific observable behavior] within [N] minutes,
> and it will feel [target]."*

Then test the **riskiest assumption first** - the one that, if false, kills the idea. Build the
cheapest thing that answers it. If you can't state what would make you abandon the idea, you're
not prototyping, you're decorating.

## The engine-vs-paper choice (why we don't prototype feel in a browser)

- **Feel / timing / game-juice** (our whole game) -> prototype in the **engine** (Godot). A browser/
  HTML mock *lies* about action-game feel - 50-133ms of input variance makes a snappy mechanic
  feel mushy and a mushy one feel fine. Never trust web-mock feel.
- **Rules / economy / turn logic** -> paper or a tiny script is fine.
- Ours is a real-time brawler -> almost everything is the engine path. (This is why the movement
  tuner is an HTML tool for *shaping a curve*, not for *judging feel* - feel gets judged in-game.)

## Sunk-cost tripwires (say the number out loud)

- **~2 hours in and the riskiest assumption still isn't answered** -> stop, the slice is wrong
  (too big, or testing the wrong thing). Re-scope before continuing.
- **A mechanic has been PIVOTed 3 times and still isn't fun** -> force a KILL decision. Do not
  pivot a 4th time. Three honest pivots is enough signal that the core idea doesn't hold.

## Verdict: PROCEED / PIVOT / KILL

After the play-test, pick one out loud:
- **PROCEED** - it works, lock it. (e.g. the movement overhaul -> "מעולה" -> locked.)
- **PIVOT** - the core is worth saving but this version failed. Capture *what worked* and *what
  specifically failed* before changing it, so the next attempt doesn't relearn the same thing.
- **KILL** - it doesn't earn its place. Cut it. **Record it in the GRAVEYARD below** (see the
  ring-out precedent - it was built unapproved, reverted, and never written down as a lesson).

## GRAVEYARD - killed / reverted mechanics (so we don't rebuild them)

One line per dead idea: what it was, why it died, what to do differently if tempted again.

- **Ring-out / knockout-of-arena (session ~2):** built unapproved, reverted. Why killed: added
  unasked, and a whole-screen arena removed the "edge" it needed anyway. Next time: get a yes
  before adding a win-condition, and don't add spatial mechanics that fight the arena shape.
- **Momentary i-frame dash (early):** replaced by SP-faithful Booster run. Why killed: SP has no
  momentary dash; it fought the "sustained run" feel. (Lunge still reuses the burst internally.)
- **Mouse-aim (early idea):** dropped before building. Why: namu.wiki verified SP is arrow-steer,
  no mouse. Lesson: verify SP claims against sources, don't build on a memory-guess.

## The one rule

A mechanic that hasn't been play-tested since it was built is an *assumption*, not a feature.
If assumptions are stacking up without a live play-test between them -> stop and play. (This is
our recurring tripwire - see memory `feedback_lead-with-critique`.)
