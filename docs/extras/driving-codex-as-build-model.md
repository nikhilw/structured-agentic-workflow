# Driving Codex as the build model or a reviewer

Only the differences from `driving-cursor-as-build-model.md`; everything else there applies.

## Launch

```bash
codex exec -m <model> -c model_reasoning_effort="medium" \
  -s workspace-write \
  --add-dir <each cache directory your toolchain writes> \
  -C <the working tree> \
  --json -o <run>.last.md \
  "Read <prompt file> and follow it exactly." \
  < /dev/null > <run>.jsonl 2> <run>.err
```

- Run it in the background; it never asks for approval in `exec` mode.
- **Close its input with `< /dev/null`.** Without it, launched from a background shell, it waits on
  stdin forever and does nothing. With it, the "Reading additional input from stdin..." line on stderr
  is harmless.
- **The launching call's timeout kills it**, mid-step if need be, with no final message. A kill during a
  mutation leaves the broken line and its backup in place. Size briefs to finish well inside the limit;
  after any stop, look for backup files and diff them against the source first.
- `-o` writes the final message to a file; `--json` streams every event, which is where to look when a
  run ends early.
- **The sandbox** (`workspace-write`) lets it write only inside the repository and the `--add-dir`
  directories. A toolchain that writes outside the repo, such as to a package cache or the temp
  directory, fails until that directory is added.
- **Network access** is off in the sandbox by default. Turn it on with
  `-c sandbox_workspace_write.network_access=true` only if the tests need it, and probe one small test
  first. The agent can then reach the network, and a reachable Docker socket is effectively root on the
  machine.
- **`-C` applies inside Codex.** The launcher's process still reports the directory you launched from, so
  confirm where it is reading from its first commands in the `.jsonl`.
- Its reports are candid about what it skipped, but it has listed a fix it had not made. Verify each item
  against the diff.
- Watch it by matching `[c]odex exec` in `ps` (the brackets stop the pattern matching itself).

## Resuming

`codex exec resume <session id>`; the id is in the first events of the `.jsonl` (`thread.started`).

- **`resume` takes no `-s` or `--add-dir`.** Pass them as settings:
  `-c sandbox_mode="workspace-write" -c 'sandbox_workspace_write.writable_roots=["<dir>","<dir>"]'`, plus
  the network setting if the first run had it.
- **A resume does not keep the model.** Without `-m` it resumes on the CLI's default. Always pass `-m` and
  the effort.
- **A resume runs in the current folder, not the original `-C` folder.** Change into the worktree first,
  and confirm with `readlink /proc/<pid>/cwd`.

## Taking over from another build model

It has none of the other model's conversation. Start the prompt with a reading list: the build contract,
the plan's rules and the phase, the briefs done and pending, and `git log`. It reads `AGENTS.md` on its
own but not `CLAUDE.md`, so point to whatever holds your conventions.

## What to watch for

- **Rework costs more than speed.** Time goes on round trips to the model, not the machine. Smaller briefs
  that spell out the expected test shapes cut rework more than a faster model would.
- **Its usual misses:** rows read by position where the plan asked for names, a dropped filter that changes
  behaviour, tie and isolation tests whose data cannot show the defect.
- **It can dodge a search it was told must come back empty,** by splitting the string in the code
  (`"foo_" + "bar"`). After such a brief, read the added lines for split strings.
- **It leaves mutation copies in the tree mid-run.** A stray one at the end is a cleanup item. At cleanup it
  may delete its own mutation specs and logs, so tell it to leave them.
- **"High Load" and `resource_exhausted`** from a provider can mean it is busy, not that your quota is gone.
  Checkpoint-commit partial work and hand the rest to whichever model is up.

## As a reviewer

Use its higher model for reviews and keep the smaller one for building. The sandbox fences writes, so a
review needs no allowlist. The brief is the `review-lenses` outside-review brief, passed as the prompt:

```bash
codex exec -m <higher model> -s read-only -C <clean clone> \
  --json -o <run>.last.md "$(cat <brief file>)" \
  < /dev/null > <run>.jsonl 2> <run>.err
```

- `-o` holds the review. Check it is not empty before counting the review as run.
- `read-only` stops writes, not reads: it can still open files elsewhere on disk. Give it a clean clone, and
  after the run check its commands in the `.jsonl` for paths outside it.
- Its findings are claims, like any reviewer's: verify each one.
