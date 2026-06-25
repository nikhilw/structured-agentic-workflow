---
name: write-plan
description: Write a formal phased implementation plan to docs/plans/new/. Use after brainstorming is complete and a direction has been chosen. Creates a plan file that decouples the planning agent from the building agent.
argument-hint: [feature-name or brainstorm summary]
allowed-tools: Read, Grep, Glob, Write, Agent
---

# Planning Phase

You are entering the **Planning Phase** of the Structured Agentic Development Workflow.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## Your Mission

Write a detailed, phased implementation plan for: **$ARGUMENTS**

## Rules

1. **Do NOT write implementation code.** You are producing a plan document, not building the feature.
2. **Save the plan to `docs/plans/new/<feature-name>.md`** — not to `docs/plans/` (that is for active plans only).
3. **Divide the work into isolated Phases.** Each phase should be independently testable and reviewable.
4. **Be hyper-granular.** Write the plan so that a different agent — possibly a smaller, faster model — can execute it without ambiguity. Name specific files, functions, classes, and test cases.
5. **Include test criteria for each phase**, expressed as the **exact command + expected output** — not a vague "tests pass". The executing model needs an objective stop condition, not a judgment call.
6. **Write down the foresight, don't leave it in your head.** A smaller build model builds exactly what is specified and fills every silence with the happy path. The errors it makes are not bad guesses — they are *gaps*: failure modes, lifetimes, error codes, and cross-component interactions you anticipated but never wrote down. The Failure-Mode & Interaction Analysis below is where that foresight becomes part of the contract.
7. **Name the seam test for every value path.** Green unit tests do not prove the wiring works. For each path data must traverse to deliver value (e.g. worker → DB, request → handler → response), the plan MUST name a no-mock test that exercises the real seam. If you don't name it, the build model will not write it.

## Before Writing the Plan — Codebase Analysis

Before writing a single phase, you MUST investigate the existing codebase. Read code, grep for patterns, understand what's already there. This analysis feeds directly into the plan and prevents the review from catching issues that should have been designed out.

### Consistency & Patterns
- **How is this problem solved elsewhere?** Grep for similar functionality. If the codebase already has a pattern for this (e.g., a base class, a utility, a convention), the plan MUST use it — not invent a new one.
- **What can be extracted or reused?** If the new feature shares logic with existing code, the plan should include a phase for extracting the common pattern first.
- **What naming and structural conventions exist?** The plan must follow them. Name new files, classes, and functions consistent with their neighbors.

### Security
- **Does this feature touch user input, external APIs, or stored data?** If yes, the plan must include input validation, output encoding, or access control steps in the relevant phases.
- **Does this introduce new attack surface?** (new endpoints, new file I/O, new shell commands, new credentials) If yes, call it out in Risks & Mitigations.

### Architecture Fit
- **Does this change respect existing boundaries?** (module boundaries, layer separation, dependency direction) If the feature requires crossing a boundary, that's a design decision — make it explicit and justify it.
- **What existing code will this interact with?** List the specific files, classes, and functions. The plan must account for their interfaces, not assume them.

### Failure-Mode & Interaction Analysis

This is the highest-value part of the analysis for a handed-off build. The build model implements each piece correctly in isolation and misses how the pieces fail or interact. Anticipate those misses here and write them into the relevant phases as concrete requirements — not as vague warnings.

Work through each of these and resolve them in the plan:

- **Lifetimes & expiry.** Does anything have a TTL, timeout, cache duration, token/cookie lifetime, or session window? For each: what happens at the moment it expires, and does its lifetime have to be coordinated with another component's? *(A cookie expiring at the access-token TTL silently breaks the next mutating request — name that requirement, don't let the build model discover it.)*
- **Error & status codes at every boundary.** Enumerate the failure codes/exceptions each seam can emit (401 vs 403, timeout, 409, validation error) and specify exactly **who handles each one**. A reactive handler that only handles one code will be defeated by the others.
- **State transitions & lifecycle paths.** For anything started, it must be stopped/cancelled/cleaned up. Specify the cancellation and shutdown paths explicitly, including concurrent cleanup (multiple tasks cancelled together must each be awaited — a shared suppressor leaks the second). Name the path; do not assume "finally" is enough.
- **Cross-component interactions.** For each pair of components that touch: "when A changes/fails, what must B do?" Make the dependency explicit in both phases.
- **Concurrency & ordering.** Races, ordering assumptions, partial failure, retries. If two things run together, state what happens if one fails first.

