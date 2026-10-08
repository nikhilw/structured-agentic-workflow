# Driving agy (Antigravity CLI) as the build model
*Tested with agy 1.2.11. Setup first: `agent-cli-setup.md`.*

These sections of `driving-cursor-as-build-model.md` apply to agy unchanged: *Safety before you launch* (never run it against
a live app), *After a killed run, check for unrestored mutations*, *Reported-done is not done*, *It
will sometimes work around a gap instead of halting*, *Long plans must be launched in phase
batches*, *Test suites*. This file holds only what differs.

## Launch

```bash
cd <repo> && agy --mode accept-edits --output-format json -p "<prompt>" > <log>.json 2> <log>.err
```

- `-p` takes the prompt as its own value. Put every flag before `-p` and the prompt directly after
  it; `agy -p --output-format json "<prompt>"` exits 2 with "-p took --output-format as its prompt".
- `--mode accept-edits` lets it write files. Without it every file write is denied.
- `--model` picks the model; `agy models` lists them. Without it, agy uses its default.
- Never `--dangerously-skip-permissions`; it approves every tool. The allowlist is the fence, as
  with cursor, and there is no sandbox, so commit everything before launching.
- The result is one JSON object:
  `{"conversation_id":"...","status":"SUCCESS","response":"...","duration_seconds":...,"num_turns":...,"usage":{...}}`,
  plus `denied_actions` when a tool was refused.
- Exit codes: 0 on success and on a denial (see below), 2 on a usage error, 3 on a model or agent
  failure, with an `AGY_ERROR: {...}` line on stderr.
- A workspace missing from `trustedWorkspaces` still runs headless; there is no trust prompt to die
  on, unlike cursor.

## A denied command ends the run and still reports success

A tool call off the allowlist, or a file write without `--mode accept-edits`, is denied, and the run
stops right there. The steps after it never run. The result still says `"status":"SUCCESS"`, exit
0, with an empty `response` and `"denied_actions":[{"action":"command",...}]`. stderr says
`no output produced: a tool required the "command" permission ...`.

After every run, check both before reading anything else:

```bash
jq '{status, denied: .denied_actions, empty: (.response == "")}' <log>.json
```

A non-empty `denied_actions` or an empty `response` means the run stopped early. Read stderr for which
permission it needed. Do not treat it as done.

## Resuming and batching

Save `conversation_id` and pass it back with `--conversation <id>` for the next batch. `--continue`
resumes the most recent conversation in the workspace, which may be someone else's; never use it.

## Conversation naming

There is no way to name a headless conversation. agy writes its own title from the content, and
`/rename` is refused in print mode ("print mode has no conversation manager"). Keep a short, unique
first line anyway: it is the handle for finding the process. To rename a conversation afterwards,
open it in the interactive CLI (`/resume`) and use `/rename`.

## Finding your run

A headless run is a single `agy` process whose full argv, prompt included, shows in `ps`. An
interactive `agy` is also named `agy`, so never match on the name; match on the prompt's first line:

```bash
ps -eo pid,etime,args | grep -F "<prompt first line>" | grep -v grep
```

## First-run prompt

The same as cursor's (`driving-cursor-as-build-model.md`, *The launch prompt*), its "Do not
commit" line included. Check any commit agy does make anyway for a trailer it added.
