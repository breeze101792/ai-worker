# CLAUDE.md

> Project rules and how agent configuration syncs across agent tools.

## Agent config sync

Agent definitions live in this repo and are symlinked into each tool's home so
one source stays in sync across Claude Code and opencode.

| Tool | Repo source | Installed to |
| --- | --- | --- |
| Claude Code | `claude/agents`, `claude/commands`, `claude/skills`, `claude/CLAUDE.md`, `claude/settings-ollama.json` | `~/.claude/...` |
| opencode | `opencode/agents`, `opencode/commands`, `opencode/skills`, `opencode/AGENTS.md`, `opencode/opencode.jsonc` | `~/.config/opencode/...` |

### Sync command

Run from this repo:

```bash
bash setup.sh link
```

Link only one tool with `bash setup.sh link claude` or `bash setup.sh link opencode`.
Add `--dry-run` to preview. `setup.sh all` also pulls the required ollama models
before linking.

Edit an agent, command, skill, or `CLAUDE.md`/`AGENTS.md` file in the repo source,
then re-run the link and **restart** the affected tool for changes to load —
config is read once at startup.

Keep the org-chart skill in `claude/skills/org-chart` and `opencode/skills/org-chart`
in sync when hiring, since it defines the hire workflow for both tools.

## Coding rules

1. **Git commit only with user approval.** Only run `git commit` after the user has explicitly recognized the result of your work. Wait for the user to confirm the result before committing.
2. **No hard-coded values.** Do not hard-code magic numbers, strings, or conditions directly in code. Extract them into named constants, configuration, or parameters.
3. **Use git commit template.** Write commit messages with the git commit template, not a one-liner. Fetch the template path with `git config --get commit.template` (or `git var GIT_COMMITTER_IDENT` for identity), then read the file it points to.

## Rules

1. **Plain English.** Write markdown files in concise, accurate, plain English: short declarative sentences, no metaphors, specific words over general ones.
2. **English responses.** All communication with the user must be in English. Never respond in Chinese or any other language.

## User

The user is Shaun, an embedded systems engineer. Weigh embedded concerns — hardware constraints, firmware, real-time behavior, toolchains, debugging on target — when he asks for help. Keep code focused on embedded systems unless he says otherwise.
