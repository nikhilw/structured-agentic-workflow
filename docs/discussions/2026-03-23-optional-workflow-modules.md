# Discussion: Optional Workflow Modules & Integrations

*2026-03-23 — Brainstorm output from conversation with Claude*

---

## The Problem

The workflow currently hardcodes its task source as local markdown files (`bugs.md`, `features.md`). Users who track work in Jira, GitHub Issues, Linear, etc. can't use `/triage` or the backlog-driven parts of the workflow without duplicating their data into flat files.

This surfaces a broader question: the workflow has **optional integration points** — places where different teams will want different backends. Task tracking is the first, but others could follow (e.g., PR creation workflows, notification channels, deployment triggers).

### Concrete Example

A user wants to say "start working on PROJ-1234" and have the workflow:
1. Fetch the Jira ticket details via MCP
2. Feed them into `/brainstorm` or `/write-plan` as context
3. Update the ticket status as phases complete

This requires: a Jira MCP server installed and configured, a modified `/triage` that reads from Jira instead of flat files, and possibly modified orchestration in `agentic-workflow`.

---

## What Needs to Change

1. **Skill overrides** — some skills (e.g., `triage`) need different versions for different backends
2. **MCP server dependencies** — integration modules need MCP servers installed and configured
3. **Install mechanism** — users need to choose which integrations they want at install time
4. **Repo structure** — we need a place for optional modules that doesn't clutter the core

---

## Approaches Considered

### Approach A: "Profiles" — Named Install Profiles

Organize skills into directories by profile: `skills/core/`, `skills/integrations/jira/`, `skills/integrations/github/`. The install script takes `--profile core+jira`.

- **Pros:** Clean separation. User picks a profile, gets exactly what they need.
- **Cons:** Restructures the entire `skills/` directory — breaking change. Profiles are rigid (what if someone wants jira + custom-triage?).
- **Complexity:** High
- **Verdict:** Over-engineered for the current scope.

### Approach B: "Modules" — Skill Packs with a Manifest

Keep `skills/` flat. Add `modules/` where each module contains override skills and a `module.json` manifest listing dependencies, conflicts, and what it replaces. Install with `--with jira`.

- **Pros:** Core stays untouched. Composable. Manifest enables conflict detection.
- **Cons:** Need conflict resolution logic. More complex install. Manifest schema is another thing to maintain.
- **Complexity:** Medium
- **Verdict:** Good if we need many modules composing together. Premature right now.

### Approach C: "Skill Variants" — Backend-Aware Skills

Skills themselves check a config file (`.claude/workflow-config.json`) to decide behavior at runtime: if Jira, use MCP tools; if local, read flat files.

- **Pros:** No directory restructuring. Single skill to maintain.
- **Cons:** Conditional logic inside markdown prompts is fragile. Testing gets harder. Couples all backends into one file. Gets ugly fast.
- **Complexity:** Medium, but grows badly
- **Verdict:** Does not scale. Rejected.

### Approach D: "Module Directory + Simple Override" (Recommended)

Keep `skills/` as the core. Add `modules/` at the repo root. Each module is a self-contained directory with its own skills, MCP setup, and documentation. The installer layers module skills on top of core (module wins on conflict).

```
modules/
  jira/
    skills/
      triage/SKILL.md        # replaces core triage — reads from Jira via MCP
    mcp/
      setup.sh               # installs and configures Jira MCP server
      setup.ps1              # Windows equivalent
    module.md                # what this module does, what it replaces, prerequisites
  github-issues/
    skills/
      triage/SKILL.md        # replaces core triage — reads from GitHub Issues via MCP
    mcp/
      setup.sh
      setup.ps1
    module.md
```

**Install flow:**
```bash
./install.sh --with jira              # core + jira module
./install.sh --with github-issues     # core + github-issues module
./install.sh                          # core only (flat-file backlog)
```

**What `--with jira` does:**
1. Install core skills (as today)
2. Run `modules/jira/mcp/setup.sh` — installs the Jira MCP server, adds it to Claude Code's MCP config
3. Overlay `modules/jira/skills/` on top of core — the module's `triage/SKILL.md` replaces the core `triage/SKILL.md` in the symlink target

**Override semantics:** simple — last one wins. If the module has a `skills/triage/`, it replaces core's `triage` in `~/.claude/skills/`. Core skills without a module override are linked as normal.

- **Pros:** Core untouched. Modules are self-contained. Override semantics are trivial. MCP setup is co-located. Easy to contribute new modules. Works with existing install architecture.
- **Cons:** Only one module can override a given skill (no composition). User must understand override semantics.
- **Complexity:** Medium-Low

---

## Recommendation

**Approach D.** It's the natural extension of what we have. The install script already discovers skills and links them — we just add a second pass for module overlays. Each module is a self-contained directory that anyone can contribute without touching core.

### What would change this recommendation

If we needed heavy module composition (e.g., Jira for bugs + GitHub for PRs + Slack for notifications, all active simultaneously and modifying different skills), we'd need Approach B's manifest system with explicit dependency and conflict declarations. But task-source swapping is the primary use case right now, and simple overrides are sufficient.

---

## Open Questions

1. **Which integrations first?** Jira and GitHub Issues are the obvious starting points. Linear? Shortcut? Plain GitHub Projects?

2. **MCP server installation** — should `setup.sh` install the MCP server globally, or just configure it? Some users may already have MCP servers running. Should we detect and skip?

3. **Should modules be able to ADD skills, not just replace?** E.g., a Jira module might add a `/jira-sync` skill that doesn't exist in core. (The current design supports this naturally — any skill in the module's `skills/` directory that doesn't conflict with core is just added.)

4. **Multiple modules overriding the same skill** — is "last one wins" (based on `--with` order) acceptable, or do we need explicit conflict detection? For now, I think it's fine — the primary use case is picking ONE task source, not composing them.

5. **How should this interact with `--target`?** Should `--with jira --target claude` install the Jira module only for Claude Code? (Probably yes — MCP servers are agent-specific.)

6. **Module-specific CLAUDE.md snippets** — should each module include a snippet that gets appended to the user's CLAUDE.md? E.g., the Jira module might want to add "When triaging, use the Jira MCP tools to read tickets" to the project's persistent context.

---

## Next Steps

Once a direction is chosen:
1. `/write-plan` to formalize the module architecture and install script changes
2. Build the core module infrastructure (directory structure, install script `--with` flag)
3. Build the first module (probably `github-issues` since no paid service needed for testing)
4. Build the second module (Jira) to validate the pattern generalizes
