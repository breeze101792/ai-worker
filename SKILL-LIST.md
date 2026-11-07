# Skills and commands

Index of the skill and command files in this repo. The tool directories are the
source of truth; this file only indexes them. Update it when a skill or command
is added, renamed, or removed.

`bash setup.sh link --group <name>` selects the groups in the `Group` column at
link time; the default is `all`.

## Skills

| Skill | Group | What it does | opencode | Claude Code | Codex |
| --- | --- | --- | --- | --- | --- |
| `webapp-design` | web | Create a new web-app project end to end: discuss, design, scaffold, build, verify. The path comes from the user. | yes | yes | yes |
| `project-design` | core | Design docs playbook — the `docs/` tree written before implementation when a change crosses a boundary. | yes | yes | yes |
| `review-feature` | core | Review a branch or commit against its own intent: spec, test plan, per-requirement verdict. | yes | yes | yes |
| `staffing` | core | Hiring playbook — agent file format, validation, and file locations. | yes | yes | yes |
| `private-search` | core | Web search through the user's private SearXNG instance. | yes | yes | yes |

## Commands

| Command | Agent | Group | What it does | opencode | Claude Code | Codex |
| --- | --- | --- | --- | --- | --- | --- |
| `/webapp` | `build` | web | New web-app project end to end. | yes | yes | skill `webapp-design` |
| `/design` | `plan` | core | Project design docs tree. | yes | yes | skill `design` |
| `/docs` | `build` | core | Generate or refresh project docs. | yes | yes | skill `docs` |
| `/hire` | `ai` | core | Interview and hire agents. | yes | yes | skill `hire` |
| `/implement` | `build` | core | Route code work to the right engineer. | yes | yes | skill `implement` |
| `/review` | `build` | core | Review changes before they land. | yes | yes | skill `review-feature` |
| `/testarch` | `tester` | core | Test architecture, then write and run tests. | yes | yes | skill `testarch` |

Codex has no slash-command format, so each command is carried as a skill under
`codex/skills/` and appears in its `/` menu.
