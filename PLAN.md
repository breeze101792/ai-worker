# PLAN.md — Tab order for primary agents

## Goal

Make the opencode Tab cycle run `build` → `plan` → `ai` → `hr`.

## What we found

Tab order is hard-coded. `Agent.list()` sorts by default agent first, then
alphabetically by agent ID (`packages/opencode/src/agent/agent.ts:336-340`), and
the TUI Tab cycle walks that list as-is. With no `default_agent` set in this
repo, the real order is `build` → `ai` → `hr` → `plan`. `README.md:92-94` says
`build, plan, hr, ai`, which is wrong.

There is no supported way to set the order. Agent config has no `order` field,
the TUI plugin API cannot reorder agents, and `default_agent` only pins one
agent first. Upstream issue #7372 asked for this and was closed; PR #19127 adds
an `order` field but is still open. No release ships it.

Renaming the agents would work alphabetically, but the agent ID is the filename,
so it would break 117 references plus the config keys and the other tool
mirrors. Not worth it for a Tab keystroke.

## Do not pre-seed `order`

Adding `order: N` today is not harmless. An unknown agent key is promoted into
the agent's `options` (`packages/opencode/src/config/agent.ts:77-81`), which is
merged into the provider request (`packages/opencode/src/session/llm/request.ts:89`)
and sent to the model provider. I tested this against a local mock server: the
request body contained `"order": 1`. Some providers ignore unknown fields, some
reject the request. Wait for #19127.

## Steps

1. Fix `README.md:92-94` to state the real order, `build` → `ai` → `hr` →
   `plan`, and mention the picker (`<leader>a`, `agent_list`) for jumping
   straight to an agent.
2. When #19127 merges, add `order` to the four agent files: `build: 1`,
   `plan: 2`, `ai: 3`, `hr: 4`. Then remove the note from `README.md`.

## Verify

- `grep -rn "build, plan, hr, ai" README.md` returns nothing after step 1.
- Restart opencode, press Tab four times, confirm `build → ai → hr → plan`.
- `grep -rn "order:" opencode/agents/*.md` returns nothing until #19127 lands.
