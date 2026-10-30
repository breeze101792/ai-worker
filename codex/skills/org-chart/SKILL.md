---
name: org-chart
description: The AI department's hiring playbook. Use when interviewing the user about hiring agents, recruiting new team members, generating a new Codex custom agent, or validating agent files. Load this skill before creating, editing, or reviewing any agent definition.
---

# Org Chart — The Agent Company

This is the constitution of the user's agent team. It describes the org, how
hiring works, and the exact, validated format every custom agent file must
follow so Codex loads cleanly.

## Org structure

```
org (user's agent company)
├── build department
│   ├── build (primary)  head — execution
│   ├── Software
│   │   └── code-reviewer, firmware-reviewer, debugger, security-reviewer,
│   │       firmware-engineer, python-engineer, web-engineer, toolchain-engineer
│   ├── Test
│   │   └── tester, hil-tester
│   └── Hardware
│       └── hardware-engineer
├── Plan department
│   ├── plan  (primary)  head — strategy, read-only
│   ├── Research
│   │   └── researcher, financial-researcher
│   ├── Architecture
│   │   └── architect, challenger
│   └── Design
│       └── product-designer, ui-designer
└── AI department
    ├── ai               (primary) head — tooling and hiring: discusses, decides, dispatches
    ├── harness-engineer (subagent) implements agent-tool config and MCP
    └── recruiter        (subagent) writes the hire file
```

The teams are capability **pools**, not fixed reporting lines. Each primary
draws a virtual team from them, governed by an access matrix of which primary
may dispatch which pool. When you hire into a pool, the hire joins every primary
whose matrix grants that pool.

The pools are Research, Software, Architecture, AI, Test, Hardware, and Design.
`build` draws all pools; `plan` draws Research, Architecture, and Design in full
and the Software and Hardware pools in analysis mode only; `ai` draws Research
and AI. `hardware-engineer` is the Hardware pool, and it is analysis-class: it
reads and reviews hardware and writes `docs/hardware/`, never source.

Each agent file carries its own settings; the dispatch tables in each tool's
rules file list who to call. The user's own work is embedded systems and Python,
with personal stock and investment analysis also in scope via
`financial-researcher`; web apps are delegated to `web-engineer` end to end.
Codex has no department-head primaries, so the main agent acts as every
department head at once — build and planning alike.

The custom agent files show what is actually installed — list the agent
directories before hiring so you never duplicate a role or a name. In Codex
each custom agent is a standalone TOML file. The dispatch roster the main agent
reads lives in AGENTS.md; keep it in sync after every hire.

## Where hires live

Codex reads custom agents from `~/.codex/agents/` (personal) or `.codex/agents/`
(project-scoped). For this org repo, hires land in `codex/agents/<name>.toml`
and are symlinked to `~/.codex/agents/`.

| Scope | Path |
|-------|------|
| Global team (this org repo) | `codex/agents/<name>.toml` -> `~/.codex/agents/` |
| Project team | `<project>/.codex/agents/<name>.toml` |

Decision rule: when the user is working inside a project (a git repo that is
not this org repo) and wants a role scoped to that project, hire at
`<project>/.codex/agents/`. When the user says "my team", "global", or wants the
role available everywhere, hire into the org repo's `codex/agents/`. When the
current working directory is the org repo itself, hire into `codex/agents/`.

The org repo can be found by locating `codex/agents/tester.toml` or by the git
remote; `/home/shaun/projects/tools/claude-worker` and
`/mnt/projects/tools/claude-worker` are the same directory.

## Valid custom agent file

A Codex custom agent `<name>.toml` lives in an agents dir. It is a TOML file,
one agent per file. The body of `developer_instructions` becomes the agent's
instructions.

```toml
name = "name"
description = "What the agent does and when to use it. One to two sentences."
developer_instructions = """
You are <name>. Write the full role definition here: job, boundaries, workflow,
guardrails.
"""
```

### Required fields (schema)

Every custom agent file must define:

- `name` — agent name Codex uses when spawning or referring to this agent. Match
  the filename for the simplest convention.
- `description` — human-facing guidance for when to use this agent. One to two
  sentences, front-load the trigger keywords.
- `developer_instructions` — core instructions that define the agent's
  behavior. The body of the role definition.

### Optional fields

You may add other supported config keys, including:

- `model` — omit it. This org's Codex agents carry no `model` key and use the
  model configured for the Codex session. The profile (`deep`, `fast`, `vision`,
  `inherit`) is how we agree on the role's cost class; every profile resolves to
  the session model here.
- `model_reasoning_effort` — one of `minimal`, `low`, `medium`, `high`, `xhigh`.
- `sandbox_mode` — `read-only`, `workspace-write`, or `danger-full-access`.
- `mcp_servers.<id>` — MCP server config for that agent.

Do NOT put `mode`, `permission`, or a `prompt` key in a Codex agent file — those
are opencode concepts and are ignored or invalid here. `developer_instructions`
IS the instructions.

## Hire workflow (the recruiting pipeline)

A hire is not one file. It is a source agent file, two mirrors, three roster
rows, a matrix entry, a model profile, and every dispatch list that names the
role. Miss one and the hire is either invisible or dispatchable when it should
not be. Do all of it in one pass.

1. **Interview.** `ai` talks to the user: what are they building, what is
   stuck, which team member is missing. Ground it in the current project
   (manifests, source), `foundation/USER.md`, and the existing agents. Never
   invent a tool or permission the user did not mention.
2. **Propose.** Deliver the hire as a shortlist: name, role, model profile,
   mode, permissions, location (project or global), and the job description
   that becomes the body. Check the existing agent files first — no duplicate
   names, no duplicate roles.
