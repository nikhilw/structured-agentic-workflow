---
name: github-backlog
description: Maintain and manage features and bugs on GitHub. Creates, updates, lists, and links GitHub issues and project cards.
argument-hint: "[create-bug | create-feature | list | update] <details>"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# GitHub Backlog Management

You are managing the feature and bug backlog on GitHub as part of the **Structured Agentic Development Workflow**.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## Prerequisites

This skill talks to GitHub through whatever **GitHub MCP server** the user has configured. The server name is install-specific, so its tools may be named `mcp__<server>__create_issue`, `mcp__<server>__list_issues`, etc. (the official GitHub MCP server is a common choice). Calls to these tools are governed by your normal permission settings — this skill does not pin a server name. Before running any backlog task:

1. `workflow-config:use-github-issues` must be `true`. If it is `false` or unset, GitHub integration is disabled — stop and tell the user to enable it with `/workflow-config` (the local `bugs.md` / `features.md` flow applies instead).
2. A GitHub MCP server must be configured and authenticated in the environment. If no GitHub MCP tools are available in the session, tell the user to configure one and stop.
3. Resolve the target repository (see next section).

---

## Resolve the Target Repository

Resolve `owner/repo` **every run**, in this order:

1. **Manual override** — if `workflow-config:github-repo` is set in memory, use it verbatim.
2. **Auto-derive from the local remote** — otherwise read the origin remote and parse it:
   ```bash
   git remote get-url origin
   ```
   Strip any trailing `.git` and extract `owner/repo` from either form:
   - SSH: `git@github.com:owner/repo.git` → `owner/repo`
   - HTTPS: `https://github.com/owner/repo.git` → `owner/repo`
   - Other hosts (e.g. `git@gitlab.com:...`) are not GitHub — stop and report.
3. **Neither available** — if there is no `origin` remote and no override, stop and ask the user to set `workflow-config:github-repo` via `/workflow-config` or add a GitHub `origin`.

Do **not** persist the derived value — deriving fresh keeps it correct if the remote changes. `workflow-config:github-repo` exists only as an explicit override (for example, tracking issues in a different repo than `origin`).

Optionally retrieve `workflow-config:github-project-id` if a GitHub Project (V2) board is in use.

---

## Commands

Parse the verb and details from **$ARGUMENTS**. Resolve the repo first (above), then:

### `create-bug <details>`
1. Compose the issue body from the **Bug Template** below, filling what the user provided and leaving optional sections out when empty.
2. Create the issue via the GitHub MCP server's create-issue tool against the resolved repo, with a title summarizing the bug and labels `bug` plus a `priority:*` label when priority is known.
3. If `workflow-config:github-project-id` is set, add the new issue to that project (see GitHub Projects section) with status **Todo**.
4. Report the created issue number and URL.

### `create-feature <details>`
Same as `create-bug`, but use the **Feature Template** and labels `feature` (or `enhancement`) plus any `priority:*`.

### `list [filter]`
1. Fetch open issues for the resolved repo via the GitHub MCP list/search tools.
2. Default to open issues; honor any filter in the details (e.g. label `bug`, `priority:high`, or `status:todo`).
3. Present a concise table: number, title, type label, priority, status.

### `update <issue-number> <changes>`
1. Apply the requested change to the issue via the GitHub MCP tools — relabel, change `status:*`, add a comment, or close.
2. When moving workflow status, keep the issue label and the Project card column in sync (see below).
3. Report what changed.

---

## Issue Templates

Use these structures so issues carry high-fidelity context into the planning and build phases.

### A. Bug Template
```markdown
## Description
[Clear, concise description of the bug]

## Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. See error '...'

## Expected Behavior
[What should have happened]

## Environment Details
- OS / Platform: [e.g., Linux, macOS, Windows]
- Context/Modules affected: [e.g., WebSocket sync, database migrations]

## Technical Analysis (Optional)
- Error trace: [paste logs or stack traces if available]
```

### B. Feature Template
```markdown
## User Story / Value
As a [user type], I want to [action] so that [benefit].

## Core Requirements
- [Requirement 1]
- [Requirement 2]

## Implementation Notes & Scope
- Proposed technical approach: [brief overview]
- Out of scope: [what this issue will NOT address]
```

---

## Labeling Standards

Use the following labels to categorize issues and drive triage:

*   **Type Labels:** `bug` (for issues) or `feature` / `enhancement` (for features).
*   **Priority Labels:** `priority:critical`, `priority:high`, `priority:medium`, `priority:low`.
*   **Workflow Status Labels:**
    *   `status:todo` — Ready to be picked up.
    *   `status:in-progress` — Currently active in a development phase.
    *   `status:in-review` — Under third-person review.
    *   `status:done` — Verified and completed.

---

## GitHub Projects (V2) Integration

If `workflow-config:github-project-id` is configured:
1. **Add to Project:** When creating a new issue, use the GitHub MCP tools to add the issue to the specified Project board.
2. **Synchronize Status:**
   - **Triage (Todo):** Set the Project status column to **Todo** (or equivalent) when the issue is logged.
   - **Plan/Build (In Progress):** Move the card to **In Progress** when starting a `/write-plan` or `/build-phase`.
   - **Review (In Review):** Move the card to **In Review** during `/3p-review`.
   - **Verify (Done):** Move the card to **Done** after `/verification-before-completion` passes.

---

## Linking Issues to Local Workflow Plans

To ensure traceability:
1. **When Writing a Plan:** When creating a plan file (e.g., `docs/plans/new/offline-sync.md`), include the GitHub Issue number at the top of the file:
   ```markdown
   # Plan: Offline Sync (#123)
   ```
2. **Comment on the Issue:** When the plan is approved, add a comment on the GitHub issue linking it to the plan file:
   ```markdown
   Plan approved. Active plan file: docs/plans/offline-sync.md
   ```
3. **Closing Issues:** When the verification phase is successful and the plan is moved to `docs/plans/done/`, close the GitHub issue with a comment referencing the final commits or verification output.
