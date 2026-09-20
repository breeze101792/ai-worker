# Models

A note on how this org thinks about models. This is a document, not config — no
tool reads it and nothing generates from it. Agent files remain the source of
truth for the `model:` line.

## Profiles

An agent does not name a model. It names a **profile**. A profile states what
the role needs — a cost/latency tier plus required capabilities — and each tool
maps it to a real model. This is what lets one org definition work across
opencode, Claude Code, and Codex, whose models and settings differ.

| Profile | Tier | Requires | opencode model | Agents |
| --- | --- | --- | --- | --- |
| `deep` | deep | tool_call | `ollama/glm-5.3:cloud` | `architect`, `debugger` |
| `fast` | fast | tool_call | `ollama/deepseek-v4.1-flash:cloud` | `code-reviewer`, `harness-engineer`, `tester`, `recruiter`, `researcher`, `product-designer` |
| `vision` | fast | tool_call, vision | `ollama/deepseek-v4.1-flash:cloud` | `ui-designer` |
| `inherit` | — | — | no model line | `ai`, `build`, `plan`, `hr`, `challenger`, `security-reviewer`, `firmware-engineer`, `python-engineer`, `web-engineer`, `toolchain-engineer`, `hil-tester` |

- **`deep`** — strongest reasoning; slow is acceptable.
- **`fast`** — low latency and cheap.
- **`vision`** — `fast` plus a hard requirement for image input. Resolves to the
  same model as `fast` today. It exists as a guard: if the fast model is ever
  replaced by a text-only one, the mapping is visibly wrong instead of silently
  handing `ui-designer` a model that cannot see.
- **`inherit`** — no model pinned. The agent follows the session model. A
  subagent inherits the parent assistant message's model, so in a glm session an
  `inherit` agent runs glm.

Do not use `ollama/deepseek-v4-pro:cloud` for any agent.

### `deep` is expensive — spend it carefully

`glm-5.3` is the slowest and most expensive model in the org. Only two agents
carry it, and both must earn it:

- Give a `deep` agent the hard problem: the reasoning, the root cause, the
  architecture decision. That is what the cost buys.
- Do not give it mechanical work. Reproducing by hand, running the build,
  formatting, copying files, or repeating a command until something happens are
  not `deep` jobs. Route those to a `fast` or `inherit` agent, or do them in the
  main session.
- Do not add a third `deep` agent without a concrete reason. Every other role
  runs on `fast` or `inherit`, and that is deliberate.
- `debugger` diagnoses only. It names the failing file and line and the
  suggested fix; the owning engineer applies the change. Do not let the
  expensive model do the repair work.

## Per-tool resolution

| Profile | opencode | Claude Code | Codex |
| --- | --- | --- | --- |
| `deep` | `ollama/glm-5.3:cloud` | inherit session | inherit session |
| `fast` | `ollama/deepseek-v4.1-flash:cloud` | inherit session | inherit session |
| `vision` | `ollama/deepseek-v4.1-flash:cloud` | inherit session | inherit session |
| `inherit` | inherit session | inherit session | inherit session |

Claude Code and Codex agents carry no `model` key, so every profile resolves to
the session model there.

## Applying a change

`Teams.md` is the roster we edit first. From there the change flows outward:

1. Edit the affected row in `Teams.md` (roster). Pick a profile.
2. Apply the matching `model:` line to the opencode agent file, or omit it for
   `inherit`.
3. Mirror the change to `claude/agents/` and `codex/agents/` in their formats —
   no `model` key there.
4. Update the dispatch tables in each tool's rules file
   (`opencode/AGENTS.md`, `claude/CLAUDE.md`, `codex/AGENTS.md`).
5. Run `bash setup.sh link` and restart the affected tools.

There is no stamp step and no generator. The agent file carries the model; these
tables are how we agree on which model that should be.

## Capabilities

Capabilities come from the backend (`GET /api/tags` → `capabilities`).

| Model | Capabilities |
| --- | --- |
| `ollama/glm-5.3:cloud` | tool_call, reasoning |
| `ollama/deepseek-v4.1-flash:cloud` | tool_call, reasoning, vision |
| `ollama/glm-5.3-flash:cloud` | tool_call, reasoning, vision |

`glm-5.3` is text-only. `deepseek-v4.1-flash` is the default and accepts images;
its model record in `opencode.jsonc` sets `"attachment": true` so opencode sends
image parts to it.

## Available models

Defined under `provider.ollama` and `provider.Macllama` in `opencode.jsonc`.

### ollama (NAS, `http://10.31.1.9:30068/v1`)

| Model ID | Context | Output |
| --- | --- | --- |
| `deepseek-v4.1-flash:cloud` | 1048576 | 32768 |
| `deepseek-v4-flash:cloud` | 1048576 | 32768 |
| `deepseek-v4-pro:cloud` | 1048576 | 32768 |
| `glm-5.3:cloud` | 1000000 | 131072 |
| `glm-5.3-flash:cloud` | 1000000 | 131072 |
| `minimax-m3:cloud` | 524288 | 16384 |
| `kimi-k2.7-code:cloud` | 262144 | 16384 |
| `qwen3.8:latest` | 131072 | 8192 |
| `qwen3.6:35b-a3b` | 131072 | 16384 |

### Macllama (Mac, `http://10.31.6.118:51434/v1`)

| Model ID | Context | Output |
| --- | --- | --- |
| `qwen3.8:27b-mlx` | 131072 | 16384 |
| `qwen3.6:35b-mlx` | 131072 | 16384 |
