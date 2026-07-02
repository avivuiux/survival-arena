# Scope-Creep Rubric - putting a number on "scope is the killer"

> Our #1 locked principle is *"scope is the killer, not code."* Until now that was a slogan
> with no measure. This is a quantified check so "it feels bigger" becomes "+35% items" -
> actionable. Read-only: it reports, it never cuts for you. Run it by hand when a feature or
> a session's work feels like it's sprawling, or before locking a milestone.
>
> Adapted (rubric only, machinery dropped) from Donchitos/Claude-Code-Game-Studios
> `.claude/skills/scope-check` (MIT). Their version reads GDD/sprint docs we don't have; ours
> uses the baseline we DO have. Lifted 2026-07-02.

## Our baseline (what "the original plan" means for us)

We have no GDDs or sprint docs. Our scope baseline is:
- **The locked decisions + "Current state" in `HANDOFF.md`** - what the slice is supposed to be.
- **The next-step we committed to** (the one recommended + approved), not the menu of maybes.
- **`git log`** since that step started - what actually got built.
- **`SKELETON.md`** for the SP-faithful feature set (the intended kit, confidence-tagged).

## The check (5 steps)

1. **State the intended scope.** From HANDOFF's current step: what were we supposed to build/tune?
2. **List what actually happened.** Scan changed files + `git log --oneline` since that step.
3. **Diff into three buckets:**
   - **Additions** (built but not in the intended scope) - for each: justified? (discovered
     requirement vs. shiny detour), effort (S/M/L).
   - **Removals** (intended but dropped) - why, and what's affected.
   - **On-plan** (matches intent).
4. **Bloat score:** `intended items = N`, `added = X`, net change = `+X/N %`.
5. **Verdict:**

| Net change | Verdict | Meaning |
|---|---|---|
| ≤10% | **PASS** | on track - normal variance |
| 10-25% | **CONCERNS** | minor creep - trim with targeted cuts |
| 25-50% | **FAIL** | significant creep - cut, or formally re-scope in HANDOFF |
| >50% | **FAIL** | out of control - stop, re-plan, re-read the core bet |

## Triage the additions

- **Cut** - nice-to-haves that don't serve the current fun moment. (Precedent: ring-out was
  built unapproved and reverted - that's a CUT.)
- **Defer** - real but belongs to a later phase (e.g. anything netcode = phase 2).
- **Keep** - genuine discovered requirement that serves the core loop.
- **Flag** - needs an Aviv decision (a direction choice, not a detail).

## Rules

- Scope creep = additions **without** matching cuts or an explicit, written re-scope.
- Not every addition is bad - but each must be *acknowledged and accounted for*, not smuggled in.
- When cutting, **preserve the core player experience** over nice-to-haves. Fun first.
- Always quantify. "+35% items" beats "feels bigger."
- This project's specific tripwire: **layers of characterization/features added without a
  live play-test in between** (see memory `feedback_lead-with-critique`). If additions
  outnumber play-tests since the last lock → that's creep even if the % looks fine.
