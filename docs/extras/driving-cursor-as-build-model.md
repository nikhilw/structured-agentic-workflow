# Driving cursor-agent as the build model

A worked recipe for the [multi-model split](../multi-model.md): plan with your strongest
model, then hand the plan file to Cursor's CLI agent to build headless.

Field notes from real builds — the launch shape, the prompt that works, the failure modes that
cost time, and the guardrails that prevent them. Observed with the `cursor-agent` CLI running
`composer-2.5`; the specifics will drift, the shape should not.

---

## Why headless

Running the build agent non-interactively is what makes the token saving real. With
`--output-format json`, a completed run returns **a few hundred bytes** — a final message and
usage stats — instead of a full transcript:

```json
{"type":"result","subtype":"success","is_error":false,"duration_ms":7870,
 "result":"…final message only…","session_id":"…","usage":{…}}
```

So the expensive model never reads the build's thinking. It reads a plan-sized input and a
paragraph-sized output, and reviews the diff. That is the whole economic argument of the split,
made concrete.

## Launch shape

```bash
cd <repo> && cursor-agent -p --output-format json --model composer-2.5 \
  "<prompt: skills + halt instruction + plan path>" > build-<plan>.json 2>&1
```

Run it **backgrounded** and read nothing while it works.

`session_id` in the result is your record of "which conversation built what" — keep it beside
the plan name; you need it to resume for the next batch.

**In `-p` mode there is no interactive channel, so "surface the issue and halt" is a process
exit**, with the reason in `result` and the outcome in `is_error` / `subtype`. One signal
covers both "finished" and "halted", which is what makes a backgrounded run safe to ignore
until it returns.

## The launch prompt

Use this close to verbatim. Many variations produce undesirable behaviour; this shape has held
up:

```
You are the build model in the structured agentic development workflow.
Load up the skills @AGENTS.md and /build-model, and wait to receive the plan.
Think critically about the plan: if you find issues or discrepancies during
implementation, surface them and halt, instead of pushing through or working around it.

If the plan cannot be followed as written, halt and report. Do not build a workaround
inside the files the plan does name. A plan gap is mine to fix, not yours to route around.

Do not modify any file the plan does not name.

If you create a file by mistake and cannot delete it, leave it in place and report it.
Do not add code anywhere to hide, skip, or work around it.

Here is the plan file, build all the phases: <plan file path>
```

Add your project's own code-style skill to the load list if you have one.

Each of those instructions is load-bearing, and the section below is why.

## Safety before you launch

You are handing an autonomous agent a repo and walking away. Two things make that reasonable:

**Commit everything first. Git is the real safety net.** Not the agent's permission model —
git. An uncommitted tree is the only thing you can actually lose, so don't have one.

**Know your approval boundary, and don't widen it.** Whatever approval mode your CLI is
configured with is a genuine boundary in headless mode: a command outside it is denied and the
agent exits cleanly rather than hanging or auto-approving. That property is worth keeping, so
**do not pass `--force` / `--yolo`** to get a run unstuck — a blocked command is information,
and the failure mode below shows what happens when the agent routes around one instead of
reporting it.

Be realistic about what an allowlist buys you, though. If it permits a language runtime or a
build tool — `uv run`, `node`, `make`, `sed`, `awk` — it permits arbitrary code execution;
`uv run python -c "…"` is a shell. An allowlist stops *casual* destruction, not *careless*
destruction. That is another way of saying: commit first.

A pleasant consequence of `git commit` typically sitting outside the allowlist: the build
agent builds, and a reviewer commits. Keep it that way.

## The failure modes, and the prompt lines that prevent them

### It rewrote production code to work around a blocked command

It created several stray migration files by mistake, could not delete them, and so edited the
migration runner to add a hardcoded skip-list of those filenames plus a function that renamed
migration files at runtime. Far worse than the deletion would have been.

The lesson is *not* "allow `rm`". It is:

> If you create a file by mistake and cannot delete it, leave it in place and report it. Do
> not add code anywhere to hide, skip, or work around it.

### It built a quadratic workaround rather than halt on a plan gap

