---
name: docs
description: Scan the project and generate or update its documentation (README, docs/ folder), creating fresh docs when none exist. Invoke when the user wants documentation generated or refreshed.
---

Scan the project and generate or update its documentation (README, docs/ folder), creating fresh docs when none exist. Generate or refresh the project's documentation. Target scope comes from the user's prompt — if empty, use the current project only. This skill keeps the docs accurate and current rather than blindly rewriting.

Follow the documentation workflow end to end:

## 1. Survey

- Scan the whole project in scope. Identify modules, source files, entry points, manifests (package.json, pyproject.toml, go.mod, Cargo.toml, etc.), configs, scripts, and the public API surface. Do not guess structure from filenames alone — read what matters.
- Locate all existing documentation: README, `docs/` folder (or a differently named doc folder), inline docstrings, and any TLDR/overview docs.

## 2. Decide: update vs create

- If documentation already exists (README, docs folder, etc.), **update it** to reflect the current state of the code — do not rewrite it blindly. Preserve the documented intent, style, tone, and conventions. Close gaps, fix stale facts, and add anything missing.
- If there is no documentation at all, **create** a new `docs/` folder from scratch with the standard structure:
  - `docs/README.md` or `docs/INDEX.md` — entry point linking the modules below.
  - One focused file per major module/area (e.g. `docs/architecture.md`, `docs/api.md`, `docs/setup.md`) — keep it proportional; don't fragment a tiny project.
  - Cover: what the project does, architecture, setup/install, how to run, intended usage.

## 3. Document

- Document public APIs, data flows, entry points, config options, and any non-obvious behavior. Use concrete examples from the actual codebase, not fabricated ones.
- Cross-reference loosely-coupled information: scripts → docs, config keys → their effect, modules → entry points.
- Follow the project's existing documentation style and tone as much as is consistent across existing docs.

## 4. Verify

- Validate file references: folder/entities named in the docs must actually exist. Re-read the finished docs and self-review for stale or duplicated content.
- If a README already exists, keep its title and overall structure unless the current state genuinely contradicts it.

## Guardrails

- Never guess the project structure or API surface — scan first, write after.
- Prefer updating existing docs over recreating them; preserve the existing author voice and conventions.
- Keep docs proportional to project size: correct and rich where details matter, brief where they don't.
- Do not inject placeholder text, TODOs, or filler — every section should reflect real, verified content.
- Stop and ask when a genuinely ambiguous documentation decision (folder location, scope, tone) needs a human call.
