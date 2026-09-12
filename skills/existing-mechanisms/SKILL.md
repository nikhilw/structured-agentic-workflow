---
name: existing-mechanisms
description: The eight questions that must be answered about what a codebase already does before anything new is proposed, planned, or built. Shared reference loaded by brainstorm, write-plan, build-phase and 3p-review. It is a reference, not a step of its own.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
---

# Existing Mechanisms

This file holds one definition the rest of the workflow depends on and must never restate: **the
questions that prove you understand what the codebase already does, before you propose changing
it.**

It is not a step. Reading this satisfies no gate. It tells you what the gate you are already
standing in has to answer.

## Why this exists

The expensive failures of this workflow are almost never bad trade-off analysis. They are analysis
that was never done: a mechanism that already existed under a name nobody searched for, a caller
nobody enumerated, a subsystem left unreachable by a change that replaced it, a second pathway
bolted alongside the first because unifying them was never considered.

These questions find something almost every time they are asked. That is the whole argument for
asking them by default instead of waiting for a human to ask them again.

They are also the reason the *ideal-then-adjusted* derivation in `/brainstorm` is worth running:
you cannot adjust an ideal design to fit existing decisions until you have written down what the
existing decisions actually are.

## The eight questions

Answer every one. A question that genuinely does not apply is answered **"does not apply,
because ..."**; silence reads identically to "checked and clean" to every later reader, and that
is how the gap ships.

1. **Callers and calls.** Enumerate *every* caller of everything this would touch, and every call
   those things make outward. Not the main ones. Not the ones you happened to open. Where an index
   exists, query it (`graphify query`, `graphify path`); a grep finds the name, the graph finds
   what reaches it. *Prevents: the signature change that breaks seven call sites nobody listed.*

2. **Scope beyond the entry point.** Which related methods, sibling flows, and alternative paths
   reach the same data or the same decision? A change scoped to one function is only correct if
   the other three ways in do not exist. *Prevents: fixing one of four entry points and calling
   the behaviour fixed.*

3. **Does this already exist?** Name the mechanism in this codebase that already does this job, or
   state what you searched for and did not find. Search by *behaviour*, not by the name you would
   have given it; the duplicate you are about to write is nearly always sitting under a word you
   did not think of. *Prevents: the second implementation of something the codebase already had.*

4. **Relationship to the incumbent.** If something related exists, say which of these you are
   doing, in one word, and then justify it: **extend** it, **replace** it, **abandon** it, or
   **compete** with it. *Compete is never an answer you get to keep.* Two mechanisms for one job is
   the defect, whichever one is better. If the honest answer is "compete", the work is not designed
   yet.

5. **Retirement and dead code.** If you are replacing or abandoning something: what happens to the
   old mechanism, its callers, its tests, its config keys, its stored data, its documentation?
   Name every part that becomes dead, unreachable, or vestigial, and where it gets removed. A
   subsystem that no longer runs but is still installed is worse than one that was never built;
   the next reader cannot tell it is dead. *Prevents: the abandoned-in-place subsystem that three
   people later assume is live.*

6. **Build on what exists.** State the version of this change that extends the existing mechanism
   rather than adding a parallel one, even if you will not recommend it. If you cannot state it,
   you have not understood the existing mechanism well enough to replace it. *Prevents: greenfield
   design applied to a field that is not green.*

7. **House patterns before book patterns.** What shape does this codebase already use for this
   class of problem? Name it before you name a pattern from a book. The project's existing
   vocabulary wins over a tidier abstraction; consistency beats correctness in isolation.
   *Prevents: a third way of doing the thing the codebase already does two ways.*

8. **Unify, do not bifurcate.** What common behaviour can be extracted here? And, the sharper half:
   does this change add a second pathway where one existed? A branch at the top that routes old
   versus new, a flag that selects between implementations, a parallel class for the new case;
   each is a bifurcation, and each one doubles every future change to this area. If you are adding
   one, say so out loud and say what collapses it back.

## How to answer

- **Every answer names its evidence.** "Checked, looks fine" is not an answer. Say what you ran or
  read: the graph query, the grep, the file you opened, the probe you executed. `/brainstorm`'s
  evidence tiers apply here exactly as they do everywhere else; a claim from docs or comments is
  tier 1 and is a liability if it is load bearing.
- **An unknown is probed or promoted, never left.** If the answer is cheap to get, get it now. If
  it is genuinely expensive, write it down as an Open Question and say what it would change. An
  unanswered question is a risk the recommendation carries silently.
- **Write the answers down where the next reader will find them.** In `/brainstorm` they belong in
  the decision document; in `/write-plan`, in the plan's Codebase Analysis. Answers that live only
  in the session are answers the build model never sees.

## The ledger

The gates below record the answers in this shape. Eight lines, one per question, each with its
evidence. Collapse the ones that genuinely do not apply onto a single "does not apply" line.

```markdown
### Existing Mechanisms
1. **Callers and calls:** [what calls it, what it calls] *(evidence: graph query / grep / read)*
2. **Scope beyond the entry point:** [related methods and flows that reach the same thing]
3. **Already exists:** [the mechanism that already does this, or what was searched for and not found]
4. **Relationship to the incumbent:** [extend / replace / abandon] + [why]
5. **Retirement:** [what becomes dead and where it is removed, or "nothing is retired"]
6. **Build on what exists:** [the extend-the-incumbent version of this change]
7. **House pattern:** [the shape this codebase already uses for this problem]
8. **Unify vs bifurcate:** [what is extracted; any second pathway introduced and what collapses it]
```

## Where this is answered

This table is the only place these assignments are written down. A skill that runs the audit names
its row here and does not restate the questions.

| Gate | Runs it against | Depth |
|---|---|---|
| `/brainstorm`, Current State Analysis | the problem space, before any approach is proposed | all eight, recorded in the decision document |
| `/brainstorm`, Decision Audit | the approach you are about to recommend | re-check 3, 4, 5, 8 against the *chosen* design |
| `/write-plan`, Codebase Analysis | the concrete chosen design, not the problem space | all eight, recorded in the plan |
| `/build-phase`, Plan Review | this phase's named files and symbols | 1, 3, 5, 8; a gap here is a halt, not a fix |
| `/3p-review`, Codebase Consistency | the code as built | 3, 5, 8; a gap here is a finding |
| Bug or quick-fix path, no plan | the fix you are about to make | 1, 2 and 8, before the fix. Question 2 is the one that matters here: a bug reached through four entry points is fixed at one of them and reported as fixed |

**The two full runs are not redundant.** `/brainstorm` asks the questions about a problem, when the
answers change which approach wins. `/write-plan` asks them about a design, when the answers change
which files the plan must name. An approach that survived question 4 in the abstract routinely fails
it once the design is concrete, and that is exactly the failure the second run is bought to catch.

**The later rows are narrow on purpose.** By the time a plan is being built or reviewed, the
questions are being asked of a decision that is already made, so only the ones that can still change
the outcome are run. Widening them there turns a build into a redesign, which is the thing the plan
exists to prevent.
