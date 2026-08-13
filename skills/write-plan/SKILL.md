---
name: write-plan
description: Write a formal phased implementation plan to docs/plans/new/. Use after brainstorming is complete and a direction has been chosen. Creates a plan file that decouples the planning agent from the building agent.
argument-hint: [feature-name or brainstorm summary]
allowed-tools: Read, Grep, Glob, Write, Agent, Bash
---

# Planning Phase

You are entering the **Planning Phase** of the Structured Agentic Development Workflow.

> **Output style:** Check memory for `workflow-config:caveman-level`. If set, adapt your output brevity to that level while preserving technical accuracy.

## Your Mission

Write a detailed, phased implementation plan for: **$ARGUMENTS**

## Rules

1. **Do NOT write implementation code.** You are producing a plan document, not building the feature.
2. **Save the plan to `docs/plans/new/<feature-name>.md`** — not to `docs/plans/` (that is for active plans only).
3. **Divide the work into isolated Phases.** Each phase should be independently testable and reviewable.
4. **Be hyper-granular.** Write the plan so that a different agent — possibly a smaller, faster model — can execute it without ambiguity. Name specific files, functions, classes, and test cases.
5. **Include test criteria for each phase**, expressed as the **exact command + expected output** — not a vague "tests pass". The executing model needs an objective stop condition, not a judgment call.
   - **Operational claims need a number and a way to measure it.** "Fast", "scales", "low memory", "won't block the UI" are not criteria — a build model cannot implement them and a reviewer cannot falsify them. Give a threshold and name the command or harness that measures it, or cut the claim from the plan.
   - **Never write a credential into a command.** The plan is committed to the repo and read by every downstream model. Keys, tokens, passwords, connection strings, and auth headers go in as `<from env: API_KEY>` — name how the value is supplied, never the value.
   - **A manual criterion is a last resort you must justify.** Manual verification is allowed only where no automated harness for it exists — and you must *confirm* that absence rather than assume it, then record what you checked: "no browser/e2e harness in this repo — checked `package.json` scripts, `tests/`, and CI config". Never fall back to manual because writing the automated check is inconvenient; that converts the phase's stop condition into an opinion.
6. **Write down the foresight, don't leave it in your head.** A smaller build model builds exactly what is specified and fills every silence with the happy path. The errors it makes are not bad guesses — they are *gaps*: failure modes, lifetimes, error codes, and cross-component interactions you anticipated but never wrote down. The Failure-Mode & Interaction Analysis below is where that foresight becomes part of the contract.
7. **Name the seam test for every value path.** Green unit tests do not prove the wiring works. For each path data must traverse to deliver value (e.g. worker → DB, request → handler → response), the plan MUST name a no-mock test that exercises the real seam. If you don't name it, the build model will not write it.
8. **Verify every name before you write it down.** Do not name a function, class, method signature, route, fixture, factory, registry entry, config key, env var, or CLI flag that you have not confirmed exists — read the definition, grep the call sites, check the registration. Naming `UserFactory.create_admin()` when the factory has no such method does not produce a question from the build model; it produces an invented method that no other code expects. For anything this plan *creates*, mark it **new** explicitly, so the build model doesn't burn a phase hunting for something that was never there.
9. **Never prescribe a command you haven't run.** Every command in the plan — test runner, migration, lint, build, script — must be one you confirmed works *in this repo*. Run it, or at absolute minimum confirm the runner, its config, and the target path all exist. `pytest tests/test_foo.py::test_bar` is worthless if the project runs `uv run pytest`, if the file lives somewhere else, or if the fixture it needs isn't in scope. A wrong command doesn't fail loudly — it turns the phase's objective stop condition into a guess, which is exactly what the criteria exist to prevent.
10. **Put the decisive gate before the work that depends on it.** If something could invalidate the plan — an assumption that might be wrong, an API that might not support what you need, a migration that might not be reversible, a library that might not do the thing — that check gets its own phase *before* the first phase that depends on it. Order phases by what could kill the plan, not by what is easiest to build first. A gate placed after three phases of implementation is not a gate; it is a post-mortem.
11. **Each phase should deliver an observable slice.** Prefer a phase that carries the change through to the outermost surface it touches — backend → API → UI, or command → output — over one that stops at a layer boundary with nothing to look at. Layer-by-layer phases pass their tests individually and still deliver nothing, and the gap only surfaces at the end. Where a phase genuinely cannot reach the surface, say what proves it works instead, and make the very next phase the one that closes the loop.
12. **Length comes from resolved decisions, not prose.** "Hyper-granular" is an instruction about *decision density*, not word count. Every file path, signature, error code, and test assertion earns its space — that specificity is the whole contract. Padding does not: restated context, redundant summaries, motivational framing, the same decision explained in three places, or a template section left in with nothing under it. A plan is long because the work has many decisions, never because the writing is loose. If a paragraph carries no decision the build model needs, cut it.

