# Driving agy as the plan reviewer and code reviewer

Launch mechanics: `driving-agy-as-build-model.md`. Setup: `agent-cli-setup.md`.

Its findings are input to weigh, not verdicts: confirm each one against the code before acting on it.

## Launch

Launch **without** `--mode accept-edits`, on a clean clone: the shell permissions from setup still apply, so this denies file edits and does not make the run read-only. A file write is then denied, which
ends the run (see *A denied command ends the run and still reports success* in the build file). Run the
same `jq` check after each run.

```bash
cd <repo> && agy --output-format json -p "<review prompt>" > <log>.json 2> <log>.err
```

Save `conversation_id`. `--conversation <conversation_id>` resumes it, which finishes a review after a
network drop. The workflow's gates start a reviewer fresh each time (`review-lenses`), because a resumed
reviewer can anchor on its earlier view.

Put the tracing tools the brief asks for on the allowlist (the language server or type checker,
`graphify query`, the project's type-check target), or the first trace ends the run.

## The prompt

Use the outside-review brief from the `review-lenses` skill. Start it with a short unique first line
naming the run, and add these lines:

```
Never start a background task.
Read skill files with cat, not your file viewer.
For every finding, quote the exact words you rely on, with file:line.
Allowed commands, one per call, nothing else: <the exact read-only commands on your allowlist>.
The checked-out branch is <branch>.
```

## What stops a review run early

- **Any command off the allowlist ends the run** with `"status":"SUCCESS"`, an empty `response` and
  `denied_actions`. List the allowed commands exactly in the prompt, and name the branch so it does not ask.
- **Pipes, redirection, loops and heredocs are refused**, and some models use them even when the prompt bans
  them by name. If it tried to write its review to a file, the text is often in its transcript (below). After
  two failed runs on one brief, move that review to another reviewer.
- **Skill files outside the workspace** are denied to its file viewer, which ends the run. Tell it to use `cat`.
- **It cannot `cd`**, so a command needing another directory ends the run unless it is on the allowlist. Tell
  it not to run those, and run them yourself.
- **Background tasks:** a network drop while it waits on one ends the run with `status: ERROR`. Resume the same
  conversation. A resumed run can end `ERROR` yet carry a full `response`, so read `response` too.
- **Quota is per model family.** One can run out mid-review while another is untouched (`RESOURCE_EXHAUSTED ...
  Individual quota reached`). Switch with `--model`; `agy models` lists the choices.

## Is it still running?

An empty log is not death: the JSON is written when the run ends. Find the process by reading
`/proc/<pid>/cmdline` of the `agy` process, since its arguments may not match a `ps` search, and watch the
transcript's line count. Do not relaunch into the same conversation until the process is gone.

## It can invent its citations

It has quoted text, function names and line numbers that exist nowhere, while being right on the substance.
Require a verbatim quote plus `file:line` for every finding, and check each quote with `rg -F` before weighing
the finding. Its business and logic instincts are worth reading; its citations are not evidence until checked.

The transcript, for tracing a claim or finding a refused command:
`$HOME/.gemini/antigravity-cli/brain/<conversation_id>/.system_generated/logs/transcript_full.jsonl`.

## A review of a later phase reads today's code

Check each finding against what the earlier phases will have built (their plan text) before accepting it.
