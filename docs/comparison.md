# How it compares

Most agent workflows stop at "does the code match the spec?". This one practises
**intent-audited development**: your intent is the baseline, and the work is checked against it
before it counts as done. Does what shipped match what you meant, and can the agent prove it? Here
is how that lands next to the best-known alternatives.

*Compared from each project's public documentation as of September 2026. Tools move fast; if a
cell is out of date, open an issue and it gets fixed.*

## What you only get here

- **Your intent is the audited baseline.** The decision document records what you chose, what you
  ruled out and what your users will see. It freezes when the plan is approved, only you can amend
  it, and before anything is called done the plan is audited against it, and the code against the
  plan. Others check code against a spec or a plan; none we found checks the plan against your
  intent.
- **The builder halts instead of improvising.** A cheaper model builds from the plan, and when the
  plan has a gap it stops and reports. The planning model amends the plan and logs every change, so
  drift stays measurable instead of hiding in a dozen reasonable corrections.
- **Seven review lenses, one question at a time, from first idea to finished code.** Impact,
  removal, logic, behaviour, business sense, proof and coherence, each run on its own, on the
  approaches, the plan and the built code.
- **A change reads as an event model.** When work changes what a system records, shows or
  automates, the brainstorm draws it as slices: what is new, changed or removed, and each case with
  today's outcome beside the decided one. A project's existing event model is read in its own
  terms, from EM-Spec JSON, `.em.hcl` or Mermaid.
- **A rule change is a table, not a paragraph.** Every case the rule can meet, today's outcome beside
  each proposal's, with every changed row marked as the fix or as collateral nobody asked for.
- **Nothing finishes smaller than it started.** Every removal names what replaces it and the test
  that proves its job is still done.

## Side by side

✅ does it  ·  ◐ partly  ·  **–** not found in public docs

| | **This workflow** | [Spec Kit](https://github.com/github/spec-kit) | [Kiro](https://kiro.dev) | [BMAD](https://github.com/bmad-code-org/BMAD-METHOD) | [Superpowers](https://github.com/obra/superpowers) | [gstack](https://github.com/garrytan/gstack) | [Compound Eng.](https://github.com/everyinc/compound-engineering-plugin) | [Traycer](https://traycer.ai/) |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Intent recorded before planning | ✅ | ✅ spec | ✅ requirements | ✅ PRD | ✅ design | ◐ plan reviews | ✅ requirements | ✅ specs |
| Intent frozen at approval, owner-only amendments | ✅ | – | – | – | – | – | – | – |
| Code checked against the plan or spec | ✅ | ✅ converge | ◐ reported | ◐ | ✅ per task | ◐ | ✅ | ✅ |
| Plan audited against the original intent before "done" | ✅ | ◐ artifact analysis | – | – | – | – | – | – |
| Builder halts on plan gaps; every plan change logged | ✅ | – | – | – | – | – | – | – |
| Plan built by another model or vendor, with a return report | ✅ | – | – | ◐ | – | ◐ second opinion | ◐ cross-model work | ✅ |
| Review by another vendor's model | ✅ ready-made brief | – | – | – | – | ✅ built in | – | – |
| Separate single-question review passes, idea to code | ✅ | – | – | ◐ personas | ◐ two-stage | ◐ role reviews | ◐ multi-agent | – |
| Business-sense review, owner's own decisions included | ✅ | – | – | ◐ PM persona | – | ✅ CEO review | – | – |
| Rule changes tabled case by case, today against proposed | ✅ | ◐ scenarios | ◐ EARS criteria | – | – | – | – | – |
| Change shown as an event model; reads EM-Spec, `.em.hcl`, Mermaid | ✅ | – | – | – | – | – | – | – |
| Every removal audited, replacement named | ✅ | – | – | – | – | – | – | – |
| Scoped test runs, full suite only where it counts | ✅ | – | – | – | – | – | – | – |
| Test-first enforced | ✅ | ◐ via constitution | – | – | ✅ | ◐ | – | – |
| QA in a real browser | ◐ when drivable | – | – | – | – | ✅ | – | – |
| Learnings captured for the next cycle | – | – | – | ◐ | – | – | ✅ | – |
| Ship and deploy automation | – | – | – | – | ◐ merge or PR | ✅ | – | – |
| Works across agents and tools | ✅ | ✅ 30+ | – IDE | ✅ | ✅ | ✅ | ✅ 14 hosts | ✅ |
| Open source | ✅ MIT | ✅ MIT | – | ✅ MIT | ✅ MIT | ✅ | ✅ MIT | – |

## Where the others lead

Being straight about this is part of the pitch.

- **Traycer** runs the same supervise, hand off, verify loop as a polished product, with one-click
  handoff to Claude Code, Codex, Cursor and OpenCode. If you want that loop with a UI and no setup,
  it is ahead.
- **gstack** tests in a real browser and writes regression tests, reviews plans as a CEO and as a
  designer, and ships and deploys. None of that is automated here.
- **Compound Engineering** writes down what each cycle learned so the next plan starts smarter.
  That loop does not exist here yet.
- **Spec Kit** is the de facto standard, with the widest agent support and a large community.
- **Superpowers** is the reference for test-first discipline, and this workflow builds on its TDD
  skill rather than competing with it.

## Which to pick

- **Pick this workflow** when what shipped has to be provably what you meant, when you want
  frontier reasoning on design and cheap models on typing across vendors, and when a silent
  workaround costs more than a halt.
- **Pick Spec Kit or Kiro** for a lighter spec, plan, tasks loop with broad adoption.
- **Pick gstack** for product review, browser QA and shipping in one kit.
- **Pick Traycer** for the supervise-and-verify loop as a managed product.
- **Pick Compound Engineering** if learning across cycles matters most.

They are not exclusive. This workflow composes with Superpowers today, and borrows freely where
someone else does a thing better.
