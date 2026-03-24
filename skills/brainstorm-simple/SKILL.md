---
name: brainstorm-simple
description: Explore a problem space before planning. Proposes architectural approaches with trade-offs, challenges the obvious solution, estimates impact, and produces a decision document. Code is the LAST thing we touch — this skill never writes code or plans.
argument-hint: [problem or feature description]
allowed-tools: Read, Grep, Glob, Agent, Write
---

# Brainstorm Phase

You are entering the **Brainstorm Phase** of the Structured Agentic Development Workflow.

<HARD-GATE>
Do NOT write code, create plan files, scaffold projects, or take ANY implementation action during brainstorming. Code is the LAST thing we touch — not the first. This applies regardless of how simple the task seems. You are thinking, not building.
</HARD-GATE>

## Your Mission

Explore the problem space for: **$ARGUMENTS**

## Rules

1. **Code is the LAST thing we touch.** Not even pseudocode in files. You are thinking, not building.
2. **Do NOT create a plan file.** That is the next phase. If you write a plan now, you will skip the critical thinking step.
3. **Do NOT enter your internal planning-executing loop.** Stay in analysis mode.
4. **DO explore the existing codebase** to understand what exists, what patterns are in use, and what constraints apply.
5. **DO propose 2-4 architectural approaches** with clear trade-offs for each.
6. **DO identify risks, unknowns, and dependencies** that will affect the plan.
7. **DO research third-party packages** via their documentation (not source code) if relevant.

## Output Structure

### 1. Problem Understanding
Restate the problem in your own words. Identify the core need vs. nice-to-haves.

### 2. Current State Analysis
What exists today? What code, patterns, or infrastructure is already in place that this work touches?

### 3. Proposed Approaches

You MUST include both ends of the spectrum — don't just propose variations of the same idea:

- **At least one minimal approach:** What is the smallest, simplest change that solves the core problem? Could this be a 10-line fix instead of a new module?
- **At least one structural/ambitious approach:** If we were building this from scratch with no legacy constraints, what would the ideal design look like? Even if it requires broader changes, name it — the user decides whether the scope is worth it.

For each approach:
- **Name:** A short descriptive name
- **How it works:** 2-3 sentence summary
- **Pros:** What makes this attractive
- **Cons:** What are the risks or costs
- **Complexity:** Low / Medium / High
- **Scope of change:** How many files/modules touched? Is this localized or cross-cutting?
- **Impact estimate:** What is the blast radius? What breaks, what improves, what gets simpler, what gets harder? One paragraph.

### 4. Challenge the Obvious Solution

Before making your recommendation, ask yourself:
- **If we were starting from zero, would we design it this way?** If not, what would we do differently — and is it worth doing that now?
- **Are we solving the right problem?** Or are we patching a symptom of a deeper structural issue?
- **Is there an approach that makes the problem disappear entirely** instead of managing its complexity? (Different data model, removing a feature, changing an interface)

### 5. Recommendation
Which approach do you recommend and why? What would change your recommendation?

### 6. Open Questions
What do you need the human to clarify before planning begins?

## After the Discussion — Save the Decision Document

Once the user has picked a direction (or the discussion has reached a natural conclusion), **ask the user if they'd like to save the discussion as a decision document.** Brainstorming sessions are where architectural decisions are made and trade-offs are weighed — this context is valuable and worth preserving.

If the user agrees, write a decision document to `docs/discussions/YYYY-MM-DD-<topic>.md` with this structure:

```markdown
# Decision: [Topic]

*Date: YYYY-MM-DD*

## Problem
[What we were trying to solve]

## Approaches Considered

### [Approach A name]
- **How it works:** [summary]
- **Pros:** [list]
- **Cons:** [list]
- **Impact:** [blast radius summary]

### [Approach B name]
...

## Decision
**Chosen approach:** [name]

**Why this approach won:**
- [key reason 1]
- [key reason 2]

**Why the others were rejected:**
- [Approach X]: [specific reason it lost]
- [Approach Y]: [specific reason it lost]

## Consequences
- [What this decision enables]
- [What this decision makes harder or rules out]
- [What to watch for / revisit if assumptions change]
```

## What Happens Next

When the human picks a direction, suggest transitioning to `/write-plan` to formalize the approach into a phased implementation plan.
