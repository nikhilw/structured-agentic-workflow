---
name: write-plan
description: Write a formal phased implementation plan to docs/plans/new/. Use after brainstorming is complete and a direction has been chosen. Creates a plan file that decouples the planning agent from the building agent.
argument-hint: [feature-name or brainstorm summary]
allowed-tools: Read, Grep, Glob, Write, Agent
---

# Planning Phase

You are entering the **Planning Phase** of the Structured Agentic Development Workflow.

## Your Mission

Write a detailed, phased implementation plan for: **$ARGUMENTS**

## Rules

1. **Do NOT write implementation code.** You are producing a plan document, not building the feature.
2. **Save the plan to `docs/plans/new/<feature-name>.md`** — not to `docs/plans/` (that is for active plans only).
3. **Divide the work into isolated Phases.** Each phase should be independently testable and reviewable.
4. **Be hyper-granular.** Write the plan so that a different agent — possibly a smaller, faster model — can execute it without ambiguity. Name specific files, functions, classes, and test cases.
5. **Include test criteria for each phase.** What tests must pass before the phase is considered complete?

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

## Phases

### Phase 1: [Name]
**Goal:** [One sentence]
**Files to modify/create:**
- `path/to/file.py` — [what changes]

**Implementation details:**
1. [Step-by-step instructions]

**Test criteria:**
- [ ] [Specific test that must pass]

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

**Self-test:** Before saving the plan, re-read each phase and ask: "Could a junior developer with access to the codebase but zero context about our conversation execute this phase without asking a single clarifying question?" If no, add more detail.

## What Happens Next

After the human reviews and approves the plan:
1. **Move it from `docs/plans/new/` to `docs/plans/`** — this marks it as the active plan. Do this immediately upon approval, do not leave it in `new/`.
2. The user will choose one of two paths:

**Path A — Same model continues to build:**
Begin execution with `/build-phase <plan-file> Phase 1`. The workflow continues in this thread through build → 3p-review → verify.

**Path B — User hands off to a different model for build:**
The user takes the plan file to a smaller/faster model (Gemini Flash, Cursor, Copilot, a local model) for execution. The dev model will build all phases and produce a **handoff summary**. The user will return to this planning model with that summary, and the workflow resumes with `/3p-review` → `/verify`.

Ask the user which path they prefer. If they don't specify, suggest both options.
