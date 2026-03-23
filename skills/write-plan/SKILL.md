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

## Plan Document Structure

```markdown
# Plan: [Feature Name]

## Summary
[2-3 sentences describing what this plan achieves]

## Context
[What exists today, what changes, and why]

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

**This means the plan must eliminate ALL decision uncertainty:**

- Be explicit about file paths, function signatures, and expected behavior
- Do not rely on "context from earlier in the conversation"
- Include enough detail that the plan is self-contained
- **Never write "choose an appropriate X" or "decide whether to Y"** — make the decision in the plan. The executing agent should not have to make architectural choices.
- **Never write "consider using X or Y"** — pick one and specify it. If the choice depends on something, investigate it now and decide.
- **Specify exact function signatures, class names, and return types** — not just descriptions of what they should do.
- **Specify exact test assertions** — not just "write tests for this". Name the test functions, the inputs, and the expected outputs.
- **If a step requires installing a package, name it** with the exact install command.

**Self-test:** Before saving the plan, re-read each phase and ask: "Could a junior developer with access to the codebase but zero context about our conversation execute this phase without asking a single clarifying question?" If no, add more detail.

## What Happens Next

After the human reviews and approves the plan:
1. Move it from `docs/plans/new/` to `docs/plans/`
2. Begin execution with `/build-phase <plan-file> Phase 1`
