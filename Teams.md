# Teams.md

> The agent company roster. This is the single source of truth for who is hired across opencode, Claude Code, and Codex. Agent definitions live in `opencode/agents/*.md` and are mirrored to `claude/agents/*.md` and `codex/agents/*.toml`.

## Org structure

```
org (user's agent company)
├── build department
│   │   build (primary)  head — execution: decompose, dispatch, collate
│   ├── Software
│   │   ├── code-reviewer      (subagent) read-only diff review
│   │   ├── debugger           (subagent) root-cause hunting
│   │   ├── firmware-engineer  (subagent) C/C++ on embedded targets
│   │   ├── python-engineer    (subagent) Python apps, tools, automation
│   │   ├── security-reviewer  (subagent) security review of code and designs
│   │   ├── web-engineer       (subagent) full-stack web, autonomous
│   │   └── toolchain-engineer (subagent) build systems, toolchain, CI, flashing
│   └── Test
│       ├── tester             (subagent) test plan and host unit/integration
│       └── hil-tester         (subagent) on-target flash, serial, timing
├── Plan department
│   │   plan (primary)  head — strategy: read-only, produces the plan
│   ├── Research
│   │   └── researcher         (subagent) facts with citations, evidence over assertion
│   ├── Architecture
│   │   ├── architect          (subagent) system design and architecture review
│   │   └── challenger         (subagent) adversarial pre-build critique of proposals
│   └── Design
│       ├── product-designer   (subagent) product & functional design
│       └── ui-designer        (subagent) visual design specs & mockups
├── AI department
│   ├── ai                     (primary)  head — discusses tooling, decides, dispatches
│   └── harness-engineer       (subagent) implements agent-tool config and MCP
└── HR department
    ├── hr                     (primary)  head of people — interviews, proposes, approves
    └── recruiter              (subagent) writes the hire file
```

`build` heads the build department and is the default agent. It owns execution
and leads the Software and Test teams. `plan` heads the Plan department: it is
read-only, works through strategy with the user, records the plan in docs, and
hands execution to `build`. The AI and HR departments sit apart, each headed by
its own primary.

The user's own work is embedded systems and Python; web apps are delegated to
`web-engineer` end to end, so that agent must verify its own output.

## Virtual teams (access matrix)

The teams are capability **pools**, not fixed reporting lines. Each primary
draws its own **virtual team** from those pools. This matrix is the source of
truth for who may dispatch whom; the tool configs are derived from it.

Pool membership:

| Pool | Agents |
| --- | --- |
| Research | `researcher` |
| Software | `code-reviewer`, `debugger`, `firmware-engineer`, `python-engineer`, `security-reviewer`, `web-engineer`, `toolchain-engineer` |
| Architecture | `architect`, `challenger` |
| AI | `harness-engineer` |
| Test | `tester`, `hil-tester` |
| Design | `product-designer`, `ui-designer` |
| HR | `recruiter` |

| Primary | Research | Software | Architecture | AI | Test | Design | HR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `build` | full | full | full | none | full | full | none |
| `plan` | full | analysis | full | none | none | analysis | none |
| `hr` | full | none | none | none | none | none | full |
| `ai` | full | none | none | full | none | none | none |

Legend:

- **full** — may dispatch any agent in the pool.
- **analysis** — may dispatch only the pool's non-writing agents:
  Software = `code-reviewer`, `security-reviewer`; Design = `product-designer`.
- **none** — may not dispatch the pool.

Primaries never dispatch other primaries, and none may dispatch itself. The
built-in `explore` and `general` agents are outside the pools and stay available
to every dispatcher.

How this is enforced per tool:

| Tool | Enforceable? | Mechanism |
| --- | --- | --- |
| opencode | Yes | `permission.task` in `opencode.jsonc`, derived from this matrix |
| Claude Code | Only for a main-thread agent | `tools: Agent(a, b)` — ignored in a subagent definition, so advisory here |
| Codex | No | `[agents]` has no per-target control, so advisory here |