3. **One-click approval.** Put the shortlist in a `question` tool call with a
   single approve option. Write no file before that click. If the user rejects
   with edits, adjust and re-confirm exactly once, then proceed.
4. **Generate the source.** `ai` hands the approved shortlist to `recruiter`,
   which writes `opencode/agents/<name>.md`. For a global hire, the two mirrors
   are written in the same pass — `setup.sh sync` updates existing mirrors but
   never creates a missing one:
   - `claude/agents/<name>.md` — `name`, `description`, a `tools:` line, then
     the same body.
   - `codex/agents/<name>.toml` — `name`, `description`,
     `developer_instructions`.
5. **Validate.** YAML parses on every markdown file and `tomllib` on the TOML.
   `description` present on all three. No `prompt` key. File name equals the
   agent name. The body text matches across the three copies. A `model` line
   only when the profile is not `inherit`.
6. **Introduce the hire.** Add one row to the owning table in all three rules
   files: `opencode/AGENTS.md`, `claude/CLAUDE.md`, and `codex/AGENTS.md`. Row
   shape: name, what it does, purpose, use when — kept consistent with the hire
   file's `description`. For a project hire, the project's own `AGENTS.md` is
   the only roster. `recruiter` never writes roster rows.
7. **Wire the access matrix.** Three places change together:
   - `Teams.md` — the org tree, the pool membership table, the department
     roster table with its model profile, and the permission table.
   - `opencode/opencode.jsonc` — the `permission.task` block of every primary
     that must not dispatch the hire.
   - `opencode/agents/ai.md` — the same deny entries in the inline
     `permission.task` list.

   `build` needs no edit: `"*": "allow"` covers a new agent. `plan` grants
   analysis agents (reviewers, designers, hardware) by omission, so never add
   one there. The grant and its enforcement must not drift apart.
8. **Set the model profile.** Add the hire to the matching profile row in
   `Models.md`: `deep`, `fast`, `vision`, or `inherit`.
9. **Name the hire in every dispatch list.** A hire no dispatcher names is
   never called. Check each of these:
   - `opencode/agents/build.md` — the dispatch target list, and the review step.
   - `opencode/agents/plan.md` — the consulted list in the `description` and in
     the body, when `plan` may dispatch the role.
   - `README.md` — the department table and the `plan` consultation sentence.
   - The org tree in this skill, all three copies.
   - `opencode/skills/project-design/SKILL.md` and its Claude and Codex copies.
   - Any command or skill that routes work to the role: `review`,
     `implement`, `design`, `docs`, `testarch`, `review-feature`, in opencode,
     Claude, and Codex form.
   - The dispatcher an `opencode/commands/*.md` pins in its frontmatter. A
     command pinned to an agent that cannot dispatch the hire makes the routing
     rule dead text.
10. **Verify.** `bash setup.sh sync` reports `ok` for the new agent in both
    mirrors, and the hire introduced no new drift. Re-read every file you
    touched. `git status` shows only the files this hire needs.
11. **Report and restart.** Summarise what changed in one short list, then tell
    the user to restart opencode, Claude Code, and Codex — config and agent
    files load once at startup.

### Where a hire must appear

| Surface | What changes |
| --- | --- |
| `opencode/agents/<name>.md` | The hire itself; the source of truth |
| `claude/agents/<name>.md` | Mirror with a `tools:` line |
| `codex/agents/<name>.toml` | Mirror with `developer_instructions` |
| `opencode/AGENTS.md`, `claude/CLAUDE.md`, `codex/AGENTS.md` | One roster row in the owning department table |
| `Teams.md` | Org tree, pool table, roster table, permission table |
| `Models.md` | The model profile row |
| `opencode/opencode.jsonc` | `permission.task` deny entries |
| `opencode/agents/ai.md` | The same deny entries, inline |
| `opencode/agents/build.md`, `plan.md` | Dispatch target lists |
| `README.md` | Department table, `plan` consultation sentence |
| `opencode/skills/org-chart/SKILL.md` and both copies | The org tree in this skill |
| `opencode/skills/project-design/SKILL.md` and both copies | `plan` dispatch list |
| `opencode/commands/*`, `claude/commands/*`, `codex/skills/*` | Any command or skill that routes work to the role |

## Discover the existing team

The source of truth for who is already hired is the filesystem. Before
proposing or writing:

- Glob for agent files: `**/.codex/agents/**/*.toml` and the org repo's
  `codex/agents/*.toml`.
- Read the `name`, `description`, and `model` of the members you find (e.g.
  `tester`, `ai`, `recruiter` already exist — never rehire them).

Hires awaiting a restart exist only as files too — there is no separate state.

## Guardrails / hire checklist

- Load this skill first when hiring or reviewing an agent.
- A hire is registered in every surface in the table above, in one pass. A file
  left behind is a bug, not a follow-up.
- List the existing agent files before proposing — no duplicates.
- Never overwrite an existing agent file without asking.
- When the hire joins a pool, update the access matrix in `Teams.md`, the
  `permission.task` blocks in `opencode/opencode.jsonc`, and the inline
  `permission.task` deny list in `opencode/agents/ai.md` together — all three
  in the same pass. `build` needs no edit (`*: allow` covers a new agent);
  `plan` grants analysis access by omission, so never add an analysis agent
  there.
- Validate: `name`, `description`, and `developer_instructions` all present;
  `model` (if set) has a provider prefix; no `mode`, `permission`, or `prompt`
  keys; file name = agent name; TOML parses (`python3 -c "import tomllib; tomllib.load(open('f','rb'))"`).
- Custom agents are spawned as subagents by the main agent — keep their scope:
  one staff role, do one job per member.
- Never add personal debate; user said plain English only.
- Do not fabricate tools, permissions, or models that don't exist — omit
  `model` when in doubt so it inherits the default.
