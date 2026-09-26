# Driving agy (Antigravity CLI) as the build model
*A worked recipe for the [multi-model split](../multi-model.md), like the
[Cursor one](driving-cursor-as-build-model.md). Verified 2026-09-26 against agy 1.2.11 on a Raspberry Pi. Set up
first: [agent-cli-setup.md](agent-cli-setup.md).*

These sections of [driving-cursor-as-build-model.md](driving-cursor-as-build-model.md) apply to agy unchanged: Never run it
against a live app, After a killed run check for unrestored mutations, Reported-done is not done,
It will sometimes work around a gap instead of halting, Batching a long plan, Test suite. This file
holds only what differs.

## Launch

```bash
cd <repo> && agy --mode accept-edits --output-format json -p "<prompt>" > <log>.json 2> <log>.err
```

- `-p` takes the prompt as its own value. Put the prompt directly after `-p` and every flag before
  it; `agy -p --output-format json "<prompt>"` exits 2 with "-p took --output-format as its prompt".
- `--mode accept-edits` lets it write files. Without it every file write is denied.
- No `--model`: the default is Gemini 3.8 Flash (High). `agy models` lists the rest.
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
`jetski: no output produced — a tool required the "command" permission ...`.

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
first line anyway: it is the handle for finding the process. To rename a conversation afterwards, the
human opens it in the interactive CLI (`/resume`) and uses `/rename`.

## Finding your run

A headless run is a single `agy` process whose full argv, prompt included, shows in `ps`. The human's
interactive `agy` is also named `agy`, so never match on the name; match on the prompt's first line:

```bash
ps -eo pid,etime,args | grep -F "<prompt first line>" | grep -v grep
```

## First-run prompt

The same as cursor's, word for word except the last line:

```
<short unique name for this run>
You are the build model in the ai agentic development workflow.
Load up the skills @AGENTS.md, /python-clean-code, /build-model and wait to receive the plan.
Think critically about the plan. If you find issues or discrepancies during implementation,
surface them and halt instead of pushing through or working around it.
If you create a file by mistake and cannot delete it, leave it in place and report it. Do not add
code anywhere to hide, skip, or work around it.
If the plan cannot be followed as written, halt and report. Do not build a workaround inside the
files the plan does name, a plan gap is mine to fix, not yours to route around.
Do not modify any file the plan does not name.
Before adding a required field to a shared dataclass, grep its constructor call sites first.
Do not commit; the reviewer commits.
Here is the plan file, build phases <N to M>: <plan file path>.
```

`git commit` is on the allowlist, hence the explicit line. Whether agy adds its own commit trailer is
not yet known; check any commit it does make.
