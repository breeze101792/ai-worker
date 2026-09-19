# Models

Models and providers are defined in `opencode.jsonc` under `provider`.
Each agent sets its `model` in its frontmatter; agents that do not set one
inherit the global default.

## Model policy

This org uses two tiers:

- **`ollama/glm-5.3:cloud`** — hard and heavy work: design, debugging,
  implementation, on-target testing, and any task that needs reasoning.
- **`ollama/deepseek-v4.1-flash:cloud`** — light work: review, test planning,
  UI design, recruiting, and the default agent.

Do not use `ollama/deepseek-v4-pro:cloud` for any agent.

## Sync rule

Change an agent's model in three places together, or the config drifts:

1. The agent's frontmatter in `agents/<name>.md`.
2. This table below (Agents by model).
3. `opencode.jsonc` `model`, when the agent inherits the global default.

When an agent stops using a model, keep a row here only if at least one
agent still uses it; otherwise remove the row.

## Default model

`ollama/deepseek-v4.1-flash:cloud`

Set by `model` in `opencode.jsonc`. Used by `build`, which does not declare its
own model.

## Agents by model

| Agent | Model |
| --- | --- |
| `build` (default) | `ollama/deepseek-v4.1-flash:cloud` |
| `plan` | `ollama/glm-5.3:cloud` |
| `architect` | `ollama/glm-5.3:cloud` |
| `toolchain-engineer` | `ollama/glm-5.3:cloud` |
| `code-reviewer` | `ollama/deepseek-v4.1-flash:cloud` |
| `debugger` | `ollama/glm-5.3:cloud` |
| `firmware-engineer` | `ollama/glm-5.3:cloud` |
| `hil-tester` | `ollama/glm-5.3:cloud` |
| `hr` | `ollama/glm-5.3:cloud` |
| `python-engineer` | `ollama/glm-5.3:cloud` |
| `product-designer` | `ollama/glm-5.3:cloud` |
| `recruiter` | `ollama/deepseek-v4.1-flash:cloud` |
| `tester` | `ollama/deepseek-v4.1-flash:cloud` |
| `ui-designer` | `ollama/deepseek-v4.1-flash:cloud` |
| `web-engineer` | `ollama/glm-5.3:cloud` |

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
