# CLAUDE.md

> Project rules and how agent configuration syncs across agent tools.

## Agent config sync

Agent definitions live in this repo and are symlinked into each tool's home so
one source stays in sync across Claude Code and opencode.

| Tool | Repo source | Installed to |
| --- | --- | --- |
| Claude Code | `claude/agents`, `claude/commands`, `claude/skills`, `claude/CLAUDE.md`, `claude/settings.json` or `claude/settings-ollama.json` | `~/.claude/...` |
| opencode | `opencode/agents`, `opencode/commands`, `opencode/skills`, `opencode/AGENTS.md`, `opencode/opencode.jsonc` | `~/.config/opencode/...` |
| Codex | `codex/agents` (TOML, converted from opencode), `codex/skills` (incl. commands converted to skills), `codex/AGENTS.md`, `codex/config.toml` | `~/.codex/agents`, `~/.agents/skills`, `~/.codex/AGENTS.md`, `~/.codex/config.toml` |

### Sync command

Run from this repo:

```bash
bash setup.sh link
```

Link only one tool with `bash setup.sh link claude`, `bash setup.sh link opencode`, or `bash setup.sh link codex`.
Add `--dry-run` to preview. `setup.sh all` also pulls the required ollama models
before linking.

Codex has no agent format matching the opencode/claude markdown, so `codex/` is a
hand-adapted copy synced via setup.sh:

- `codex/agents/*.toml` — one TOML per agent (`name`, `description`, `model`,
  `developer_instructions`). Re-convert when you edit an opencode agent; Codex
  reads only its own `.toml` agents, not opencode `.md`.
- `codex/skills/` — Codex skills, format-compatible with opencode
  (`<name>/SKILL.md` with `name`+`description`). Includes the two opencode
  skills plus `docs`/`hire`/`testarch`, which are the opencode *commands*
  converted to skills (Codex CLI has no custom slash-command format; skills
  are its documented equivalent and appear in the `/` menu). Install target is
  `~/.agents/skills`, Codex's USER skill dir (symlinks followed).
- `codex/AGENTS.md` — adapted from opencode: `task` tool → Codex `spawn_agent`,
  `explore`/`general` → built-in `explorer`; install to `~/.codex/AGENTS.md`.

Edit an agent, command, skill, or `CLAUDE.md`/`AGENTS.md` file in the repo source,
then re-run the link and **restart** the affected tool for changes to load —
config is read once at startup.

Keep the org-chart skill in `claude/skills/org-chart`, `opencode/skills/org-chart`,
and `codex/skills/org-chart` in sync when hiring, since it defines the hire
workflow for all three tools.

## Coding rules

1. **Git commit only with user approval.** Run `git commit` only after the user has explicitly recognized the result of your work. Wait for confirmation before committing. Write a descriptive commit message with a body, not a one-line summary.
2. **Never run `git push`.** Do not run `git push`, `git push --force`, or any other command that publishes commits to a remote. Pushing is always the user's action.
3. **Follow the project's coding convention.** Match the style the project already uses. For example, adopt the Linux kernel coding style in Linux code and Zephyr's conventions in Zephyr code. When in doubt, mirror nearby files.
4. **Group declarations.** Put variable and `#define` declarations in their own dedicated area, separate from executable logic, rather than scattering them mid-function or mid-file.
5. **No hard-coded values.** Do not hard-code magic numbers, strings, or conditions directly in code. Extract them into named constants, configuration, or parameters.

## Rules

1. **Plain English.** Write markdown files in concise, accurate, plain English: short declarative sentences, no metaphors, specific words over general ones.
2. **English responses.** All communication with the user must be in English. Never respond in Chinese or any other language.

## User

The user is Shaun, an embedded systems engineer. Weigh embedded concerns — hardware constraints, firmware, real-time behavior, toolchains, debugging on target — when he asks for help. Keep code focused on embedded systems unless he says otherwise.
