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
| Software | `architect`, `challenger`, `code-reviewer`, `debugger`, `firmware-engineer`, `python-engineer`, `security-reviewer`, `web-engineer`, `toolchain-engineer` |
| Test | `tester`, `hil-tester` |
| Design | `product-designer`, `ui-designer` |

The HR department (`hr`, `recruiter`) sits outside the build department and runs
hiring. See `Teams.md` for models and permissions, and the `org-chart` skill for
the hiring pipeline.

## How to use each tool

The org is the same everywhere, but each tool exposes it differently.

### opencode

- **Primary agents** — press **Tab** to cycle between `build` (default,
  department head), `plan` (co-leader, read-only), and `hr`.
- **Subagents** — type `@` and the agent name to invoke one directly, e.g.
  `@researcher find the errata for this part`. Primary agents also dispatch
  subagents automatically via the `task` tool.
- **Commands** — type `/` for `implement`, `review`, `docs`, `hire`, `testarch`.
- **Watch a subagent** — each dispatch runs in a child session. Press
  **Leader+Down** (`session_child_first`) to enter it, **Right**/**Left** to
  cycle children, **Up** (`session_parent`) to return.

### Claude Code

- **Main agent is the department head.** Normal mode does the work; there is no
  `build` agent because the main session plays that role.
- **Planning mode is the co-leader.** Press **Shift+Tab** to toggle plan mode
  (read-only). This is Claude's equivalent of the `plan` agent. Restart-free:
  Claude Code watches `~/.claude/agents/` and picks up edits within seconds.
- **Subagents** — type `@` and the name to invoke one, or let the main agent
  delegate with the **Agent** tool (formerly Task).
- **Built-in subagents** — **Explore** (read-only codebase search), **Plan**
  (read-only research during plan mode), and **General-purpose**.
- **Commands** — type `/` for `implement`, `review`, `docs`, `hire`, `testarch`.

### Codex

- **Main agent is the department head.** There are no `build`/`plan` agents;
  the main thread leads and delegates. Built-in agents you can also use:
  `default` (general), `worker` (implementation), `explorer` (read-heavy
  codebase search).
- **Delegation is request-driven.** Codex spawns subagents when you ask
  directly or when `AGENTS.md` or a skill asks for it. Example prompts:
  - `Spawn one agent per point, wait for all of them, and summarize each result.`
  - `Delegate this in parallel: one agent for the firmware change, one for the
    Python host tool.`
- **Custom agents** live in `~/.codex/agents/*.toml` (personal) or
  `.codex/agents/*.toml` (project). Each file needs `name`, `description`, and
  `developer_instructions`. A custom agent named after a built-in overrides it.
- **Inspect threads** — run `/agent` in the CLI to switch between running agent
  threads. App and IDE show a subagents panel with Active and Done lists.
- **Commands are skills** — Codex has no custom slash commands, so `implement`,
  `review`, `docs`, `hire`, and `testarch` appear as skills in the `/` menu.
- **Permissions inherit** — subagents inherit the parent turn's sandbox and
  approval mode. Choose the permission mode under the composer before you
  delegate. Approval requests can surface from a background thread; press `o`
  to open that thread before approving.
- **Global defaults** live under `[agents]` in Codex `config.toml` (`enabled`,
  `max_concurrent_threads_per_session`, `default_subagent_model`,
  `default_subagent_reasoning_effort`). This repo does not create one; add
  `~/.codex/config.toml` only if you need to tune those defaults.

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
