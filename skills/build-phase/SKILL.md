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

**This is a loop:** if the review surfaces CRITICAL or MAJOR issues → fix → re-test → re-review from scratch. Repeat until clean. Do not wait for the user to tell you to re-review.

### Step 4: Proceed

Report:
- What was implemented
- Test results (pass/fail count)
- Review findings, rounds, and fixes applied
- Whether you recommend proceeding to the next phase

**Then auto-advance:** if the phase is clean and more phases remain, immediately suggest and begin the next phase. Do not wait for the user to say "proceed" unless the plan requires a human decision gate.

## Resuming After External Model Execution

If the user tells you that code was written by another agent (Cursor, Copilot, a local model, etc.) or simply says "it's done" / "I've implemented Phase N" / pastes a diff:

1. **Do NOT re-implement.** The code is already written.
2. **Immediately run Step 2 (Test)** — verify the external model's work passes tests.
3. **Then run Step 3 (3p-review)** — review the external model's code with full rigor. External models are more likely to have drifted from project conventions.
4. **Continue the loop** as normal — fix issues, re-test, re-review until clean.
5. **Then auto-advance** to the next phase.

The user should not have to tell you to continue the workflow. You own the process from the moment they hand you back control.

## BDD/TDD Integration

When the plan includes behavioral specifications or acceptance criteria, use `/test-driven-development` and follow this order:
1. Write the failing test first (red)
2. Implement the minimum code to pass (green)
3. Refactor while keeping tests green (refactor)

## Phase Completion

When all phases in the plan are complete:
1. Run the FULL test suite: `uv run pytest tests/ -x`
2. Move the plan from `docs/plans/` to `docs/plans/done/`
3. Report the final status

## What Happens Next

If more phases remain, suggest `/build-phase <plan-file> Phase N+1`.
If all phases are complete, the feature is done — suggest any follow-up work if appropriate.
