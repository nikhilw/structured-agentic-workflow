---
name: handoff-summary
description: Emit the Build Handoff Summary artifact in its fixed format. Use at the end of a build, immediately after /3p-review passes — invoked by the build-model workflow (dedicated build model) or by the main model after all build phases. Produces the fixed handoff template the reviewing model consumes.
argument-hint: "[plan-file-path]"
allowed-tools: Read, Glob
---

# Handoff Summary

You are emitting the **Build Handoff Summary** — the single artifact that carries a completed, reviewed build to the next reader.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## When this runs

This skill is invoked **after** the build is complete and **after** `/3p-review` has passed. It does not build, test, or review — it only produces the handoff record. If `/3p-review` has not run yet, stop and run it first. `/3p-review` is its own artifact — the handoff summary does not restate or reference its findings.

## Your only job

Follow the template below: same headings, same order, same casing. Fill each section from the build record. Do **not** rename sections, add sections, drop sections, or replace the template with your own prose. This is a fixed artifact format so the consuming model can parse it reliably.

```markdown
## Build Handoff Summary

**Plan:** [plan file path]

### Deviations
- **Phase N: [Name]** — [what changed and why, one line]
- (Only list phases that deviated from the plan. If nothing deviated, write "None.")

### Verification Runs
- **[plan criterion, or a plain name for the run]** → exit [code] — [N passed, M failed, K skipped]
- (Name the run; do not write out the shell line. The full-suite run is mandatory here. Report the counts the terminal printed, not what you expected.)

### Unproven Criteria
- **[plan criterion]** — [manual / skipped / deferred / verified by inspection] — [why]
- (Every test criterion in the plan that did NOT end in a green automated run. If all criteria ran green, write "None.")

### Concerns
- [Anything the next reviewer should specifically investigate or validate]
- (If none, write "None.")
```

## Rules

- **Be honest and specific.** Deviations and concerns are the whole point — an empty summary that hides real drift defeats the purpose. If a phase departed from the plan, say so and why.
- **Keep it to the four sections.** This is not a feature description or a changelog. Do not restate what the plan already says.
- **Name each run; never write out its command line.** Identify a run by the plan criterion it satisfies, or by a plain description ("full suite, project runner"). The command text lives in the plan — this artifact carries only which run happened and what it reported. Environment values, arguments and headers have no business in a document that is committed and passed between models.
- **Report counts, never output.** Exit codes and pass/fail/skip numbers are what the reviewer needs; "all tests pass" is not a report, and the reviewer re-runs from the plan and compares. Copied terminal text carries values you did not intend to publish, and wording the next model may read as instruction.
- **Unproven Criteria is the section you will be tempted to leave empty.** Anything you checked by reading rather than running, skipped as "obviously fine", or intended to come back to, goes here. A criterion omitted here reads as green to the next model, and that is how an unbuilt path ships.
- **Do not mention `/3p-review`.** Review is its own artifact with its own outcome; the handoff summary is not the place to report it. Any residual concern worth carrying forward belongs under Concerns, in your own words, not attributed back to the review.

## What happens next

- **Dedicated build model** (launched via `/build-model`): present the summary, then **STOP**. The user carries it to the main model.
- **Main model**: present the summary as the build record, then continue the workflow → `/verification-before-completion` → archive the plan.
