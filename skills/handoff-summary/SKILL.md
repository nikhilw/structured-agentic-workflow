---
name: handoff-summary
description: Emit the Build Handoff Summary artifact in its fixed format. Use at the end of a build, immediately after /3p-review passes — invoked by the build-model workflow (dedicated build model) or by the main model after all build phases. Produces the exact handoff template the reviewing model consumes.
argument-hint: "[plan-file-path]"
allowed-tools: Read, Glob
---

# Handoff Summary

You are emitting the **Build Handoff Summary** — the single artifact that carries a completed, reviewed build to the next reader.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## When this runs

This skill is invoked **after** the build is complete and **after** `/3p-review` has passed. It does not build, test, or review — it only produces the handoff record. If `/3p-review` has not run yet, stop and run it first; the summary records the review result.

## Your only job

Reproduce the template below **exactly** — same headings, same order, same casing. Fill in the bracketed parts from what was actually built and reviewed. Do **not** rename sections, add sections, drop sections, or replace the template with your own prose. This is a fixed artifact format so the consuming model can parse it reliably.

```markdown
## Build Handoff Summary

**Plan:** [plan file path]

**3p-review:** [PASS — zero open findings | the findings that were raised and how each was resolved]

### Deviations
- **Phase N: [Name]** — [what changed and why, one line]
- (Only list phases that deviated from the plan. If nothing deviated, write "None.")

### Concerns
- [Anything the next reviewer should specifically investigate or validate]
- (If none, write "None.")
```

## Rules

- **Be honest and specific.** Deviations and concerns are the whole point — an empty summary that hides real drift defeats the purpose. If a phase departed from the plan, say so and why.
- **Keep it to deviations and concerns.** This is not a feature description or a changelog. Do not restate what the plan already says.
- **The `3p-review` line is mandatory.** It is the evidence that review happened. If review surfaced findings, list them and how each was resolved — do not write "PASS" unless the review is genuinely clean.

## What happens next

- **Dedicated build model** (launched via `/build-model`): present the summary, then **STOP**. The user carries it to the main model.
- **Main model**: present the summary as the build record, then continue the workflow → `/verification-before-completion` → archive the plan.
