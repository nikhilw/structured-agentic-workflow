# AGENT.md

Minimal project guide. This repo **is** the Structured Agentic Development Workflow — a set of agent skills (`SKILL.md` files), not an application.

## Edit local files only

- The source of truth is **this repo's `skills/`** directory. Edit and reference only files here.
- Do **not** edit the installed copies under `~/.claude/skills/`, `~/.cursor/skills/`, etc. Those are install targets — on this machine the Claude symlinks resolve to `~/.agents/skills/` (a separate non-git copy), not to this repo. Editing them is editing the wrong file.
- Changes here are **not live** until installed. `./install.sh --local` symlinks every `skills/*/` dir into the agent skill dirs (it auto-discovers new skill folders). Re-run it after adding or changing a skill.

## Skill architecture

The workflow is **Brainstorm → Plan → Build → 3p-Review → Verify**, with two build entry points so the main-vs-build-model choice is *which skill is launched*, never a runtime conditional inside a skill:

- `agentic-workflow` — main orchestrator (the standard lifecycle). `user-invocable: false`.
- `build-model` — entry point for a dedicated (smaller/faster) build model: drives `build-phase` (all phases) → `3p-review` (loop until clean) → `handoff-summary` → **stop**. Does not verify.
- `build-phase` — **model-agnostic**: builds phases via TDD → test → self-review, emits a build completion report. Owns no review/handoff.
- `handoff-summary` — emits the fixed-format **Build Handoff Summary** (loaded at generation time for format reliability).
- `3p-review`, `brainstorm`, `write-plan`, `triage`, `workflow-config` — the rest of the lifecycle.
- `vendor/superpowers/` holds upstream skills (`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `brainstorming`) pulled by `pull-superpowers.sh`; their kebab names are kept verbatim. Don't hand-edit vendored skills.

### Invariant when changing build/review/handoff skills

A skill must not restate another skill's branch. The "stops after build" bug came from `build-phase` carrying an `if dedicated build model … else …` conditional repeated across sections, which drifted into a contradiction (one section said run `/3p-review`, another said don't). Keep each skill single-purpose; let the entry point decide.

## Conventions

- Plans live in `docs/plans/`: `new/` (staged) → `plans/` (active) → `done/` (archived). Move with plain `mv`, not `git mv` — plan files may be untracked.
- Brainstorm decision docs go to `docs/discussions/YYYY-MM-DD-<topic>.md`.
- Commit only when asked. Keep README's skill tables/lists and the mermaid diagram in sync when skills change.
