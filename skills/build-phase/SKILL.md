---
name: build-phase
description: Execute one phase from a plan file using the TDD → Test → Self-Review loop. Use when a plan has been approved and it's time to build. Accepts a plan file path and phase number. Produces a handoff summary after all phases. When running as a dedicated build model, also runs /3p-review before handoff — does NOT run /verification-before-completion.
argument-hint: "[plan-file-path] [Phase N]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, Agent
---

# Build Phase

You are entering the **Build Phase** of the Structured Agentic Development Workflow.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## Your Mission

Execute **$ARGUMENTS** using the strict phase-wise loop.

## The Loop: Read Plan → TDD (Red/Green/Refactor) → Test Suite → Self-Review → Proceed

You MUST follow this loop for every phase. Do not skip steps. Every step produces output — do not stop after one step.

### Step 1: Read the Plan

1. Read the plan file and locate the specified phase.
2. Understand what the phase requires: files to modify/create, expected behavior, test criteria.
3. **Surface discrepancies — do not silently work around them.** If the plan is ambiguous, contradictory, or assumes something that doesn't match the codebase, STOP and flag it to the user. Do not guess or make design decisions that the plan should have made. The user may need to take the issue back to the planning model.

### Step 2: TDD — Write Tests, Then Implement

Use `/test-driven-development`. This is mandatory for every phase.

1. **Red:** Write the failing tests first — encode the expected behavior from the plan's test criteria before writing any production code.
2. **Green:** Implement the minimum code to make the tests pass. Implement exactly what the plan describes — no more, no less. Do not refactor surrounding code unless the plan explicitly calls for it.
3. **Refactor:** Clean up while keeping all tests green.

**You must complete all three steps.** Do not stop after writing tests. The tests exist to drive the implementation — writing them is the beginning of the phase, not the end.

### Step 3: Run the Full Test Suite

1. Run the tests specified in the plan's "Test criteria" for this phase.
2. Also run any tests for other modules you modified — check for regressions.
3. Command: `uv run pytest tests/ -x` (or the project's test command).
4. **All tests must pass before proceeding.** If tests fail, fix the implementation — do not modify existing tests to make them pass.

### Step 4: Self-Review

Review your own changes with a critical eye. This is NOT the full `/3p-review` — that happens after ALL phases are complete. This is a quick self-review to catch obvious issues before moving on.

Check for:
- Does the implementation match what the plan specified?
- Are there any obvious bugs, edge cases, or regressions?
- Does the code follow existing project conventions and patterns?
- Is anything over-engineered or under-tested?

If you find CRITICAL issues, fix them and re-test before proceeding. For minor concerns, note them — the full `/3p-review` will catch them after all phases.

Present the self-review findings to the human for confirmation before proceeding.

### Step 5: Proceed

Report:
- What was implemented
- Test results (pass/fail count)
- Self-review findings and any fixes applied
- Whether you recommend proceeding to the next phase

**Then auto-advance:** if the phase is clean and more phases remain, immediately suggest and begin the next phase. Do not wait for the user to say "proceed" unless the plan requires a human decision gate.

## Resuming After External Model Execution

If the user tells you that code was written by another agent (Cursor, Copilot, a local model, etc.) or simply says "it's done" / "I've implemented Phase N" / pastes a diff:

1. **Do NOT re-implement.** The code is already written.
2. **Immediately run Step 3 (Test Suite)** — verify the external model's work passes tests.
3. **Then run Step 4 (Self-Review)** — review the external model's code carefully. External models are more likely to have drifted from project conventions.
4. **Continue the loop** as normal — fix issues, re-test, re-review until clean.
5. **Then auto-advance** to the next phase.

The user should not have to tell you to continue the workflow. You own the process from the moment they hand you back control.

## Phase Completion

When all phases in the plan are complete:

1. Run the FULL test suite: `uv run pytest tests/ -x`
2. **If you are a dedicated build model** (the user set up this session with a smaller/faster model specifically for the build phase): run `/3p-review` on the full implementation. It must pass (zero open findings) before you proceed.
3. Generate a **handoff summary** — cover only what deviated and what concerns remain:

## Build Handoff Summary

**Plan:** [plan file path]

### Deviations
- **Phase 2: [Name]** — [what changed and why, one line]
- (Only list phases that deviated. If nothing deviated, write "None.")

### Concerns
- [Anything the reviewer should specifically investigate or validate]
- (If none, write "None.")

This summary is the handoff artifact. The user carries it to the main model for the post-handoff review.

## What Happens Next

If more phases remain, suggest `/build-phase <plan-file> Phase N+1`.

If all phases are complete and you are the **main model**: present the handoff summary — the agentic-workflow will drive you into `/3p-review`.

If all phases are complete and you are the **dedicated build model**: present the handoff summary and **STOP**. Do not proceed to `/3p-review` or any other phase. The user carries the summary to the main model.
