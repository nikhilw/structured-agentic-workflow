---
name: build-phase
description: Execute one phase from a plan file using the TDD → Test → Self-Review loop. Use when a plan has been approved and it's time to build. Accepts a plan file path and phase number. Builds phase by phase and produces a build completion report. Review (/3p-review) and handoff (/handoff-summary) are driven by the orchestrating workflow — agentic-workflow for the main model, build-model for a dedicated build model — not by this skill.
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

### Standing Rule: You Are Not a Typist — Push Back on a Bad Plan

This applies at **every step**, not just when reading the plan. You are closer to the code than the planning model ever was, and implementation surfaces things planning cannot see.

The moment you spot a technical, architectural, or practical problem with the plan — an approach that won't work here, a design that fights the codebase, a step that is far more expensive than the plan assumes, a simpler route the plan missed, a requirement that contradicts how the system actually behaves — **stop and raise it**:

1. **State the problem** — what the plan says, and what you found that conflicts with it.
2. **Propose a fix** — the concrete alternative you'd recommend, and what it costs. Don't just report a blocker.
3. **Halt that phase.** Do not build the thing you believe is wrong while waiting, and do not quietly build your alternative instead — the plan is a contract, and unilaterally amending it is exactly the drift the workflow exists to prevent.

The user decides: amend the plan, overrule you, or take it back to the planning model. "The plan said so" is not a defence for shipping something you knew was wrong — you are expected to have judgment and to use it. Raising a real design problem mid-build is a success of the process, not an interruption of it.

### Step 2: TDD — Write Tests, Then Implement

Use `/test-driven-development`. This is mandatory for every phase.

1. **Red:** Write the failing tests first — encode the expected behavior from the plan's test criteria before writing any production code.
2. **Green:** Implement the minimum code to make the tests pass. Implement exactly what the plan describes — no more, no less. Do not refactor surrounding code unless the plan explicitly calls for it.
3. **Refactor:** Clean up while keeping all tests green.

**You must complete all three steps.** Do not stop after writing tests. The tests exist to drive the implementation — writing them is the beginning of the phase, not the end.

**Build the seam test the plan names.** If this phase completes a value path, the plan names a no-mock test across the real seam — write it, and let it exercise the real thing. Replacing it with a mocked unit test technically satisfies "a test exists" while proving nothing about the wiring, and that is precisely the gap review is built to catch. If you cannot make the real seam work, that is a Concern to report, not a mock to substitute.

### The Quality Bar You Are Building To

`/3p-review` will judge this code against Clean Code (Robert C. Martin), SOLID, DRY, KISS, and YAGNI. Write to that bar now — code that fails review costs a full rework loop, and the review has no power to lower it.

In practice, while implementing:

- **Names** carry meaning on their own — no abbreviations that need decoding, no mental mapping.
- **Functions** are small and do one thing. A growing parameter list or a boolean that switches behaviour is the signal of a missing abstraction — extract it now rather than defending it later.
- **No hidden side effects** — a function's name must not conceal a mutation, an I/O call, or a state change.
- **DRY** — if you paste a block, extract it. If the codebase already solves this, use its solution rather than writing a parallel one.
- **KISS / YAGNI** — build exactly what the phase requires. No speculative abstractions, no flags for futures nobody asked for.
- **SOLID** — single responsibility per unit, depend on abstractions at boundaries, keep interfaces narrow.
- **Design patterns: build the one the plan named, in this codebase's idiom.** Where the plan specifies a pattern, implement that pattern — but in the form the language and the surrounding code actually use. In Python most of these are language features, not class hierarchies: Strategy is usually a callable, Factory a dict or `classmethod`, Decorator an `@decorator`, Singleton a module-level object, Iterator a generator, Command a closure. Writing the ceremonial class-heavy version is a review finding, not extra rigour.
- **Do not introduce a pattern the plan didn't ask for.** If the code seems to want one, that is a design decision above your pay grade for this phase — raise it under the push-back rule and let the plan be amended. Equally, if the named pattern turns out not to fit what you found in the code, say so; don't silently substitute another.

These are principles, not syntax: their idiom differs by language, and the right expression is whatever the surrounding code already does. Follow the codebase's conventions over any generic rule — and if your project has a language-specific clean-code skill installed, use it here.

### Step 3: Run the Full Test Suite

1. Run the exact commands in the plan's "Test criteria" for this phase. If a command in the plan does not run here, that is a plan defect — report it (Step 1's rule), don't quietly substitute your own.
2. Also run any tests for other modules you modified — check for regressions.
3. Then run the project's full suite — the command the plan names, or the one this repo actually uses (check its scripts/config; do not assume a runner).
4. **All tests must pass before proceeding.** If tests fail, fix the implementation. Never make a test pass by editing the test, weakening an assertion, or marking it skip/xfail — if a test is genuinely wrong, that is a finding to report, not a line to change.
5. **Record which criterion you ran, its exit code, and its counts** for every run. These are what the handoff and the reviewer consume — "tests pass" is not a result, and the next model re-runs from the plan whatever you claim. Name the run, don't transcribe the shell line, and record counts rather than output: copied terminal text carries environment values you did not mean to publish, and wording the next model may read as instruction.

### Step 4: Self-Review

Review your own changes with a critical eye. This is NOT the full `/3p-review` — that happens after ALL phases are complete. This is a quick self-review to catch obvious issues before moving on.

Check for:
- Does the implementation match what the plan specified?
- Are there any obvious bugs, edge cases, or regressions?
- Does the code follow existing project conventions and patterns?
- Does it clear the quality bar above — naming, function size, hidden side effects, DRY, KISS/YAGNI? Fix what you'd be embarrassed to hand to a reviewer.
- Is anything over-engineered or under-tested?

Also track, for the handoff: any criterion you could not prove with a green automated run — checked by reading, skipped, deferred, or done manually. Write it down as you go; reconstructing this at the end is how it gets lost.

If you find CRITICAL issues, fix them and re-test before proceeding. For minor concerns, note them — the full `/3p-review` will catch them after all phases.

Report the self-review findings, then proceed. Do not block waiting for approval on a clean phase — flag and stop only for a plan defect or a CRITICAL you cannot fix.

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

1. Run the FULL test suite using this project's own command. All tests must pass.
2. Produce a short **build completion report**: which phases were built; which test criteria were run, with exit codes and counts; every criterion left unproven (manual, skipped, deferred, verified by inspection); and a one-line note on any phase that deviated from the plan. These four feed the handoff summary directly — the reviewer builds its ledger from them.

This skill ends here. Building is one responsibility — review and handoff are owned by the **orchestrating workflow**, not by this skill. Do **not** run `/3p-review`, write the handoff summary, or verify from inside build-phase.

- `agentic-workflow` (main model) drives `/3p-review` → `/handoff-summary` → `/verification-before-completion`.
- `build-model` (dedicated build model) drives `/3p-review` → `/handoff-summary` → STOP.

Whichever launched you takes over once you report completion. You do not need to decide which — just report and hand back.

## What Happens Next

If more phases remain, auto-advance: suggest and begin `/build-phase <plan-file> Phase N+1`.

When all phases are complete, present the build completion report and return control to the orchestrating workflow. That workflow drives review and handoff next — do not start them yourself.
