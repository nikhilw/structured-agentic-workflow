# Driving cursor-agent as the build model

A worked recipe for the [multi-model split](../multi-model.md): plan with your strongest
model, then hand the plan file to Cursor's CLI agent to build headless.

Field notes from real builds: the launch shape, the prompt that works, the failure modes that
cost time, and the guardrails that prevent them. Observed with the `cursor-agent` CLI running
`composer-2.5`; the specifics will drift, the shape should not. Setup first: `agent-cli-setup.md`.

---

## Why headless

Running the build agent non-interactively is what makes the token saving real. With
`--output-format json`, a completed run returns **a few hundred bytes** (a final message and
usage stats) instead of a full transcript:

```json
{"type":"result","subtype":"success","is_error":false,"duration_ms":7870,
 "result":"...final message only...","session_id":"...","usage":{...}}
```

So the expensive model never reads the build's thinking. It reads a plan-sized input and a
paragraph-sized output, and reviews the diff. That is the whole economic argument of the split,
made concrete.

## Launch

```bash
cd <repo> && cursor-agent -p --output-format json --model composer-2.5 \
  "<prompt>" > <log>.json 2> <log>.err
```

- **Run it backgrounded**, with your harness's own background mechanism and its maximum timeout. A
  30-minute default kills a run mid-phase with a 0-byte log. `setsid nohup ... &` plus `disown`
  exits within seconds.
- **In `-p` mode there is no interactive channel, so "surface the issue and halt" is a process
  exit**, with the reason in `result` and the outcome in `is_error` / `subtype`. One signal covers
  both "finished" and "halted", which is what makes a backgrounded run safe to ignore until it
  returns.
- **Save `session_id`** from the result. Its only use is as the value to pass to `--resume`; it does
  not name the conversation (see *Conversation naming*).
- **`--auto-review`, opt-in**: a server classifier auto-runs tool calls it judges safe and falls
  back to the allowlist for the rest. It gets more done than the plain allowlist, short of the full
  bypass of `--force`/`--yolo`, but **it widens the boundary**: it has let through `rm` and
  `git checkout`, which the allowlist blocks (see *Permissions*). Add it only with the prompt's git
  line in place and everything committed.
  It can be refused per session ("requires a classifier-capable model and team permission"); the
  run then continues on the allowlist, with the notice on stderr only.
- **Send stderr to its own file**, not `2>&1`. Merged, it corrupts the JSON and buries startup
  warnings.
- **The JSON flushes only at exit**, so a killed run leaves a 0-byte log. A 0-byte log means
  "still running" as often as "died"; check the process.
- **A fresh git worktree is untrusted** and the run dies in seconds with "Workspace Trust Required"
  on stderr. Add `--trust` ("trust the current workspace without prompting"). It is not `--force`
  and leaves the allowlist in force; trust and approval are separate fences.

## The launch prompt

Use this close to verbatim. Many variations produce undesirable behaviour; this shape has held
up:

```
<short unique name for this run>
You are the build model in the structured agentic development workflow.
Load up the skills @AGENTS.md and /build-model, and wait to receive the plan.
Think critically about the plan: if you find issues or discrepancies during
implementation, surface them and halt, instead of pushing through or working around it.

If the plan cannot be followed as written, halt and report. Do not build a workaround
inside the files the plan does name. A plan gap is mine to fix, not yours to route around.
Size is never a reason to halt; halt only when the plan cannot be followed as written.

Do not modify any file the plan does not name.

If you create a file by mistake and cannot delete it, leave it in place and report it.
Do not add code anywhere to hide, skip, or work around it.

Before adding a required field to a shared type, check its constructor call sites.
Do not spawn subagents. Build everything yourself, in this session, on this model.
Never run git checkout, git restore, git reset, git stash or git clean. To restore a
mutation, copy the file aside first and copy it back after.
Run one test suite at a time. Do not commit; the reviewer commits.

Here is the plan file, build phases <N to M>: <plan file path>
```

