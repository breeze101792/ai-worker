# Teams.md

> The agent company roster. This is the single source of truth for who is hired across opencode, Claude Code, and Codex. Agent definitions live in `opencode/agents/*.md` and are mirrored to `claude/agents/*.md` and `codex/agents/*.toml`.

## Org structure

```
org (user's agent company)
├── build department
│   │   build (primary)  department head — execution: decompose, dispatch, collate
│   │   plan  (primary)  co-leader — strategy: read-only, produces the plan
│   ├── Research
│   │   └── researcher         (subagent) facts with citations, evidence over assertion
│   ├── Software
│   │   ├── architect          (subagent) system design and architecture review
│   │   ├── challenger         (subagent) adversarial pre-build critique of proposals
│   │   ├── code-reviewer      (subagent) read-only diff review
│   │   ├── debugger           (subagent) root-cause hunting
│   │   ├── firmware-engineer  (subagent) C/C++ on embedded targets
│   │   ├── python-engineer    (subagent) Python apps, tools, automation
│   │   ├── security-reviewer  (subagent) security review of code and designs
│   │   ├── web-engineer       (subagent) full-stack web, autonomous
│   │   └── toolchain-engineer (subagent) build systems, toolchain, CI, flashing
│   ├── Test
│   │   ├── tester             (subagent) test plan and host unit/integration
│   │   └── hil-tester         (subagent) on-target flash, serial, timing
│   └── Design
│       ├── product-designer   (subagent) product & functional design
│       └── ui-designer        (subagent) visual design specs & mockups
└── HR department
    ├── hr                     (primary)  head of people — interviews, proposes, approves
    └── recruiter              (subagent) writes the hire file
```

`build` is the department head and the default agent; it owns execution and
leads the Software, Test, and Design teams. `plan` is the co-leader: it is
read-only, works through strategy with the user, and hands execution to `build`.
The HR department sits outside the build department.

The user's own work is embedded systems and Python; web apps are delegated to
`web-engineer` end to end, so that agent must verify its own output.

## Team roster

Models below are the opencode definitions. Claude Code agents and Codex agents
carry no `model` key — they use each tool's own configured model.

### Leadership

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `build` | primary | inherited (default) | The build department head and the default agent. Restates the goal, decomposes it, dispatches each part to the specialist who owns it, collates the results, and verifies. Keeps full tools, so it also does small single-domain work directly. | Anything that needs work done. |
| `plan` | primary | inherited (default) | The co-leader. Read-only strategy: consults `explore`, `architect`, `challenger`, and `researcher`, weighs options, and produces a concrete plan. Never implements. | The shape of a change should be decided before any code is written. |

Neither agent sets a `model`, so both use opencode's default. The team under
them is listed below.

### HR department

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `hr` | primary | `ollama/glm-5.3:cloud` | Head of people. Interviews the user, surveys existing agents and the project to spot team gaps, and runs the recruiting pipeline (propose → one-click approve → dispatch recruiter). | The user wants to build, staff, or expand an agent team. |
| `recruiter` | subagent | `ollama/deepseek-v4.1-flash:cloud` | Writes one or more valid agent files from an approved shortlist. Dispatched by `hr` after approval. | New subagents or primary agents are approved and need files created. |

### Research

Establishes facts before anyone acts on them. Serves every domain, so it sits at
department level rather than under one engineering team.

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `researcher` | subagent | `ollama/glm-5.3:cloud` | Digs original sources (datasheets, errata, vendor SDKs, official docs, upstream history) and the local code, then reports findings with citations. Separates observation from inference from assumption, and says plainly when something is not established. | A decision depends on what is actually true — a part's behavior, an API's version, a library's limits, a protocol's rules. |

### Software

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `architect` | subagent | `ollama/glm-5.3:cloud` | Principal software architect. Designs and reviews system architecture, hunts duplicate code, designs event/IPC frameworks, and recommends structure that prevents bugs. Rejects overengineering. | Planning a new system or major refactor, reviewing an architecture, deduplicating shared logic, or designing an event bus or IPC layer. |
| `challenger` | subagent | `ollama/glm-5.3:cloud` | Attacks a proposal before it is built — a plan, architecture, or spec — to find the wrong assumption, the missing case, the failure mode, and the cost. Read-only and adversarial by design; proposes no design of its own. | Before implementation, when changing course is still cheap, and the proposal must be stress-tested. |
| `code-reviewer` | subagent | `ollama/deepseek-v4.1-flash:cloud` | Reviews code changes — diffs, staged changes, commits, and local branches — and reports ranked findings with file:line citations. Read-only. | A change needs review before it lands, or a commit or PR needs a sanity check. |
| `debugger` | subagent | `ollama/glm-5.3:cloud` | Reproduces hard bugs, traces the code path, proves a root cause, applies a minimal fix, and verifies it. | A bug resists quick fixes, errors or crashes have no obvious cause, or a stack trace needs tracing to source. |
| `firmware-engineer` | subagent | `ollama/glm-5.3:cloud` | Writes bare-metal and RTOS firmware in C and C++ — drivers, ISRs, DMA, memory-mapped IO, power states. Follows kernel or Zephyr conventions. | Implementing or modifying firmware on microcontrollers, SoCs, and real-time targets. |
| `python-engineer` | subagent | `ollama/glm-5.3:cloud` | Writes Python applications, tools, and automation. Follows PEP 8, the project's packaging and test conventions. | Implementing Python code, CLI tools, scripts, or library work. |
| `security-reviewer` | subagent | `ollama/glm-5.3:cloud` | Reviews code and designs for security — injection, memory safety, secrets, auth, crypto, unsafe deserialization, and supply chain — and reports ranked findings with file:line citations. Read-only. | A change touches untrusted input, authentication, secrets, network or serial interfaces, or anything memory-unsafe. |
| `web-engineer` | subagent | `ollama/glm-5.3:cloud` | Builds full-stack web apps autonomously — frontend markup, styles, and TypeScript plus the backend API. Implements `ui-designer` specs. | A web app or web feature must be implemented end to end without a human in the loop. |
| `toolchain-engineer` | subagent | `ollama/glm-5.3:cloud` | Owns build systems and toolchains — Make, CMake, Zephyr west, cross-compilers, linker scripts, CI, flashing. Diagnoses build and link failures. | A build breaks, a toolchain must be configured, or CI and flashing need work. |

