# Driving agy as the plan reviewer and code reviewer
*Launch mechanics: `driving-agy-as-build-model.md`. Setup: `agent-cli-setup.md`.*

agy can review twice per plan, in one conversation: the plan review before the build model is
launched (after the workflow's own plan reviews), and the code review after the build and its
review, before `/verify-completion`. Its findings are input to weigh, not verdicts: confirm each one
against the code before acting on it.

## Launch

Reviews are read-only, so launch **without** `--mode accept-edits`. A file write is then denied,
which ends the run (see *A denied command ends the run and still reports success* in the build file). Run the same `jq` check
after each run.

```bash
cd <repo> && agy --output-format json -p "<plan review prompt>" > <log>.json 2> <log>.err
```

Save `conversation_id`. The code review resumes the same conversation, so it keeps the plan review's
context:

```bash
cd <repo> && agy --conversation <conversation_id> --output-format json -p "<code review prompt>" > <log>.json 2> <log>.err
```

Put the tracing tools the brief asks for on the allowlist (the language server or type checker,
`graphify query`, the project's type-check target), or the first trace ends the run.

The workflow's gates start a reviewer fresh each time (`review-lenses`). Resuming one conversation
across the plan and code review is a choice you make outside them: the reviewer remembers what it
flagged and can check the build delivered it, but it can anchor on its earlier view. Start fresh
where a wrong assumption costs most. Resuming after a network drop is different: it finishes the
same review.

## The prompts

Use the outside-review brief from the `review-lenses` skill (*Handing a review to an outside
model*), filled in by `/write-plan` or `/3p-review` when you accept their offer. Start it with a
short unique first line naming the run. Add these lines for agy, for the reasons below:

```
Never start a background task.
Read skill files with cat, not your file viewer.
For every finding, quote the exact words you rely on, with file:line.
Allowed commands, one per call, nothing else: <the exact read-only commands on your allowlist>.
The checked-out branch is <branch>.
```

## What stops a review run early

- **Any command off the allowlist ends the run** with `"status":"SUCCESS"`, an empty `response` and
  `denied_actions`. A reviewer reaches for commands you did not expect (`git branch --show-current`
  to learn the branch), so list the allowed commands exactly in the prompt, and name the branch.
- **Pipes, redirection, loops and heredocs are refused**, and some models use them even when the
  prompt bans them by name. Gemini 3.1 Pro did in four of six pre-build reviews: writing the answer to a file with a heredoc, `> /dev/null; echo`, a `for`
  loop, `git ls-tree ... | rg`. When it tried to write its review to a file, the full text is often
  recoverable from its transcript (below). After two failed runs on one brief, move that review to
  another reviewer (`driving-claude-cli-as-reviewer.md`).
- **Skill files outside the workspace** are denied to its file viewer, which ends the run at once.
  Tell it to read them with `cat`.
- **It cannot `cd`**, so a command that needs another directory (`pnpm --prefix frontend ...`)
  ends the run unless it is on the allowlist. Tell it not to run those, and run them yourself.
- **Background tasks:** it starts long commands as background tasks and waits on them; a network
  drop during that wait ends the run with `status: ERROR`. Resume the same conversation after a drop.
- **Quota is per model family.** One family's quota can run out mid-review while another's is
  untouched (`RESOURCE_EXHAUSTED ... Individual quota reached`); switch with `--model`.

## It can invent its citations

Asked to quote exact words with line numbers, it has quoted plan text, function names and line
numbers that exist nowhere (a line 632 of a 238-line document), while being right on the substance.
So require a verbatim quote plus `file:line` for every finding, and check each quote with `rg -F`
before weighing the finding. Its business and logic instincts are worth reading; its citations are
not evidence until checked.

The transcript, for tracing a claim or finding a refused command:
`$HOME/.gemini/antigravity-cli/brain/<conversation_id>/.system_generated/logs/transcript_full.jsonl`.

## A review of a later phase reads today's code

A reviewer checking a phase that is not built yet sees the code as it is now. Check each finding
against what the earlier phases will have built (their plan text) before accepting it.
