# Driving a Claude CLI process as the phase driver
*Experimental. Tested with Claude Code 2.1 on one long build; the verdict on whether a mid-tier model
can drive as well as the planner is still open.*

The phase driver does the planner's build-time job for one phase: it writes the build model's
briefs, launches and watches it, checks every run itself (the diff, every new test, the mutations),
runs the reviews, amends the plan, and stops before the phase is closed. The planner then closes the
phase: it re-runs the mutations, runs the gates, and reads the driver's reviews and decisions. The
question a trial answers is whether a cheaper model can sit in the architect's seat.

## Launch

```bash
claude -p --model <model> --output-format json --max-budget-usd <cap> \
  --permission-mode auto \
  --disallowedTools "ReportFindings" "Bash(git push:*)" "Bash(git reset:*)" "Bash(git checkout:*)" \
    "Bash(git stash:*)" "Bash(git rebase:*)" "Bash(git clean:*)" \
  < <driver prompt file> > <run>.json 2> <run>.err
```

- **Run it with your harness's background option.** It runs for hours, and the result JSON is
  written only when it ends.
- **Permissions.** A driver launches build models, waits on them, and runs suites, so a hand-written
  allowlist that refuses `cd`, `sleep`, `mkdir` or redirection stops it from doing the job; a good
  driver stops and asks at that point. Accept-edits mode with a broad allowlist was refused by the launching session's own safety check,
  as creating an agent with fewer guardrails than itself. Auto permission mode, which applies the
  harness's own safety checks, is what worked, with the destructive git commands disallowed outright as above. Decide this
  yourself: the driver acts with your account's permissions while you are not watching, so commit
  everything first and keep the budget cap.
- **`--max-budget-usd`** caps its own spend. The counter restarts when the session is resumed.
- **To change its instructions mid-run**, stop it by exact process id, write a short resume prompt,
  and relaunch with `--resume <session id>` and the same flags.

## Its prompt

- **A reading list, in order:** the project's instructions (`CLAUDE.md` / `AGENTS.md`), the build's
  state notes, the driver's checklist, the build model's launch recipe, then the plan sections and
  the phase.
- **Scope:** exactly which amendments and which phase, and what it must not touch.
- **How to run things headless:** the build model with the harness's background option rather
  than `nohup` or `&`, which detach it and lose its result; bounded wait loops (`timeout 590 bash -c 'while pgrep -f "[c]odex exec" >/dev/null; do sleep 20; done'`);
  the test suite the same way, output to a file, the exit code read from the file.
- **Which reviewers it may use**, by name: one outside model for the deep review, a small model for
  fix checks. The driver does not choose models; the prompt does.
- **The hard rules:** commit by path; no push, reset, checkout, stash or rebase; kill by exact
  process id; a failing test is read and fixed, never re-run until it passes.
- **When to stop and ask:** write the question to a file the planner watches, then end the run. And
  when to stop at the close without writing the close entry.
- **A report file it rewrites as it goes, and a decisions file** for every call it made without asking.

## Watching it

Watch its commits, its questions file and its process (`pgrep -f "[c]laude -p --resume <id>"`; the
brackets stop the pattern matching itself). Do not touch the tree while it runs mutations, and point
any reviewer you launch yourself at committed code only.

## What a driver did well

- It checked the build model's work itself and found what the build model's report left out: a real
  behaviour change from the main branch (a dropped filter), rows still read by position, hollow tie
  and isolation tests, a dead helper.
- It ran its own mutations on top of the ones the briefs named.
- It ruled on the build model's halts from the plan instead of asking, and recorded each ruling.
- It found a real schema gap and fixed it by the plan's own pattern, recording the decision.
- It stopped and asked, correctly, when its permissions made the prompt impossible to follow.

## What it missed or cost

- It committed tie tests whose mutations survived, before it reworked them. The planner's own
  mutation re-run at the close is not optional.
- Rework is heavy: close to half of the build model's runs were reworks. Each rework was a defect it
  caught, but its briefs did not prevent them.
- Wall time is dominated by the build model's round trips, not by the machine.
