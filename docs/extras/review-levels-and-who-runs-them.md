# Review levels, and which model runs each
*From long multi-phase builds that split planning, building and reviewing across models. Each level
catches what the one before it cannot. Costs are rough orders of magnitude from 2026, to compare the
levels, not quotes.*

## The levels

| Level | When | Who runs it | What it catches | Cost |
|---|---|---|---|---|
| 1. The plan's own passes | While writing the plan | The planner, `/write-plan`'s ten passes, with a caller trace from the type checker or graph | Design gaps, unnamed callers, plans that cannot build in order | Planner's time |
| 2. Outside plan review | After level 1, per batch of phases | An outside model, read-only: a fresh subagent on another model, or another CLI | What the planner assumes: missed callers, wrong line ranges, rules that do not hold | About a dollar a round, or none on another provider's quota |
| 3. Pre-build review of a phase group | Just before that group is built | An outside model; a small model when it fails twice on one brief | Drift between the plan and code that moved since; findings from earlier phases not yet applied | Cents to a dollar |
| 4. Re-review of closed phases | After rules change mid-plan | An outside model, against the new rules | Closed phases that break a rule added later | As level 2 |
| 5. The driver's check of every build run | After each build-model run | Whoever drives the build: the planner, or a phase driver | Hollow tests, claims the build model did not do, files it should not touch | Driver's time |
| 6. Mutation check | After each run, and at the close | The driver, never the build model's word | Tests that pass with the code broken | Minutes per mutation |
| 7. Deep post-build review | Once per `/3p-review`, at its first round (a long build reviewed phase by phase runs one review per phase) | A capable model with none of the build's context (`/3p-review`'s deep read) | Behaviour changes from the main branch, missed rules, design problems in the built code | One to several dollars, growing with the diff |
| 8. Fix check | After each review round's fixes | The smallest model tier, fresh, given only the fixes and the findings (`/3p-review`'s fix check) | Findings not really fixed; new breakage in the rework | Cents |
| 9. Close gates | End of phase | The planner itself: the full suite, type check, lint, every named mutation | Anything the reviews and the driver did not run | The suite's wall time |

Levels 7 and 8 are built into `/3p-review` when the harness can start a fresh subagent on a named
model. The rest are what a long build adds around the workflow's gates.

## Rules that hold at every level

- **Every finding is verified first-party before acting**, against the main branch for "as today",
  and against the plan's state after the earlier phases for a later phase. Reject only on running
  evidence, never on a grep that found nothing.
- **After every review, apply each finding to every later phase it reaches** before the next review
  starts (`/write-plan`, *When a build halt comes back*, step 3).
- **Reviewers read committed code** whenever a build or mutations are running in the tree.
- **Each brief lists what is already known or ruled**, so the reviewer spends on new problems.

## Who not to use

- **Not a large model for fix checks.** The smallest tier does them for cents and finds real gaps.
- **Not the model that wrote the code to certify it.** A build model's report is a claim; the code
  is signed off by a model that did not write it.
- **Not the planner's own expensive model for everything.** Keep it for planning, verifying and
  closing, and spend the reviews on cheaper or other-provider models where they find as much.

## Where each one's mechanics live

- Claude CLI reviewer (deep read and fix check): `driving-claude-cli-as-reviewer.md`
- agy reviewer: `driving-agy-as-plan-and-code-reviewer.md`
- A Claude CLI phase driver: `driving-claude-cli-as-phase-driver.md`
- Build models: `driving-cursor-as-build-model.md`, `driving-codex-as-build-model.md`,
  `driving-agy-as-build-model.md`
