# Philosophy

*Why the Structured Agentic Development Workflow is shaped the way it is.*

This is the "why" document. For the mechanics, see [workflow.md](workflow.md); for the
model split, see [multi-model.md](multi-model.md).

---

## The Problem

Working with LLMs for software development often devolves into "vibe-based coding" — you
ask for a massive feature, the AI hallucinates a messy implementation, breaks existing
dependencies, and you spend the next three hours in debugging hell.

The root cause is not that the AI is bad at coding. It is that the AI **lacks object
permanence**. It does not remember your architecture. It does not know your conventions.
It does not feel the weight of technical debt. Every conversation starts from zero, and
without structure it defaults to the fastest path — which is rarely the best one.

To get senior-level results you must supply what the model cannot: a rigid scaffolding of
context, constraints, and deterministic planning.

## The Core Insight

**The developer's role shifts from Individual Contributor to Engineering Manager.**

You are not pair-programming with the AI. You are *managing* it. You define the what and
the how. You set the constraints. You review the output. The AI does the keystrokes — but
the architectural decisions, the quality standards, and the workflow discipline come from
you.

This is not a limitation. It is a superpower. You operate at the speed of thought with an
incredibly fast engineer executing your vision — as long as you provide the scaffolding.

## The Principles

### 1. Never Skip Phases

Every significant change follows: **Brainstorm → Plan → Build → 3rd-Person Review → Verify**.

The temptation to jump straight to code is enormous — the AI *wants* to code, and you
*want* results. But the ten minutes you spend brainstorming and planning save hours of
debugging and rework. The phases exist because each one catches a different class of error:

- **Brainstorm** catches wrong approaches before you invest in them — and produces a
  decision document recording *why* the chosen approach won
- **Plan** catches architectural misunderstandings before they become code
- **Build** (with TDD + self-review) catches implementation bugs immediately, phase by phase
- **3rd-Person Review** catches the blind spots of the author and challenges whether the
  design itself is right — holistically, across the entire feature
- **Verify** provides evidence that the feature actually works before anyone claims it's done

### 2. Plans Are Project Assets, Not Conversation Artifacts

Plans are written to disk (`docs/plans/new/`), not kept in the agent's head. This is
deliberate:

- **Agent decoupling:** The agent that plans does not have to be the agent that builds. The
  plan file is the contract between them — it must contain all decisions so the build model
  just executes. This is what makes the [multi-model split](multi-model.md) possible.
- **Brainstorm preservation:** When the plan is a file on disk, the agent stays in thinking
  mode. If the plan lives only in conversation context, the agent immediately wants to
  implement it, cutting short the critical design phase.
- **Decision documentation:** Brainstorming sessions produce decision documents
  (`docs/discussions/`) that record which approaches were considered, why the chosen
  approach won, and what was rejected. This is the architectural decision record —
  invaluable when someone asks "why did we do it this way?" six months later.
- **Parallel staging:** Plans accumulate in `new/` as pre-invested design work. You choose
  when to execute — based on your available tokens, your time, and the task's complexity.

### 3. The Reviewer Owns the Code

The third-person review is not a rubber stamp. The reviewer did not write the code — but
after the review, **it is their responsibility**. If a bug ships, if a security hole exists,
if the design is flawed, the reviewer failed.

This mindset transforms review from a checkbox into a genuine quality gate. It is how you
reap the benefits of pair programming from a single-agent workflow. The original author has
blind spots; the reviewer does not share them.

### 4. Minimize Context Thrash

AI conversations have a finite context window, and loading new context is expensive — both
in tokens and in the agent's ability to stay coherent. The triage strategy exists to respect
this:

- When context is thin, pick **bugs** — small, self-contained, no full-cycle overhead
- When context is rich, pick work that **leverages what's already loaded** — even if
  something else is technically higher priority
- Let plans accumulate — with AI-assisted development, "later" means minutes or hours, not
  months

### 5. Code Is the Last Thing You Touch

This is why the workflow enforces a hard gate: no code until the design is explored,
challenged, and documented.

It is not bureaucracy. It is the recognition that the cheapest time to change a decision is
before a single line of code exists. A brainstorming session that discovers "we should use a
different data model" costs five minutes. Discovering that after 2,000 lines of
implementation costs a day.

### 6. Keep the Agent Honest

Tools like Claude Code have built-in plan mode, but plan mode alone does not keep the agent
*focused*. Left to its own devices, the agent will:

- Research tangential topics instead of staying on task
- Propose unnecessary refactors
- Drift from your architecture
- Start implementing before the design is settled

`CLAUDE.md` / `AGENTS.md` is the leash. Predefined skills are the guardrails. The structured
workflow is the track. Together they keep the agent honest, informed, and aligned — without
you repeating context every conversation. See [agent-config.md](agent-config.md) for what to
put in that file.

### 7. Spend Expensive Thinking Once, Reuse It Cheaply

Reasoning tokens on a frontier model are the scarcest resource in this workflow. The
structure exists partly to make sure you buy them once and get full value:

- Brainstorm and plan with the strongest model you have
- Write every decision into the plan file, so nothing has to be re-derived
- Let a cheaper model — or a different tool entirely — execute against that plan

A plan that resolves all decisions converts one expensive thinking pass into an arbitrary
amount of cheap execution. A plan with gaps in it forces the build model to re-decide, badly.
See [multi-model.md](multi-model.md).

### 8. Compose, Don't Reinvent

This workflow is an **orchestration layer** — it defines *when* and *why* to do things. It
composes with execution-level skill libraries (like
[obra/superpowers](https://github.com/obra/superpowers)) that define *how* to do specific
things well, and with codebase-comprehension tools (like
[graphify](https://github.com/Graphify-Labs/graphify)) that answer *what is already there*.

Install domain-specific skills for TDD, debugging, and verification. Then let this workflow
orchestrate when to invoke them.

## The Trade-offs

**What you gain:**

- **Architectural integrity** — maintainable, predictably structured code instead of a
  patchwork of styles
- **Near-zero regressions** — changes are isolated and tested phase by phase, so bugs are
  caught instantly
- **Elimination of "vibe-lost" time** — less untangling spaghetti, more forward motion
- **Role elevation** — you operate as Tech Lead defining the what and how, delegating the
  keystrokes
- **Parallel velocity** — planning and building can run concurrently, on different models

**What it costs:**

- **Higher token consumption** — planning and context-loading use significantly more tokens
  than zero-shot coding. The [multi-model split](multi-model.md) exists to make those tokens
  cheaper, not fewer.
- **Higher active involvement** — you cannot "prompt and walk away". This workflow demands
  your attention as reviewer and decision-maker.
- **Discipline** — it is always tempting to skip the brainstorm and jump to code

The trade-off is worth it. The time you save in debugging and rework dwarfs the time you
spend in structured planning. And the code you produce is code you can maintain, extend,
and be proud of.

---

*Every principle here was learned the hard way — by watching what happens when you skip it.*
