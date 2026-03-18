# The Structured Agentic Development Workflow

*A pragmatic approach to building complex software with autonomous AI agents. This methodology shifts the developer's role from Individual Contributor to Engineering Manager, focusing on deterministic outcomes, architectural integrity, and continuous improvement.*

---

## The Philosophy: Beyond "Vibe Coding"

Working with LLMs for software development often devolves into "vibe-based coding"—you ask for a massive feature, the AI hallucinates a messy implementation, breaks existing dependencies, and you spend the next three hours in debugging hell.

The **Structured Agentic Development Workflow** treats the AI not as a magical junior developer who can read your mind, but as an incredibly fast, highly capable engineer that *lacks object permanence*. To get senior-level results, you must provide a rigid scaffolding of context, constraints, and deterministic planning.

### The Trade-offs

**Benefits:**
*   **Architectural Integrity:** You get maintainable, predictably structured code instead of a patchwork of different styles.
*   **Near-Zero Regressions:** Because changes are isolated and tested phase-by-phase, bugs are caught instantly.
*   **Elimination of "Vibe-Lost" Time:** You spend less time untangling spaghetti code and more time in active, forward-moving development.
*   **Role Elevation:** You operate as a Tech Lead defining the "what" and "how," delegating the keystrokes to the agent.

**Drawbacks:**
*   **Higher Token Consumption:** Planning and context-loading consume significantly more tokens (and therefore money) than zero-shot coding.
*   **Higher Active Involvement:** You cannot simply prompt "build the app" and walk away. This workflow demands your constant attention as a reviewer and decision-maker.

---

## 1. Project Initialization & Context Scaffolding

Before you prompt the AI to write a feature, you must establish its world. Let's imagine a hypothetical project: **SyncScribe**, a real-time collaborative Markdown editor. 

Create a dedicated `docs/` or `.ai/` directory in your project root containing:

1. **`ai-context.md` (The Worldview)**
   - *Example:* "SyncScribe uses FastAPI (Python 3.13) for the backend and React (TypeScript) for the frontend. We use CRDTs (Yjs) for state resolution. All database interactions must go through the Repository layer."

2. **`CLAUDE.md` (The Persistent System Prompt)**
   - Most agentic coding tools (Claude Code, Cursor, Windsurf) support a project-level instruction file—`CLAUDE.md`, `.cursorrules`, etc. This file is loaded into every conversation automatically and acts as the agent's persistent memory of your project's architecture, conventions, and hard rules.
   - **Why this matters beyond built-in plan mode:** Tools like Claude Code already have a "plan mode" where the agent plans before building. But plan mode alone does not keep the agent *focused*. Left to its own devices, the agent will start researching tangential topics, propose unnecessary refactors, or drift from your architecture. `CLAUDE.md` is the leash—it keeps the agent honest, informed, and aligned with your project's reality without requiring you to repeat context every conversation.
   - *Example contents:* "SQLite is the source of truth. Config uses Dynaconf + dataclasses. Entity relationships are stored by NAME not ID. Cost-conscious: use haiku/sonnet for bulk work, opus for planning only."

3. **The Backlog (`features.md`, `bugs.md`)**
   - A prioritized list of tasks. This grounds the AI. When a task is completed, the AI crosses it off, maintaining a shared sense of progress.

4. **Global System Prompt & Predefined Skills**
   - **Initial Prep (The Skill-set):** Equip the AI with predefined skills *before* the first task.
     - **Clean Code & Patterns:** Hard-code instructions for naming conventions, SOLID principles, and design patterns.
     - **Project-Specific standards:** Define exactly how configuration management (e.g., Dynaconf) or logging (e.g., RichHandler) should be implemented.
   - **Strict Rules (The Guardrails):**
     - *Example:* "Do not use `any` types in TypeScript; define strict interfaces for all API payloads."
     - *Example:* "Always use the public APIs of third-party libraries; do not import internal private modules."

