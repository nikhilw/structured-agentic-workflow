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

1. **Callers and calls, in both directions.** Trace the target backward *and* forward. They answer
   different questions and missing either one is its own class of defect, so answer them as two
   separate lists rather than one paragraph about "usages".

   - **Backward, what reaches this.** Every direct caller, then *their* callers, outward until you
     reach a boundary that this change cannot disturb (a stable public API, a process edge, a
     surface with its own contract). Say where you stopped and why. Direct callers are the easy
     half; the defect usually lives one hop further out, where a caller adapts to the change and
     quietly passes something different to *its* caller. Include the inbound edges that carry no
     literal reference to the name: test doubles and fixtures, dependency-injection registrations,
     route and command tables, event or signal subscriptions, decorators, serialized or persisted
     references, config keys, scheduled jobs, and anything dispatched by string. A grep finds the
     name; none of these spell it.
   - **Forward, what this reaches.** Everything the target calls out to, and what those things
     depend on in turn: modules, shared helpers, database tables and columns, queues, caches,
     files, environment variables, external services, and the assumptions each of those carries.

   Backward tells you who breaks when this changes. Forward tells you what can break *this*, and
   what the change inherits whether or not you looked. Where an index exists, walk it both ways:
   `graphify query` to find the thing, its incoming edges for backward, its outgoing edges for
   forward, and `graphify path "A" "B"` to confirm two things actually connect.

   *Prevents, backward: the signature change that breaks seven call sites nobody listed, and the
   caller two hops out that silently changes meaning. Forward: building on a dependency that
   already has the constraint you are about to design around.*

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

   **The moment anything is removed, this answer stops being a line and becomes a table.** One row
   per removal, with a replacement named for each. Summarising instead — "cleaned up the old prune
   path" — is how the load-bearing half of a removal disappears without anyone deciding to drop it.

   | Removed | What it did | Replaced by | Anything lost? |
   |---|---|---|---|

   - **Nothing is deleted because it "looks unused".** Prove the callers both ways, per question 1,
     including the inbound edges that never spell the name: tests, fixtures, DI registrations,
     route and command tables, config keys, scheduled jobs, anything dispatched by string.
   - **Ask what the code was load-bearing *for*, not only who calls it.** The dangerous removals
     are the ones that read as housekeeping. A checkpoint prune that looks like tidy-up can be the
     only thing bounding a database that is already at 100 MB, and no caller says so.
   - **A test left covering a path nobody takes any more is a coverage hole, not a pass.** It stays
     green and proves nothing. Name it in the row, and say which assertion replaces it.
   - **Deleting a test because it went red is not updating it.** A changed rule needs a test that
     states the new rule.
   - **Scalpel, not butcher knife.** Remove exactly the lines the table names, not the
     neighbourhood. Anything you want to remove that the table does not name gets a row first.
   - **You cannot finish with less than you started with.** A row whose *Replaced by* cell is empty
     is a capability the work took away. That is a loud failure, not a simplification — say so in
     those words rather than letting the blank cell read as an answer. Reduced functionality is a
     decision the owner is allowed to make; it is not one any gate here makes quietly on their
     behalf.

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
1. **Callers and calls:**
   - *backward:* [direct callers → their callers, to the boundary named here; plus the inbound
     edges that do not spell the name] *(evidence: graph incoming edges / grep / read)*
   - *forward:* [what it calls, and what those depend on: modules, tables, queues, services, env]
     *(evidence: graph outgoing edges / read)*
2. **Scope beyond the entry point:** [related methods and flows that reach the same thing]
3. **Already exists:** [the mechanism that already does this, or what was searched for and not found]
4. **Relationship to the incumbent:** [extend / replace / abandon] + [why]
5. **Retirement:** [what becomes dead and where it is removed, or "nothing is retired". If anything
   is removed, this line is the removal table above, one row per removal]
6. **Build on what exists:** [the extend-the-incumbent version of this change]
7. **House pattern:** [the shape this codebase already uses for this problem]
8. **Unify vs bifurcate:** [what is extracted; any second pathway introduced and what collapses it]
```

## The second sweep

**Expect the first pass to be incomplete.** It is run against the problem while the design is still
in your head. The second is run against what you actually wrote, and that is where precision
defects surface: the ones that are invisible in a summary and obvious in a file list.

Three things make the second sweep find what the first missed. Drop any one and it degrades into
confirming the first.

- **Run it against the artifact, not your memory of it.** Take the finished document's own list of
  names, files, symbols and commands, and walk it back against the codebase mechanically, both
  directions per question 1. "I checked that earlier" is the answer that produces nothing.
- **Hunt a named list.** Generic re-reading finds generic problems. These are the classes that
  actually recur: a **dropped** step or requirement that quietly vanished between documents; a
  **deletion or abandonment** that left callers, tests, config or data dangling; a **duplicate** of
  something that already exists; a **missed caller**, especially one that does not spell the name;
  a **bifurcated** pathway added beside an existing one; and **drift** from what was decided. Say
  which you are looking for before you look.
- **Give yourself permission to reverse.** A sweep that can only confirm is not a sweep. Finding
  four defects in your own finished work is the mechanism paying for itself, not a failure.

**"Anything else you would rethink?" is a trigger, not a question.** When a human asks it, or when
you are about to hand work over as done, re-run the sweep for real. Answering it from memory is the
single cheapest way to waste the most valuable question anyone will ask you.

## Where this is answered

This table is the only place these assignments are written down. A skill that runs the audit names
its row here and does not restate the questions.

| Gate | Runs it against | Depth |
|---|---|---|
| `/brainstorm`, Current State Analysis | the problem space, before any approach is proposed | all eight, recorded in the decision document |
| `/brainstorm`, Decision Audit | the approach you are about to recommend | re-check 3, 4, 5, 8 against the *chosen* design |
| `/brainstorm`, after the decision document is written | the saved document's own claims and names | the second sweep, before handing over to `/write-plan` |
| `/write-plan`, Pass 2 | the finished plan's own file and symbol list | the second sweep, before the plan is saved or activated |
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
