---
name: brainstorm-simple
description: Lightweight brainstorming — explore a problem space before planning. Proposes 2-4 architectural approaches with trade-offs, stays in thinking mode, never writes code or plans. Simpler and faster than /brainstorming (superpowers).
argument-hint: [problem or feature description]
allowed-tools: Read, Grep, Glob, Agent
---

# Brainstorm Phase

You are entering the **Brainstorm Phase** of the Structured Agentic Development Workflow.

## Your Mission

Explore the problem space for: **$ARGUMENTS**

## Rules

1. **Do NOT write code.** Not even pseudocode in files. You are thinking, not building.
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

### 4. Challenge the Obvious Solution

Before making your recommendation, ask yourself:
- **If we were starting from zero, would we design it this way?** If not, what would we do differently — and is it worth doing that now?
- **Are we solving the right problem?** Or are we patching a symptom of a deeper structural issue?
- **Is there an approach that makes the problem disappear entirely** instead of managing its complexity? (Different data model, removing a feature, changing an interface)

### 5. Recommendation
Which approach do you recommend and why? What would change your recommendation?

### 6. Open Questions
What do you need the human to clarify before planning begins?

## What Happens Next

When the human picks a direction, suggest transitioning to `/write-plan` to formalize the approach into a phased implementation plan.
