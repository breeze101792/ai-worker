---
name: org-chart
description: The HR department playbook. Use when interviewing the user about hiring agents, recruiting new team members, generating a new agent (Claude Code or opencode), or validating agent files. Load this skill before creating, editing, or reviewing any agent definition.
---

# Org Chart — The Agent Company

This is the constitution of the user's agent team. It describes the org, how
hiring works, and the exact, validated format every agent file must follow so
the target tool (Claude Code or opencode) starts cleanly.

## Org structure

```
org (user's agent company)
├── build department
│   ├── build (primary)  department head — execution
│   ├── plan  (primary)  co-leader — strategy, read-only
│   ├── Software
│   │   └── architect, code-reviewer, debugger
│   │       firmware-engineer, python-engineer, web-engineer, toolchain-engineer
│   ├── Test
│   │   └── tester, hil-tester
│   └── Design
│       └── product-designer, ui-designer
└── HR department
    ├── hr         (primary) head of people — interviews, proposes, approves
    └── recruiter  (subagent) — writes the hire file
```

The full roster with modes, models, and permissions lives in the repo root
`Teams.md`. The user's own work is embedded systems and Python; web apps are
delegated to `web-engineer` end to end.

Agent files are the source of truth for who is hired — list the agents
directories (glob) before hiring so you never duplicate a role or a name. The
`Subagents` table in AGENTS.md is not a second source of truth; it is the
dispatch roster the main agent reads to decide who to call. Keep it in sync
after every hire.

## Where hires live

| Target tool | Scope | Path |
|-------------|-------|------|
| Claude Code | Global team (this org repo) | `claude/agents/<name>.md` |
| Claude Code | Project team | `<project>/.claude/agents/<name>.md` |
| opencode | Global team (this org repo) | `opencode/agents/<name>.md` |
| opencode | Project team | `<project>/.opencode/agent/<name>.md` |

Decision rule: when the user is working inside a project (a git repo that is
not this org repo) and wants a role scoped to that project, hire into the
project's agent directory. When the user says "my team", "global", or wants
the role available everywhere, hire into the org repo's directory for the
target tool. When the working directory is the org repo itself, hire into the
org repo's directory.

The org repo can be found by locating `opencode/agents/tester.md` (glob for
it) or by the git remote; `/home/shaun/projects/tools/claude-worker` and
`/mnt/projects/tools/claude-worker` are the same directory.

## Valid Claude Code agent file

An agent file `<name>.md` lives in an agents dir. It has YAML frontmatter +
a body. The body becomes the agent's system prompt.

```markdown
---
description: What the agent does and when to use it. One to two sentences.
mode: subagent
tools: Read, Grep, Glob, Write, Edit, Bash, Agent
---

You are <name>. Write the full role definition here: job, boundaries, workflow,
guardrails.
```

Frontmatter fields (Claude Code schema):

- `description` — required. One to two sentences, front-load the trigger
  keywords. Written to help other agents decide when to use it.
- `model` — optional. Omit it so the agent uses the model configured for the
  Claude Code session (the official/default model). Do not pin an alias unless
  the role genuinely needs a different model.
- `mode` — optional. `subagent` (= launched via Agent/task tool) is the safe
  default. `primary` for a selectable agent.
- `tools` — optional comma-separated string restricting which tools the agent
  may use. Omit to grant the default toolset. To restrict a reader, list only
  `Read, Grep, Glob`. To allow a writer, add `Write, Edit, Bash`.
- No `permission` or `prompt` keys — the body is the prompt.

## Valid opencode agent file

```markdown
---
description: What the agent does and when to use it. One to two sentences.
mode: subagent
model: provider/model-id
permission:
  edit: deny
---

You are <name>. Write the full role definition here.
```

Frontmatter fields (opencode schema): `name, model, variant, description,
mode, hidden, color, steps, options, disable, temperature, top_p, permission`.
`permission` is a flat action or `{tool: action}` map, e.g. `edit: deny` for
pure readers. Do NOT put a `prompt` key — the body is the prompt. `model` must
carry a provider prefix (`ollama/glm-5.3:cloud`).

## Hire workflow (the recruiting pipeline)

1. **Interview.** `hr` talks to the user: what are they building, what's
   stuck, which team member is missing. From the current project (manifests,
   source), `foundation/USER.md`, and the existing agents, propose a list of
   role(s). Never invent a tool, model, or permission the user didn't mention.
2. **Propose.** Deliver candidate hires as a shortlist: name, role, model,
   mode, target tool (Claude Code or opencode), permission/tools, location
   (project or global), and the job description (the body). Check against the
   existing agents in both `claude/agents/` and `opencode/agents/` — no
   duplicate names or duplicated roles.
3. **One-click approval.** Put the final shortlist in an AskUserQuestion /
   question tool call with a single "Approve hires" option — the user clicks
   once and then it generates. Do not write a file before that click. If the
   user rejects with edits, adjust and re-confirm exactly once, then proceed.
4. **Generate.** `hr` passes the approved shortlist to the `recruiter`
   subagent via the task tool. The `recruiter` writes one valid `<name>.md`
   per hire in the target tool's format.
5. **Validate.** Re-read every written file and run the checklist below.
6. **Introduce the hire.** A hire no one can find is useless. `hr` adds one
   row to the `Subagents` table of the owning AGENTS.md. Row shape: name, what
   it does, purpose, use when — kept consistent with the hire file's
   `description`. The recruiter only writes hire files; `hr` writes the roster
   row.
7. **Report + restart.** Show a summary and tell the user to quit and restart
   the target tool — config loads once; hires activate only after restart.

## Discover the existing team

The source of truth for who is already hired is the filesystem. Before
proposing or writing:

- Glob for agent files: `**/.claude/agents/**/*.md`, `claude/agents/*.md`,
  `**/.opencode/agent/**/*.md`, `**/.opencode/agents/**/*.md`, and the org
  repo's `opencode/agents/*.md`.
- Read the `description`, `mode`, and `model` of the members you find (e.g.
  `tester`, `hr`, `recruiter` already exist — never rehire them).

Hires awaiting a restart exist only as files too — there is no separate state.

## Guardrails / hire checklist

- Load this skill first when hiring or reviewing an agent.
- List the existing agent files before proposing — no duplicates.
- Never overwrite an existing agent file without asking.
- Claude Code: `model` is an alias (no provider prefix); `tools` is a
  comma-separated list; no `permission`/`prompt` keys.
- opencode: `mode` in `primary|subagent|all`; `model` has a provider prefix;
  `description` present; `prompt` never a frontmatter key.
- Both: filename = agent name (hyphen-separated); YAML parses (no unquoted
  `#`/`:`, consistent indentation, quotes on values with special chars).
- Subagents run with the task tool by the main agent — keep their scope: one
  staff role, do one job per member.
- Never add personal debate; the user said plain English only.
- Do not fabricate tools, models, or permissions that don't exist in the
  config — default to the minimal toolset when in doubt.
