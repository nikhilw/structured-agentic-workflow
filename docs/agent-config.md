# Configuring `CLAUDE.md` / `AGENTS.md`

Skills installed globally are discovered automatically — but discovery is not the same as
*adoption*. Your project's agent-config file is what makes the agent open a session already
knowing the workflow exists, which phase it is in, and what your project's hard rules are.

It is the leash. Without it, the agent free-associates: researching tangents, proposing
refactors nobody asked for, and starting to implement before the design is settled.

## Which file

| Agent | File |
|---|---|
| Claude Code | `CLAUDE.md` (project root) |
| Codex / OpenCode / most others | `AGENTS.md` (project root) |
| Cursor | `.cursorrules` (project root) |
| Gemini CLI | `GEMINI.md` (project root) |
| GitHub Copilot | `.github/copilot-instructions.md` |

Same content in all of them. If you use several agents on one repo, keep one canonical file
and symlink the rest.

---

## What belongs in it

### 1. The workflow skills list

The single highest-value block. Listing the skills loads them into context at conversation
start, so the agent can *suggest* phase transitions instead of waiting to be told.

```markdown
## Workflow Skills

ALWAYS follow the Structured Agentic Development Workflow. These skills are installed
globally and define the development lifecycle:

- `agentic-workflow` — orchestrates the full lifecycle; suggests phase transitions automatically
- `/brainstorm` — explore the problem space before planning (no code, no plans)
- `/write-plan` — write phased plans to `docs/plans/new/` (agent-decoupled)
- `/build-phase` — execute one plan phase: test-first → implement → test suite → self-review
- `/build-model` — dedicated build-model session: build → 3p-review → handoff-summary → stop
- `/3p-review` — independent code review; the reviewer owns the code
- `/handoff-summary` — emit the fixed-format Build Handoff Summary
- `/verification-before-completion` — evidence before any "done" claim
- `/triage` — recommend the next task, minimizing context thrash

Startup default: load `agentic-workflow` at startup.
```

> **Do not** add "use graphify" instructions here. `/brainstorm` and `/write-plan` build and
> query the index themselves. Repeating it in the config file just spends context on
> something the skill already does.

### 2. A standing quality bar

One short paragraph that names the failure modes you actually keep hitting. This is the
highest-signal customization in the file — it is your project's accumulated scar tissue.

```markdown
## Standing Instructions

Our recurring failure modes are: missed edge cases; code we never searched for or checked;
and building a duplicate, less capable alternative to something that already exists. Search
everything needed and resolve every doubt before a brainstorm or plan is considered solid.
```

### 3. The project worldview

The architecture facts the agent cannot infer in one session. Keep it dense — every line
costs context on every conversation.

```markdown
## Architecture

- SQLite is the source of truth. All DB access goes through the repository layer.
- Config: Dynaconf + dataclasses. Logging: `logger = get_logger(__name__)`.
- Entity relationships are stored by NAME, not ID.
- Backend: FastAPI (Python 3.13). Frontend: React + TypeScript.
```

### 4. Hard rules (the guardrails)

Phrase these as prohibitions with no wiggle room. Vague preferences get negotiated away
under pressure; absolutes do not.

```markdown
## Hard Rules

- Never use `print()` — use the project logger. Non-negotiable.
- No `any` types in TypeScript; define strict interfaces for all API payloads.
- Use only public APIs of third-party libraries; never import internal/private modules.
- Never modify code without explicit permission. Propose changes one file at a time.
- Do not remove business-logic comments during refactoring without asking first.
```

### 5. Where the backlog lives

```markdown
## Backlog

- Bugs: `docs/plans/bugs.md`
- Features: `docs/plans/features.md`
- Staged plans: `docs/plans/new/`
```

`/triage` reads these. If you use GitHub issues instead, enable it once with
`/workflow-config use github issues` and `/triage` will read the issue tracker.

---

## A complete starting template

Copy this into `CLAUDE.md` or `AGENTS.md` and fill in the project-specific parts.

```markdown
# <Project Name>

## Workflow Skills

ALWAYS follow the Structured Agentic Development Workflow. These skills are installed
globally and define the development lifecycle:

- `agentic-workflow` — orchestrates the full lifecycle; suggests phase transitions automatically
- `/brainstorm` — explore the problem space before planning (no code, no plans)
- `/write-plan` — write phased plans to `docs/plans/new/` (agent-decoupled)
- `/build-phase` — execute one plan phase: test-first → implement → test suite → self-review
- `/build-model` — dedicated build-model session: build → 3p-review → handoff-summary → stop
- `/3p-review` — independent code review; the reviewer owns the code
- `/handoff-summary` — emit the fixed-format Build Handoff Summary
- `/verification-before-completion` — evidence before any "done" claim
- `/triage` — recommend the next task, minimizing context thrash

Startup default: load `agentic-workflow` at startup.

## Standing Instructions

Our recurring failure modes are: missed edge cases; code we never searched for or checked;
and building a duplicate, less capable alternative to something that already exists. Search
everything needed and resolve every doubt before a brainstorm or plan is considered solid.

## Architecture

- <source of truth, layering rules, key libraries, language versions>

## Hard Rules

- Never modify code without explicit permission. Propose changes one file at a time.
- <project-specific prohibitions>

## Backlog

- Bugs: `docs/plans/bugs.md`
- Features: `docs/plans/features.md`
- Staged plans: `docs/plans/new/`
```

---

## Keep it out of the config file

- **Secrets.** This file is committed and loaded into every conversation and every model you
  hand work to — including ones running outside your machine. Reference a credential by the
  name of the variable that supplies it, never by value.
- **A restatement of the workflow.** The skills carry their own instructions. Duplicating
  them here means two sources of truth that drift apart, and the agent follows the shorter
  one.
- **Content pasted from untrusted sources.** Everything in this file is treated as a trusted
  instruction from you. An issue body, a vendor README, or another model's output pasted in
  verbatim is an instruction-injection vector — read it, extract the fact, write the fact.
- **Anything the code already says.** Directory listings and file inventories go stale and
  cost context on every turn. State the rules, not the contents.

## Keep it alive — the memory loop

Even with strict planning, models drift. The config file is where you make a correction
permanent, and updating it is the last step of the fix, not an optional follow-up.

When the agent violates a rule, fix the code **and** write the rule down in the same breath:

- *The agent used `print()` instead of the project logger* → fix it, then add:
  "Always use `logger = get_logger(__name__)`; never use `print()`. Non-negotiable."
- *The agent deleted comments explaining a complex regex while refactoring* → restore them,
  then add: "Do not remove business-logic comments during refactoring without asking first."

A rule you had to state twice belongs in this file. A rule in this file that has never once
been violated is probably costing context for nothing — delete it.
