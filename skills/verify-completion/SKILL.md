---
name: verify-completion
description: The final gate before any claim of "done", "fixed", or "passing", and before any commit or PR. Runs three checks that nothing earlier in the workflow guarantees, a fresh full-suite result, a line-by-line tick-off of the plan's requirements, and a plan-drift audit from the decision document through the plan to the code. Evidence before assertions, always.
argument-hint: "[plan file path, or what is being claimed complete]"
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Verify Completion

You are standing at the **final gate** of the Structured Agentic Development Workflow. Nothing
downstream checks your work. What you sign here is what ships.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output
> brevity to that level while preserving technical accuracy.

> **Lineage:** the Iron Law, the gate function, the failure and rationalization tables, and the key
> patterns below are adapted from `verification-before-completion` in
> [superpowers](https://github.com/obra/superpowers) (MIT, Jesse Vincent). This skill **replaces**
> it: everything that skill does, plus the requirements tick-off and the drift audit. This workflow
> does not install the upstream skill; if a project has it by another route, this one is the gate.

**What you may write.** Editing is granted for one purpose: closing the *record*, by appending to a
decision document's Amendments section and to a plan's Amendment Log. Do not fix code from inside
this gate. A gate that repairs what it is measuring has stopped measuring, and a fix made here is
one nothing re-reviews and no suite re-runs. Code gaps go back to build.

## What this gate is, and is not

It is **not a second review**. `/3p-review` proved the *code* is sound; re-reading the code here
buys nothing and costs a rework loop's worth of time. This gate proves three different
propositions, none of which review establishes:

1. **The suite is green right now.** Review may have passed several edits ago.
2. **Every requirement was actually built.** Review judges completeness qualitatively; this is the
   line-by-line tick-off.
3. **What shipped is still what was decided.** Plans drift. Every halt, every constraint found
   mid-build, every reverted phase moves the plan a little, and the accumulated distance from the
   decision document is invisible from inside any single step. This is the only place the whole
   chain is read end to end.

Check 3 exists because of a specific, expensive failure: you set out to build one thing, the plan
absorbed a dozen small corrections, and what shipped is a different thing. Nobody notices for days,
because every individual amendment was reasonable.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification yourself, in this session, you cannot claim it passes.

The only exception is a citation meeting all four conditions in Part 1, and it is an exception in
name only: a citation is a *stricter* claim than a fresh run, because it proves both that the suite
passed and that nothing has changed since. Anything less than that, a run someone reported to you,
a run from before an edit, a narrower run described in wider words, is not evidence.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY  What proves this claim? (command, checklist, document comparison)
2. RUN       Execute it fully, fresh, now
3. READ      Full output, exit code, counts, both sides of every comparison
4. VERIFY    Does the evidence confirm the claim?
             If NO:  state the actual status, with the evidence
             If YES: state the claim, with the evidence
5. ONLY THEN make the claim

Skip any step and you are not verifying, you are asserting.
```

---

# Part 1 — The suite, true right now

Take `/test-scope`'s *"`/verify-completion`"* row. Load `/test-scope` if you have not this session.

That row is the full suite, **or** a citation of `/3p-review`'s sign-off run under the citable-run
rule. The four conditions are not a judgment call: you made the run yourself this session, same
command and same rung, `git status --porcelain` and `git diff` clean since, and you write the
citation down naming what proved the tree unchanged.

Fail any condition and there is no citation, only a run you still owe. Pass all four and the
citation is *stronger* evidence than re-running would be: re-running proves the suite passes, while
the citation additionally proves nothing changed since it passed. Do not re-run out of an
abundance of caution once the citation is written.

**The citation covers Part 1 only.** Parts 2 and 3 are document comparisons, not test runs. They
are never cited, and they always run fresh.

---

# Part 2 — Requirements tick-off (plan → code)

Re-read the plan from disk. Not from memory of it, not from the handoff summary, not from the
review. Build a checklist and walk it.

- **Every phase, every implementation step, every test criterion, one line each.** Mark each
  **built and proven**, **built but unproven**, or **not built**.
- **Proven means an automated run you can name.** A criterion checked by reading is *unproven*, and
  it goes on the report as unproven. So does a criterion proven only at a scoped rung, which is a
  real result but a narrower claim than the plan asked for.
- **Walk the plan's own sections, not just its phases.** State & Data Contracts, Failure Modes &
  Interactions, and Value Paths & Seam Tests each specify behaviour. A named seam test that was
  never written is a missing requirement, not a missing nicety.
- **Anything in Out of Scope that got built anyway is a finding.** Scope grows silently and this is
  the only line that catches it.

A gap here does not fail the gate by itself. An *unreported* gap does. The output is a truthful
ledger; the human decides whether an unproven row is acceptable.

---

# Part 3 — The drift audit (decision → plan → code)

Do for the decision document and the plan exactly what Part 2 does for the plan and the code: read
both, line by line, and name every difference.

**If no decision document exists** (a bug fix, a quick fix, or a plan written without a brainstorm),
say so explicitly and run D2 and D3 against the plan alone. Silence about a missing decision doc
reads as "checked, matched".

### D1 — Decision document → the plan as it now stands

Read `docs/discussions/<the relevant doc>.md` and the current plan side by side. For every decision
in the document, and every consequence it recorded:

| Disposition | Meaning | Acceptable? |
|---|---|---|
| **Upheld** | the plan implements the decision as written | yes |
| **Narrowed** | the plan implements part of it, deliberately, and says so | yes, if the plan says so |
| **Superseded** | the plan does something the decision ruled out | only with an Amendment Log entry naming the decision it supersedes |
| **Dropped** | the decision is simply absent from the plan | **no**, this is the finding |

Also check the two lines of the decision document that age fastest:

- **"What would reverse this decision."** The document named the condition under which the
  runner-up wins. Did it come true during the build? A build that discovers exactly that condition,
  patches around it, and ships the original approach anyway is the most expensive form of drift
  there is, and no single amendment entry will show it.
- **Open Questions.** Each is answered, or still open and carried forward in writing. An open
  question that quietly stopped being asked was answered by whoever wrote the code.

### D2 — The plan as approved → the plan as it now stands

Every difference must have an entry in the plan's **Amendment Log**. Establish the approved
baseline in this order, and say which one you used:

1. **Git history of the plan file** (`git log --follow -p -- <plan path>`), if it is tracked. This
   is the only baseline that cannot be edited after the fact.
2. **The Amendment Log itself**, read as a claim rather than as proof.
3. **The copy the build model was handed**, if the user still has it.

If the plan was never tracked and the log is empty while the code plainly implements something the
plan does not describe, that absence *is* the finding. Write it that way.

### D3 — Decision document → what actually shipped

The round trip, and the one that catches what D1 and D2 individually cannot. Read the decision
document's **Problem** statement, then read the code. Answer in your own words:

- Does what shipped solve the problem that was decided, or a neighbouring one?
- Would the approach comparison in that document still choose this approach, knowing what the build
  found out?
- Did the accumulated amendments move this to a different approach than the one chosen, without any
  single amendment saying so?

The third question is the point of this gate. Six reasonable amendments can add up to Approach C
while every entry in the log reads like a detail.

**A "yes" to any D3 question goes to the human, even when every amendment is logged.** Perfect
bookkeeping and a feature that ended up somewhere nobody chose are entirely compatible states, and
this is the last moment anyone is looking at both documents at once.

**Scale the audit to what actually moved.** A plan with an empty Amendment Log and a decision
document it never departed from is audited in minutes: D2 is trivially clean, and D1 and D3 are one
careful read of two documents you already have open. The work grows with the drift, which is the
correct shape; if this gate feels expensive, that is the feature telling you something.

### The verdict, and what to do with it

| Verdict | Meaning | Action |
|---|---|---|
| **NO DRIFT** | plan implements the decisions; code implements the plan | record it and move on |
| **DOCUMENTED DRIFT** | differences exist and every one is written down | record it in the report; the human confirms it is still the feature they wanted |
| **UNDOCUMENTED DRIFT** | a difference nobody wrote down | **blocking.** Fix the record before claiming completion |

**The fix for drift is the written record, not a revert.** A superseded decision is usually the
right call; the defect is that nothing says so. Close undocumented drift by appending to the
decision document:

```markdown
## Amendments
### YYYY-MM-DD — [what changed]
- **Supersedes:** [the decision or consequence in this document]
- **Now:** [what was actually built]
- **Because:** [what the build or the plan found that the decision did not know]
- **Recorded in:** [plan Amendment Log entry ID, or "found at verification, no plan entry existed"]
```

Then add the matching plan Amendment Log entry if one is missing. Only a genuine gap in the work
goes back to build; a gap in the *record* is closed here, in writing, now.

---

# Part 4 — The completion report

```markdown
## Completion Verification

**Claim:** [what is being claimed complete]
**Plan:** [path]   **Decision doc:** [path, or "none"]

### Suite
- **[run name]** (rung T4) → exit [code], [N passed, M failed, K skipped]
- [Fresh, or: cited from /3p-review's sign-off run; tree proven unchanged by git status and git diff]

### Requirements (plan → code)
| Requirement | Status | Evidence |
|---|---|---|
| [phase / criterion / contract line / seam test] | built and proven / built but unproven / not built | [run name, or why not] |

**Unproven or missing:** [each row that is not "built and proven", or "none"]
**Built but not in the plan:** [scope that grew, or "none"]

### Drift (decision → plan → code)
- **D1 decision doc → plan:** [upheld / narrowed / superseded with entry ID / dropped]
- **D2 approved plan → current plan:** [every difference and its Amendment Log entry; baseline used]
- **D3 decision doc → shipped code:** [does it still solve the decided problem; did the reversal
  condition come true; did the amendments add up to a different approach]

**Verdict:** NO DRIFT / DOCUMENTED DRIFT / UNDOCUMENTED DRIFT
**Record closed by:** [decision-doc amendment appended, plan entry added, or "nothing needed"]

### Status
COMPLETE / NOT COMPLETE — [one line]
```

If the verdict is UNDOCUMENTED DRIFT, or any requirement is "not built", the status is **NOT
COMPLETE** until the record is closed or the human accepts the gap in writing.

---

## Common failures

| Claim | Requires | Not sufficient |
|---|---|---|
| Tests pass | Test command output, 0 failures | A previous run, "should pass" |
| Linter clean | Linter output, 0 errors | A partial check, extrapolation |
| Build succeeds | Build command, exit 0 | Linter passing, logs that look fine |
| Bug fixed | The original symptom re-tested, passing | Code changed, fix assumed |
| Regression test works | Red then green, verified | The test passing once |
| Agent completed | The VCS diff, read | The agent reporting success |
| Requirements met | The line-by-line checklist | Tests passing |
| Built what we decided | The drift audit, all three comparisons | The plan being followed |

## Red flags, stop

- "Should", "probably", "seems to"
- Satisfaction expressed before evidence ("Great!", "Perfect!", "Done!")
- About to commit, push, or open a PR without running this gate
- Trusting an agent's or another model's success report
- Relying on a partial run, or on a scoped rung described in full-suite words
- "Just this once"
- Tired and wanting the work over
- Any wording that implies success without the evidence behind it

## Rationalization prevention

| Excuse | Reality |
|---|---|
| "Should work now" | Run it |
| "I'm confident" | Confidence is not evidence |
| "Just this once" | No exceptions |
| "The linter passed" | The linter is not the compiler |
| "The agent said success" | Verify it first-party |
| "I'm tired" | Exhaustion is not an excuse |
| "A partial check is enough" | Partial proves nothing |
| "Different words, so the rule does not apply" | Spirit over letter |
| "Review already ran the tests" | Grounds for a citation if all four conditions hold; never grounds to skip the gate |
| "The plan changed, so the decision doc is out of date" | That is drift. Write it down, then claim completion |
| "Every amendment was reasonable" | Reasonable amendments still add up to a different feature |

## Key patterns

Each row of the Common failures table has a procedure behind it. These are the ones people get
wrong most often, in the form that is quickest to check yourself against.

**Tests**
```
GOOD  run the suite → read "34 passed, 0 failed" → "all tests pass (T4 full, exit 0)"
BAD   "should pass now" / "looks correct" / "tests pass" with no rung and no counts
```

**Regression tests, red then green**
```
GOOD  write the test → run it (passes) → revert the fix → run it (MUST FAIL) → restore → run (passes)
BAD   "I've written a regression test" with no red phase ever observed
```
A regression test that was never seen failing is not known to test the regression. This is the
single most common way a fix ships with a test that would not have caught it, and the revert takes
seconds.

**Build**
```
GOOD  run the build → exit 0 → "the build passes"
BAD   "the linter passed" (a linter does not compile, and a type checker does not link)
```

**Bug fixed**
```
GOOD  reproduce the original symptom → apply the fix → the original reproduction now passes
BAD   the code changed in the right area, so the bug is assumed fixed
```

**Requirements**
```
GOOD  re-read the plan from disk → checklist → verify each line → report gaps or completion
BAD   "tests pass, so the phase is complete"
```

**Delegated or handed-off work**
```
GOOD  the agent (or build model) reports success → read the VCS diff → verify the changes → report the actual state
BAD   the report is taken as the result
```
This is the same rule `/3p-review` runs on a handoff summary, applied here to anything you did not
do with your own hands: a subagent, another session, another model, another person. A report is a
claim about the tree. The tree is the evidence.

## When to apply

**Always, before:** any claim of completion, correctness, or success, in any wording; any
expression of satisfaction with the work; committing, pushing, or opening a PR; moving to the next
task; archiving the plan.

This gate is never optional and is never skipped, regardless of model, time pressure, or
confidence. It also covers the bug and quick-fix path, which skips full review entirely: there the
suite comes from `/test-scope`'s no-plan row, Part 2 runs against the reported symptom instead of a
plan, and Part 3 says explicitly that there was no decision document.

## The bottom line

No shortcuts for verification. Run it, read the output, then claim the result. Read both documents,
then claim it is what was decided. This is non-negotiable, and claiming completion without it is
dishonesty rather than efficiency.

## What happens next

When the report says COMPLETE: move the plan from `docs/plans/` to `docs/plans/done/` with plain
`mv` (not `git mv`; the plan file may not be tracked). The feature is done.
