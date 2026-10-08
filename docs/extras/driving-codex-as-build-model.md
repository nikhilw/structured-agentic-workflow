# Driving Codex as the build model
*Tested with codex-cli 0.161.0 on a ChatGPT login. Only the differences from
`driving-cursor-as-build-model.md`; everything else there applies.*

## Launch

```bash
codex exec -m <model> -c model_reasoning_effort="medium" \
  -s workspace-write \
  --add-dir <each cache directory your toolchain writes> \
  --json -o <run>.last.md \
  "Read <prompt file> and follow it exactly." \
  > <run>.jsonl 2> <run>.err
```

- Run it in the background; it never asks for approval in `exec` mode.
- `-o` writes the final message (the handoff) to a file; `--json` streams every event, which is
  where to look when a run ends early.
- **The sandbox** (`workspace-write`) lets it write only inside the repository and the `--add-dir`
  directories. A toolchain that writes outside the repo fails without them: `uv run` fails with
  "Read-only file system" on the uv cache lock until its cache directory is added, and the same goes
  for other package caches and the temp directory.
- **Network access** is off in the sandbox by default. Turn it on with
  `-c sandbox_workspace_write.network_access=true` only if the tests need it, for example to reach
  the Docker socket for testcontainers, and probe one small test inside the sandbox before a full
  run. Know what that costs: the agent can then reach the network, and a reachable Docker socket is
  effectively root on the machine.
- **Resume** with `codex exec resume <session id>`; the id is in the first events of the `.jsonl`
  (`thread.started`). `resume` takes no `-s` or `--add-dir`; pass them as settings:
  `-c sandbox_mode="workspace-write" -c 'sandbox_workspace_write.writable_roots=["<dir>","<dir>"]'`,
  plus the network setting if the first run had it.
- Its reports are candid about what it skipped, but it has listed a fix it had not made; verify each
  item against the diff, as with any build model.
- Watch it by matching `[c]odex exec` in `ps` (the brackets stop the pattern matching itself).

## Taking over from another build model

It has none of the other model's conversation. Start the prompt with a reading list: the build
contract, the plan's rules and the phase, the briefs already done and still pending, and `git log`.
Codex reads `AGENTS.md` on its own but not `CLAUDE.md`, so point to whatever holds your conventions.

## When the other build model's provider is down

"High Load ... try again" and `resource_exhausted` errors can come from a provider being busy, not
from your quota. A run killed this way can end with an empty log; checkpoint-commit its partial work
and hand the remaining list to whichever model is up.

## Field notes

- **Speed comes from round trips, not the machine.** A build step can take most of an hour for a
  few hundred small actions (read a file, edit a line, run one test), with each test run taking
  seconds and the rest spent waiting on model replies. A faster machine does not help much.
- **Rework costs more than speed.** Smaller briefs that spell out the expected test shapes cut
  rework rounds more than a faster model would.
- **What it got wrong:** rows read by position (tuple unpacking, slices) where the plan asked for
  names, a dropped filter that changed behaviour, tie and isolation tests whose data could not show
  the defect, and "the key is unique" given as a reason to skip an ordering test.
- **What it got right:** it halts on real doubts, and its own tests have found real schema gaps.
- **It leaves mutation copies in the tree mid-run** (`*.mutation-backup` and similar). Normal while
  it runs; a stray one at the end of a run is a cleanup item.
