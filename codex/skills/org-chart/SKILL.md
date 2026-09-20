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
│   │   └── code-reviewer, debugger, security-reviewer, firmware-engineer
│   │       python-engineer, web-engineer, toolchain-engineer
│   └── Test
│       └── tester, hil-tester
├── Plan department
│   ├── plan  (primary)  head — strategy, read-only
│   ├── Research
│   │   └── researcher
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

Each agent file carries its own settings; the dispatch tables in each tool's
rules file list who to call. The user's own work is embedded systems and Python;
web apps are delegated to `web-engineer` end to end. Codex has no department-head
primaries, so the main agent acts as every department head at once — build and
planning alike.

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

1. **Interview.** `ai` talks to the user: what are they building, what's
   stuck, which team member is missing. From the current project (manifests,
   source), `foundation/USER.md`, and the existing agents, propose a list of
   role(s). Never invent a tool or permission the user didn't mention.
2. **Propose.** Deliver candidate hires as a shortlist: name, role, model,
   mode, permissions, location (project or global), and the job description
   (the `developer_instructions`). Check against the existing agents — no
   duplicate names or duplicated roles.
3. **One-click approval.** Show the final shortlist plainly, then ask once with a
   single "Approve hires" option — the user clicks once and then it generates.
   Do not write a file before that click. If the user rejects with edits, adjust
   and re-confirm exactly once, then proceed.
4. **Generate.** `ai` passes the approved shortlist to the `recruiter`
   subagent via spawn_agent. The `recruiter` writes one valid `<name>.toml`
   per hire.
5. **Validate.** Re-read every written file and run the checklist below.
6. **Introduce the hire.** A hire no one can find is useless. `ai` adds one
   row to the agent roster table of the owning AGENTS.md. Row shape: name,
   what it does, purpose, use when — kept consistent with the hire file's
   `description`.
7. **Report + restart.** Show a summary and tell the user to re-run
   `bash setup.sh link codex` and restart Codex — config loads once; hires
   activate only after restart.

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
- List the existing agent files before proposing — no duplicates.
- Never overwrite an existing agent file without asking.
- Validate: `name`, `description`, and `developer_instructions` all present;
  `model` (if set) has a provider prefix; no `mode`, `permission`, or `prompt`
  keys; file name = agent name; TOML parses (`python3 -c "import tomllib; tomllib.load(open('f','rb'))"`).
- Custom agents are spawned as subagents by the main agent — keep their scope:
  one staff role, do one job per member.
- Never add personal debate; user said plain English only.
- Do not fabricate tools, permissions, or models that don't exist — omit
  `model` when in doubt so it inherits the default.
