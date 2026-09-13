# AGENTS.md

> Rules for every Codex agent when they touch this project's config and agent files.

## Rules

1. **Plain English.** Write Codex config files in concise, accurate, plain English: short declarative sentences, no metaphors, specific words over general ones.
2. **English responses.** All communication with the user must be in English. Never respond in Chinese or any other language.

## Coding rules

1. **Git commit only with user approval.** Only run `git commit` after the user has explicitly recognized the result of your work. Wait for the user to confirm the result before committing.
2. **Use git commit template.** Write commit messages with the git commit template, not a one-liner. Fetch the template path with `git config --get commit.template` (or `git var GIT_COMMITTER_IDENT` for identity), then read the file it points to.
3. **Follow the project's coding convention.** Match the style the project already uses. For example, adopt the Linux kernel coding style in Linux code and Zephyr's conventions in Zephyr code. When in doubt, mirror nearby files.
4. **Group declarations.** Put variable and `#define` declarations in their own dedicated area, separate from executable logic, rather than scattering them mid-function or mid-file.
5. **No hard-coded values.** Do not hard-code magic numbers, strings, or conditions directly in code. Extract them into named constants, configuration, or parameters.

## User

The user is Shaun, an embedded systems engineer. Weigh embedded concerns — hardware constraints, firmware, real-time behavior, toolchains, debugging on target — when he asks for help. Keep code focused on embedded systems unless he says otherwise.

## Custom agents

Custom agents live in `~/.codex/agents/` as one TOML file per agent (name, description, developer_instructions). Spawn them on demand with the spawn_agent tools for specialized work.

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `architect` | Designs and reviews system architecture: hunts duplicate code, designs robust event/IPC frameworks, draws high-level blueprints, and recommends structure that prevents common bugs. Rejects overengineering — every abstraction must trace to a real requirement. | Architecture design and review before implementation. | Planning a new system or major refactor, reviewing an architecture, deduplicating shared logic, or designing an event bus or IPC layer. |
| `code-reviewer` | Reviews code changes — diffs, staged changes, commits, and local branches before merge — and reports ranked findings with file:line citations. Read-only: never edits code. | Last check before a change lands. | A change needs review before it lands, or a commit or PR needs a sanity check. |
| `debugger` | Reproduces hard bugs, traces the code path, proves a root cause, applies a minimal fix, and verifies it. | Serious debugging that needs a powerful reasoning model. | A bug resists quick fixes, errors or crashes have no obvious cause, or a stack trace needs tracing to source. |
| `recruiter` | Writes one or more valid Codex agent TOML files from an approved shortlist. Dispatched by `hr` after approval. | Hires new team members from a spec it receives. | New subagents or primary agents are approved and need files created. |
| `tester` | Surveys the project, builds the test plan, writes tests with the project's framework, runs the suite, and reports coverage. | Test design, execution, and coverage reporting. | A test plan is needed, tests must be written or extended, or the suite must run and report coverage. |
| `ui-designer` | Designs tasteful, modern, accessible interfaces and writes handoff-ready design docs plus an HTML/CSS mockup. | Clean UI design work before code. | A website or interface should not ship with a default look and needs design tokens, layout, and component specs first. |

Codex also ships built-in agents: `default` (general-purpose), `worker` (implementation), and `explorer` (read-heavy codebase exploration). Prefer `explorer` for codebase surveys, and add it where opencode-style exploration subagents would be used.

## Fan-out

When you run as an agent, delegate independent subtasks to your own custom agents. Fan-out keeps each subtask focused and lets them run in parallel.

1. **Decompose first.** Split the task into independent chunks, each with a clear deliverable.
2. **Delegate via spawn_agent.** Hand each chunk to the dedicated custom agent best suited for it. Prefer built-in `explorer` for read-heavy exploration; you may spawn generic workers for simple subtasks. Do not spawn a copy of yourself.
3. **Never re-delegate your own task.** Do not spawn an agent for the task you were given; do it yourself. Fan-out is only for independent subtasks.
4. **Collate.** Collect each spawned agent's result and synthesize it into your own report to the dispatcher.
5. **Stop at one level.** You may spawn subagents; they may not spawn their own. Depth is capped by permission, not by luck.

## Shared knowledge

`~/projects/notebook` is our shared notebook. Codex and the user use it to read knowledge, write notes, and plan work together.
