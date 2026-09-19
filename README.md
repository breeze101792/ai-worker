# claude-worker

> One source of truth for the agent setup shared by opencode, Claude Code, and
> Codex. Agent definitions, commands, skills, and rules live here and are
> symlinked into each tool's home so all three stay in sync.

## The three tools

Each tool gets its own directory in this repo. The repo is the source; the
tool's home directory holds symlinks back here.

| Tool | Repo directory | Installed to |
|------|----------------|--------------|
| opencode | `opencode/` | `~/.config/opencode/` |
| Claude Code | `claude/` | `~/.claude/` |
| Codex | `codex/` | `~/.codex/` and `~/.agents/skills/` |

What each directory contains:

| opencode | Claude Code | Codex | Content |
|----------|-------------|-------|---------|
| `agents/*.md` | `agents/*.md` | `agents/*.toml` | Agent definitions |
| `commands/*.md` | `commands/*.md` | `skills/*/SKILL.md` | Slash commands (Codex uses skills) |
| `skills/` | `skills/` | `skills/` | Skills |
| `AGENTS.md` | `CLAUDE.md` | `AGENTS.md` | Tool-wide rules and dispatch roster |
| `opencode.jsonc` | `settings-ollama.json` | — | Tool configuration |

## How the tools differ

The three tools do not share a file format, so each tool's files are hand-adapted
copies of the same content. Edit the source, then re-link and restart the tool.

- **opencode** is the richest format and the source of truth for agent design.
  Its agents use YAML frontmatter with `mode`, `model`, `permission`, and a
  markdown body that becomes the prompt. It has real primary agents, so the
  department head (`build`) and co-leader (`plan`) exist only here.
- **Claude Code** agents are markdown with `description`, `mode`, and a `tools`
  list. It has no `build`/`plan` primaries, so the main agent acts as the
  department head. Agents carry no `model` key; they use the session's model.
- **Codex** agents are TOML, one file per agent (`name`, `description`,
  `developer_instructions`). Codex has no custom slash commands, so commands are
  converted to skills. Agents carry no `model` key; they inherit Codex's model.

opencode agents set `model` explicitly, using two tiers: `glm-5.3` for hard or
heavy work and `deepseek-v4.1-flash` for light work. Claude Code and Codex agents
omit `model` and use each tool's own configured model, so we never pin another
vendor's model in their files.

## The org

The agent roster is in `Teams.md` — the single source of truth for who is hired.
The org has a build department led by two primary agents:

- **`build`** — department head and default agent. Owns execution: restate the
  goal, decompose it, dispatch each part to the right specialist, collate, and
  verify.
- **`plan`** — co-leader. Owns strategy: read-only, consults `explore`,
  `architect`, and `code-reviewer`, and produces a concrete plan. Never
  implements.

Under the build department:

| Team | Agents |
|------|--------|
| Research | `researcher` |
| Software | `architect`, `code-reviewer`, `debugger`, `firmware-engineer`, `python-engineer`, `web-engineer`, `toolchain-engineer` |
| Test | `tester`, `hil-tester` |
| Design | `product-designer`, `ui-designer` |

The HR department (`hr`, `recruiter`) sits outside the build department and runs
hiring. See `Teams.md` for models and permissions, and the `org-chart` skill for
the hiring pipeline.

## Setup and sync

```bash
# link one tool
bash setup.sh link opencode
bash setup.sh link claude
bash setup.sh link codex

# link several
bash setup.sh link opencode,claude,codex

# preview without changing anything
bash setup.sh link codex --dry-run

# pull required ollama models, then link
bash setup.sh all
```

`setup.sh link` is safe to re-run. It replaces a stale symlink, and backs up a
real file to `<path>.bak` rather than overwriting it. Adding agent files needs no
script change — it symlinks whole directories.

After linking, **restart the tool**. Configuration is read once at startup, so
new agents and rules only appear after a restart.

## Editing workflow

1. Edit the file in the repo — for agents, start with `opencode/agents/*.md`.
2. Mirror the change to `claude/agents/` and `codex/agents/` in their formats.
3. Update `Teams.md` and the dispatch tables in each tool's rules file.
4. Run `bash setup.sh link` and restart the affected tools.

`CLAUDE.md` (repo root) has the detailed sync rules per tool.

## Foundation

`foundation/` holds shared context documents — user profile, tool notes, a
bootstrap sequence, and detailed instruction files under `foundation/instructions/`.
These are reference material, not tool config.

## Tech stack

- Plain Markdown and TOML (no build step)
- Shell (`setup.sh`) for symlinking
- Ollama for local models
