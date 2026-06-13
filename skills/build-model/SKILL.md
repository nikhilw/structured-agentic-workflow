---
name: build-model
description: Entry point for a dedicated build model — a smaller/faster model run in a session whose only job is to build a plan, review it, and hand off. Orchestrates /build-phase across all phases, then /3p-review (loop until clean), then /handoff-summary, then pauses. Does NOT run /verification-before-completion. The main model uses agentic-workflow instead.
argument-hint: "[plan-file-path]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, Agent
---

# Build Model Workflow

You are running as a **dedicated build model**: a focused session — usually a smaller or faster model — whose entire job is to build a plan to completion, review it, and produce a clean handoff for the main model. You are NOT the main model and you do NOT run the full lifecycle.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## Your Mission

Build the plan at **$ARGUMENTS** to completion, review it, and hand it off — then stop.

## The Sequence

Run these steps **in order**. Each step has a clear owner; do not collapse them or skip ahead. Finishing one step is the trigger to start the next — not a reason to stop.

1. **Build — `/build-phase`.** Start at Phase 1 and advance through every phase. `/build-phase` owns the per-phase loop (Read Plan → TDD → Test Suite → Self-Review) and auto-advances between phases. Let it run until all phases are built and the full test suite passes, then take back its build completion report.

2. **Review — `/3p-review`.** Run a holistic third-person review of the **entire** implementation. This is a loop: if it raises any findings, fix them and re-review from scratch. Continue until **zero open findings**. Completing the build is what triggers this step — do not stop after building.

3. **Hand off — `/handoff-summary`.** Emit the Build Handoff Summary in its exact format. Record the `/3p-review` result in the summary's `3p-review` line.

4. **Pause.** Present the handoff summary and **STOP**. Do not run `/verification-before-completion`, do not archive the plan, do not start new work. The user carries the summary to the main model, which re-reviews and verifies.

## Why these boundaries

- **`build-phase` builds; it does not review or hand off.** Keeping it single-purpose is what lets both this workflow and the main model share it without contradictory branches.
- **This workflow owns review + handoff for the build model.** That responsibility lives here, in one place, instead of as a conditional inside `build-phase`.
- **Verification and plan archival belong to the main model** (`agentic-workflow`). The main model re-reviews your handoff with fresh eyes — that is the point of the handoff.

## Guardrails

- **Surface plan discrepancies, don't paper over them.** `/build-phase` will stop and flag an ambiguous or contradictory plan. Do not invent design decisions the plan should have made — report them in the handoff's Concerns.
- **The review loop is a loop.** One clean pass is required; any fix triggers a fresh review.
- **Never skip the handoff.** Building and reviewing without emitting the summary leaves the main model blind to what changed and what to watch.
- **Stop means stop.** After the handoff, your job is done. Do not continue into verification or the next plan.
