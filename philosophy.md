# Philosophy: The Structured Agentic Development Workflow

*Set of skills and workflows to ensure humans and agents stay focused while vibe-coding.*

---

## The Problem

Working with LLMs for software development often devolves into "vibe-based coding" — you ask for a massive feature, the AI hallucinates a messy implementation, breaks existing dependencies, and you spend the next three hours in debugging hell.

The root cause is not that the AI is bad at coding. It is that the AI **lacks object permanence**. It does not remember your architecture. It does not know your conventions. It does not feel the weight of technical debt. Every conversation starts from zero, and without structure, it defaults to the fastest path — which is rarely the best one.

## The Core Insight

**The developer's role shifts from Individual Contributor to Engineering Manager.**

You are not pair-programming with the AI. You are *managing* it. You define the what and the how. You set the constraints. You review the output. The AI does the keystrokes — but the architectural decisions, the quality standards, and the workflow discipline come from you.

This is not a limitation. This is a superpower. You can now operate at the speed of thought, with an incredibly fast engineer executing your vision — as long as you provide the scaffolding.

## The Principles

### 1. Never Skip Phases

Every significant change follows: **Brainstorm → Plan → Build → Review**.

The temptation to jump straight to code is enormous — the AI *wants* to code, and you *want* results. But the ten minutes you spend brainstorming and planning save hours of debugging and rework. The phases exist because each one catches a different class of error:

- **Brainstorm** catches wrong approaches before you invest in them
- **Plan** catches architectural misunderstandings before they become code
- **Build** (with tests) catches implementation bugs immediately
- **Review** catches the blind spots of the author

### 2. Plans Are Project Assets, Not Conversation Artifacts

Plans are written to disk (`docs/plans/new/`), not kept in the agent's head. This is deliberate:

- **Agent decoupling:** The agent that plans does not have to be the agent that builds. You can brainstorm with Claude Opus, then hand the plan to Gemini Flash for execution. The plan file is the contract between them.
- **Brainstorm preservation:** When the plan is a file on disk, the agent stays in thinking mode. If the plan lives only in conversation context, the agent immediately wants to implement it, cutting short the critical design phase.
- **Parallel staging:** Plans accumulate in `new/` as pre-invested design work. You choose when to execute — based on your available tokens, your time, and the task's complexity.

### 3. The Reviewer Owns the Code

The third-person review is not a rubber stamp. The reviewer did not write the code — but after the review, **it is their responsibility**. If a bug ships, if a security hole exists, if the design is flawed — the reviewer failed.

This mindset transforms review from a checkbox into a genuine quality gate. It is how you reap the benefits of pair programming from a single-agent workflow. The original author has blind spots; the reviewer does not share them.

### 4. Minimize Context Thrash

AI conversations have a finite context window, and loading new context is expensive — both in tokens and in the agent's ability to stay coherent. The triage strategy exists to respect this:

- When context is thin, pick **bugs** — small, self-contained, no full-cycle overhead
- When context is rich, pick work that **leverages what's already loaded** — even if something else is technically higher priority
- Let plans accumulate — with AI-assisted development, "later" means minutes or hours, not months

### 5. Keep the Agent Honest

Tools like Claude Code have built-in plan mode, but plan mode alone does not keep the agent *focused*. Left to its own devices, the agent will:

- Research tangential topics instead of staying on task
- Propose unnecessary refactors
- Drift from your architecture
- Start implementing before the design is settled

`CLAUDE.md` is the leash. Predefined skills are the guardrails. The structured workflow is the track. Together, they keep the agent honest, informed, and aligned — without you needing to repeat context every conversation.

### 6. Compose, Don't Reinvent

This workflow is an **orchestration layer** — it defines *when* and *why* to do things. It is designed to compose with execution-level skill libraries (like [obra/superpowers](https://github.com/obra/superpowers)) that define *how* to do specific things well.

Install domain-specific skills for TDD, debugging, git workflows, and clean code. Then let this workflow orchestrate when to invoke them. The document already instructs you to "equip the AI with predefined skills before the first task" — this is that principle in action.

## The Trade-offs

**What you gain:**
- Architectural integrity — maintainable, predictably structured code
- Near-zero regressions — bugs caught phase-by-phase
- Role elevation — you operate as Tech Lead, not typist
- Parallel velocity — planning and building can run concurrently

**What it costs:**
- Higher token consumption — planning and context-loading use tokens
- Higher active involvement — you cannot "prompt and walk away"
- Discipline — it is always tempting to skip the brainstorm and jump to code

The trade-off is worth it. The time you save in debugging and rework dwarfs the time you spend in structured planning. And the code you produce is code you can maintain, extend, and be proud of.

---

*This workflow was born from building [DragonEye](https://github.com/nicholasgasior/dragon-eye), an investigative intelligence tool, entirely with AI-assisted development. Every principle here was learned the hard way — by watching what happens when you skip it.*
