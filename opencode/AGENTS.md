# AGENTS.md

> Rules for every opencode agent when they touch this project's config and agent files.

## Rules

1. **Plain English.** Write opencode markdown files in concise, accurate, plain English: short declarative sentences, no metaphors, specific words over general ones.
2. **English responses.** All communication with the user must be in English. Never respond in Chinese or any other language.

## Coding rules

1. **Git commit only with user approval.** Only run `git commit` after the user has explicitly recognized the result of your work. Wait for the user to confirm the result before committing.
2. **Use git commit template.** Write commit messages with the git commit template, not a one-liner. Fetch the template path with `git config --get commit.template` (or `git var GIT_COMMITTER_IDENT` for identity), then read the file it points to.
3. **Follow the project's coding convention.** Match the style the project already uses. For example, adopt the Linux kernel coding style in Linux code and Zephyr's conventions in Zephyr code. When in doubt, mirror nearby files.
4. **Group declarations.** Put variable and `#define` declarations in their own dedicated area, separate from executable logic, rather than scattering them mid-function or mid-file.
5. **No hard-coded values.** Do not hard-code magic numbers, strings, or conditions directly in code. Extract them into named constants, configuration, or parameters.

## User

The user is Shaun, an embedded systems engineer. Weigh embedded concerns — hardware constraints, firmware, real-time behavior, toolchains, debugging on target — when he asks for help. Keep code focused on embedded systems unless he says otherwise.

## Leadership

The build department is led by two primary agents, both defined in
`opencode/agents/`:

- **`build`** — the department head and the default agent. Owns execution:
  restates the goal, decomposes it, dispatches each part to the specialist who
  owns it, collates the results, and verifies. Keeps full tools, so it also does
  small single-domain work directly.
- **`plan`** — the co-leader. Owns strategy: read-only, consults `explore`,
  `architect`, and `code-reviewer`, and produces a concrete plan. It never
  implements; it hands execution to `build`.

The Research, Software, Test, and Design teams below sit under this department.
Route work through the department head, or dispatch a specialist directly when
the match is obvious. The AI and HR departments sit outside it, each headed by
its own primary.

Each primary draws a **virtual team**: the teams are capability pools, and who
may dispatch whom is governed by `permission.task`. If a dispatch is denied, the
pool is not in that primary's virtual team; report the denial instead of working
around it. Use `plan` when the shape of a change should be decided before
any code is written.

## Subagents

The tables below are the dispatch roster the main agent reads, grouped by team.

### Research

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `researcher` | Establishes facts before anyone acts on them — digs original sources (datasheets, errata, vendor SDKs, official docs, upstream history) and the local code, then reports findings with citations. Separates observation from inference from assumption, and says plainly when something is not established. | Established facts with evidence. | A decision depends on what is actually true — a part's behavior, an API's version, a library's limits, a protocol's rules. |

### Software

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `architect` | Designs and reviews system architecture: hunts duplicate code, designs robust event/IPC frameworks, draws high-level blueprints, and recommends structure that prevents common bugs. Rejects overengineering — every abstraction must trace to a real requirement. | Architecture design and review before implementation. | Planning a new system or major refactor, reviewing an architecture, deduplicating shared logic, or designing an event bus or IPC layer. |
| `challenger` | Attacks a proposal before it is built — a plan, architecture, or spec — to find the wrong assumption, the missing case, the failure mode, and the cost. Read-only and adversarial by design. | Adversarial critique before implementation. | The shape of a change must be stress-tested while changing course is still cheap. |
| `code-reviewer` | Reviews code changes — diffs, staged changes, commits — and reports ranked findings with file:line citations. Read-only: never edits code. | Last check before a change lands. | A change needs review before it lands, or a commit or PR needs a sanity check. |
| `debugger` | Reproduces hard bugs, traces the code path, proves a root cause, applies a minimal fix, and verifies it. | Serious debugging that needs a powerful reasoning model. | A bug resists quick fixes, errors or crashes have no obvious cause, or a stack trace needs tracing to source. |
| `firmware-engineer` | Writes bare-metal and RTOS firmware in C and C++ — drivers, ISRs, DMA, memory-mapped IO, power states — following kernel or Zephyr conventions. | Embedded implementation. | Firmware must be implemented or modified on a microcontroller, SoC, or real-time target. |
| `python-engineer` | Writes Python applications, tools, and automation following PEP 8 and the project's packaging and test conventions. | Python implementation. | Python code, CLI tools, scripts, or library work must be written or changed. |
| `security-reviewer` | Reviews code and designs for security — injection, memory safety, secrets, auth, crypto, unsafe deserialization, and supply chain — and reports ranked findings with file:line citations. Read-only. | Security check before a change lands. | A change touches untrusted input, authentication, secrets, network or serial interfaces, or anything memory-unsafe. |
| `web-engineer` | Builds full-stack web apps autonomously — frontend markup, styles, and TypeScript plus the backend API — implementing `ui-designer` specs. | Delegated web implementation. | A web app or feature must be implemented end to end without a human in the loop. |
| `toolchain-engineer` | Owns build systems and toolchains — Make, CMake, Zephyr west, cross-compilers, linker scripts, CI, flashing — and fixes build and link failures. | Build and toolchain ownership. | A build breaks, a toolchain must be configured, or CI and flashing need work. |

