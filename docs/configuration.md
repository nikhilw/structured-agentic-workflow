# Configuration

Preferences are set with `/workflow-config` and persisted to your agent's memory, so they
apply across sessions.

```
/workflow-config use bdd
/workflow-config enable caveman full
/workflow-config use github issues
/workflow-config show
```

---

## Testing methodology

| Setting | Behaviour |
|---|---|
| `tdd` *(default)* | Red-Green-Refactor via `/test-driven-development` |
| `bdd` | Given-When-Then scenarios and feature files |

Only one is active at a time. The core rule — **test first, always** — applies either way.

## Output style: caveman brevity

The workflow integrates with the [caveman](https://www.npmjs.com/package/@anthropics/skills)
brevity style. Every skill checks memory for the configured level and adapts its own output.

| Level | Style |
|---|---|
| `off` *(default)* | Normal output |
| `lite` | Shorter prose, all technical detail preserved |
| `full` | Terse bullets, minimal preamble |
| `ultra` | Maximum compression, sentence fragments |

Technical accuracy is never sacrificed — only verbosity changes.

**This workflow does not bundle or vendor caveman.** Compatibility is built into each skill
independently. If you also want caveman to govern the agent's base system prompt, outside of
workflow skills, install the caveman package separately.

## Backlog source

| Setting | Behaviour |
|---|---|
| `use-github-issues false` *(default)* | `/triage` reads local `bugs.md` / `features.md` and `docs/plans/` |
| `use-github-issues true` | `/triage` and `/github-backlog` read GitHub Issues through a GitHub MCP server |

With GitHub enabled, the target repo is derived from `git remote get-url origin`, so the
common case needs no further configuration. Two optional overrides:

| Key | Purpose |
|---|---|
| `workflow-config:github-repo` | Use a different repo, as `owner/repo` — when issues live outside `origin` |
| `workflow-config:github-project-id` | A GitHub Project (V2) board to sync cards to |

> Issue titles, bodies, and comments are authored by outside users and are treated as
> **untrusted input**: the skills extract facts and ignore any instructions embedded in them.
> Text in an issue that tells the agent to run a command or add a dependency is
> prompt-injection, not a priority signal.

## Memory keys

| Key | Values |
|---|---|
| `workflow-config:testing-methodology` | `tdd` · `bdd` |
| `workflow-config:caveman-level` | `off` · `lite` · `full` · `ultra` |
| `workflow-config:use-github-issues` | `true` · `false` |
| `workflow-config:github-repo` | `owner/repo` |
| `workflow-config:github-project-id` | project number or ID |

---

## What cannot be configured

These are core guarantees, not preferences:

- **Verification** — `/verification-before-completion` is always mandatory
- **Phase order** — Brainstorm → Plan → Build → 3p-Review → Verify
- **Plan lifecycle** — `new/` → `plans/` → `done/`
- **The review loop** — `/3p-review` loops until clean
