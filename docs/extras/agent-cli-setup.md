# Setting up cursor-agent and agy on a dev machine
*Tested with cursor-agent and agy 1.2.11. CLIs change; re-check with the two probes at the end.*

Every machine that runs a build or review model headless needs this once. Paths below use `$HOME`;
never write `~` into a config file, because agy rejects it (see Skills).

## Workflow skills

Install the skills where your agents read them: per project with `./install.sh --local <project>`
(into the project's `.agents/skills/`), or user-wide with `npx skills`. Point every CLI at that one
directory rather than copying the skills around.

- **agy** reads skills through `$HOME/.gemini/config/skills.json`. The path must be absolute: `~/...`
  fails with "must be an absolute path" in agy's log, and agy then shows only its built-in skills,
  silently.

  ```bash
  printf '{\n  "entries": [\n    { "path": "%s" }\n  ]\n}\n' "<absolute path to the skills directory>" > "$HOME/.gemini/config/skills.json"
  ```

  Because it points at a directory, a skill added or updated there is seen on the next launch with
  no copying. Delete any skill copies made earlier under `$HOME/.gemini/config/`.
- **cursor-agent** reads `AGENTS.md` in the repo, and the skills through the prompt.

## Permissions: one allowlist, two formats

Keep one allowlist as the source, here cursor's in `$HOME/.cursor/cli-config.json`, and make agy's
match it.

- **cursor-agent**, `$HOME/.cursor/cli-config.json`: `"approvalMode": "allowlist"`,
  `"sandbox": {"mode": "disabled"}`, and `permissions.allow` entries written `Shell(<command>)`.
- **agy**, `$HOME/.gemini/antigravity-cli/settings.json`: `permissions.allow` entries written
  `command(<command>)`. The match is by prefix: `command(git status)` also allows
  `git status --short`.

Copy cursor's list into agy's format. This **replaces** agy's allow list and keeps its other keys.
It expects agy's settings file to exist, so launch agy once first:

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

cursor's `Mcp(...)` entries are not copied; agy's syntax for MCP permission entries has not been
checked.

**A starting list**, to trim to your stack: reading commands (`ls`, `cat`, `head`, `tail`, `wc`,
`grep`, `rg`, `sort`, `stat`, `pwd`, `which`, `date`, `ps`), reading git
(`git diff`, `git log`, `git status`, `git show`, `git ls-files`, `git merge-base`, `git rev-parse`),
`git add`, your project's test, lint, type-check and build runners (for example `make`, `uv run`,
`npm test`, `pnpm test`, `npx tsc`), and file moves (`cp`, `mv`, `mkdir`). **Never** `rm`, `chmod`,
`sudo`, `curl`, `wget`, `ssh`, `git push`, `git reset`, `git checkout`, `git clean`. The match is by
prefix, so no entry is truly read-only: `sed -i`, `find -delete` and `awk`'s `system()` write or
execute, which is why they are left off. A language runtime or build tool on the list is a shell
(`uv run python -c "..."`), and there is no sandbox, so commit before every launch.

## Probes: run both after setup, in a scratch clone

Run probes in a throwaway clone (`git clone --no-hardlinks --depth 1 file://<repo> <scratch>`),
never in a working tree you care about: the second probe writes files.

```bash
agy --output-format json -p "setup probe
Do not run any tools. List the names of every skill available to you, comma separated."
```
Expect `build-model` and the rest of your skills directory.

```bash
agy --mode accept-edits --output-format json -p "setup probe 2
Run: wc -l AGENTS.md, then cp AGENTS.md probe-copy.md, then mv probe-copy.md probe-moved.md. Reply DONE."
```
Expect `DONE` and no `denied_actions` key in the JSON.