opencode has no team concept of its own; the derived config names agents
individually. A glob such as `*-engineer` cannot respect a pool boundary, so
never use one for this matrix. A department groups teams for ownership; the
pools above still govern dispatch, so a department's teams are not automatically
reachable by that department's head.

## Team roster

Each agent runs a **model profile**, not a named model. The profile states what
the role needs; `Models.md` maps it to a concrete model per tool. So one org
definition works across opencode, Claude Code, and Codex even when their models
and settings differ. The profiles are:

- `deep` — strongest reasoning, slow is acceptable.
- `fast` — low latency and cheap.
- `vision` — `fast` plus a hard requirement for image input.
- `inherit` — no model pinned; follow whatever the session runs. Switch a
  session to glm and an `inherit` agent runs glm.

Claude Code and Codex agents carry no `model` key, so a profile resolves to the
session model there. See `Models.md` for the per-tool mapping.

### Leadership

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `build` | primary | `inherit` | The build department head and the default agent. Restates the goal, decomposes it, dispatches each part to the specialist who owns it, collates the results, and verifies. Keeps full tools, so it also does small single-domain work directly. | Anything that needs work done. |
| `plan` | primary | `inherit` | Head of the Plan department. Read-only strategy: consults `explore`, `architect`, `challenger`, and `researcher`, weighs options, and produces a concrete plan. Never implements. | The shape of a change should be decided before any code is written. |

`plan` leads the Plan department's Research, Architecture, and Design teams;
`build` leads Software and Test. Neither agent pins a model, so both follow the
session model. The teams under them are listed below.

### Software — build department

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `code-reviewer` | subagent | `fast` | Reviews code changes — diffs, staged changes, commits, and local branches — and reports ranked findings with file:line citations. Read-only. | A change needs review before it lands, or a commit or PR needs a sanity check. |
| `debugger` | subagent | `deep` | Reproduces hard bugs, traces the code path, proves a root cause, applies a minimal fix, and verifies it. | A bug resists quick fixes, errors or crashes have no obvious cause, or a stack trace needs tracing to source. |
| `firmware-engineer` | subagent | `inherit` | Writes bare-metal and RTOS firmware in C and C++ — drivers, ISRs, DMA, memory-mapped IO, power states. Follows kernel or Zephyr conventions. | Implementing or modifying firmware on microcontrollers, SoCs, and real-time targets. |
| `python-engineer` | subagent | `inherit` | Writes Python applications, tools, and automation. Follows PEP 8, the project's packaging and test conventions. | Implementing Python code, CLI tools, scripts, or library work. |
| `security-reviewer` | subagent | `inherit` | Reviews code and designs for security — injection, memory safety, secrets, auth, crypto, unsafe deserialization, and supply chain — and reports ranked findings with file:line citations. Read-only. | A change touches untrusted input, authentication, secrets, network or serial interfaces, or anything memory-unsafe. |
| `web-engineer` | subagent | `inherit` | Builds full-stack web apps autonomously — frontend markup, styles, and TypeScript plus the backend API. Implements `ui-designer` specs. | A web app or web feature must be implemented end to end without a human in the loop. |
| `toolchain-engineer` | subagent | `inherit` | Owns build systems and toolchains — Make, CMake, Zephyr west, cross-compilers, linker scripts, CI, flashing. Diagnoses build and link failures. | A build breaks, a toolchain must be configured, or CI and flashing need work. |

### Test — build department

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `tester` | subagent | `fast` | Surveys the project, builds the test plan, writes host tests, runs the suite, and reports coverage. | A test plan is needed, host tests must be written or extended, or the suite must run and report coverage. |
| `hil-tester` | subagent | `inherit` | Runs tests on real hardware — flashes targets, captures serial output, drives rigs, and runs on-target timing and power checks. | Tests must run on the board rather than on the host. |

### Research — Plan department

Establishes facts before anyone acts on them. Serves every domain, so it sits
under the strategy department rather than under one engineering team.

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `researcher` | subagent | `fast` | Digs original sources (datasheets, errata, vendor SDKs, official docs, upstream history) and the local code, then reports findings with citations. Separates observation from inference from assumption, and says plainly when something is not established. | A decision depends on what is actually true — a part's behavior, an API's version, a library's limits, a protocol's rules. |

