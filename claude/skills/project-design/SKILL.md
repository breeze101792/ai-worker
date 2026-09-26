---
name: project-design
description: Project design docs playbook — writes a structured docs/ folder tree before implementation, covering requirements, scope, flows, architecture overview, per-module contracts, external contracts, data model, testing with traceability, and operations, plus optional ui/security/reference/research/hardware folders. Load this skill before writing or revising a project's design docs, or when a new project or feature needs its design pinned down before implementation.
---

# Project Design — The Design Docs Playbook

This is the playbook for the project design documentation set: the docs written
before any implementation. It defines the canonical folder tree, the module
contract template, and the quality bar. Load it before writing or revising the
design docs.

## The deliverable

- A structured `docs/` folder tree at the project root. NOT a single file.
- ONE entry point: `docs/README.md`. It indexes every doc with its ID and its
  status. Do not create a separate `docs/DESIGN.md`.
- Write design BEFORE code. The doc set is the gate: implementation starts only
  after it exists.
- Write every required folder. Within one, a file whose subject does not apply
  is marked "Not applicable — <reason>" rather than padded.
- Never invent a requirement the user did not state or imply. Mark assumptions
  as assumptions.

## The folder tree

Every project gets these required folders:

```
docs/
├── README.md          the single entry point: index of every doc, its ID, its status
├── requirements/      WHAT and WHY
│   ├── requirements.md    REQ-* numbered, each individually testable
│   ├── scope.md           must-have / should-have / out-of-scope, the MVP line
│   ├── flows.md           use cases: trigger, happy path, branches, failure/recovery
│   └── features/          one file per feature
├── architecture/      HOW it is built
│   ├── overview.md        components, responsibilities, boundaries, dependency
│   │                      direction, data flow, diagram; AND the modularization
│   │                      decision (see below)
│   ├── modules/           one file per module — INTERNAL boundaries
│   ├── data-model.md      entities, fields, units, valid ranges, storage, lifetime
│   └── decisions/         ADR-*: decision, why, alternatives rejected
├── contracts/         the EDGE agreements — EXTERNAL boundaries
│   ├── api.md             REST/GraphQL (web) or host/board protocol (embedded)
│   ├── schemas.md         DB, JSON, message formats
│   ├── registers.md       register & memory map (embedded)
│   └── protocols.md       buses, framing, timing, byte order
├── testing/           HOW it is proven
│   ├── TEST_PLAN.md       strategy, host vs on-target, rigs, framework, layout
│   ├── cases.md           T-* test cases
│   └── trace.md           REQ → function → T coverage matrix
└── operations/        HOW it is built and run
    ├── build.md           toolchain, flags, commands
    ├── deploy.md          deploy / flash / release procedure
    ├── calibration.md     NVM layout, procedure, versioning
    └── repos.md           dependencies and submodules
```

### Optional folders — create only when the trigger fires

| Folder | Create when | Skip when |
| --- | --- | --- |
| `ui/` | a human interacts with it — screen, display, CLI, TUI | no user interface |
| `security/` | there is a threat surface — untrusted input, auth, secrets, network | none |
| `reference/` | code exists and needs as-built docs | design-only phase |
| `research/` | facts had to be established from sources | nothing researched |
| `hardware/` | custom board, pinout, or power/clock design | stock devkit, or no MCU |

Do NOT scaffold optional folders empty. Empty folders invite padding, which this
skill forbids.

## Module boundary vs contract boundary

`architecture/modules/` holds INTERNAL boundaries. `contracts/` holds EXTERNAL
boundaries.

Both are "contracts", which causes confusion. Use this one test:

> **Can you change both sides at the same time?**
> - **Yes** — both sides are your code → it is a **module boundary** → `architecture/modules/`
> - **No** — the other side is not yours → it is a **contract** → `contracts/`

When something spans both, SPLIT it. Never duplicate a fact in both.

- HAL — the register semantics in `contracts/registers.md`; the HAL's own
  module structure in `architecture/modules/hal.md`.
- Protocol library — the wire format in `contracts/protocols.md`; the
  library's modules in `architecture/modules/`.
- Serial CLI — the command grammar a human types in `ui/`; the
  machine-readable output format in `contracts/`.

## The module contract template

Every file in `architecture/modules/` defines BOTH sides of the module
boundary.

**Header:** purpose (one sentence) · what it MUST NOT do (its boundary) ·
dependencies and direction · state it owns and its lifetime · whether it is
internal/private.

**PROVIDES** — its public API, the only way others may reach it. For every
public function, one subsection:

```
### <function_name>

    <exact signature>

| Field | Content |
| --- | --- |
| Purpose | one sentence |
| Parameters | name; in/out; units; valid range; who owns the memory |
| Returns | every return/error code and exactly when each occurs |
| Preconditions | what must be true before the call |
| Postconditions | what is guaranteed after a successful return |
| Side effects | state it changes, other modules it notifies |
| Context | task / ISR-safe? reentrant? may it block? |
| Timing | worst-case duration, or explicitly unbounded |
```

**REQUIRES** — what it needs from other modules. Name each dependency as
`module.function()`. A module may REQUIRE only another module's PROVIDES list,
never its internals.

**OWNS** — the state it alone may touch.

**INVARIANTS** — always true regardless of call order, e.g. `count <= capacity`.

**ERRORS** — the full error-code table. One meaning per code, never reused.

**CONCURRENCY** — which context may call what; what is atomic; what needs a
lock.

**RESOURCES** — static RAM, max stack, heap use. Write "none" explicitly when
there is none.

