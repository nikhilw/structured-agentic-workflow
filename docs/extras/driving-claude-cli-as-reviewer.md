# Driving a separate Claude CLI process as a reviewer
*Tested with Claude Code 2.1 (`claude --version`). Covers the deep read (a Sonnet-class model) and
the fix check (a Haiku-class model). Which one to use where: `review-levels-and-who-runs-them.md`.*

A subagent inside a session is the simplest fresh reader, and the workflow's gates offer one. A
separate `claude -p` process is the alternative when you want a reviewer whose session lives on disk
and outlasts the calling session or its compactions. It never sees the calling session's
conversation, only the files. It does load the project's `CLAUDE.md` and memory, like any session,
so it is not completely cold.

## Launch

```bash
claude -p --model <model> --output-format json --disallowedTools "ReportFindings" \
  --allowedTools "Read" "Grep" "Glob" "Bash(rg:*)" "Bash(grep:*)" "Bash(git log:*)" \
    "Bash(git show:*)" "Bash(git diff:*)" "Bash(git ls-tree:*)" "Bash(sed -n:*)" "Bash(cat:*)" "Bash(ls:*)" \
  < <brief file> > <run>.json 2> <run>.err
```

- **Pass the brief on stdin from a file.** Its first line is a short name for the run.
- **Run it with your harness's background option and its maximum timeout.** A deep read can take
  a quarter of an hour, so a 10-minute timeout kills it partway through.
- **`--allowedTools` is the fence.** The list above is meant for reading, for plan reviews, fix
  checks and code reviews that only read. Entries match by prefix, so even these can write in
  corners (`git diff --output=`, `sed`'s `w` command); keep the list short and the tree committed. A review that runs tests or mutation checks also needs your test
  runner and the Edit tool, and its brief must say to restore each mutation by copying the file
  back, never with git.
- **Block the findings tool.** A `claude -p` session can have a `ReportFindings` tool; a reviewer
  that files its list there leaves only a summary in `result`. Hence `--disallowedTools
  "ReportFindings"`, and the brief says findings go in the final message.
- **Read the answer** with `jq -r .result <run>.json`, and the cost with `.total_cost_usd` and
  `.num_turns`. `result` holds only the final message; if it summarises ("10 of 19 findings"),
  resume the session and ask for the full numbered list.
- **A command off the list is refused and the run carries on**; `permission_denials` in the result
  lists each one. Compound commands are checked part by part, so `cd x && ...`, `mkdir -p`, pipes,
  heredocs and redirection are refused unless every part is allowed.
- **Your Bash hooks apply to it too.** A command your hooks block is blocked for the reviewer.
- **It bills the same account** as the calling session. A review that hits the session limit ends
  with an API error and no findings; relaunch after the reset.

## Resuming, and when not to

The workflow's gates start a reviewer fresh each time (`review-lenses`); resuming is a choice you
make outside them, knowing its cost. The JSON result carries `session_id`. `--resume <session_id>` with the same flags continues that
reviewer with its history; a launch without it starts a fresh one.

- **Resuming a long session is expensive**: every turn re-reads the whole history. Resume only while
  the history is short. To check fixes after a long round, start a fresh process with the commit
  range and the fix list instead.
- **A resumed reviewer anchors on its own earlier view.** It can check that a build delivered what
  it flagged, but use a fresh process where a wrong assumption costs most, such as batches that
  delete old code.

## Cost comes mostly from refused commands

A code-running review spends most of its turns retrying refused `cd` chains, heredocs and package
dry-runs, and can hit the session limit before it reports. A read-only review with no refusals costs
a fraction of that. So the brief says: never `cd`; one command per call; no pipes, `&&`, heredocs or
redirection; a refusal is final. When a review must run code, allow the Write tool and your runner,
and tell it to write scripts to one scratch folder and run them from there.

**Keep a ledger of verified probes** for a long plan: claim, command, output, commit. Every reviewer
reads it first and skips what it already proves; the planner adds entries after checking them.

## The deep read

One per phase, after the build, on a capable model. Use the outside-review brief from the
`review-lenses` skill. Cost grows with the diff and with every turn re-reading the history: from
around a dollar for a plan batch or a small phase to several dollars for a diff of thousands of
lines. Each one on real builds found real defects.

## The fix check

The small review after a rework round: one commit range, the list of findings it was meant to fix,
a yes or no on each, and anything new it broke. A Haiku-class model does it for cents to tens of
cents, and finds real gaps in most rounds (rows still read by position after a fix whose search
pattern was too narrow; major defects in a rework). It checks what it is pointed at, so it never
replaces the deep read. How often it raises a finding that does not hold has not been measured;
verify each one as with any reviewer.

Every fix-check brief that worked had these parts, in order:

1. **A first line naming the run.**
2. **The fence:** read-only; no edits, tests, containers or commits; findings in the final message,
   no findings tool; the command rules above.
3. **When another agent is changing the tree** (a build or mutations running): read code only with
   `git show <commit>:<path>`. Never point a checker at working files while mutations run; it would
   review a deliberately broken file.
4. **Scope:** the exact commit range and the standard it is checked against (the amendment and the
   plan's rules, by their tags).
5. **The previous round's findings**, each named, so it checks each one, and the items the owner
   ruled to leave as they are, so it does not report them again.
6. **What is already proven** (for example, mutations witnessed first-party), so it does not spend
   turns on it.
7. **The output shape:** for each previous finding, fixed or not with the line; then new findings
   with severity, file and line.

For the next round, copy the brief and change the range and the findings list.

A fix-check model also makes a good fallback when another outside reviewer fails twice on one brief.

## A killed reviewer can leave mutations in the tree

A reviewer that runs mutation checks and is killed mid-review (a compaction, a timeout) can leave a
deliberately broken file behind with no backup named. After any reviewer that did not finish, compare
the tree with the commit it reviewed, restore from that commit, and clear bytecode caches.

Treat every report as another model's claims: verify each finding against the code before acting.