## Before Writing the Plan — Codebase Analysis

Before writing a single phase, you MUST investigate the existing codebase. Read code, grep for patterns, understand what's already there. This analysis feeds directly into the plan and prevents the review from catching issues that should have been designed out.

### Consistency & Patterns
- **How is this problem solved elsewhere?** Grep for similar functionality. If the codebase already has a pattern for this (e.g., a base class, a utility, a convention), the plan MUST use it — not invent a new one.
- **What can be extracted or reused?** If the new feature shares logic with existing code, the plan should include a phase for extracting the common pattern first.
- **What naming and structural conventions exist?** The plan must follow them. Name new files, classes, and functions consistent with their neighbors.
- **Do not design in a violation.** The structures this plan specifies are the ones the build model will write verbatim, and `/3p-review` will hold them to Clean Code, SOLID, DRY, KISS, and YAGNI. So the plan must clear that bar *on paper*: no seven-argument signatures, no boolean flag parameters switching behaviour, no god class collecting unrelated responsibilities, no duplicated logic specified into two phases, no abstraction built for a caller that doesn't exist. If a specified signature or structure would be a review finding, it is a planning defect — fix it here, where it costs one line.

### Design Patterns

Choosing a pattern is an architectural decision, so **the plan makes it and names it** — the build model should never have to decide "what shape should this be?". Name the pattern *and* the problem it solves; a pattern named without its problem is decoration the reviewer will strip out.

Three rules, in priority order:

1. **The problem comes first.** If you cannot state the concrete problem in one sentence — "three export formats chosen at runtime", "an external API whose interface we don't control" — do not name a pattern. A pattern applied to a problem you don't have is over-engineering, and `/3p-review` treats it as a finding.
2. **The codebase's existing vocabulary wins.** If this project already solves this shape of problem a particular way, specify that, even when a textbook pattern would be tidier. Consistency beats correctness-in-isolation.
3. **The language may already be the pattern.** Half of GoF dissolves into language features — most visibly in Python, where the class-heavy form is *worse* than the idiom, not more rigorous.

| Problem | Pattern | Usual Python form |
|---|---|---|
| Interchangeable algorithms picked at runtime | Strategy | a callable passed in, or a dict of callables |
| Build one of several related objects from a key or config | Factory | a dict registry, or a `classmethod` |
| An external interface we don't control and can't change | Adapter | a thin wrapper — worth it as-is |
| Notify N interested parties when something happens | Observer / pub-sub | a list of callbacks, or an event bus |
| Wrap behaviour around a call (logging, retry, caching) | Decorator | `@decorator`, `functools.wraps`, `lru_cache` |
| Fixed skeleton, varying steps | Template Method | a higher-order function, or an ABC with hooks |
| One shared instance or shared state | Singleton | a module-level object — modules already are singletons |
| Encapsulate a request to queue, log, or undo it | Command | a closure or `functools.partial` |
| Traverse without exposing internals | Iterator | a generator (`yield`) |
| Swap an implementation for tests or per-environment | Dependency Injection | pass the collaborator in as a parameter |

Specify which form the plan wants. "Use a Strategy" is ambiguous; "pass a `Callable[[Row], str]` formatter into `export()`; the three formatters live in `exporters.py`" is a decision.

And do not introduce a pattern for a single implementation on the grounds that more may come later — that is YAGNI, and the second implementation is the cheapest possible moment to extract it.

