---
name: testarch
description: Refine or build the full test architecture for the current project, then write, run, and report the tests. Invoke when the user wants the test suite planned, written, or run.
---

Refine or build the test architecture for the targets in scope. Target scope comes from the user's prompt — if empty, use the current project only; if a comma-separated list of directories or projects is given, process them one at a time.

Work through the tester workflow. If the project already has a test architecture and the scope is narrow, you may take the partial path below instead of the full end-to-end run — decide which fits.

## 0. Partial test (only when warranted)

Take this fast path when **both** are true: the project already has a test setup (plan, suites, framework), and the scope is a specific module, unit, or buggy/broken area — not a fresh or broadly under-tested project. Do not run this path on an empty or un-established suite.

- Test the public API and the contract only — do not test private/internal functions.
- Scan only the targets in scope to see which existing tests cover them.
- Execute just those tests with the project's own tooling — do not re-plan, rewrite, or rebuild the suite.
- Report pass/fail for the affected tests and any regressions. If a targeted test fails, fix your own test code or flag a real bug, then retest only that area.
- If the scope turns out to be wider than expected (existing coverage is missing or tests are unrelated), escalate to the full workflow below.

## 1. Survey

- Scan every module, entry point, manifest, config, and README in scope. Do not guess structure.
- Identify components, public APIs, data flows, failure-prone paths, and the actual test framework/tooling already in use (package.json, pyproject.toml, go.mod, CMakeLists, etc.).
- Determine what testing already exists (test dirs, suites, CI config) versus what is missing.

## 2. Plan

- Design a proportional test architecture: unit tests for pure logic and helpers, integration tests for module boundaries and data flow, E2E for user-facing workflows. Cover edge cases, error paths, and boundary conditions — not just happy paths.
- If no test plan document exists, create one (e.g. `tests/TEST_PLAN.md`) capturing the architecture, per-module coverage matrix, and framework choices. If one exists, refine it to close gaps instead of rewriting blindly.

## 3. Build

- Implement the missing test cases following the project's framework and conventions — never assume a framework.
- Refine existing tests that are brittle, wrong, or under-covering rather than duplicating them.

## 4. Execute

- Run the suite with the project's own tooling. Fix failures caused by your own test code or infrastructure.
- Distinguish real bugs from bad tests. Do not change production code to force a pass.

## 5. Report

- Summarize per-module coverage, pass/fail counts, regressions found, and remaining thin areas.
- Flag any genuine bugs the tests surfaced and ask before changing production behavior.

## Guardrails

- Never guess a test framework — infer it from manifests and the codebase first.
- Match existing style, naming, and tooling conventions.
- A failing test is either a real bug or a bad test — diagnose which before changing anything.
- Keep the work proportional: prioritize critical paths and shared logic over trivial getters.
- Stop and ask when a design decision (framework, directory layout, scope) is genuinely ambiguous.
