---
name: agentic-workflow
description: The Structured Agentic Development Workflow — orchestrates brainstorm, write-plan, build-phase, 3p-review, and triage skills. Use when starting new work, switching between development phases, or when the user asks about the workflow. Defines the full lifecycle and tells the agent when to invoke each phase skill.
user-invocable: false
---

# The Structured Agentic Development Workflow

You are operating under a structured workflow that treats you as a highly capable engineer that lacks object permanence. To produce senior-level results, you follow a rigid scaffolding of context, constraints, and deterministic planning.

## The Workflow Phases

Every significant change follows this cycle: **Brainstorm → Plan → Build → Review**. You must never skip phases or collapse them together.

### Phase Transitions

You SHOULD proactively suggest phase transitions when the conversation naturally reaches one. Use this guide:

| Current State | Signal to Transition | Suggest |
|---------------|---------------------|---------|
| Open-ended discussion | User describes a problem or feature need | → `/brainstorm` |
| Brainstorm complete | Options explored, user has picked a direction | → `/write-plan` |
| Plan approved | User says "approved", "let's build", or "proceed" | → `/build-phase` |
| Phase complete | Tests pass, review clear | → next `/build-phase` or "all phases complete" |
| Code written (any context) | User wants quality assurance | → `/3p-review` |
| Context loaded with project files | User asks "what should I work on?" | → `/triage` |
| Low context / fresh conversation | Bugs exist in backlog | → `/triage` (will recommend bugs) |

### The Rules

1. **Never jump to code during brainstorm.** Brainstorm produces options and analysis, not implementations.
2. **Never implement without a plan.** Plans are written to `docs/plans/new/` as versioned project assets.
3. **Plans decouple the planning agent from the building agent.** The agent that brainstorms and plans does not have to be the agent that builds. Plans are the contract between them.
4. **Execute one phase at a time.** Each phase goes through Implement → Test → 3rd-Person Review before proceeding.
5. **3rd-person review is a mindset, not a checkbox.** The reviewer owns the code now — it must meet world-class standards.
6. **Triage minimizes context thrash.** When recommending work, factor in what is already loaded in the current conversation context — don't suggest work that requires loading entirely different modules.

## Plan Directory Lifecycle

- **`docs/plans/new/`** — Brainstormed and written, not yet started. Staging area.
- **`docs/plans/`** — Active plan being executed.
- **`docs/plans/done/`** — Completed plans, kept as audit trail.

Plans accumulate in `new/` — this is intentional. With AI-assisted development, "later" means minutes or hours, not months. Accumulating plans is staging work for rapid parallel execution.

## Task Selection Strategy

When tokens or context are constrained, pick **bugs** — they are small, self-contained, and don't require the full Brainstorm → Plan → Build cycle.

When resources are plentiful, pick **features and plans** — they require sustained attention and the full workflow.

Always minimize context thrash: prefer work that aligns with what's already loaded in the conversation.

## Integration with CLAUDE.md

For best results, list the workflow skills in your project's `CLAUDE.md` so they are loaded automatically:

```markdown
## Workflow Skills
- `agentic-workflow` — orchestrates the structured development lifecycle
- `/brainstorm` — explore problem space before planning
- `/write-plan` — write phased plans to docs/plans/new/
- `/build-phase` — execute one plan phase with test + review
- `/3p-review` — independent third-person code review (standalone or within build)
- `/triage` — recommend next task minimizing context thrash
```