### Security
- **Does this feature touch user input, external APIs, or stored data?** If yes, the plan must include input validation, output encoding, or access control steps in the relevant phases.
- **Does this introduce new attack surface?** (new endpoints, new file I/O, new shell commands, new credentials) If yes, call it out in Risks & Mitigations.

### Architecture Fit
- **Does this change respect existing boundaries?** (module boundaries, layer separation, dependency direction) If the feature requires crossing a boundary, that's a design decision — make it explicit and justify it.
- **What existing code will this interact with?** List the specific files, classes, and functions. The plan must account for their interfaces, not assume them.
- **Where is each invariant enforced?** If a rule matters, it belongs at the lowest layer that can violate it — a unique index, a foreign key, a check constraint, a non-nullable type — with application validation on top as the friendly error, not as the guarantee. Repository- or service-level validation alone is bypassed by every other writer: migrations, fixtures, admin scripts, the next feature. Specify the layer in the plan.

### State & Data Contracts

*Skip this section only if the feature touches no persisted, cached, derived, or shared state — and say that you're skipping it.*

The build model implements the write path you describe and never asks what a concurrent reader sees, or what is on disk if the process dies halfway. Resolve that here.

- **Identity & cardinality:** What identifies one record here, and how many can exist? Is the key you're planning to use actually unique, and is it stable over time? Name the column/field, not the concept.
- **Currentness:** How does a reader know what it read is current — a version, generation, timestamp, ETag, or nothing? If nothing, state the staleness window and whether this feature tolerates it.
- **Authority & rebuildability:** Which store is the source of truth, and which are derived from it? For every derived store — index, cache, materialized view, generated artifact — give the exact command that rebuilds it from source, and what it costs to run. A derived store with no rebuild path is a second source of truth wearing a disguise.
- **Visibility during change:** If this state takes more than one write to update, what does a concurrent reader see in between? If the process dies between write N and N+1, what is on disk, and what brings it back to consistent? Name the mechanism — transaction, atomic rename, build-then-swap-pointer, idempotent retry, fencing token. "It's fast, so it won't happen" is not a mechanism; it is a description of how rare the corruption will be.
- **Migration & backfill:** If existing data must change shape, specify the preflight check that runs first, whether the migration **fails closed** on data it doesn't recognize, and what happens to rows that don't fit. A migration that silently skips unparseable rows produces a partially-migrated system that reads as success.

### Failure-Mode & Interaction Analysis

This is the highest-value part of the analysis for a handed-off build. The build model implements each piece correctly in isolation and misses how the pieces fail or interact. Anticipate those misses here and write them into the relevant phases as concrete requirements — not as vague warnings.

Work through each of these and resolve them in the plan:

- **Lifetimes & expiry.** Does anything have a TTL, timeout, cache duration, token/cookie lifetime, or session window? For each: what happens at the moment it expires, and does its lifetime have to be coordinated with another component's? *(A cookie expiring at the access-token TTL silently breaks the next mutating request — name that requirement, don't let the build model discover it.)*
- **Error & status codes at every boundary.** Enumerate the failure codes/exceptions each seam can emit (401 vs 403, timeout, 409, validation error) and specify exactly **who handles each one**. A reactive handler that only handles one code will be defeated by the others.
- **State transitions & lifecycle paths.** For anything started, it must be stopped/cancelled/cleaned up. Specify the cancellation and shutdown paths explicitly, including concurrent cleanup (multiple tasks cancelled together must each be awaited — a shared suppressor leaks the second). Name the path; do not assume "finally" is enough.
- **Cross-component interactions.** For each pair of components that touch: "when A changes/fails, what must B do?" Make the dependency explicit in both phases.
- **Concurrency & ordering.** Races, ordering assumptions, partial failure, retries. If two things run together, state what happens if one fails first. Include **aliasing**: when two call sites hold the same object, connection, buffer, or config instance, a mutation by one is instantly visible to the other. For each thing passed across a boundary, say whether it is shared or copied — "passed the same dict to both" is a race the build model will not see, because in its phase there was only one caller.

Every item you surface here becomes either a phase implementation step or a named test below. An anticipated failure mode with no corresponding test is not actually handled.

