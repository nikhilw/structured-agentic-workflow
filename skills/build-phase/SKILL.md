---
name: build-phase
description: Execute one phase from a plan file using the Implement → Test → Self-Review loop. Use when a plan has been approved and it's time to build. Accepts a plan file path and phase number. Full /3p-review runs after ALL phases complete.
argument-hint: [plan-file-path] [Phase N]
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, Agent
---

# Build Phase

You are entering the **Build Phase** of the Structured Agentic Development Workflow.

## Your Mission

Execute **$ARGUMENTS** using the strict phase-wise loop.

## The Loop: Implement → Test → Self-Review → Proceed

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

### Step 3: Self-Review

Review your own changes with a critical eye. This is NOT the full `/3p-review` — that happens after ALL phases are complete. This is a quick self-review to catch obvious issues before moving on.

Check for:
- Does the implementation match what the plan specified?
- Are there any obvious bugs, edge cases, or regressions?
- Does the code follow existing project conventions and patterns?
- Is anything over-engineered or under-tested?

If you find CRITICAL issues, fix them and re-test before proceeding. For minor concerns, note them — the full `/3p-review` will catch them after all phases.

Present the self-review findings to the human for confirmation before proceeding.

### Step 4: Proceed

Report:
- What was implemented
- Test results (pass/fail count)
- Self-review findings and any fixes applied
- Whether you recommend proceeding to the next phase

**Then auto-advance:** if the phase is clean and more phases remain, immediately suggest and begin the next phase. Do not wait for the user to say "proceed" unless the plan requires a human decision gate.

## Resuming After External Model Execution

If the user tells you that code was written by another agent (Cursor, Copilot, a local model, etc.) or simply says "it's done" / "I've implemented Phase N" / pastes a diff:

1. **Do NOT re-implement.** The code is already written.
2. **Immediately run Step 2 (Test)** — verify the external model's work passes tests.
3. **Then run Step 3 (Self-Review)** — review the external model's code carefully. External models are more likely to have drifted from project conventions.
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
2. Invoke `/3p-review` for a **holistic review of the entire feature**. This is the full third-person review — the independent Senior Architect persona with fresh eyes, reviewing ALL changes across ALL phases as a whole. This is where architectural coherence, cross-cutting concerns, and systemic issues are caught.
3. Fix any issues found, re-test, and re-review until clean.
4. Move the plan from `docs/plans/` to `docs/plans/done/`
5. Report the final status and suggest `/verify` for final evidence-based verification.

## What Happens Next

If more phases remain, suggest `/build-phase <plan-file> Phase N+1`.
If all phases are complete and `/3p-review` is clean, suggest `/verify` for final validation.
