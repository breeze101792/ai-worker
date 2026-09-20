---
description: Implement a feature or fix by dispatching to the right domain engineer — firmware, Python, or web — based on the task. Use when code must be written or changed and the correct specialist is not already selected.
agent: build
---

Implement the following by delegating to the domain engineer that fits: $ARGUMENTS — if empty, ask what to implement and where.

## 1. Size the request

Size the request before you route it, and state the size in one line.

- **Small** — a one-file edit, a clear bug fix, a typo, a config change. One engineer, no design stage.
- **Medium** — a bounded change inside one domain. One engineer, no design stage.
- **Large** — a new system, a public interface change, or work that spans domains. Do the design stages in step 3.

A bug fix is never a "feature". "Substantial" means a public interface change or
more than about three files — not "it felt big". When two sizes both seem to fit,
pick the smaller one and say which you picked.

## 2. Determine the domain

Inspect the target and the project before routing. Do not assume the language.

- **Firmware** — C or C++ for a microcontroller, SoC, or real-time target; drivers, ISRs, DMA, memory-mapped IO, power states. Route to `firmware-engineer`.
- **Python** — Python applications, CLI tools, scripts, libraries, automation. Route to `python-engineer`.
- **Web** — HTML/CSS/TypeScript and a backend API, regardless of framework. Route to `web-engineer`.

Read the manifests (`package.json`, `pyproject.toml`, `CMakeLists.txt`, `Kconfig`, `prj.conf`) and the nearby source to confirm the domain. If the task spans domains, split it and dispatch each part to its engineer.

## 3. Build the change

For a large request only:

- **Define the product first when it is a new project or feature.** If the behavior, scope, or acceptance criteria are not yet pinned down, dispatch to `product-designer` first, then build from its spec.
- **Design first when it is a new system or a refactor.** If the work changes architecture, boundaries, or contracts, dispatch to `architect` first, then implement from its blueprint.
- **Design source for web.** If a `ui-designer` spec or mockup exists, pass it to `web-engineer`; if the task is visual and no design exists, dispatch to `ui-designer` first.
- **Build and toolchain problems** go to `toolchain-engineer`, not the domain engineer.

Hand the chosen engineer the task, the target paths, and any design or constraints. The engineer reads the project's own conventions and makes the smallest correct change.

## 4. Verify

After the engineer reports, check the change against the task and run the project's lint, type-check, and test commands. Send it to `code-reviewer` when the request is large, or when the change touches untrusted input, authentication, secrets, or memory-unsafe code.

## Guardrails

- Never implement the change yourself in this command — dispatch to the specialist and let it work.
- Match the engineer to the real language and platform; do not send C firmware to `python-engineer` or HTML to `firmware-engineer`.
- Do not commit changes; only commit when the user explicitly asks.
- Report what was implemented, where, and what remains unverified.