### Delegating the analysis

Subagents multiply cost and latency: each one re-establishes context, re-explores, reports back, and then you re-read the report. Delegate only when the payoff clearly exceeds that overhead.

- **Do delegate** a genuinely wide investigation — several unrelated modules to survey, a large unfamiliar surface to map. Send those in one message so they run concurrently.
- **Do NOT delegate** work you could finish in a handful of tool calls (a few file reads, one grep, checking a convention), and do not delegate review or verification of your own plan — that belongs in your main loop.
- **Pin the cheapest model that can do the job.** Mechanical breadth work — grep, enumerate call sites, list what exists, summarize a module — does not need the planning model. Reserve the expensive model for the judgment: trade-offs, decisions, the plan itself. If your harness lets a subagent inherit the parent's model by default, override it explicitly; an un-pinned subagent costs planning-model rates for clerical work.
- **The saving is context compression, so brief for a summary.** The win is that you read a short report instead of forty files. Ask for findings — paths, patterns, the specific answer — not raw file contents. A subagent that dumps everything it read back into your context has cost you money instead of saving it.
- **Keep spawn counts low.** If one subagent can do it, use one. Brief it precisely the first time rather than launching, waiting, and re-briefing. Once it reports back, commit to its findings — do not re-derive them yourself.

## Plan Document Structure

```markdown
# Plan: [Feature Name]

## Summary
[2-3 sentences describing what this plan achieves]

## Context
[What exists today, what changes, and why]

## Codebase Analysis
- **Existing patterns used:** [patterns/utilities this plan reuses]
- **New patterns introduced:** [if any — justify why existing patterns don't fit]
- **Security considerations:** [attack surface, input boundaries, access control]
- **Files/modules affected:** [list with brief description of each interaction]

## State & Data Contracts
*(omit only if no persisted, cached, derived, or shared state is touched)*
- **Identity & cardinality:** [what identifies a record, how many, which field]
- **Currentness:** [version/generation/timestamp mechanism, or the tolerated staleness window]
- **Authority & rebuildability:** [source of truth; each derived store + its exact rebuild command]
- **Visibility during change:** [what a concurrent reader sees mid-update; crash-window recovery mechanism]
- **Invariant enforcement:** [invariant → the storage/type-level constraint that enforces it]
- **Migration & backfill:** [preflight check, fail-closed behavior, handling of non-conforming rows]

## Failure Modes & Interactions
- **Lifetimes/expiry:** [each TTL/timeout/session and its behavior at expiry + coordination requirement]
- **Boundary error codes:** [code/exception → who handles it]
- **Lifecycle/cancellation:** [start → stop/cleanup path for each long-lived thing]
- **Cross-component interactions:** [when A changes/fails → what B must do]
- **Concurrency & aliasing:** [what races, what ordering is assumed, which objects are shared vs copied across boundaries]

## Value Paths & Seam Tests
- **[value path, e.g. worker → DB heartbeat]:** named no-mock test → [test name + what it asserts at the real seam]

## Phases

### Phase 1: [Name]
**Goal:** [One sentence]
**Files to modify/create:**
- `path/to/file.py` — [what changes]

**Implementation details:**
1. [Step-by-step instructions]

**Test criteria:** (each as command + expected output)
- [ ] `exact command to run` → [expected output / assertion that proves the phase is done]
- [ ] Seam test (if this phase completes a value path): `command` → [no-mock assertion across the real seam]

### Phase 2: [Name]
...

## Risks & Mitigations
- [Risk] → [Mitigation]

## Out of Scope
- [What this plan explicitly does NOT cover]
```

## Agent Decoupling — Zero Ambiguity for External Models

This plan is designed as a **contract between agents**. The agent that writes this plan does not have to be the agent that executes it — it may be a smaller model (Gemini Flash, GPT-4o-mini), a different tool (Cursor Composer, Copilot), or a local model with no conversation history.

**This means the plan must resolve ALL decisions. No open questions may remain:**

