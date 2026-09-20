---
name: org-chart
description: The HR department playbook. Use when interviewing the user about hiring agents, recruiting new team members, generating a new opencode agent or subagent, or validating agent files. Load this skill before creating, editing, or reviewing any agent definition.
---

# Org Chart — The Agent Company

This is the constitution of the user's agent team. It describes the org, how
hiring works, and the exact, validated format every agent file must follow so
opencode starts cleanly.

## Org structure

```
org (user's agent company)
├── build department
│   ├── build (primary)  department head — execution
│   ├── plan  (primary)  co-leader — strategy, read-only
│   ├── Research
│   │   └── researcher
│   ├── Software
│   │   └── architect, challenger, code-reviewer, debugger, security-reviewer
│   │       firmware-engineer, python-engineer, web-engineer, toolchain-engineer
│   ├── Test
│   │   └── tester, hil-tester
│   └── Design
│       └── product-designer, ui-designer
├── AI department
│   ├── ai               (primary) head — discusses tooling, decides, dispatches
│   └── harness-engineer (subagent) implements agent-tool config and MCP
└── HR department
    ├── hr         (primary) head of people — interviews, proposes, approves
    └── recruiter  (subagent) — writes the hire file
```

The teams are capability **pools**, not fixed reporting lines. Each primary
draws a virtual team from them, governed by an access matrix of which primary
may dispatch which pool. When you hire into a pool, the hire joins every primary
whose matrix grants that pool.

Each agent file carries its own mode, permissions, and model line. The dispatch
tables in each tool's rules file list who to call. The user's own work is
embedded systems and Python; web apps are delegated to `web-engineer` end to
end.

The agent files show what is actually installed in this tool — list the agents
directories (glob) before hiring so you never duplicate a role or a name. The
`Subagents` table in AGENTS.md is not a second roster; it is the dispatch roster
the main agent reads to decide who to call. Keep it in sync after every hire
(see step 6 of the pipeline).

## Where hires live

| Scope | Path |
|-------|------|
| Global team (this org repo) | `opencode/agents/<name>.md` |
| Project team | `<project>/.opencode/agent/<name>.md` |

Decision rule: when the user is working inside a project (a git repo that is
not this org repo) and wants a role scoped to that project, hire at
`<project>/.opencode/agent/`. When the user says "my team", "global", or wants
the role available everywhere, hire into the org repo's `opencode/agents/`.
When the current working directory is the org repo itself, hire into
`opencode/agents/`.

The org repo can be found by locating `opencode/agents/tester.md` (glob for
it) or by the git remote; `/home/shaun/projects/tools/claude-worker` and
`/mnt/projects/tools/claude-worker` are the same directory.

## Valid agent file

An agent file `<name>.md` lives in an agents dir. It has YAML frontmatter +
a body. The body becomes the agent's prompt.

```markdown
---
description: What the agent does and when to use it. One to two sentences.
mode: subagent
model: provider/model-id
permission:
  edit: deny
---

You are <name>. Write the full role definition here: job, boundaries, workflow,
guardrails.
```

### Frontmatter allowed fields (schema)

`name, model, variant, description, mode, hidden, color, steps, options,
disable, temperature, top_p, permission`. Any other field is silently routed
into `options` — avoid it. Rules:

- `description` — required on every agent. One to two sentences, front-load
  the trigger keywords. Written to help other agents decide when to use it.
- `mode` — required. One of `primary`, `subagent`, `all`. `primary` = a
  selectable agent (needs a real model + tools). `subagent` = launched via the
  task tool; the main agent talks to the user.
- `model` — pick the profile that matches the role's cost profile, then apply
  its model. Profiles: `deep` (strongest reasoning, slow ok), `fast` (low
  latency), `vision` (`fast` plus image input), `inherit` (no model line; follow
  the session model). A pinned model carries a provider prefix:
  `provider/model`. Never use `ollama/deepseek-v4-pro:cloud`.
- `permission` — flat action or `{tool: action}` map. Needed to lock down a
  hire: e.g. `edit: deny` for pure-readers, or allow for writers.
- Do NOT put a `prompt` key in frontmatter — the body IS the prompt.

## Hire workflow (the recruiting pipeline)

1. **Interview.** `hr` talks to the user: what are they building, what's
   stuck, which team member is missing. From the current project (manifests,
   source), `foundation/USER.md`, and the existing agents, propose a list of role(s).
   Never invent a tool or permission the user didn't mention.
2. **Propose.** Deliver candidate hires as a shortlist: name, role, model,
   mode, permissions, location (project or global), and the job description
   (the body). Check against the existing agents — no duplicate names or
   duplicated roles.
3. **One-click approval.** Put the final shortlist in a `question` tool call
   with a single "Approve hires" option — the user clicks once and then it
   generates. Do not write a file before that click. If the user rejects with
   edits, adjust and re-confirm exactly once, then proceed.
4. **Generate.** `hr` passes the approved shortlist to the `recruiter`
   subagent via the task tool. The `recruiter` writes one valid `<name>.md`
   per hire.
5. **Validate.** Re-read every written file and run the checklist below.
6. **Introduce the hire.** A hire no one can find is useless. `hr` adds one
   row to the `Subagents` table of the owning AGENTS.md: the org repo's
   `opencode/AGENTS.md` for global hires, the project's root `AGENTS.md` for
   project hires. Row shape: name, what it does, purpose, use when — kept
   consistent with the hire file's `description`. The recruiter only writes
   hire files; `hr` writes the roster row.
7. **Report + restart.** Show a summary and tell the user to quit and restart
   opencode — config loads once; hires activate only after restart.

## Discover the existing team

The source of truth for who is already hired is the filesystem. Before
proposing or writing:

- Glob for agent files: `**/.opencode/agent/**/*.md`, `**/.opencode/agents/**/*.md`,
  and the org repo's `opencode/agents/*.md`.
- Read the `description`, `mode`, and `model` of the members you find (e.g.
  `tester`, `hr`, `recruiter` already exist — never rehire them).

Hires awaiting a restart exist only as files too — there is no separate state.

## Guardrails / hire checklist

- Load this skill first when hiring or reviewing an agent.
- List the existing agent files before proposing — no duplicates.
- Never overwrite an existing agent file without asking.
- Validate: mode in `primary|subagent|all`; model has a provider prefix;
  `description` present; `prompt` never a frontmatter key; file name =
  agent name (hyphen-separated); YAML parses (no unquoted `#`/`:`, consistent
  indentation, quotes on the values that contain special chars).
- Subagents run with the task tool by the main agent — keep their scope: one
  staff role, do one job per member.
- Never add personal debate; user said plain English only.
- Do not fabricate tools, permissions, or models that don't exist in the
  config — default `permission` to omit when in doubt.