# Our workflow vs. obra/superpowers — approach differences

_Last reviewed: 2026-06-25 (against superpowers `main`)._

Both projects ship agent skills for disciplined development. The philosophies have
diverged. This is where each approach is stronger.

## The core difference

- **superpowers** is a **toolbox** — ~14 loosely-coupled skills (worktrees, parallel
  agents, code-review request/receive, plan execution, skill authoring) the agent
  picks from. Its center of gravity is *how to author and operate skills well*.
- **ours** is an **opinionated end-to-end lifecycle** — one orchestrator
  (`agentic-workflow`) drives a fixed cycle (Brainstorm → Plan → Build → 3p-Review →
  Verify) with enforced phase transitions. Its center of gravity is *not letting the
  agent skip steps*.

## Where we win

- **The 3p-review quality gate.** Our reviewer switches persona to an independent
  Senior Architect who *takes ownership* on sign-off, loops until **zero findings of
  any severity** (minors are fixed, not waved), and must clear an **integration-seam
  gate** (no PASS without a no-mock test across the value path). Superpowers splits
  this into lighter `requesting-code-review` / `receiving-code-review` skills with no
  ownership framing and no seam gate.
- **Cross-model cost split.** Two build entry points (`build-model` for a cheap/fast
  model, `agentic-workflow` for the main model) plus a fixed-format `handoff-summary`
  contract. The plan is a **contract between a planning model and a smaller build
  model**. Superpowers assumes one capable agent throughout and doesn't optimize for
  this hand-off.
- **Plan-as-contract foresight.** `write-plan` resolves *all* decisions up front and
  (as of 2026-06-25) forces failure-mode/interaction analysis and **named seam tests**
  into the plan — moving the expensive model's foresight upstream so the cheap build
  model can't fill silences with the happy path.
- **Enforced lifecycle.** Explicit phase-transition table and plan lifecycle
  (`new/` → `plans/` → `done/`). The agent owns forward motion instead of stalling
  between phases.
- **Configurability.** `workflow-config` (TDD/BDD, caveman output brevity) and caveman
  token-efficiency integration — knobs superpowers doesn't offer.

## Where they win

- **Skill-authoring discipline.** `writing-skills` is a rigorous meta-skill:
  behavioral skill testing with subagents (RED/GREEN/REFACTOR via pressure
  scenarios), rationalization tables, CSO descriptions, persuasion principles. We
  author skills ad hoc and discover failures (e.g. "stops after build") only in
  production.
- **Parallelism & subagents.** `subagent-driven-development` and
  `dispatching-parallel-agents` — patterns we have no equivalent for.
- **Branch/worktree hygiene.** `using-git-worktrees` and
  `finishing-a-development-branch` formalize isolation and clean branch closure; we
  leave this to the human.
- **Separation of plan execution.** `executing-plans` is a distinct skill; we fold
  execution into `build-phase`.
- **CSO descriptions.** Their descriptions state *only when to use* a skill; several
  of ours still summarize the workflow (the anti-pattern they warn causes the model to
  follow the description instead of reading the skill).

## One-line summary

We are stronger at **enforcing a disciplined lifecycle and a hard review gate across a
cheap/expensive model split**; they are stronger at **the meta-craft of authoring,
testing, and composing skills, plus parallel/branch tooling.**

See `superpowers-learnings.md` for what to adopt.