**VERIFICATION** — clause → proof method → test ID → host or on-target. For
every clause.

Boundary rules:

- Reach a module only through its PROVIDES.
- A module may REQUIRE only another module's PROVIDES.
- Record the dependency direction. It must be acyclic.
- PROVIDES is what gets tested.

## Modularization is an explicit decision

A module is not free — a boundary costs maintenance. Create a module only when
a real trigger justifies it:

- real duplication exists
- the logic must be testable in isolation
- the logic must be portable across platforms
- multiple contributors need a boundary
- a requirement demands isolation, such as a real-time hot path

Do NOT create a module for tidiness. Every abstraction must trace to a named
requirement or to real duplicated code (YAGNI).

`architecture/overview.md` states the modularization decision explicitly:
either the module list, or "single module; no internal boundaries needed —
<reason>". A small project with zero module files is a PASSING design, not a
gap.

## Proof and traceability

A document alone cannot prove software works. Only execution can. A contract
clause is a claim; a test is what falsifies or confirms it.

Three artifacts, all required:

- the contract — in `architecture/modules/`
- the proof — tests in the project's own test layout
- the trace — `testing/trace.md`

Rule: **every contract clause names how it is verified, or is explicitly marked
`unverified`.** Unverified is allowed. Silently unverified is forbidden.

| Method | Proves | Cannot prove |
| --- | --- | --- |
| host unit test | logic, error codes, ranges, invariants | timing, real registers, ISR behaviour |
| integration + mock | module boundaries, bus failure paths | real silicon quirks |
| on-target / HIL | timing, power, register behaviour, boot | rare races |
| static analysis | a bug class is absent | that the logic is right |
| inspection / review | intent vs implementation | anything untested |

## ID scheme

Prefixes are stable and never reused:

| Prefix | Meaning |
| --- | --- |
| `REQ-<AREA>-NNN` | requirement |
| `MOD-NNNN` | module |
| `IF-NNNN` | contract / interface |
| `T-NNNN` | test |
| `ADR-NNNN` | decision |
| `RISK-NNNN` | risk |
| `ERR-<PART>-NNN` | erratum workaround |

`testing/trace.md` answers two questions in one glance:

- Does every REQ have a proving T?
- Does every T trace to a REQ?

A test with no requirement is scope creep. A requirement with no test is an
unkeepable promise.

## Domain profiles

The tree shape never changes. Only the leaves change. `/design` takes a
`--profile` (or infers it):

| Folder | embedded | web | cli | library |
| --- | --- | --- | --- | --- |
| `requirements/` | device behaviour | features, user stories | command behaviour | API behaviour |
| `architecture/` | drivers, ISRs, tasks | services, components, data layer | command dispatch, io | modules, parsing |
| `contracts/` | registers, protocols, ICD | REST, schemas, events | args, exit codes, formats | public API, ABI, semver |
| `testing/` | host + HIL, timing, power | unit, integration, E2E | golden files, exit codes | API contract tests |
| `operations/` | build, flash, calibrate | build, deploy, migrate | package, release | publish, version |
| `hardware/` *(opt)* | MCU, pins, power | — dropped | — dropped | — dropped |
| `ui/` *(opt)* | display, controls, CLI | screens, tokens, a11y | TUI, help text | — dropped |

## The workflow

1. Determine the domain profile and the project scope.
2. Survey the project first — manifests, source, existing docs. Never guess
   structure.
3. Decide the modularization answer. Justify each module. Cut every module that
   no trigger justifies.
4. Write the required folders. Instantiate optional folders only on trigger.
5. For each module, write the PROVIDES/REQUIRES contract with its verification
   map.
6. Write `testing/trace.md` mapping every REQ to a T and back.
7. Hand the draft to `challenger` before calling it done.
8. Keep the doc set complete before implementation starts.

## Quality bar

- One entry point: `docs/README.md`. No separate `docs/DESIGN.md`.
- Every requirement numbered and individually testable. No "fast", no
  "user-friendly".
- Every number carries units and a source.
- Every contract clause has a verifier or is marked `unverified`.
- Prefer tables over prose.
- Cite `file:line`, datasheets, or doc URLs where a fact came from somewhere.
- Keep a running decision log and an open-questions list rather than guessing.

## Who writes it

Claude Code has no `plan` primary, so the main agent adopts the
Plan-department posture: read-only planning, no source edits. It authors and
assembles the docs. It consults the specialists for the deep sections, then
writes the final text itself:

- `product-designer` — requirements, scope, and flows (`requirements/`).
- `architect` — architecture, modules, contracts, and data model.
- `ui-designer` — the `ui/` folder when one exists.
- `researcher` — when a fact must be established.
- `challenger` — attack the finished draft before it is called done.

The main agent never offloads the writing to a subagent. It collects each
specialist's findings and writes the `docs/` tree itself.

## Guardrails

- One entry point: `docs/README.md`. Do not create a separate `docs/DESIGN.md`.
- Write design BEFORE code. The doc set is the gate.
- A folder with no real content is not created. Mark a required section "Not
  applicable — <reason>" rather than padding it.
- Every requirement numbered and testable. No "fast", no "user-friendly".
- Every number carries units and a source. Every contract clause has a verifier
  or is marked `unverified`.
- Never invent a requirement the user did not state or imply. Mark assumptions
  as assumptions.
- Prefer tables over prose.
- Never create a module that no trigger justifies.
- No source code edits — this produces documentation only.
- Ask when a decision is genuinely ambiguous rather than guessing.
