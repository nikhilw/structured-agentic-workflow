---
name: workflow-config
description: Configure the Structured Agentic Development Workflow — set testing methodology (TDD/BDD), output style (caveman brevity), and persist preferences to agent memory.
argument-hint: [preferences, e.g. "enable caveman full" or "use bdd"]
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# Workflow Configuration

You are configuring the **Structured Agentic Development Workflow**.

## Your Mission

Parse the user's preferences from: **$ARGUMENTS**

Then persist each preference to your agent's persistent memory so it applies across all future workflow phases and sessions.

## Supported Preferences

### Testing Methodology
- **TDD** (default) — Test-Driven Development. Red-Green-Refactor cycle via `/test-driven-development`.
- **BDD** — Behavior-Driven Development. Given-When-Then scenarios, feature files. When BDD is active, the build phase uses BDD-style test specifications instead of unit-first TDD.

Only one can be active at a time. Setting one disables the other.

### Output Style: Caveman Compatibility
- **caveman off** (default) — Normal verbose output from all workflow phases.
- **caveman lite** — Shorter prose. Cut filler sentences, keep all technical detail.
- **caveman full** — Terse. Bullet points over paragraphs. Minimal preamble. All technical accuracy preserved.
- **caveman ultra** — Maximum compression. Sentence fragments. Only essential information.

When caveman is enabled, ALL workflow skills (brainstorm, write-plan, build-phase, 3p-review, triage, systematic-debugging, verification-before-completion) adapt their output to the requested brevity level. Technical accuracy is never sacrificed — only prose style changes.

**Important:** This workflow does NOT bundle or vendor the Caveman skills package. If the user wants caveman to also govern the agent's base system prompt (outside of workflow skills), they should install the caveman package separately (e.g., via `npx @anthropics/skills`). The workflow's caveman compatibility works independently — it adapts workflow skill output regardless of whether the caveman package is installed.

## How to Persist

Save each preference as a memory entry in your agent's persistent memory system. Use whatever memory mechanism your platform provides — the key requirement is that the preference survives across conversation sessions.

**Memory entries should be structured as:**
- **Key:** `workflow-config:<preference-name>` (e.g., `workflow-config:testing-methodology`, `workflow-config:caveman-level`)
- **Value:** The chosen setting (e.g., `bdd`, `full`)

## What You Cannot Configure

The following are NOT configurable — they are core workflow guarantees:
- **Verification (`/verification-before-completion`)** — Always mandatory. Cannot be disabled.
- **Phase order** — Brainstorm → Plan → Build → 3p-Review → Verify. Cannot be reordered or skipped.
- **Plan lifecycle** — Plans move through `new/` → `plans/` → `done/`. Cannot be bypassed.
- **3p-review loop** — Review loops until clean. Cannot be short-circuited.

## Output

After saving preferences, confirm what was set:

```
## Workflow Configuration Updated

- Testing methodology: [TDD / BDD]
- Output style: [normal / caveman lite / caveman full / caveman ultra]

These preferences are saved to memory and will apply to all future workflow phases.
```

If the user asks to see current configuration, read the preferences from memory and display them in the same format.
