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

3. **Hand off — `/handoff-summary`.** Emit the Build Handoff Summary in its exact format. Review is a gate, not content — the summary does not restate the `/3p-review` result.

4. **Pause.** Present the handoff summary and **STOP**. Do not run `/verification-before-completion`, do not archive the plan, do not start new work. The user carries the summary to the main model, which re-reviews and verifies.

## If the main model sends back a Rework Brief

The reviewing model returns rework here when the findings are too many or too systemic for it to fix without losing its independence. When you receive one:

1. **Work it item by item, in severity order.** Each item states where, what is wrong, what is required, and the command that proves it. Do not redesign around it — the required change is already decided.
2. **Failing test first, every time.** Reproduce the defect, then fix it. An item fixed with no test that was red first is not done.
3. **Fix the Systemic section as one change**, at every site listed — not site-by-site with three different shapes of fix.
4. **Respect "Do not touch."** Files outside the brief's scope stay untouched, including anything already dirty in the worktree.
5. **Run the "Do not regress" commands** at the end, plus the full suite.
6. **Re-emit `/handoff-summary`** with the rework reflected, then STOP. The reviewing model restarts its review from scratch — your report is a claim it will re-verify, not evidence it will accept.

If an item is wrong or impossible as written, say so explicitly with the reason and stop on that item. Do not silently substitute a different fix.

## Why these boundaries

- **`build-phase` builds; it does not review or hand off.** Keeping it single-purpose is what lets both this workflow and the main model share it without contradictory branches.
- **This workflow owns review + handoff for the build model.** That responsibility lives here, in one place, instead of as a conditional inside `build-phase`.
- **Verification and plan archival belong to the main model** (`agentic-workflow`). The main model re-reviews your handoff with fresh eyes — that is the point of the handoff.

## Guardrails

- **Re-read the plan from disk at the start of every batch.** A resumed thread carries the *conversation*, not the *file*. If the plan was corrected between batches — by the user, by the planning model, or by you after a halt — your thread still remembers the version you discussed, and that memory silently wins over the file you never re-opened. Re-read before acting, and re-read especially right after a correction, when the gap between thread and disk is widest and freshest. The same applies to a Rework Brief you are resuming mid-way.
- **Stage by path when you share a working tree.** If another agent or session has uncommitted work in the same tree, `git add -A` and `git commit -a` sweep it into your commit. Add the specific paths your build touched. (This is a shared-tree hazard: when the build runs in its own git worktree, isolation handles it — but never assume you have one without checking.)
- **Surface plan problems, don't paper over them.** `/build-phase` halts on a plan that is ambiguous, contradictory, *or wrong* — and you are expected to use judgment, not just follow instructions. When you hit a technical, architectural, or practical defect in the plan, stop, state it, propose the fix, and let the user decide. Do not invent design decisions the plan should have made, and do not silently build your own better idea. Anything unresolved goes in the handoff's Concerns.
- **The review loop is a loop.** One clean pass is required; any fix triggers a fresh review.
- **Never skip the handoff.** Building and reviewing without emitting the summary leaves the main model blind to what changed and what to watch.
- **Stop means stop.** After the handoff, your job is done. Do not continue into verification or the next plan.
