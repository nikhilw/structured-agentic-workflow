---
name: build-phase
description: Execute one phase from a plan file using the Implement → Test → 3rd-Person Review loop. Use when a plan has been approved and it's time to build. Accepts a plan file path and phase number. Invokes /3p-review as part of the loop.
argument-hint: [plan-file-path] [Phase N]
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, Agent
---

# Build Phase

You are entering the **Build Phase** of the Structured Agentic Development Workflow.

## Your Mission

Execute **$ARGUMENTS** using the strict phase-wise loop.

## The Loop: Implement → Test → Review → Proceed

You MUST follow this loop for every phase. Do not skip steps.

### Step 1: Implement

1. Read the plan file and locate the specified phase.
2. Implement exactly what the plan describes — no more, no less.
3. Do not refactor surrounding code unless the plan explicitly calls for it.
4. Do not add features, error handling, or "improvements" beyond what is specified.

### Step 2: Test

1. Run the tests specified in the plan's "Test criteria" for this phase.
2. If no specific tests are listed, run the tests for the modules you modified.
3. Command: `uv run pytest tests/ -x` (or the project's test command).
4. **All tests must pass before proceeding.** If tests fail, fix the implementation — do not modify existing tests to make them pass.

### Step 3: Third-Person Review

Invoke `/3p-review` on the changes you just made. This is not optional.

The review follows the full 3p-review protocol: switch personas to an independent Senior Architect who did NOT write this code, who now owns it, and who holds it to world-class standards.

If the review surfaces CRITICAL or MAJOR issues, fix them, re-run tests, and re-review.

### Step 4: Proceed

Report:
- What was implemented
- Test results (pass/fail count)
- Review findings and fixes applied
- Whether you recommend proceeding to the next phase

## BDD/TDD Integration (Evolving)

When the plan includes behavioral specifications or acceptance criteria, prefer this order:
1. Write the failing test first (red)
2. Implement the minimum code to pass (green)
3. Refactor while keeping tests green (refactor)

This discipline will be further enforced via a dedicated BDD/TDD skill in the future.

## Phase Completion

When all phases in the plan are complete:
1. Run the FULL test suite: `uv run pytest tests/ -x`
2. Move the plan from `docs/plans/` to `docs/plans/done/`
3. Report the final status

## What Happens Next

If more phases remain, suggest `/build-phase <plan-file> Phase N+1`.
If all phases are complete, the feature is done — suggest any follow-up work if appropriate.
