# Driving a Claude CLI process as the phase driver

Experimental: whether a mid-tier model can drive as well as the planner is an open question.

The phase driver does the planner's build-time job for one phase: it writes the build model's briefs, launches and
watches it, checks every run itself (the diff, every new test, the mutations), runs the reviews, amends the plan, and
stops before the phase is closed. The planner then closes the phase: it runs, once, any mutation nothing first-party
has witnessed, runs the gates, and reads the driver's reviews and decisions.

## Launch

```bash
claude -p --model <model> --output-format json --max-budget-usd <cap> \
  --permission-mode auto \
  --disallowedTools "ReportFindings" "Bash(git push:*)" "Bash(git reset:*)" "Bash(git checkout:*)" \
    "Bash(git stash:*)" "Bash(git rebase:*)" "Bash(git clean:*)" \
  < <driver prompt file> > <run>.json 2> <run>.err
```

- **Run it with your harness's background option.** It runs for hours, and the result JSON is written only when it ends.
- **Permissions.** A driver launches build models, waits on them and runs suites, so a hand-written allowlist that
  refuses `cd`, `sleep`, `mkdir` or redirection stops it from doing the job. Accept-edits with a broad allowlist can be
  refused by the launching session's own safety check. Auto permission mode, with the destructive git commands disallowed
  as above, is what works. Decide this yourself: the driver acts with your account's permissions while you are not
  watching, so commit everything first and keep the budget cap.
- **`--max-budget-usd`** caps its own spend. The counter restarts when the session is resumed.
- **To change its instructions mid-run**, stop it by exact process id, write a short resume prompt, and relaunch with
  `--resume <session id>` and the same flags.

## Its prompt

- **A reading list, in order:** the project's instructions, the build's state notes and the driver's checklist, the build
  model's launch recipe, then the plan sections and the phase.
- **Scope:** exactly which amendments and which phase, and what it must not touch.
- **How to run things headless:** the build model with the harness's background option rather than `nohup` or `&`, which
  detach it and lose its result; bounded wait loops (`timeout 590 bash -c 'while pgrep -f "<pattern unique to this run>" >/dev/null; do sleep 20; done'`, first letter of the pattern in brackets so it does not match itself; exit 124 means still running, so loop again);
  the test suite the same way, output to a file, the exit code read from the file.
- **Which reviewers it may use**, by name: one outside model for the deep read, a small model for fix checks. The prompt
  chooses models, not the driver.
- **The hard rules:** commit by path; no push, reset, checkout, stash or rebase; kill by exact process id; a failing test
  is read and fixed, never re-run unchanged in the hope it passes.
- **When to stop and ask:** write the question to a file the planner watches, then end the run. And when to stop at the
  close without writing the close entry.
- **A report file it rewrites as it goes, and a decisions file** for every call it made without asking.

## Watching it

Watch its commits, its questions file and its process (`pgrep -f` on a pattern unique to this run, bracketed the same way). Do not touch the tree while it runs mutations, and point any reviewer you launch yourself at
committed code only.

## What to expect

- **Good at:** checking the build model's work itself and finding what its report left out, ruling on the build model's
  halts from the plan and recording each ruling, stopping when its permissions make the prompt impossible.
- **Watch for:** tests committed before their mutations were run. A first-party run of each mutation, once, is not
  optional; repeating one whose test and code have not changed is waste.
- **Cost:** rework is heavy unless the briefs spell out expected test shapes, and wall time is mostly the build model's
  round trips.
