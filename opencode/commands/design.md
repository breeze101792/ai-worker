---
description: Write the project design docs before any implementation — a structured docs/ folder tree (requirements, architecture, contracts, testing, operations, plus optional folders) instead of a single file. Use when a new project or feature needs its design pinned down, or when the design docs must be created or revised before implementation.
agent: plan
---

Write the project design docs set. Scope: $ARGUMENTS — if empty, use the current project.

Take a domain profile — `embedded`, `web`, `cli`, or `library`. If the profile is not given, infer it from the current project and ask if it is ambiguous.

Load the `project-design` skill and follow it as the checklist. Survey the project first — manifests, source, and existing docs — and never guess structure.

Dispatch the Plan-department specialists for the deep sections, then assemble and write the docs yourself:

- `product-designer` — requirements, scope, and flows (`requirements/`).
- `architect` — architecture, modules, contracts, and data model.
- `ui-designer` — the `ui/` folder when one exists.
- `researcher` — when a fact must be established.
- `challenger` — attack the finished draft before it is called done.

You assemble and write the docs yourself. Never offload the writing to a subagent.

The deliverable is the `docs/` folder tree, NOT a single file. Write `docs/README.md` as the one entry point, with the required folders beneath it: `requirements/`, `architecture/`, `contracts/`, `testing/`, and `operations/`. Instantiate the optional folders — `ui/`, `security/`, `reference/`, `research/`, `hardware/` — only when their trigger fires. Do not scaffold optional folders empty.

## Guardrails

- One entry point: `docs/README.md`. Do not create a separate `docs/DESIGN.md`.
- Never edit source code. This command produces documentation only.
- Never invent a requirement the user did not state or imply. Mark assumptions as assumptions.
- Mark a required section "Not applicable — <reason>" rather than padding it.
- Ask when a decision is genuinely ambiguous rather than guessing.
- The doc set must be complete before implementation starts.
- Do not commit; only commit when the user explicitly asks.
- Report the tree written and any open questions left for the user.
