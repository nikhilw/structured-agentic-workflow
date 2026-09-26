# Setting up cursor-agent and agy on a dev machine
*Verified 2026-09-26 on a Raspberry Pi: cursor-agent, agy 1.2.11. Re-check: the two probes at the end.*

Every dev machine that runs a build or review model needs this once. Paths below use `$HOME`; never
write `~` into a config file, agy rejects it (see Skills).

## Workflow skills

The skills live in `$HOME/.agents/skills/` (installed and updated by `npx skills`, or by this repo's
`./install.sh`). Claude Code reads
them through symlinks in `$HOME/.claude/skills/`. Do not copy them anywhere else.

- **agy** reads them through `$HOME/.gemini/config/skills.json`. The path must be absolute: `~/...`
  fails with "must be an absolute path" in `$HOME/.gemini/antigravity-cli/log/`, and agy then shows
  only its two built-in skills, silently.

  ```bash
  printf '{\n  "entries": [\n    { "path": "%s/.agents/skills" }\n  ]\n}\n' "$HOME" > "$HOME/.gemini/config/skills.json"
  ```

  Because it points at the directory, a skill added or updated by `npx skills` is seen on the next
  launch with no copying. Delete any skill copies made earlier under `$HOME/.gemini/config/`.
- **cursor-agent** reads `AGENTS.md` in the repo, and the skills through the prompt.

## Permissions: one allowlist, two formats

The allowlist in `$HOME/.cursor/cli-config.json` is the source. agy's list must match it.

- **cursor-agent**, `$HOME/.cursor/cli-config.json`: `"approvalMode": "allowlist"`,
  `"sandbox": {"mode": "disabled"}`, and `permissions.allow` entries written `Shell(<command>)`.
- **agy**, `$HOME/.gemini/antigravity-cli/settings.json`: `permissions.allow` entries written
  `command(<command>)`. The match is by prefix: `command(git status)` also allows
  `git status --short`.

Copy cursor's list into agy's format, keeping agy's other keys:

```bash
python3 - <<'EOF'
import json, pathlib
home = pathlib.Path.home()
allow = json.load(open(home / ".cursor/cli-config.json"))["permissions"]["allow"]
commands = [entry[len("Shell("):-1] for entry in allow if entry.startswith("Shell(")]
settings_path = home / ".gemini/antigravity-cli/settings.json"
settings = json.load(open(settings_path))
settings.setdefault("permissions", {})["allow"] = [f"command({c})" for c in commands]
settings_path.write_text(json.dumps(settings, indent=2) + "\n")
EOF
```

cursor's `Mcp(...)` entries are not copied. agy has no MCP servers configured, and its syntax for
MCP permission entries has not been checked.

If the machine has no cursor config yet, the list used on 2026-09-26 was: `ls`, `cat`, `head`,
`cd`, `uv run`, `wc`, `uv add`, `git diff`, `git log`, `git status`, `find`, `git ls-files`,
`git add`, `echo`, `tail`, `xargs`, `git show`, `rg`, `pnpm run`, `pnpm test`, `pnpm exec`,
`pnpm lint`, `pnpm install`, `grep`, `pnpm vitest`, `sort`, `node`, `timeout`, `pnpm tsc`,
`pnpm build`, `test`, `npm run`, `npm test`, `npx vitest`, `npx eslint`, `npx tsc`, `podman`,
`uv sync`, `docker build`, `docker run`, `graphify`, `tee`, `make`, `nvm`, `pwd`, `semble`, `stat`,
`which`, `dbmate`, `ps`, `date`, `sha256sum`, `docker --version`, `docker images`, `git stash`,
`dirname`, `sed`, `git merge-base`, `cp`, `sqlite3`, `git rev-parse`, `awk`, `git commit`, `mv`,
`mkdir`. Never `rm`, `chmod`, `sudo`, `curl`, `wget`, `ssh`, `git push`, `git reset`,
`git checkout`, `git clean`.

## Probes: run both after setup, in a scratch clone

Run probes in a throwaway clone (`git clone --no-hardlinks --depth 1 file://<repo> <scratch>`),
never in the shared working tree: the second probe writes files.

```bash
agy --output-format json -p "setup probe
Do not run any tools. List the names of every skill available to you, comma separated."
```
Expect `build-model`, `python-clean-code` and the rest of `$HOME/.agents/skills/`.

```bash
agy --mode accept-edits --output-format json -p "setup probe 2
Run: wc -l AGENTS.md, then cp AGENTS.md probe-copy.md, then mv probe-copy.md probe-moved.md. Reply DONE."
```
Expect `DONE` and no `denied_actions` key in the JSON.
