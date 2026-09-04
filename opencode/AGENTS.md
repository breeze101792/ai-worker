# AGENTS.md

> Rules for every opencode agent when they touch this project's config and agent files.

## Rules

1. **Plain English.** Write opencode markdown files in concise, accurate, plain English: short declarative sentences, no metaphors, specific words over general ones.
2. **Traditional Chinese only.** If output is Chinese, output in Traditional Chinese (zh-Hant), not Simplified Chinese. This applies to all output, not just markdown.

## Coding rules

1. **Git commit only with user approval.** Only run `git commit` after the user has explicitly recognized the result of your work. Wait for the user to confirm the result before committing.
2. **No hard-coded values.** Do not hard-code magic numbers, strings, or conditions directly in code. Extract them into named constants, configuration, or parameters.

## User

The user is Shaun, an embedded systems engineer. Weigh embedded concerns — hardware constraints, firmware, real-time behavior, toolchains, debugging on target — when he asks for help. Keep code focused on embedded systems unless he says otherwise.

## Subagents

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `architect` | Designs and reviews system architecture: hunts duplicate code, designs robust event/IPC frameworks, draws high-level blueprints, and recommends structure that prevents common bugs. Rejects overengineering — every abstraction must trace to a real requirement. | Architecture design and review before implementation. | Planning a new system or major refactor, reviewing an architecture, deduplicating shared logic, or designing an event bus or IPC layer. |
| `debugger` | Reproduces hard bugs, traces the code path, proves a root cause, applies a minimal fix, and verifies it. | Serious debugging that needs a powerful reasoning model. | A bug resists quick fixes, errors or crashes have no obvious cause, or a stack trace needs tracing to source. |
| `recruiter` | Writes valid opencode agent files from an approved shortlist. Dispatched by `hr` after approval. | Hires new team members from a spec it receives. | New subagents or primary agents are approved and need files created. |
| `tester` | Surveys the project, builds the test plan, writes tests with the project's framework, runs the suite, and reports coverage. | Test design, execution, and coverage reporting. | A test plan is needed, tests must be written or extended, or the suite must run and report coverage. |
| `ui-designer` | Designs tasteful, modern, accessible interfaces and writes handoff-ready design docs plus an HTML/CSS mockup. | Clean UI design work before code. | A website or interface should not ship with a default look and needs design tokens, layout, and component specs first. |

## Fan-out

When you run as a subagent, delegate independent subtasks to your own subagents. Fan-out keeps each subtask focused and lets them run in parallel.

1. **Decompose first.** Split the task into independent chunks, each with a clear deliverable.
2. **Delegate via the `task` tool.** Hand each chunk to the subagent best suited for it. You may only spawn `explore` (codebase exploration) or `general` (generic subtasks) — never a copy of yourself.
3. **Never re-delegate your own task.** Do not spawn a subagent for the task you were given; do it yourself. Fan-out is only for independent subtasks.
4. **Collate.** Collect each sub-subagent's result and synthesize it into your own report to the dispatcher.
5. **Stop at one level.** You may spawn sub-subagents; they may not spawn their own. Depth is capped by permission, not by luck.

## Shared knowledge

`~/projects/notebook` is our shared notebook. OpenCode and the user use it to read knowledge, write notes, and plan work together.