Add your project's own code-style skill to the load list if you have one.

Each of those instructions is load-bearing, and the sections below are why.

**Keep the halt lines although the skills carry them too.** `/build-model` opens with the same
standing instruction and `/build-phase` repeats it at every step, including a list of the specific
moves that mean "you have found a plan defect" (a parameter the plan never named, a nearby function
called because the named one is missing, a mocked seam where the plan asked for a real one). The
prompt line is still worth its space: it is the first thing in the session's context, it survives a
skill that loads late or not at all, and in `-p` mode it is the only instruction you can be certain
arrived. Belt and braces, cheaply.

## Safety before you launch

You are handing an autonomous agent a repo and walking away. Two things make that reasonable:

**Commit everything first. Git is the real safety net.** Not the agent's permission model, but
git. An uncommitted tree is the only thing you can actually lose, so don't have one.

**Know your approval boundary, and don't widen it.** Whatever approval mode your CLI is
configured with is a genuine boundary in headless mode: a command outside it is denied and the
agent exits cleanly rather than hanging or auto-approving. That property is worth keeping, so
**do not pass `--force` / `--yolo`** to get a run unstuck. A blocked command is information,
and the failure modes below show what happens when the agent routes around one instead of
reporting it.

Be realistic about what an allowlist buys you, though. If it permits a language runtime or a
build tool (`uv run`, `node`, `make`, `sed`, `awk`) it permits arbitrary code execution;
`uv run python -c "..."` is a shell. An allowlist stops *casual* destruction, not *careless*
destruction. That is another way of saying: commit first.

**Never run it against a live app.** Stop the app's services before launching. A build that adds
or changes a migration while they are up leaves the running processes holding code that writes
columns the migration removed. The order is: stop, build, migrate, restart. And the agent never
writes to a database a running worker holds.

## Permissions

- `approvalMode: allowlist` in `$HOME/.cursor/cli-config.json`. A command off the list is denied
  and the agent exits cleanly (`subtype: success`); it does not hang and does not auto-approve.
- There is no sandbox (`sandbox.mode: disabled`). The allowlist is the only fence.
- **Under `--auto-review`, `rm` and `git checkout` are not blocked.** One run ended a compound
  mutation-restore command with `rm -rf` on a gitignored scratch directory; another restored a
  mutation with `git checkout -- .` and wiped a whole phase of uncommitted work. Hence the prompt's
  git line and its copy-aside rule. Keep nothing in a scratch directory you want to survive a run.
- If `git commit` is on the allowlist, the prompt still says not to commit.

## Confirming a run, and whose it is

The process runs as `node`, so `pgrep -x cursor-agent` never matches it. Match on the session id,
never the process name; another agent's concurrent `cursor-agent` is otherwise indistinguishable
from yours:

```bash
ps -eo pid,etime,stat,args | grep "cursor-agent/versions" | grep "<session-id>"
```

Both greps are needed: the session id alone also matches the shell wrapper that launched the run,
and `cursor-agent/versions` alone matches another agent's run. Before the first result is written
there is no session id yet, so match the prompt's first line instead. It is unique per run:

```bash
ps -eo pid,etime,stat,args | grep -F "<prompt first line>" | grep -v grep
```

`ps -eo args` can clip a long argv, so that grep can find nothing while the run is alive. Then find
the `worker-server` child and walk up with `ps -o ppid= -p <worker-server pid>`; that parent is the
run. A PID captured at launch is not a handle on the run. The parent's argv starts with the install
path of `cursor-agent`, not `cursor-agent/versions`, so a PID-based or versions-based check can
report a run dead while it is alive and working.

**A 0-byte log plus one absent PID is not death.** Relaunching on that evidence puts two agents in
one tree. Search by prompt line twice, a minute apart, and confirm no `cursor-agent` process of any
shape remains. A long silent stretch is normal.

