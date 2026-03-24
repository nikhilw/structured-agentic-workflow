---
name: agentic-workflow
description: The Structured Agentic Development Workflow — orchestrates brainstorm, write-plan, build-phase, 3p-review, triage, test-driven-development, debug, and verify skills. Use when starting new work, switching between development phases, or when the user asks about the workflow.
user-invocable: false
---

# The Structured Agentic Development Workflow

You are operating under a structured workflow that treats you as a highly capable engineer that lacks object permanence. To produce senior-level results, you follow a rigid scaffolding of context, constraints, and deterministic planning.

## The Workflow Phases

Every significant change follows this cycle: **Brainstorm → Plan → Build → Review**. You must never skip phases or collapse them together.

### Phase Transitions

You MUST drive phase transitions forward automatically. Within the build loop (implement → test → review → next phase), do not wait for the user to tell you to proceed — own the process. For cross-phase transitions (e.g., brainstorm → plan), suggest and confirm. Use this guide:

| Current State | Signal to Transition | Suggest |
|---------------|---------------------|---------|
| Open-ended discussion | User describes a problem or feature need | → `/brainstorm` |
| Brainstorm complete | Options explored, user has picked a direction | → `/write-plan` |
| Plan approved | User says "approved", "let's build", or "proceed" | → `/build-phase` |
| Implementing code | About to write production code | → `/test-driven-development` (write test first) |
| Phase complete | Tests pass, self-review clear | → next `/build-phase` or "all phases complete" |
| All build phases complete | Every phase implemented, tested, self-reviewed | → `/3p-review` (holistic review of entire feature) |
| Code written (any context) | User wants quality assurance | → `/3p-review` |
| Bug, test failure, unexpected behavior | Something is broken | → `/debug` (investigate before fixing) |
| About to claim work is done | Ready to commit, PR, or move on | → `/verify` (evidence before claims) |
| Context loaded with project files | User asks "what should I work on?" | → `/triage` |
| Low context / fresh conversation | Bugs exist in backlog | → `/triage` (will recommend bugs) |

### The Rules

1. **Never jump to code during brainstorm.** Brainstorm produces options and analysis, not implementations.
2. **Never implement without a plan.** Plans are written to `docs/plans/new/` as versioned project assets.
3. **Plans decouple the planning agent from the building agent.** The agent that brainstorms and plans does not have to be the agent that builds. Plans are the contract between them.
4. **Execute one phase at a time.** Each phase goes through Implement → Test → Self-Review before proceeding. The full `/3p-review` runs after ALL phases are complete.
5. **Test first, always.** Use `/test-driven-development` — no production code without a failing test first.
6. **3rd-person review is a mindset, not a checkbox.** The reviewer owns the code now — it must meet world-class standards.
7. **Debug systematically, not randomly.** Use `/debug` — investigate root cause before proposing fixes.
8. **Evidence before claims.** Use `/verify` — never claim work is done without running verification commands and confirming output.
9. **Triage minimizes context thrash.** When recommending work, factor in what is already loaded in the current conversation context — don't suggest work that requires loading entirely different modules.
10. **Resume automatically after external execution.** When the user returns after handing a phase to an external model, immediately pick up the workflow: test the work, review it, fix issues, and advance to the next phase. Do not wait to be told.
11. **The review loop is a loop.** After `/3p-review` finds issues and they are fixed, re-review from scratch. Repeat until clean. Do not stop after one round.

## Plan Directory Lifecycle

- **`docs/plans/new/`** — Brainstormed and written, not yet started. Staging area.
- **`docs/plans/`** — Active plan being executed.
- **`docs/plans/done/`** — Completed plans, kept as audit trail.

Plans accumulate in `new/` — this is intentional. With AI-assisted development, "later" means minutes or hours, not months. Accumulating plans is staging work for rapid parallel execution.

## Task Selection Strategy

When tokens or context are constrained, pick **bugs** — they are small, self-contained, and don't require the full Brainstorm → Plan → Build cycle.

When resources are plentiful, pick **features and plans** — they require sustained attention and the full workflow.

Always minimize context thrash: prefer work that aligns with what's already loaded in the conversation.

## Integration with Your Agent's Config

For best results, list the workflow skills in your project's config file (`CLAUDE.md`, `.cursorrules`, `GEMINI.md`, or `.github/copilot-instructions.md`) so they are loaded automatically:

```markdown
## Workflow Skills
- `agentic-workflow` — orchestrates the structured development lifecycle
- `/brainstorm` — explore problem space, challenge the design, produce decision documents
- `/write-plan` — write phased plans to docs/plans/new/
- `/build-phase` — execute one plan phase with test + self-review
- `/3p-review` — independent third-person code review (after all build phases)
- `/test-driven-development` — RED-GREEN-REFACTOR, test first always (from superpowers)
- `/debug` — 4-phase root cause investigation (from superpowers)
- `/verify` — evidence before claims (from superpowers)
- `/triage` — recommend next task minimizing context thrash
```
