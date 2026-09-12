# Installation Reference

The [README](../README.md) covers the three-step setup. This file is the reference for
everything else: per-agent targets, script options, the full skill inventory, and manual
installation.

---

## Where skills are installed

| Agent | Skills directory |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Cursor | `~/.cursor/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| GitHub Copilot | `~/.config/github-copilot/skills/` |

> Cursor also reads `~/.claude/skills/` natively, so installing for Claude Code alone is
> enough if you use both.

Every skill uses the standard `SKILL.md` format, which all four agents read. That is what
makes the [multi-model handoff](multi-model.md) work — the build model needs the same skills
installed in *its* environment.

A few skills ship supporting files alongside their `SKILL.md` (for example
`3p-review/deep-audits.md`, loaded only when the change touches derived state, migrations, or
third-party dependencies). Both install paths symlink the **whole skill directory**, so those
files travel with the skill automatically. Supporting files always live inside the skill that
uses them, never shared across skill directories — `npx skills` lets users install skills
individually, and a cross-directory reference would break for anyone who does.

## Option A — the `skills` CLI

Works with Claude Code, Cursor, Gemini CLI, GitHub Copilot, and 40+ other agents.

```bash
# Install workflow skills for your agent
npx skills add nikhilw/structured-agentic-workflow

# Install for a specific agent
npx skills add nikhilw/structured-agentic-workflow -a claude-code

# superpowers skills live in a separate repo — install them separately
npx skills add obra/superpowers -s test-driven-development -s systematic-debugging
```

The CLI discovers all skills in the repo, lets you pick which to install, and symlinks them
into your agent's skills directory.

> We keep the upstream superpowers names verbatim (`systematic-debugging`,
> `test-driven-development`) rather than shortening them to `debug`/`tdd`. The
> `npx skills` CLI has no rename flag, so keeping the upstream names means installs via
> `npx skills` and installs via `install.sh` produce identically-named skills.

> **Do not install superpowers' `verification-before-completion`.** This workflow replaces it with
> `verify-completion`: the same Iron Law, gate function and key patterns, plus the plan-requirements
> tick-off and the drift audit. Installing both leaves two skills claiming one gate, and the agent
> takes whichever it reads first. The name differs deliberately, since the install script copies
> vendored skills into `skills/` and a same-named skill of ours would be clobbered on every pull.
> If you already have the upstream one from an earlier install, `./install.sh` removes the link it
> created; a copy you installed by another route stays, and `/verify-completion` is still the gate.

## Option B — the install script

One command that pulls superpowers and installs everything.

```bash
git clone https://github.com/nikhilw/structured-agentic-workflow.git
cd structured-agentic-workflow