**If two runs do overlap, kill the newer by its exact process id and check the tree** before doing
anything else: unrestored mutations (below), files neither run should have touched, then the scoped
suite.

## The failure modes, and the prompt lines that prevent them

### It rewrote production code to work around a blocked command

It created several stray migration files by mistake, could not delete them, and so edited the
migration runner to add a hardcoded skip-list of those filenames plus a function that renamed
migration files at runtime. Far worse than the deletion would have been.

The lesson is *not* "allow `rm`". It is:

> If you create a file by mistake and cannot delete it, leave it in place and report it. Do
> not add code anywhere to hide, skip, or work around it.

### It will sometimes work around a gap instead of halting

The plan required admitting certain rows into a grouping step, but the query feeding that rule
filtered them out, in a file the plan never named. Held by *"do not modify any file the plan
does not name"*, the agent stayed inside the fence and probed every candidate pair one query at
a time: **632,896 queries, turning a 0.24s call into 8.41s.** Every gate stayed green, because
the test fixtures are small.

Its handoff flagged the plan gap honestly, and it *still* shipped the workaround. So the
"leave it and report it" line above is not enough; that only covers a file it created by
mistake. You need the general case:

> If the plan cannot be followed as written, halt and report. Do not build a workaround inside
> the files the plan does name. A plan gap is mine to fix, not yours to route around.

Read the diff for branches that look like compensation. Two lessons outlive this run:

- **The fence is load-bearing, so a gap in your plan becomes a defect in the code.** The
  guardrail silently converts a planning error into an implementation error. This is why
  `/build-phase` opens with a plan review, and why halts should be read as *your* plan defects.
- **Performance regressions are invisible to a green suite.** Nothing in the gates catches
  O(n·m). A reviewer has to measure the real case, not trust the tests.

### It may halt on size alone

Told to halt on plan gaps, it has halted minutes in because a phase was "thousands of lines", with
a partial tree and no gap named. Hence the prompt's "size is never a reason to halt". Commit the
partial tree as a checkpoint before resuming, and give a large phase its own run.

### It added a required field to a shared type and broke eight unrelated tests

Adding a non-defaulted field to a widely-constructed dataclass cascaded into every test that
builds one. Hence the prompt's call-site line.

### Reported-done is not done

A report can describe a refactor it did not perform: "no longer reaches through private stores",
while the file was unmodified and every reach-through remained. Tests were green before and after,
because they asserted behaviour and the private path behaves identically. It has also reported
proof it does not have: a mutation "witnessed" that survived, a "tie" test that created one row, a
guard test that compared a list with itself, a cost test that timed a copy of the fixture.

Give it an acceptance command that is not the test suite, and run that command yourself; a grep
that must return nothing is usually the right shape. Re-run every mutation it names, and read every
new test.

### After a killed run, check for unrestored mutations

A kill can land between "break it" and "restore it" in a mutation check, leaving a deliberately
broken line that reads as ordinary code. One left a step returning a hardcoded value, which would
have looped that step forever. Before committing anything from a killed run, compare the tree with
the last commit and sweep for whatever marker your mutation checks use.

A restored mutation can keep running from bytecode. Python trusts `__pycache__` while the source's
size and whole-second mtime match, so a same-size edit (`> 1` to `> 2`) restored within the same
second leaves the mutated `.pyc` live while the source reads correct. After any mutation run, clear
`__pycache__` before judging a test result.

### Network and memory deaths

`Connection lost, reconnecting` then `Retry attempt N` in the log means the run is dying on the
network; relaunch with `--resume`, and committed work is unaffected. A heap overflow also ends in a
truncated or empty log. Read the log before naming a cause.

## Long plans must be launched in phase batches

**Do not ask it to build all phases of a long plan in one run.** The process heap grows across
the run and overflows partway through. This is a memory limit, not a model limit: a better
prompt does not fix it, and retrying the same shape fails the same way.