### Architecture — Plan department

Technical design and adversarial review. `architect` produces the blueprint;
`challenger` attacks it before anything is built.

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `architect` | subagent | `deep` | Principal software architect. Designs and reviews system architecture, hunts duplicate code, designs event/IPC frameworks, and recommends structure that prevents bugs. Rejects overengineering. | Planning a new system or major refactor, reviewing an architecture, deduplicating shared logic, or designing an event bus or IPC layer. |
| `challenger` | subagent | `inherit` | Attacks a proposal before it is built — a plan, architecture, or spec — to find the wrong assumption, the missing case, the failure mode, and the cost. Read-only and adversarial by design; proposes no design of its own. | Before implementation, when changing course is still cheap, and the proposal must be stress-tested. |

### Design — Plan department

Product and visual design. `product-designer` defines what the product does and
why; `ui-designer` defines how it looks.

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `product-designer` | subagent | `fast` | Defines what a product should do and why — user goals, feature scope, functional flows, edge cases, and testable acceptance criteria — as handoff-ready specs for `architect`, `ui-designer`, and the engineers. Domain-agnostic: embedded, Python, and web alike. | Starting a new project or feature, before any technical or visual design. |
| `ui-designer` | subagent | `vision` | Designs tasteful, modern, accessible interfaces and writes handoff-ready design docs plus an HTML/CSS mockup for `web-engineer` to implement. | A web interface needs design tokens, layout, and component specs before implementation. |

### AI department

The tools we build with, rather than the things we build. `ai` is the primary
you discuss tooling with; it decides and dispatches `harness-engineer`.
`toolchain-engineer`, which owns the build toolchain for target code, sits in
the build department's Software team.

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `ai` | primary | `inherit` | Head of the AI department. Discusses agent tooling with the user — what MCP servers, skills, commands, and plugins the tools need — weighs options, and dispatches `harness-engineer` to implement. Does not edit config itself. | A tool needs configuring, a skill or command must be written, or an MCP server must be set up. |
| `harness-engineer` | subagent | `fast` | Owns the agent-tool configuration for opencode, Claude Code, and Codex — MCP servers, skills, slash commands, plugins, hooks, permission rules, providers, and model declarations. Validates every change against the opencode config schema. Dispatched by `ai`. | An approved tooling change needs to be implemented and validated. |

### HR department

| Agent | Mode | Model | What it does | Use when |
| --- | --- | --- | --- | --- |
| `hr` | primary | `inherit` | Head of people. Interviews the user, surveys existing agents and the project to spot team gaps, and runs the recruiting pipeline (propose → one-click approve → dispatch recruiter). | The user wants to build, staff, or expand an agent team. |
| `recruiter` | subagent | `fast` | Writes one or more valid agent files from an approved shortlist. Dispatched by `hr` after approval. | New subagents or primary agents are approved and need files created. |

Built-in agents are not listed here: opencode provides `explore` and `general`;
Codex provides `default`, `worker`, and `explorer`.

## Permissions

Only the opencode definitions carry an explicit permission block. An agent not
listed for a tool inherits the session default.

| Agent | edit | bash | Notable |
| --- | --- | --- | --- |
| `build` | allow | allow | Head of the build department; task access per the Virtual teams matrix |
| `plan` | deny (`*`) | — | Head of the Plan department; read-only, writes docs only; task access per the Virtual teams matrix |
| `hr` | allow | allow | Task access per the Virtual teams matrix; `question: allow` |
| `ai` | allow | allow | Task access per the Virtual teams matrix; `question: allow` |
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
| `harness-engineer` | allow | allow | Changes tool config, skills, commands, and MCP; dispatched by `ai` |
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
4. `hr` adds a row to the owning `AGENTS.md` dispatch table and mirrors the
   hire to the other tools' agent directories.
5. The user adds the row here, to keep this roster current.
6. Restart the affected tool — config loads once at startup.

This roster is the user's document. It is not installed into any tool and no
agent reads it at runtime; the dispatch tables are what agents read.

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