5. **List Your Workflow Skills in `CLAUDE.md`**
   - Skills installed globally (in `~/.claude/skills/`) or at project level (in `.claude/skills/`) are automatically discovered by the agent. However, explicitly listing them in `CLAUDE.md` ensures they are loaded into context at the start of every conversation, so the agent knows the workflow exists and can suggest phase transitions proactively.
   - *Example:*
     ```markdown
     ## Workflow Skills
     - `agentic-workflow` — orchestrates the structured development lifecycle
     - `/brainstorm` — explore problem space before planning
     - `/write-plan` — write phased plans to docs/plans/new/
     - `/build-phase` — execute one plan phase with test + review
     - `/3p-review` — independent third-person code review
     - `/triage` — recommend next task minimizing context thrash
     ```

---

## 2. The Development Lifecycle

Every significant change must follow a rigid, iterative cycle: **Brainstorm → Plan → Build → 3rd-Person Review**.

### Step 1: The Brainstorm Phase
Do not ask the AI to "build offline support." Ask it to explore the problem space.

*   **Prompt Example:** *"We need offline support for SyncScribe. Analyze our current WebSocket sync layer in `frontend/src/sync/` and propose three architectural ways to queue local edits for reconnection. Consider IndexedDB vs localStorage."*
*   **The Human's Active Role:** While the AI generates its analysis, **you are doing parallel research** (via Perplexity or Google). 
*   **The Pivot:** Often, you will discover a library or approach the AI missed. 
    *   *Human response:* *"Your IndexedDB proposal is good, but I just found a new library `RxDB` that handles conflict resolution better. Let's discard these three options and pivot to exploring an RxDB adapter approach instead."*

### Step 2: The Planning Phase
The AI must write a formal technical specification *before* writing any code.

*   **Model Scoping:** You can specify which model should handle the build.
    *   *Prompt Example:* *"Write a detailed technical plan for the RxDB adapter. Save it to `docs/plans/offline-sync.md`. Divide this into isolated Phases. **Plan this specifically for a smaller model (e.g., Gemini 2.5 Flash)** to execute—be hyper-granular and explicit."*
*   **Human Role:** Review the Markdown plan. Correct architectural misunderstandings. Approve the plan.

#### The Plan Directory Workflow: `plans/`, `plans/new/`, `plans/done/`

Plans are not throwaway conversation artifacts—they are versioned project assets with a deliberate lifecycle.

*   **`docs/plans/new/`** — Plans that have been brainstormed and written but not yet approved or started. This is the staging area.
*   **`docs/plans/`** — The active plan currently being executed.
*   **`docs/plans/done/`** — Completed plans, kept as an audit trail and architectural reference.

**Why write plans to disk instead of keeping them in the agent's head?**

1.  **Agent decoupling:** The agent that *plans* does not have to be the agent that *builds*. You can brainstorm a plan with Claude Opus, then hand the plan file to Gemini Flash or a local model for execution. The plan is the contract between them.
2.  **Brainstorm preservation:** When the plan lives as a file on disk, the agent does not enter its internal "planning → executing" loop. It stays in brainstorm mode, which is exactly where you want it during the design phase. If the plan lived only in conversation context, the agent would immediately start nagging you to implement it, cutting short the critical thinking phase.
3.  **Parallel workflow:** Plans can accumulate in `plans/new/` while you focus on other work. You choose *when* to pick them up—based on your available tokens, your own availability, and the complexity of the task. This decouples planning velocity from implementation velocity and lets you run both in parallel.

### Step 3: The Build Phase (The Phase-Wise Loop)
Execute the plan strictly **one phase at a time** using the internal loop: `Implement -> Test -> Review -> Proceed`.

1.  **Implement:**
    *   *Prompt Example:* *"Execute Phase 1 (Database Schema) from `docs/plans/offline-sync.md`. Stop when finished."*
2.  **Test:**
    *   Run the unit/integration tests for that specific module.
