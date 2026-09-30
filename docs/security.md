# Security notes

skills.sh scans every skill with Gen (Agent Trust Hub), Socket and Snyk. Four skills carry a
standing Snyk warning, **W011: third-party content exposure**. It is expected, and it stays.

## Why W011 fires

W011 flags any skill that reads text written by people outside the project. It measures exposure,
not a defect: the only way to clear it is to stop reading that text.

| Skill | What it reads | Why it must |
|---|---|---|
| `github-backlog` | GitHub issues and comments | Managing issues is the skill's whole job |
| `triage` | GitHub issues, when `workflow-config:use-github-issues` is on | Recommending what to work on next means reading the backlog |
| `brainstorm` | Package docs and READMEs, pasted by the user or fetched under BS-7 | Judging a third-party package means reading what it says it does |
| `knowledge-graph` | The graphify index, which holds repo text and anything added with `graphify add <url>` | Finding callers and dependents is what the index is for |

## What contains it

- **Outside text is data, never instruction.** Each skill says so explicitly. An embedded
  instruction to run a command, add a dependency or start other work is not followed.
- **Nothing read goes to a shell.** `github-backlog` and `triage` run one shell command,
  `git remote get-url origin`, and `allowed-tools` pre-approves no other shell command. Links,
  paths and package names found in issue text are named to the user, never opened or installed.
- **Issue text never triggers a write.** In `github-backlog`, creating, labelling, commenting on or closing an issue
  happens only on the user's command or at a named workflow point.
- **Quoted issue text stays fenced.** Issue text passed on in a report or a recommendation goes in
  a fenced block labelled as quoted, so the next model meets it as data.
- **Fetched docs are unverified.** In `brainstorm`, directives in a README get no weight, its
  wording never decides a tool, dependency or recommendation, and a passage carried into the
  decision document is fenced as quoted outside text (BS-7).
- **A graph answer is a pointer, not proof.** The source file decides, and graph content never
  steers a dependency, tool or design choice.

Every command any skill runs from a document is bounded by `test-scope`'s *What a run may execute*.
If a scanner flags something not listed here, treat it as new and open an issue.