- Be explicit about file paths, function signatures, and expected behavior
- Do not rely on "context from earlier in the conversation"
- Include enough detail that the plan is self-contained
- **Never write "choose an appropriate X" or "decide whether to Y"** — make the decision in the plan. The executing agent should not have to make architectural choices.
- **Never write "consider using X or Y"** — pick one and specify it. If the choice depends on something, investigate it now and decide.
- **Specify exact function signatures, class names, and return types** — not just descriptions of what they should do.
- **Specify exact test assertions** — not just "write tests for this". Name the test functions, the inputs, and the expected outputs.
- **If a step requires installing a package, name it** with the exact install command.
- **Resolve all design trade-offs in the plan itself.** The plan need not include all the code, but it MUST include all decisions. The dev model's job is to execute, not to design.

## Before Saving — The Two-Pass Plan Review

Review the finished plan twice, with a different lens each time, and do not collapse them into one pass. They catch different classes of defect: Pass 1 catches a plan that is wrong, Pass 2 catches a plan that is right but unrunnable. **Both passes must complete before the plan is saved, and before the plan is activated (moved out of `new/`).**

### Pass 1 — Contracts & Architecture: *is this the right plan?*

- Does every State & Data Contract line have an actual answer — identity, currentness, authority and rebuild path, visibility during change, enforcement layer, migration behavior? An `unknown` left here is a decision the build model will make for you, at the worst possible moment.
- For every long-lived thing, TTL, and boundary: is what happens at expiry/failure written down, with a named owner for **each** error code? A failure mode that lives only in my head will not be built.
- Does every value path have a named no-mock seam test? An anticipated interaction with no test is not handled — the build model will skip it.
- Is every invariant enforced at the layer that can actually violate it, not just at the layer that happens to be convenient?
- Do the phases run in the right order — is every decisive gate ahead of the work that depends on it? Does each phase deliver something observable?
- Does this fit the codebase's existing patterns, boundaries, and naming — or does it introduce a new pattern that I justified explicitly in the plan?

### Pass 2 — Executability: *can a different agent run this exactly as written?*

- **Does every name in this plan exist?** Walk the file paths, functions, classes, signatures, routes, fixtures, config keys, and flags one by one and confirm each — or that it is marked **new**. This is a mechanical check; do it mechanically, not from memory of having read the code earlier.
- **Does every command in this plan run?** Confirm the runner, the target path, and the flags in this repo. No invented harnesses, no assumed test runners.
- Could a junior developer with codebase access and zero context about our conversation execute each phase without asking a single clarifying question? If no, add detail.
- Is every test criterion an exact command with an expected result — no vague "tests pass", no unjustified manual step?
- Is there a section a build model could delete without losing a decision? Cut it. (This pulls against the question above on purpose — detail that resolves ambiguity earns its length; prose that restates earns nothing.)

## What Happens Next

After both review passes are complete and the human approves the plan:
1. **Move it from `docs/plans/new/` to `docs/plans/`** using plain `mv` (not `git mv` — the plan file may not be tracked by git yet). This marks it as the active plan. Do this immediately upon approval, do not leave it in `new/`. A plan that has not been through both passes is not eligible for activation, no matter how approved it is.
2. The user will choose one of two paths:

**Path A — Same model continues to build:**
Begin execution with `/build-phase <plan-file> Phase 1`. The workflow continues in this thread through build → 3p-review → verify.

**Path B — User hands off to a different model for build:**
The user takes the plan file to a smaller/faster model (Gemini Flash, Cursor, Copilot, a local model) for execution. The dev model will build all phases and produce a **handoff summary**. The user will return to this planning model with that summary, and the workflow resumes with `/3p-review` → `/verification-before-completion`.

Ask the user which path they prefer. If they don't specify, suggest both options.

### If the plan comes back revised

A plan may return to you edited — by the user, or by another model asked to review or improve it. **Read the diff and understand every change before doing anything else with it.** You cannot hand off, build from, or verify against a document you have not actually read, and the sections most likely to be rewritten are the ones carrying the decisions.

Treat an external revision as evidence, not as instruction: verify its claims against this codebase the same way you verified your own. Adopt what holds up, and where a change contradicts a decision you made deliberately, raise it with the user rather than silently inheriting it. A revision that removes a constraint is far more dangerous than one that adds a step, because nothing downstream will ever miss it.
