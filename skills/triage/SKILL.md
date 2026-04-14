---
name: triage
description: Recommend what to work on next by reading the backlog (bugs.md, features.md, plans/) and considering what is already loaded in the current conversation context. Minimizes context thrash — prefers tasks aligned with current context. Recommends bugs when context is low, features when resources are plentiful.
allowed-tools: Read, Grep, Glob
---

# Triage — What Should We Work On Next?

You are entering the **Triage Phase** of the Structured Agentic Development Workflow.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## Your Mission

Analyze the current state — backlog, context, and resources — and recommend the highest-value next task.

## Step 1: Assess Current Context

Before looking at the backlog, understand what is already loaded:

- What files and modules are in the current conversation context?
- What domain knowledge has already been established?
- How deep are we into the conversation? (Fresh start vs. mid-session)

This matters because **switching to work that requires loading entirely different modules wastes the context you've already built**. Context thrash is the enemy.

## Step 2: Read the Backlog

Check these sources:
- `docs/plans/bugs.md` — known bugs
- `docs/plans/features.md` — planned features
- `docs/plans/new/` — plans written but not yet started
- `docs/plans/` — any active plans in progress

## Step 3: Apply the Selection Strategy

### When context is thin (fresh conversation, few files loaded):
→ **Pick bugs.** They are small, self-contained, and don't require the full Brainstorm → Plan → Build cycle. They warm up the context efficiently.

### When context is rich (mid-session, modules loaded, domain established):
→ **Pick work that leverages what's already loaded.** If you've been working in the entity extraction module, recommend tasks in that same area — even if a task in a different module is technically higher priority.

### When context is rich AND resources are plentiful:
→ **Pick features or plans.** These require the full workflow and sustained attention. Now is the time.

### Priority ordering (within context-aligned work):
1. **Critical bugs** — broken functionality, data loss risks
2. **Active plan phases** — work already in progress
3. **High-priority features** — user-requested, high impact
4. **Accumulated plans in `new/`** — pre-invested design work ready for execution
5. **Low-priority bugs** — cosmetic, edge cases
6. **New feature brainstorming** — only when everything else is clear

## Output Format

```
## Recommended Next Task

**Task:** [description]
**Source:** [bugs.md #3 / plans/new/offline-sync.md / features.md #7]
**Why now:** [context alignment + priority reasoning]
**Context cost:** [Low — already loaded / Medium — partial overlap / High — fresh context needed]

## Alternatives
1. [Second choice] — [why it's second]
2. [Third choice] — [why it's third]
```

## The Mindset

With AI-assisted development, "later" does not mean months — it means minutes or hours. Plans accumulate in `new/` as pre-invested design work, not as a guilt-inducing backlog. Triage is about picking the *right* task for *right now*, not clearing a queue.