3.  **Third-Person Review (Crucial):**
    *   Immediately after the code is written, force the AI to switch personas.
    *   The philosophy: **"I didn't write this code, but after this review it is my responsibility. It must meet my world-class standards."** This is not a rubber stamp—it is the moment you reap the benefits of pair programming. The original author has blind spots; the reviewer does not share them. If the code ships with a flaw, the reviewer owns that failure.
    *   *Prompt Example:* *"Now, act as an independent 3rd-person Senior Architect who didn't write this code. Review it for bugs, messy heuristics, and 'lazy code'. Check it against our predefined Clean Code skills. Be brutal."*
    *   This review can also be invoked independently at any time via `/3p-review`—not just within the build loop.
4.  **Proceed:**
    *   *Prompt Example:* *"Tests pass and 3rd-person review is clear. Proceed to Phase 2."*

#### Evolving Toward BDD/TDD

The Build Phase naturally lends itself to a test-first discipline. When plan phases include behavioral specifications or acceptance criteria, the implementation order should evolve toward:

1.  **Red:** Write the failing test first—encode the expected behavior before writing any implementation.
2.  **Green:** Write the minimum code to make the test pass. No more.
3.  **Refactor:** Clean up while keeping all tests green. This is where the Boy Scout Rule applies.

This BDD/TDD loop nests inside the existing phase loop: for each phase, you write tests first, implement to green, refactor, then proceed to the Third-Person Review. The combination of test-first discipline and independent review produces code with both high correctness and high quality.

*A dedicated BDD/TDD skill will be integrated into the build phase to enforce this discipline more rigorously.*

*Final Validation:** At the end of the complete build (all phases), ALL project tests must pass. No feature is "done" until the suite is green.

---

## 3. Task Selection Strategy: Bugs vs. Features

Not all work is created equal, and your available resources—tokens, time, mental energy—should dictate what you pick up next. This is a deliberate triage strategy, not procrastination.

### When Tokens Are Low: Pick Bugs

Bug fixes are typically small, well-scoped, and self-contained. They require minimal brainstorming and can often be resolved within a single conversation. When your token budget is running low or you only have a short window of availability, bugs are the highest-value work you can do. They improve the product without demanding the deep planning overhead of a new feature.

### When Tokens Are Plentiful: Work on Features and Plans

Feature development requires the full Brainstorm → Plan → Build cycle. It consumes significantly more tokens and demands your sustained attention as a reviewer. Save this work for sessions where you have the budget and the bandwidth.

### Let Plans Accumulate—That's a Feature, Not a Bug

Plans in `docs/plans/new/` are not a backlog to feel guilty about. They are *pre-invested design work* waiting for the right moment. You can brainstorm three plans in the morning, let them sit, and implement them in the afternoon—or next week. This decouples *thinking* from *doing* and lets you work on both in parallel, far more easily than a traditional workflow allows.

**A critical mindset shift:** With AI-assisted development, "later" does not mean months. It means minutes or hours. The time between "plan written" and "feature shipped" has collapsed. So accumulating plans is not deferring work—it is *staging* work for rapid, parallel execution.

---

## 4. Continuous Improvement: The Memory Loop

Even with strict planning, AI models drift. The system must adapt immediately to failures. This is the last and most vital step.

### The "No Surprises" Rule
Always enforce this constraint: **"NEVER modify code without explicit permission. Propose changes one file at a time."**

### Continuous Memory Updates
Whenever you find an incorrect behavior or a rule violation, **update the AI's memory immediately** with exact, preventative instructions.

*   **Example (Logging violation):** The AI uses `print()` instead of your project's custom logger.
    *   *Action:* Fix the code, then say: *"You violated our logging standard. Update your `ai-context.md` or memory: 'Rule: Always use `logger = get_logger(__name__)` and never use `print()`. This is non-negotiable.'"*
*   **Example (Refactoring drift):** The AI refactors a function and removes comments explaining a complex regex.
    *   *Action:* *"You deleted vital documentation. Restore it and update your memory: 'Do not remove business-logic comments during refactoring without asking first.'"*

### Refactoring Monoliths
Treat refactoring as a feature:
1. Ask the AI to analyze the monolith and propose domain boundaries.
2. Generate a phased refactoring plan.
3. Execute using the `Implement -> Test -> Review` loop for every single file extraction.