Every item you surface here becomes either a phase implementation step or a named test below. An anticipated failure mode with no corresponding test is not actually handled.

## Plan Document Structure

```markdown
# Plan: [Feature Name]

## Summary
[2-3 sentences describing what this plan achieves]

## Context
[What exists today, what changes, and why]

## Codebase Analysis
- **Existing patterns used:** [patterns/utilities this plan reuses]
- **New patterns introduced:** [if any — justify why existing patterns don't fit]
- **Security considerations:** [attack surface, input boundaries, access control]
- **Files/modules affected:** [list with brief description of each interaction]

## Failure Modes & Interactions
- **Lifetimes/expiry:** [each TTL/timeout/session and its behavior at expiry + coordination requirement]
- **Boundary error codes:** [code/exception → who handles it]
- **Lifecycle/cancellation:** [start → stop/cleanup path for each long-lived thing]
- **Cross-component interactions:** [when A changes/fails → what B must do]

## Value Paths & Seam Tests
- **[value path, e.g. worker → DB heartbeat]:** named no-mock test → [test name + what it asserts at the real seam]

## Phases

### Phase 1: [Name]
**Goal:** [One sentence]
**Files to modify/create:**
- `path/to/file.py` — [what changes]

**Implementation details:**
1. [Step-by-step instructions]

**Test criteria:** (each as command + expected output)
- [ ] `exact command to run` → [expected output / assertion that proves the phase is done]
- [ ] Seam test (if this phase completes a value path): `command` → [no-mock assertion across the real seam]

### Phase 2: [Name]
...

## Risks & Mitigations
- [Risk] → [Mitigation]

## Out of Scope
- [What this plan explicitly does NOT cover]
```

## Agent Decoupling — Zero Ambiguity for External Models

This plan is designed as a **contract between agents**. The agent that writes this plan does not have to be the agent that executes it — it may be a smaller model (Gemini Flash, GPT-4o-mini), a different tool (Cursor Composer, Copilot), or a local model with no conversation history.

**This means the plan must resolve ALL decisions. No open questions may remain:**

- Be explicit about file paths, function signatures, and expected behavior
- Do not rely on "context from earlier in the conversation"
- Include enough detail that the plan is self-contained
- **Never write "choose an appropriate X" or "decide whether to Y"** — make the decision in the plan. The executing agent should not have to make architectural choices.
- **Never write "consider using X or Y"** — pick one and specify it. If the choice depends on something, investigate it now and decide.
- **Specify exact function signatures, class names, and return types** — not just descriptions of what they should do.
- **Specify exact test assertions** — not just "write tests for this". Name the test functions, the inputs, and the expected outputs.
- **If a step requires installing a package, name it** with the exact install command.
- **Resolve all design trade-offs in the plan itself.** The plan need not include all the code, but it MUST include all decisions. The dev model's job is to execute, not to design.

**Self-test:** Before saving the plan, re-read each phase and ask:
- "Could a junior developer with access to the codebase but zero context about our conversation execute this phase without asking a single clarifying question?" If no, add more detail.
- "For every long-lived thing, TTL, and boundary I introduced — did I write down what happens at expiry/failure and who handles each error code?" If a failure mode lives only in my head, it will not be built. Move it into Failure Modes & Interactions.
- "Does every value path have a named no-mock seam test in the plan?" An anticipated interaction with no test is not handled — the build model will skip it.
- "Is every test criterion an exact command with an expected result, not a vague 'tests pass'?"

## What Happens Next

After the human reviews and approves the plan:
1. **Move it from `docs/plans/new/` to `docs/plans/`** using plain `mv` (not `git mv` — the plan file may not be tracked by git yet). This marks it as the active plan. Do this immediately upon approval, do not leave it in `new/`.
2. The user will choose one of two paths:

**Path A — Same model continues to build:**
Begin execution with `/build-phase <plan-file> Phase 1`. The workflow continues in this thread through build → 3p-review → verify.

**Path B — User hands off to a different model for build:**
The user takes the plan file to a smaller/faster model (Gemini Flash, Cursor, Copilot, a local model) for execution. The dev model will build all phases and produce a **handoff summary**. The user will return to this planning model with that summary, and the workflow resumes with `/3p-review` → `/verification-before-completion`.

Ask the user which path they prefer. If they don't specify, suggest both options.
