# Skills and commands

Index of the skill and command files in this repo. The tool directories are the
source of truth; this file only indexes them. Update it when a skill or command
is added, renamed, or removed.

## Skills

| Skill | What it does | opencode | Claude Code | Codex |
| --- | --- | --- | --- | --- |
| `webapp-design` | Create a new web-app project end to end: discuss, design, scaffold, build, verify. The path comes from the user. | yes | yes | yes |
| `project-design` | Design docs playbook — the `docs/` tree written before implementation. | yes | yes | yes |
| `review-feature` | Review a branch or commit against its own intent: spec, test plan, per-requirement verdict. | yes | yes | yes |
| `org-chart` | Hiring playbook — agent file format, validation, and file locations. | yes | yes | yes |
| `private-search` | Web search through the user's private SearXNG instance. | yes | yes | yes |

## Commands

| Command | Agent | What it does | opencode | Claude Code | Codex |
| --- | --- | --- | --- | --- | --- |
| `/webapp` | `build` | New web-app project end to end. | yes | yes | skill `webapp-design` |
| `/design` | `plan` | Project design docs tree. | yes | yes | skill `design` |
| `/docs` | `build` | Generate or refresh project docs. | yes | yes | skill `docs` |
| `/hire` | `ai` | Interview and hire agents. | yes | yes | skill `hire` |
| `/implement` | `build` | Route code work to the right engineer. | yes | yes | skill `implement` |
| `/review` | `build` | Review changes before they land. | yes | yes | skill `review-feature` |
| `/testarch` | `tester` | Test architecture, then write and run tests. | yes | yes | skill `testarch` |

Codex has no slash-command format, so each command is carried as a skill under
`codex/skills/` and appears in its `/` menu.