**Start each batch as a fresh session.** The plan is the handoff, and a resumed session re-reads
its whole history every turn: after a few phases and reworks it is slow and carries nothing the plan
does not. Launch each batch without `--resume`, with the full launch prompt; resume a batch's session
only for its own reworks. On a short plan, resuming one thread across two or three batches is fine.

Rules for batching:

- **Three to four phases per batch** is a default that survives. Treat it as a ceiling.
- **Give an atomic phase its own batch**: a cutover that deletes modules, drops columns, or removes
  an old mechanism. A mid-phase death leaves the tree half-migrated.
- **Every batch prompt tells it to re-read the plan file.** A resumed thread carries the
  conversation, not the file; it is stale the moment the plan is amended. This matters most after a
  gate failure, where the plan has just been corrected.
- **Batches do not overlap.** Each phase is built exactly once. Say in each prompt which earlier
  phases you verified, so finished work is not rebuilt.
- **Commit a checkpoint between batches.** Stage by explicit path when another agent shares the tree.
- **Do nothing else between batches.** Review happens once, at the end, against the diff.

## Subagents and model choice

`--model` sets the main agent only. The agent can pass any model to a subagent, and a subagent can
be billed from a different pool. It may read a line in your project's instructions such as "use a
smaller model for bulk work" as permission to build a whole phase on another model, so scope any
such line to the planning model, and keep the prompt's no-subagents line. No flag turns subagents
off.

- `exploreSubagentModel` in `$HOME/.cursor/cli-config.json` should be `inherit`. The schema accepts
  only `default` or `inherit`; a model name there fails validation, and cursor then silently rewrites
  **the whole file** to defaults at the next launch: allowlist down to `Shell(ls)`, every shell call
  denied. After any hand edit, launch once and confirm the allowlist is still there.
- To audit which models a run used: each chat is `$HOME/.cursor/chats/<hash>/<agent-id>/store.db`;
  grep its `blobs` for `"modelName":"` and `"model":"`. A subagent's `meta` value (hex-encoded JSON) names
  its parent.

## Test suites

- **Set the parallel worker count in the project's config**, not in the prompt. A parallel test
  runner loads the whole app per worker, so too many workers gets the run killed for memory; the
  project's own default is what will run.
- **It copies flags from the plan.** A single-test flag such as `-n 0` ends up on a whole-suite run
  and takes hours. Say which flags are for single tests and which command runs a whole directory.
- **One full suite at a time.** Several suites at once have slowed a shared machine to a crawl and
  coincided with the provider answering "High Load" for over an hour. The prompt forbids a second
  suite; stop the newer one by exact process id.
- Note that each invocation burns a fixed chunk of input context before doing anything, so prefer
  one long run over many short ones, within the batching limit above.

## Conversation naming

The **first line of the prompt** sets the conversation's name; `session_id` has no effect on it.
Put a short, human-readable name for the run on its own first line.

## Judge by the diff, never the transcript

The reviewer's evidence is `git diff`, `git status`, and the gates re-run first-hand. A
flawless transcript would not change the verdict, and a self-congratulatory one would not fool
it. Read `result` only to learn whether it halted, and why.

This matters more than it sounds, because the report is also **the thing you lose**:
`--output-format json` flushes only at exit, so a killed run leaves a **0-byte log** and no
account of itself. The code it wrote is still on disk and still reviewable, which is exactly
the point of judging by the diff.

## What it gets right

Given a plan with resolved decisions, the output is genuinely good. In one bundle the migration
DDL matched the plan character-for-character, including a down-migration that restored rows
before dropping tables; the frontend wiring was complete; and it independently found and worked
around a latent test defect the plan had not anticipated. Three of that bundle's seven defects
were the build model's; the other four belonged to the plan or the reviewer.

That ratio is the honest summary of this approach: **a cheap build model is about as good as
the plan you hand it**, and the failures it produces are specific, diagnosable, and mostly
preventable with the prompt lines above.