./install.sh          # all supported agents (pulls superpowers automatically)
.\install.ps1         # Windows PowerShell — requires Developer Mode or admin
```

It does three things:

1. **Pulls superpowers skills** — sparse-clones [obra/superpowers](https://github.com/obra/superpowers)
   (MIT-licensed) into `vendor/superpowers/`, then copies the adopted skills into `skills/`
   under their upstream names.
2. **Symlinks all skills** into the global skills directory for each supported agent.
3. **Cleans up retired skills** — `verification-before-completion` is no longer part of this
   workflow, so a stale copy under `skills/` and the symlink an earlier install created are
   removed. Only a link that is broken or points back into this repo is touched; a copy you
   installed some other way is left alone.

### Targeting one agent

```bash
./install.sh --target claude     # Claude Code only
./install.sh --target cursor     # Cursor only
./install.sh --target gemini     # Gemini CLI only
./install.sh --target copilot    # GitHub Copilot only
```

### Other options

```bash
./install.sh --local                   # skip the superpowers pull, use existing vendor/
./install.sh --remove                  # remove all symlinks
./install.sh --remove --target claude  # remove for one agent
./install.sh --list                    # show agents and install status
```

---

## The skills

### Core workflow

| Skill | Source | Description |
|---|---|---|
| `agentic-workflow` | this project | Orchestrates the full development lifecycle |
| `workflow-config` | this project | Configure preferences — TDD/BDD, caveman brevity, GitHub issues |
| `brainstorm` | this project | Explore approaches, challenge the design, estimate impact, produce decision documents |
| `write-plan` | this project | Write phased implementation plans |
| `build-phase` | this project | Execute plan phases with test + self-review; emits a build completion report |
| `build-model` | this project | Dedicated build-model workflow — build-phase → 3p-review → handoff-summary → stop |
| `3p-review` | this project | Independent third-person review; returns a Rework Brief when there is too much to fix in place |
| `handoff-summary` | this project | Emit the fixed-format Build Handoff Summary after review passes |
| `verify-completion` | this project | The final gate: fresh suite, plan-requirements tick-off, decision-to-code drift audit. Replaces the upstream `verification-before-completion` |
| `test-scope` | this project | Shared reference: how wide each test run must be, and when a recorded run can be cited. Not invoked directly |
| `existing-mechanisms` | this project | Shared reference: the eight questions about what the codebase already does. Not invoked directly |
| `triage` | this project | Recommend the next task, minimizing context thrash |
| `github-backlog` | this project | Maintain features and bugs on GitHub |
| `test-driven-development` | [superpowers](https://github.com/obra/superpowers) | RED-GREEN-REFACTOR discipline |
| `systematic-debugging` | [superpowers](https://github.com/obra/superpowers) | Systematic 4-phase root cause investigation |

### Optional vendor skills

Installed, but not part of the workflow.

| Skill | Source | Description |
|---|---|---|
| `brainstorming` | [superpowers](https://github.com/obra/superpowers) | Interactive brainstorming with visual companion and spec review loop. Available if you prefer it over `/brainstorm`. |

### Retired

| Skill | Why it is gone |
|---|---|
| `verification-before-completion` | Replaced by `verify-completion`, which does everything it did and adds the requirements tick-off and the drift audit. No longer pulled or linked; `./install.sh` removes a stale copy and the symlink it created. The one upstream reference to it, in `systematic-debugging`'s related-skills list, is rewritten to `/verify-completion` at pull time. |

---

## Manual installation

If the install script does not work on your system. Two steps: pull the superpowers skills,
then symlink everything into your agent's skills directory.

### Step 1 — pull superpowers skills

```bash
git clone --depth 1 https://github.com/obra/superpowers.git /tmp/superpowers

# Keep a vendored reference copy
mkdir -p vendor/superpowers
cp -r /tmp/superpowers/skills/brainstorming vendor/superpowers/
cp -r /tmp/superpowers/skills/test-driven-development vendor/superpowers/
cp -r /tmp/superpowers/skills/systematic-debugging vendor/superpowers/
cp /tmp/superpowers/LICENSE vendor/superpowers/

# Copy into skills/ under their upstream names
cp -r /tmp/superpowers/skills/brainstorming skills/brainstorming
cp -r /tmp/superpowers/skills/test-driven-development skills/test-driven-development
cp -r /tmp/superpowers/skills/systematic-debugging skills/systematic-debugging

# Point systematic-debugging's cross-references at skills that exist here
sed -i 's|superpowers:test-driven-development|/test-driven-development|g' skills/systematic-debugging/SKILL.md
sed -i 's|superpowers:verification-before-completion|/verify-completion|g' skills/systematic-debugging/SKILL.md

# Retired: remove it if an earlier install left it behind
rm -rf vendor/superpowers/verification-before-completion skills/verification-before-completion

rm -rf /tmp/superpowers
```

### Step 2 — symlink the skills

Replace `~/.claude/skills` with the path for your agent from the table above.

**macOS / Linux** — symlink every skill directory, including any added later:

```bash
mkdir -p ~/.claude/skills
for skill in "$(pwd)"/skills/*/; do
    ln -sfn "${skill%/}" ~/.claude/skills/"$(basename "$skill")"
done
```

**Windows (PowerShell — requires Developer Mode or admin):**

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills" -Force

$skills = Get-ChildItem -Path ".\skills" -Directory
foreach ($skill in $skills) {
    New-Item -ItemType SymbolicLink `
        -Path "$env:USERPROFILE\.claude\skills\$($skill.Name)" `
        -Target $skill.FullName -Force
}
```

### Step 3 — verify

```bash
ls -la ~/.claude/skills/
```

Each entry should be a symlink pointing back into this repo's `skills/` directory.
