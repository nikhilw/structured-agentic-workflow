# Driving cursor-agent as the build model

Hand a plan file to Cursor's CLI agent to build headless. Setup first: `agent-cli-setup.md`.

With `--output-format json`, a completed run returns a few hundred bytes (a final message and usage
stats) instead of a transcript, so the planning model reads a plan-sized input and a paragraph-sized
output, then reviews the diff.

## Launch

```bash
cd <repo> && cursor-agent -p --output-format json --model <model> \
  "<prompt>" > <log>.json 2> <log>.err
```

- **Run it with your harness's background option and its maximum timeout.** A short default kills a
  run mid-phase with a 0-byte log. `setsid nohup ... &` plus `disown` exits within seconds.
- **"Surface the issue and halt" is a process exit in `-p` mode**, with the reason in `result` and the
  outcome in `is_error` / `subtype`. One signal covers both finished and halted.
- **Save `session_id`** for `--resume`. It does not name the conversation; the prompt's first line does.
- **Send stderr to its own file.** Merged, it corrupts the JSON and buries startup warnings.
- **The JSON is written only at exit.** A 0-byte log means "still running" as often as "died"; check
  the process. A killed run leaves no account of itself, only the code on disk.
- **A fresh git worktree is untrusted**, and the run dies in seconds with "Workspace Trust Required".
  Add `--trust`. It leaves the allowlist in force.
- **`--auto-review` is opt-in and widens the boundary.** A server classifier auto-runs what it judges
  safe, and it has let through `rm` and `git checkout`. Add it only with the prompt's git line in place
  and everything committed. It can be refused per session; the run then continues on the allowlist,
  with the notice on stderr only.

## The launch prompt

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

Add your code-style skill to the load list if you have one. Keep the halt lines although the skills
carry them too: the prompt is the only instruction you can be certain arrived.

## Safety before you launch

- **Commit everything first.** Git is the real safety net; an uncommitted tree is the only thing you
  can lose.
- **Do not pass `--force` / `--yolo`** to get a run unstuck. A blocked command is information.
- **An allowlist that permits a language runtime or build tool permits arbitrary code** (`node`, `make`,
  `sed`, `awk`, a runner's `python -c`). It stops casual destruction, not careless destruction.
- **Never run it against a live app.** A build that changes a migration while services are up leaves
  them holding code that writes columns the migration removed. Stop, build, migrate, restart.

## Permissions

- `approvalMode: allowlist` in `$HOME/.cursor/cli-config.json`. A command off the list is denied and
  the agent exits cleanly (`subtype: success`); it does not hang and does not auto-approve.
- There is no sandbox (`sandbox.mode: disabled`). The allowlist is the only fence.
- **Under `--auto-review`, `rm` and `git checkout` are not blocked.** Keep nothing in a scratch directory
  you want to survive a run.
- If `git commit` is on the allowlist, the prompt still says not to commit.

## Confirming a run, and whose it is

The process runs as `node`, so `pgrep -x cursor-agent` never matches it. Match on the session id; both
greps are needed, because the id alone also matches the launching shell and the path alone matches
another agent's run:

```bash
ps -eo pid,etime,stat,args | grep "cursor-agent/versions" | grep "<session-id>"
```

Before the first result there is no session id, so match the prompt's first line:

```bash
ps -eo pid,etime,stat,args | grep -F "<prompt first line>" | grep -v grep
```

`ps` can clip a long argv, so this can find nothing while the run is alive. Then find the
`worker-server` child and walk up with `ps -o ppid= -p <pid>`. A PID captured at launch is not a handle
on the run.

**A 0-byte log plus one absent PID is not death.** Relaunching on that puts two agents in one tree.
Search twice, a minute apart, and confirm no `cursor-agent` process of any shape remains. If two runs
do overlap, kill the newer by its exact process id and check the tree before anything else.

## What goes wrong, and what prevents it

### It rewrites production code to work around a blocked command

Told it cannot delete a stray file, it can edit real code to hide or skip it. The fix is the prompt's
"leave it in place and report it" line, not allowing `rm`.

### It will sometimes work around a gap instead of halting

Fenced to the plan's files, it can compensate inside them, for example with one query per pair where
the feeding query should have changed, and every gate stays green on small fixtures. It may flag the
gap and still ship the workaround. Hence the prompt's general "do not build a workaround" line. Read
the diff for branches that look like compensation, and measure the real case, since a green suite does
not show a slowdown.

### It may halt on size alone

Hence "size is never a reason to halt". Commit the partial tree as a checkpoint before resuming, and
give a large phase its own run.

### Reported-done is not done

A report can describe a refactor it did not perform, or proof it does not have: a mutation "witnessed"
that survived, a tie test with one row, a guard test comparing a list with itself. Give it an acceptance
command that is not the test suite, and run that yourself; a search that must return nothing is usually
the right shape. Re-run every mutation it names, once, and read every new test.

### After a killed run, check for unrestored mutations

A kill can land between "break it" and "restore it", leaving a broken line that reads as ordinary code.
Before committing anything from a killed run, compare the tree with the last commit and sweep for your
mutation marker.

A restored mutation can keep running from bytecode. Python trusts `__pycache__` while the source's size
and whole-second mtime match, so clear it after any mutation run before judging a test result.

### Network and memory deaths

`Connection lost, reconnecting` then `Retry attempt N` means the run is dying on the network; relaunch
with `--resume`. A heap overflow also ends in a truncated or empty log. Read the log before naming a
cause.

## Long plans must be launched in phase batches

The process heap grows across a run and overflows partway through a long plan. A better prompt does not
fix that.

- **Three to four phases per batch**, as a ceiling.
- **Each batch is a fresh session.** The plan is the handoff, and a resumed session re-reads its whole
  history every turn. Resume a batch's session only for its own reworks. On a short plan, resuming across
  two or three batches is fine.
- **An atomic phase gets its own batch**: a cutover that deletes modules or drops columns.
- **Every batch prompt tells it to re-read the plan file**, because a resumed thread carries the
  conversation, not the file.
- **Batches do not overlap.** Say which earlier phases you verified, so finished work is not rebuilt.
- **Commit a checkpoint between batches**, by explicit path when another agent shares the tree.

## Subagents and model choice

`--model` sets the main agent only. The agent can pass any model to a subagent, which can bill a
different pool, and no flag turns subagents off. So keep the prompt's no-subagents line, and scope any
"use a smaller model for bulk work" line in your project's instructions to the planning model.

- `exploreSubagentModel` in `$HOME/.cursor/cli-config.json` should be `inherit`. It accepts only `default`
  or `inherit`; a model name fails validation, and cursor then silently rewrites **the whole file** to
  defaults at the next launch, allowlist included. After any hand edit, launch once and confirm the
  allowlist is still there.
- To audit which models a run used: each chat is `$HOME/.cursor/chats/<hash>/<agent-id>/store.db`; search
  its `blobs` for `"modelName":"` and `"model":"`.

## Test suites

- **Set the parallel worker count in the project's config**, not the prompt. Too many workers gets the
  run killed for memory.
- **It copies flags from the plan.** A single-test flag on a whole-suite run can take hours. Say which
  flags are for single tests.
- **One full suite at a time.** Stop a second one by exact process id.

## Judging the result

Your evidence is `git diff`, `git status`, and the gates re-run first-hand. Read `result` only to learn
whether it halted, and why. A cheap build model is about as good as the plan you hand it.
