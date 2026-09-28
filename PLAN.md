# PLAN.md — Fitting the org to a modern software development flow

## Goal

Close the SDLC-tail gaps in the agent company and remove the internal
contradictions in the docs system. No new department. The org already covers
requirements → adversarial design → architecture → implementation → review →
host/on-target verification. This plan fixes what is broken, adopts the cheap
modern-flow practices, and defers the genuine future hires until their trigger
fires.

The earlier statement "No new agent is hired" is superseded by the
`hardware-engineer` hire recorded below.

Findings came from an `architect` coverage review, a `researcher` survey of
modern SDLC practice (ISO/IEC/IEEE 12207, DORA, Zephyr release/safety docs,
MISRA/ISO 26262/IEC 61508), and a `challenger` attack of the draft.

## Phase 1 — fix what is broken

1. **Project-design skill dispatch contradiction.** The skill told `plan` to
   dispatch `tester`, `toolchain-engineer`, and `firmware-engineer`, which
   `opencode.jsonc` denies to `plan`. Removed the three bullets; added a
   "Design-time versus after-implementation ownership" section: `plan` drafts
   `testing/`, `operations/`, and `hardware/` itself, and the named owners take
   over from implementation on. (opencode/claude/codex skills + design commands)
2. **`/docs` vs `/design` tree conflict.** `/docs` could fork a parallel flat
   `docs/` structure with a competing index. Added a clause: when the
   project-design tree exists, update it in place and respect folder owners.
   (opencode/claude/codex commands and skills)
3. **Dispatch tables out of sync.** The in-flight architect/toolchain/firmware
   charter lines were not mirrored into the rules-file dispatch tables. Synced
   `opencode/AGENTS.md`, `claude/CLAUDE.md`, and `codex/AGENTS.md`.
4. **Stale `plan` prose.** `Teams.md`, `README.md`, `opencode/AGENTS.md`, and
   `opencode/agents/plan.md` listed only part of `plan`'s consult set. Fixed.

## Phase 2 — adopt the cheap modern-flow practices

5. **Licences / provenance** — `security-reviewer` now flags incompatible or
   unknown dependency licences alongside advisories; the licence decision stays
   the human's.
6. **Release artifact chain** — `toolchain-engineer` now authors CI (not just
   repairs it) and owns the release artifact chain: reproducible outputs,
   SBOM/provenance (`west spdx`), version bump, changelog, and signed tag on
   request. Tagging and pushing stay user-gated (`git push` denied, `git commit`
   asks); branch/maintenance policy is the user's decision.
7. **LTS / maintenance window / disposal** — `product-designer` now decides the
   maintenance window, update mechanism, and end-of-life policy at requirements
   time.

## Phase 3 — decide, then add

8. **Static analysis** — `tester` gained `bash: allow` and runs the project's
   static-analysis tools when the plan names analysis as a verifier, triaging
   findings. Tool setup and flags stay with `toolchain-engineer`.
9. **Performance split** — `hil-tester` tracks on-target timing/power/memory
   budgets over time; `debugger` diagnoses a regression that resists
   explanation. Measurement stays on the cheaper agent; `deep` is spent only on
   the hard analysis, per `Models.md`.
10. **OTA / fault handling** — `architect` now owns update strategy (image
    layout, rollback, signing-key lifecycle, staged rollout, and naming the
    update backend as out of firmware scope) and fault handling (watchdog,
    crash capture, log discipline). `firmware-engineer` owns the bootloader and
    firmware-side update path, implementing from `architect`'s design.
    `security-reviewer` reviews signing and rollback.

## The hardware-engineer hire

One agent was added: **`hardware-engineer`** — a new **Hardware** pool under the
**build** department. It is analysis-class: it reads and reviews schematics, PCB
layouts, RTL/Verilog, datasheets, reference designs, and errata, and reports
trade-offs; it never implements. It runs the **`vision`** profile (it must read
images), and the opencode agent pins
`ollama/deepseek-v4.1-flash:cloud`; the claude and codex agents carry no `model`
key. It owns `docs/hardware/`, moved from `firmware-engineer`, which now hands
board and target documentation to it and supplies the firmware side.

Access: `edit: {"*": deny, "docs/hardware/**": allow}`, no `bash`, and fan-out
through `explore`/`general` only. The `plan` pool grant is by omission from its
deny list; `opencode.jsonc` and the inline list in `opencode/agents/ai.md` deny
it to `ai`.

## The financial-researcher hire

One agent was added: **`financial-researcher`** — a second member of the
existing **Research** pool under the **Plan** department, with `researcher`. It
applies the org's evidence discipline to finance: it establishes what is true
from sources, then builds the financial model the decision needs. Its scope is
securities, portfolios, and markets — not project budgeting. It runs the
**`inherit`** profile, so it carries no `model` line in any tool; the claude and
codex agents carry no `model` key either.

Access: read-only on source. `edit: {"*": deny, "docs/**": allow}`, no `bash`,
and fan-out through `explore`/`general` only. It writes `docs/research/`
alongside `researcher`, which now owns that folder jointly. The Research pool is
already `full` for `build`, `plan`, and `ai`, so no `permission.task` change was
needed in `opencode.jsonc` or `opencode/agents/ai.md`.

This adds a domain beyond embedded, Python, and web: personal stock and
investment analysis.

## Deferred — future hires

No further hire now. Candidates, each with its trigger:

- **safety/compliance engineer** (MISRA C, ISO 26262, IEC 61508, DO-178C).
  Trigger: the first product Shaun commits to a safety-certified standard.
  Requirements traceability already exists in the design tree; the certification
  evidence pack (tool qualification, structural coverage, waiver records) is the
  genuinely new job.
- **fpga-engineer**, with verilator and yosys in the toolchain. Trigger: RTL
  implementation work — `hardware-engineer` reviews RTL but does not write it.
- **pcb-designer**, with KiCad. Trigger: board layout work, not just review.
- **ic-designer** (custom silicon). Trigger: a design that a standard ASIC or
  FPGA flow cannot meet.
- **release-engineering** is a distant candidate — extend
  `toolchain-engineer` until a fielded product has parallel maintenance branches
  and a signing/rollout ceremony.

## Verification

Every change here is a config, docs, or agent-file edit. Per the rules files
("verify in proportion to the change"), the check is well-formedness only:

- `codex/agents/*.toml` parse (19 files, verified with `tomllib`).
- `opencode/agents/*.md` and `claude/agents/*.md` frontmatter is balanced
  (40 files, verified).
- Restart the affected tool — config loads once at startup.
- One runtime check: after the `tester` `bash: allow` change, confirm opencode
  starts and `tester` can run a command.

---

## Deferred note — Tab order for primary agents

Unrelated to the org-fit work, kept for reference.

Goal: make the opencode Tab cycle run `build` → `plan` → `ai`. Tab order is
hard-coded (`packages/opencode/src/agent/agent.ts:336-340`), so the real order
is `build` → `ai` → `plan`. Do not pre-seed an `order` field: an unknown agent
key is promoted into `options` and sent to the provider. When upstream PR
#19127 merges, add `order` to the three agent files (`build: 1`, `plan: 2`,
`ai: 3`), then remove this note.
