# Driving agy as the plan reviewer and code reviewer
*Prompts from the owner, 2026-09-26. Launch mechanics: [driving-agy-as-build-model.md](driving-agy-as-build-model.md).
Setup: [agent-cli-setup.md](agent-cli-setup.md).
The generic form of these prompts, for any outside model, is the outside-review brief in
`skills/review-lenses/SKILL.md`, which every gate offers.*

agy reviews twice per plan, in one conversation: the plan review before the build model is launched
(after our own plan reviews), and the code review after the build and its review, before
`/verify-completion`. Its findings are input to weigh, not verdicts: confirm each one against the code
before acting on it.

## Launch

Reviews are read-only, so launch **without** `--mode accept-edits`. A file write is then denied,
which ends the run (see "A denied command ends the run" in the build file). Run the same `jq` check
after each run.

```bash
cd <repo> && agy --output-format json -p "<plan review prompt>" > <log>.json 2> <log>.err
```

Save `conversation_id`. The code review resumes the same conversation, so it keeps the plan review's
context:

```bash
cd <repo> && agy --conversation <conversation_id> --output-format json -p "<code review prompt>" > <log>.json 2> <log>.err
```

Tracing uses `graphify`, `uv run pyright` and `make typecheck`, all on the allowlist.

## Plan review prompt

```
<short unique name, e.g. r1a-1 plan review>
This is a review-only task. I need you to review the given plan and its decision document. I am
aligned with the decisions, but I don't know if the decision doc and the plan are fully aligned, and
if the plan is correct on all fronts: logic, code references, impact, implementation logic, and
whether it delivers what we intended. And if the delivery and plan are aligned with the business
requirements and business logic. Also make sure we are precisely carving out what we don't need; we
must use a scalpel, not a butcher's knife.
Tell me only what is broken, or potentially broken, or doubtful. Tell me if there is a better
approach than what is suggested in the plan. I don't need details on what is okay.
Here is the plan: @<plan file path>
```

## Code review prompt

Sent into the same conversation as the plan review.

```
<short unique name, e.g. r1a-1 code review>
Your job is to review. Compare the code now with the plan. Trace it with graphify, mypy and pyright,
fully and properly, forward and backward, to make sure we have covered it all and considered all the
points: impacted code, all callers, all calls, all call sites and so on, and that the plan is sound
on this code.
Tell me only what is broken, or potentially broken, or doubtful. Tell me if there is a better
approach than what is suggested in the plan. I don't need details on what is okay.
```
