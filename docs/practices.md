# Working Practices

Habits that sit alongside the lifecycle rather than inside it: choosing what to work on, and
handling work that does not fit a single feature.

---

## Task selection: bugs vs. features

Not all work is equal, and your available resources — tokens, time, mental energy — should
decide what you pick up next. This is deliberate triage, not procrastination. `/triage`
implements it.

**When tokens or context are low → pick bugs.** Bug fixes are small, well-scoped, and
self-contained. They need minimal brainstorming and usually fit in one conversation. When
your budget is thin or your window is short, bugs are the highest-value work available: they
improve the product without the planning overhead of a feature.

**When resources are plentiful → work on features and plans.** The full Brainstorm → Plan →
Build cycle consumes real tokens and demands sustained attention as a reviewer. Save it for
sessions where you have both.

**When context is rich → pick work that leverages what is already loaded.** Switching to a
task in a different module throws away the context you just paid to build, even if that task
is technically higher priority. Context thrash is the enemy.

### Priority order, within context-aligned work

1. Critical bugs — broken functionality, data-loss risk
2. Active plan phases — work already in progress
3. High-priority features — user-requested, high impact
4. Accumulated plans in `new/` — pre-invested design work, ready to execute
5. Low-priority bugs — cosmetic, edge cases
6. New feature brainstorming — when everything else is clear

### Let plans accumulate

Plans in `docs/plans/new/` are not a backlog to feel guilty about. They are *pre-invested
design work* waiting for the right moment. Brainstorm three in the morning, build them in the
afternoon — or next week.

The mindset shift: with AI-assisted development, "later" does not mean months. It means
minutes or hours. The gap between "plan written" and "feature shipped" has collapsed, so
accumulating plans is not deferring work — it is *staging* it for rapid, parallel execution.
Combined with the [multi-model split](multi-model.md), a planning session and a build session
can run at the same time.

---

## Refactoring a monolith

Treat refactoring as a feature — same cycle, no shortcuts:

1. Ask the agent to analyse the monolith and propose domain boundaries (`/brainstorm`).
2. Generate a phased refactoring plan (`/write-plan`), one extraction per phase.
3. Execute with the normal build loop — TDD → implement → test → self-review — for every
   single file extraction.

The phase boundaries matter more here than anywhere else. A refactor that moves six modules
in one phase has no meaningful test gate and no reviewable diff; a refactor that moves one
module per phase can be stopped, reviewed, and reverted at any point.

---

## The "no surprises" rule

A standing constraint worth putting in your [agent config file](agent-config.md):

> **Never modify code without explicit permission. Propose changes one file at a time.**

It costs a little velocity and buys back the ability to actually review what happened. An
agent that edits eleven files before showing you anything has not saved you time — it has
moved the review cost to the least convenient moment.