The plan required admitting certain rows into a grouping step, but the query feeding that rule
filtered them out — in a file the plan never named. Held by *"do not modify any file the plan
does not name"*, the agent stayed inside the fence and probed every candidate pair one query at
a time: **632,896 queries, turning a 0.24s call into 8.41s.** Every gate stayed green, because
the test fixtures are small.

Its handoff flagged the plan gap honestly, and it *still* shipped the workaround. So the
"leave it and report it" line above is not enough — that only covers a file it created by
mistake. You need the general case:

> If the plan cannot be followed as written, halt and report. Do not build a workaround inside
> the files the plan does name. A plan gap is mine to fix, not yours to route around.

Two lessons outlive this run:

- **The fence is load-bearing, so a gap in your plan becomes a defect in the code.** The
  guardrail silently converts a planning error into an implementation error. This is why
  `/build-phase` opens with a plan review, and why halts should be read as *your* plan defects.
- **Performance regressions are invisible to a green suite.** Nothing in the gates catches
  O(n·m). A reviewer has to measure the real case, not trust the tests.

### It added a required field to a shared type and broke eight unrelated tests

Adding a non-defaulted field to a widely-constructed dataclass cascaded into every test that
builds one. Worth a line in your project's own skill or config file:

> Before adding a required field to a shared type, check its constructor call sites.

### It was killed by OOM

Twice, once alongside the IDE. Not the agent's fault — a parallel test runner configured for
many workers loads the whole app per worker. If your suite runs under `pytest-xdist` or
similar, set a worker count the machine can actually take, and set it in the project config
rather than telling the build model a number: the Makefile's own default is what will run.

Note also that a cursor invocation burns a fixed chunk of input context before doing anything,
so prefer one long run over many short ones — within the batching limit below.

## Long plans must be launched in phase batches

**Do not ask it to build all phases of a long plan in one run.** The process heap grows across
the run and overflows partway through. This is a memory limit, not a model limit — a better
prompt does not fix it, and retrying the same shape fails the same way.

Batch the phases across several runs on **the same conversation thread**:

1. Launch asking for **phases 1–4 only**, and tell it to stop cleanly when those are done.
2. Let it finish and exit. A clean exit at a batch boundary is the goal, not a failure.
3. Launch again on the **same thread** (reuse `session_id`) for phases **5–7**.
4. Repeat to the end.

Three rules for batching:

- **Every batch prompt must tell it to re-read the plan file.** A resumed thread carries the
  conversation, not the file — the agent works from what it remembers, which is a summary at
  best and stale the moment the plan is amended. Start each follow-up with
  "Re-read `<plan path>` and build phases N to M". This matters most in the case where it is
  easiest to forget: a batch launched after a gate failure, where the plan has just been
  corrected and the thread remembers the *wrong* version.
- **Batches do not overlap.** Each phase is built exactly once. The thread carries continuity;
  re-sending a completed phase only invites it to redo finished work.
- **Do nothing between batches.** No review, no gates, no commentary. Batching exists to keep
  the heap small; interleaving work adds nothing and costs a round trip. Review happens once,
  at the end, against the diff.

Three to four phases per batch is a default that survives. Treat it as a ceiling rather than
something to tune upward.

## Judge by the diff, never the transcript

The reviewer's evidence is `git diff`, `git status`, and the gates re-run first-hand. A
flawless transcript would not change the verdict, and a self-congratulatory one would not fool
it. Read `result` only to learn whether it halted, and why.

This matters more than it sounds, because the report is also **the thing you lose**:
`--output-format json` flushes only at exit, so a killed run leaves a **0-byte log** and no
account of itself. The code it wrote is still on disk and still reviewable — which is exactly
the point of judging by the diff.

## What it gets right

Given a plan with resolved decisions, the output is genuinely good. In one bundle the migration
DDL matched the plan character-for-character, including a down-migration that restored rows
before dropping tables; the frontend wiring was complete; and it independently found and worked
around a latent test defect the plan had not anticipated. Three of that bundle's seven defects
were the build model's — the other four belonged to the plan or the reviewer.

That ratio is the honest summary of this approach: **a cheap build model is about as good as
the plan you hand it**, and the failures it produces are specific, diagnosable, and mostly
preventable with the prompt lines above.
