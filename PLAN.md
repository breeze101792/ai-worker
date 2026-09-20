# PLAN.md — Tab order for primary agents

## Goal

Make the opencode Tab cycle run `build` → `plan` → `ai`.

## What we found

Tab order is hard-coded. `Agent.list()` sorts by default agent first, then
alphabetically by agent ID (`packages/opencode/src/agent/agent.ts:336-340`), and
the TUI Tab cycle walks that list as-is. With no `default_agent` set in this
repo and three primaries, the real order is `build` → `ai` → `plan`.
`README.md` now states that real order.

There is no supported way to set the order. Agent config has no `order` field,
the TUI plugin API cannot reorder agents, and `default_agent` only pins one
agent first. Upstream issue #7372 asked for this and was closed; PR #19127 adds
an `order` field but is still open. No release ships it.

Renaming the agents would work alphabetically, but the agent ID is the filename,
so it would break every reference plus the config keys and the other tool
mirrors. Not worth it for a Tab keystroke.

## Do not pre-seed `order`

Adding `order: N` today is not harmless. An unknown agent key is promoted into
the agent's `options` (`packages/opencode/src/config/agent.ts:77-81`), which is
merged into the provider request (`packages/opencode/src/session/llm/request.ts:89`)
and sent to the model provider. I tested this against a local mock server: the
request body contained `"order": 1`. Some providers ignore unknown fields, some
reject the request. Wait for #19127.

## Steps

1. `README.md` states the real order, `build` → `ai` → `plan`.
2. When #19127 merges, add `order` to the three agent files: `build: 1`,
   `plan: 2`, `ai: 3`, to force the goal order `build` → `plan` → `ai`. Then
   remove this note from `README.md`.

The picker (`<leader>a`, `agent_list`) is the supported way to jump straight to
an agent today, so a wrong Tab order costs little.

## Verify

- `grep -n "Three departments" README.md` matches the new three-primary list.
- Restart opencode, press Tab three times, confirm `build → ai → plan`.
- `grep -rn "order:" opencode/agents/*.md` returns nothing until #19127 lands.
