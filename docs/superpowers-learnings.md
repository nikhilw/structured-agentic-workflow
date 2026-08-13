# What to adopt from obra/superpowers

_Companion to `superpowers-comparison.md`. Last reviewed: 2026-06-25._

Prioritized list of what we can pull in, highest-leverage first. Adopt the **idea**,
re-expressed in our own skills — do **not** hand-edit vendored copies (they are
overwritten by `pull-superpowers.sh`).

## 1. Behavioral skill testing (highest leverage)

From `writing-skills` + `testing-skills-with-subagents.md`.

A skill has no code, so its **test is a subagent's behavior under pressure**:

- **RED** — write a *pressure scenario* (a realistic task combining 3+ pressures: time,
  sunk cost, authority, exhaustion, pragmatism) as a concrete A/B/C choice. Run a fresh
  subagent on it **without** the skill. Record the wrong choice and its **verbatim
  rationalization**.
- **GREEN** — write the minimal skill text that names and blocks *that* rationalization.
  Re-run; it passes when the subagent makes the right call under pressure **and cites
  the skill**.
- **REFACTOR** — capture each new excuse into a **rationalization table**; re-test.

**Why it matters for us:** our "stops after build" bug was a skill that failed a
pressure test we never ran. Adopting this turns "the skill looks right" into "the skill
holds under pressure." Start by retro-testing the recently-churned skills
(`build-phase`, `build-model`, `3p-review`, and the new `write-plan` foresight sections).

**Concrete step:** store scenarios per skill (e.g. `skills/<name>/pressure-tests.md`);
this is the QA layer the repo currently lacks entirely.

## 2. Rationalization tables + red-flag sections in skill bodies

We already write these inline and scattered. Consolidate into a named section per skill
so excuses accumulate instead of being re-discovered. Known ones to seed:

- `build-phase`/`build-model`: "build's done, I'll stop" · "I'll let the user run review"
- `verification-before-completion` (our framing): "review already ran the tests"
- `3p-review`: "it's minor, fix later" · "tests are green so it works"
- `handoff-summary`: "I'll paraphrase the template"

## 3. CSO descriptions (Claude Search Optimization)

A `description` should state **only when to use** the skill (triggers/symptoms), never
summarize its workflow — when it summarizes, the model follows the description instead
of reading the skill. Audit our descriptions; the workflow-summarizing ones
(`agentic-workflow`, `build-model`, `brainstorm`, `triage`, `workflow-config`) are the
offenders. Low effort, do as a pass.

## 4. Single-responsibility / no embedded conditionals

Already learned the hard way via the two-entry-point split. Keep it as a named
invariant (it is, in `AGENT.md`): a skill that says "if you are X do A else B" is a
smell — split by entry point. This matches their composition philosophy.

## 5. Worktree & branch-closure hygiene (optional)

`using-git-worktrees` + `finishing-a-development-branch` formalize isolation and clean
branch closure. We leave this to the human today. Consider a lightweight skill if/when
parallel or hand-off builds need isolation.

## 6. Parallelism patterns (later)

`subagent-driven-development` / `dispatching-parallel-agents`. Defer until we have a
concrete need; our lifecycle is currently single-track by design.

## Not adopting (deliberately)

- Splitting `executing-plans` out of `build-phase` — our build loop already owns
  execution; a separate skill would add a seam without payoff.
- Lighter request/receive code-review split — our single `3p-review` ownership gate is
  stronger; keep it.
