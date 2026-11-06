# Driving a separate Claude CLI process as a reviewer

Covers the deep read (a Sonnet-class model) and the fix check (a Haiku-class model). Which one to use where:
`review-levels-and-who-runs-them.md`.

A `claude -p` process is a reviewer whose session lives on disk and outlasts the calling session or its
compactions. It never sees the calling session's conversation, only the files. It does load the project's
`CLAUDE.md` and memory, so it is not completely cold. It bills the same account as the calling session.

## Launch

```bash
claude -p --model <model> --output-format json --disallowedTools "ReportFindings" \
  --allowedTools "Read" "Grep" "Glob" "Bash(rg:*)" "Bash(grep:*)" "Bash(git log:*)" \
    "Bash(git show:*)" "Bash(git diff:*)" "Bash(git ls-tree:*)" "Bash(sed -n:*)" "Bash(cat:*)" "Bash(ls:*)" \
  < <brief file> > <run>.json 2> <run>.err
```

- **Pass the brief on stdin from a file.** Its first line is a short name for the run.
- **Run it with your harness's background option and its maximum timeout.** A deep read can take a quarter of
  an hour.
- **`--allowedTools` pre-approves; it does not restrict.** What your settings already allow still runs. For a limit on which tools exist, also pass `--tools` with the bare names (`Read Grep Glob Bash`); it takes tool names, not command patterns, so it does not limit what Bash runs. The list above is for reading. Entries match by prefix, so even these can
  write in corners (`git diff --output=`, `sed`'s `w` command); keep the list short and the tree committed. A
  review that runs tests or mutation checks also needs your test runner and the Edit tool, and its brief must
  say to restore each mutation by copying the file back, never with git.
- **Block the findings tool.** A reviewer that files its list in `ReportFindings` leaves only a summary in
  `result`. The brief says findings go in the final message.
- **Read the answer** with `jq -r .result <run>.json`, and the cost with `.total_cost_usd` and `.num_turns`. If
  `result` summarises ("10 of 19 findings"), resume the session and ask for the full numbered list.
- **A command neither on the list nor allowed by your settings is refused and the run carries on**; `permission_denials` lists each one. Compound
  commands are checked part by part, so `cd x && ...`, pipes, heredocs and redirection are refused unless every
  part is allowed.
- **Your Bash hooks apply to it too.**
- **A review that hits the session limit** ends with an API error and no findings. Switch to another reviewer (RL-9); relaunch after the reset only if there is none.

## Resuming, and when not to

The workflow's gates start a reviewer fresh each time (`review-lenses`). `--resume <session_id>` with the same
flags continues one, from the `session_id` in the JSON result.

- **Resuming a long session is expensive**: every turn re-reads the whole history. To check fixes after a long
  round, start a fresh process with the commit range and the fix list.
- **A resumed reviewer anchors on its own earlier view.** Use a fresh process where a wrong assumption costs most.

## Cost comes mostly from refused commands

A code-running review can spend most of its turns retrying refused `cd` chains and heredocs, and hit the session
limit before it reports. So the brief says: never `cd`; one command per call; no pipes, `&&`, heredocs or
redirection; a refusal is final. When a review must run code, allow the Write tool and your runner, and tell it to
write scripts to one scratch folder and run them from there.

**For a long plan, keep a ledger of verified probes** (claim, command, output, commit). Every reviewer reads it
first and skips what it already proves; the planner adds entries after checking them.

## The deep read

Use the outside-review brief from the `review-lenses` skill. Cost grows with the diff and with every turn
re-reading the history.

## The fix check

The small review after a rework round: one commit range, the findings it was meant to fix, a yes or no on each, and
anything new it broke. It checks what it is pointed at, so it never replaces the deep read. Its brief, in order:

1. **A first line naming the run.**
2. **The fence:** read-only; no edits, tests, containers or commits; findings in the final message; the command
   rules above.
3. **When another agent is changing the tree:** read code only with `git show <commit>:<path>`. A checker pointed
   at working files during mutations reviews a deliberately broken file.
4. **Scope:** the exact commit range and the standard it is checked against, by rule tag.
5. **The previous round's findings**, each named, and what the owner ruled to leave as it is.
6. **What is already proven**, so it does not spend turns on it.
7. **The output shape:** each previous finding, fixed or not with the line; then new findings with severity, file
   and line.

For the next round, copy the brief and change the range and the findings list. A fix-check model also makes a good
fallback when another outside reviewer fails twice on one brief.

## A killed reviewer can leave mutations in the tree

After any reviewer that ran mutation checks and did not finish, compare the tree with the commit it reviewed,
restore only the files it broke, and clear bytecode caches.

Treat every report as another model's claims: verify each finding before acting.