### Test

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `tester` | Surveys the project, builds the test plan, writes host tests, runs the suite, and reports coverage. | Host test design, execution, and coverage. | A test plan is needed, host tests must be written or extended, or the suite must run and report coverage. |
| `hil-tester` | Runs tests on real hardware — flashes targets, captures serial output, drives rigs, and runs on-target timing and power checks. | On-target test execution. | Tests must run on the board rather than on the host. |

### Design

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `product-designer` | Defines what a product should do and why — user goals, feature scope, functional flows, edge cases, and testable acceptance criteria. Domain-agnostic: embedded, Python, and web alike. | Product and functional definition before any technical or visual design. | Starting a new project or feature and the behavior, scope, or acceptance criteria must be pinned down first. |
| `ui-designer` | Designs tasteful, modern, accessible interfaces and writes handoff-ready design docs plus an HTML/CSS mockup for `web-engineer` to implement. | Clean UI design before web code. | A web interface needs design tokens, layout, and component specs first. |

### AI department

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `ai` | Head of the AI department. The agent the user discusses agent tooling with — MCP servers, skills, slash commands, plugins, hooks, permission rules, providers, and model declarations. Decides the shape of a tooling change and dispatches `harness-engineer` to implement it. | Agent-tooling owner. | A tool needs configuring, a skill or command must be written, or an MCP server must be set up. |
| `harness-engineer` | Owns the agent-tool configuration for opencode, Claude Code, and Codex — MCP servers, skills, slash commands, plugins, hooks, permission rules, providers, and model declarations. Validates every change against the opencode config schema. Dispatched by `ai`. | Agent-tool configuration. | An approved tooling change needs to be implemented and validated. |

### HR

| Agent | What it does | Purpose | Use when |
| --- | --- | --- | --- |
| `recruiter` | Writes valid opencode agent files from an approved shortlist. Dispatched by `hr` after approval. | Hires new team members from a spec it receives. | New subagents or primary agents are approved and need files created. |

## Fan-out

When you run as a subagent, delegate independent subtasks to your own subagents. Fan-out keeps each subtask focused and lets them run in parallel.

1. **Decompose first.** Split the task into independent chunks, each with a clear deliverable.
2. **Delegate via the `task` tool.** Hand each chunk to the subagent best suited for it. You may only spawn `explore` (codebase exploration) or `general` (generic subtasks) — never a copy of yourself.
3. **Never re-delegate your own task.** Do not spawn a subagent for the task you were given; do it yourself. Fan-out is only for independent subtasks.
4. **Collate.** Collect each sub-subagent's result and synthesize it into your own report to the dispatcher.
5. **Stop at one level.** You may spawn sub-subagents; they may not spawn their own. Depth is capped by permission, not by luck.

## Shared knowledge

`~/projects/notebook` is our shared notebook. OpenCode and the user use it to read knowledge, write notes, and plan work together.