### Test

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `tester` | subagent | `ollama/deepseek-v4.1-flash:cloud` | Surveys the project, builds the test plan, writes host tests, runs the suite, and reports coverage. | A test plan is needed, host tests must be written or extended, or the suite must run and report coverage. |
| `hil-tester` | subagent | `ollama/glm-5.3:cloud` | Runs tests on real hardware — flashes targets, captures serial output, drives rigs, and runs on-target timing and power checks. | Tests must run on the board rather than on the host. |

### Design

Product and visual design. `product-designer` defines what the product does and
why; `ui-designer` defines how it looks.

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `product-designer` | subagent | `ollama/glm-5.3:cloud` | Defines what a product should do and why — user goals, feature scope, functional flows, edge cases, and testable acceptance criteria — as handoff-ready specs for `architect`, `ui-designer`, and the engineers. Domain-agnostic: embedded, Python, and web alike. | Starting a new project or feature, before any technical or visual design. |
| `ui-designer` | subagent | `ollama/deepseek-v4.1-flash:cloud` | Designs tasteful, modern, accessible interfaces and writes handoff-ready design docs plus an HTML/CSS mockup for `web-engineer` to implement. | A web interface needs design tokens, layout, and component specs before implementation. |

Built-in agents are not listed here: opencode provides `explore` and `general`;
Codex provides `default`, `worker`, and `explorer`.

## Permissions

Only the opencode definitions carry an explicit permission block. An agent not
listed for a tool inherits the session default.

| Agent | edit | bash | Notable |
| --- | --- | --- | --- |
| `build` | allow | allow | Department head; `task: allow` for the whole team except `recruiter` |
| `plan` | deny (`*`) | — | Read-only; task denies the writer agents |
| `hr` | allow | allow | `task: allow`, `question: allow` |
| `recruiter` | allow | allow | Writes agent files |
| `researcher` | docs/**, README.md, AGENTS.md allow; `*` deny | — | Writes research reports only, not source |
| `architect` | docs/**, README.md, AGENTS.md allow; `*` deny | — | Writes design docs only, not source |
| `challenger` | deny | — | Read-only by design; attacks proposals, never edits |
| `code-reviewer` | deny | — | Read-only by design |
| `debugger` | allow | allow | Fixes the bug it proves |
| `firmware-engineer` | allow | allow | Builds for the real target |
| `python-engineer` | allow | allow | Runs code and tests |
| `security-reviewer` | deny | — | Read-only by design; finds security defects, never edits |
| `web-engineer` | allow | allow | Verifies its own output end to end |
| `toolchain-engineer` | allow | allow | Changes the build and CI |
| `tester` | inherited | — | Writes test code |
| `hil-tester` | allow | allow | Flashes targets; confirms board and image first |
| `product-designer` | allow (docs only) | — | Writes product and functional specs, no source |
| `ui-designer` | allow | — | Writes design docs and mockups |

All subagents are limited to fan-out through `explore` and `general`; none may
spawn a copy of themselves.

## How a hire changes the org

1. `hr` interviews the user and proposes a shortlist.
2. The user approves in one click.
3. `recruiter` writes `opencode/agents/<name>.md` (and the mirrored
   `claude/` and `codex/` file).
4. `hr` adds a row to the owning `AGENTS.md` dispatch table and updates this
   roster and `opencode/MODELS.md`.
5. Restart the affected tool — config loads once at startup.

The full pipeline and the valid agent frontmatter are defined in the
`org-chart` skill.

## Cross-tool sync

| Tool | Repo source | Installed to |
| --- | --- | --- |
| opencode | `opencode/agents`, `opencode/commands`, `opencode/skills`, `opencode/AGENTS.md`, `opencode/opencode.jsonc` | `~/.config/opencode/...` |
| Claude Code | `claude/agents`, `claude/commands`, `claude/skills`, `claude/CLAUDE.md`, `claude/settings-ollama.json` | `~/.claude/...` |
| Codex | `codex/agents`, `codex/skills`, `codex/AGENTS.md` | `~/.codex/agents`, `~/.agents/skills`, `~/.codex/AGENTS.md` |

Run `bash setup.sh link` from this repo to sync all three, or
`bash setup.sh link <tool>` for one. See `CLAUDE.md` for details.
