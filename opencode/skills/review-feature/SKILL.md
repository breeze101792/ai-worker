---
name: review-feature
description: Review a feature branch or commit against its own intent — recover the goal from the code, commits, and description, restate it as a pure spec, build a test plan covering normal and edge cases, then run the branch against that plan and report a per-requirement pass/fail. Use when a feature branch or commit must be checked against what it was meant to do before it merges.
---

# Feature Review

Review a feature branch or commit against the goal it was written to achieve.
The output is a spec, a test plan, and a per-requirement verdict. This is a
review: it changes nothing in the feature's production code.

The target comes from the user's request — a branch, a commit, a range, or the
current branch if none is named. Resolve it first. If it does not resolve, ask.

## 1. Recover the intent

- Read the commit messages, the PR/MR description if one exists, the branch
  name, any linked issue or design doc, and the diff itself.
- Separate three things and label each one:
  - **Stated** — the goal written down (commit body, PR text, docs), with a citation.
  - **Inferred** — behavior the code shows that no text states, with a `file:line`.
  - **Unknown** — intent you cannot establish. Ask rather than assume.
- Read the surrounding code needed to judge the change in context, not only the diff.

## 2. Restate as a pure spec

- Write the goal as numbered, testable requirements: `REQ-1`, `REQ-2`, and so on.
- A requirement states behavior only — inputs, outputs, side effects, error
  behavior, units, timing, and ranges. No implementation detail, no file names.
- Every requirement must be individually verifiable. Split one that is not.
- List assumptions and open questions separately. Never invent a requirement the
  user or the code did not state or imply.
- If the code does more or different than the stated intent, record it as **spec
  drift** — a finding, not a requirement.

## 3. Build the test plan

- For every requirement, name cases: the normal case, the boundary case, and the
  failure or edge case.
- For embedded targets, cover the hardware-shaped edges too: overflow and wrap,
  uninitialized or erased NVM, power loss mid-write, ISR against main-context
  races, timeout and watchdog expiry, byte order, and worst-case timing.
- For each case, name how it is verified: host test, on-target (HIL), static
  analysis, or inspection. Mark any requirement with no possible verifier.
- Reuse existing tests that already cover a requirement; name them.

## 4. Run the branch against the plan

- Run the existing suite on the branch with the project's own tooling.
- Write new test code only for requirements that existing tests cannot prove.
  Keep it to the minimum that proves the requirement, following the project's
  framework and conventions.
- Never change production code to make a test pass.
- Record one verdict per requirement: PASS, FAIL, or UNPROVEN, each with the
  evidence — the test name and the log line that shows the result.

## 5. Report

- A traceability table: `REQ-N | case | verifier | PASS/FAIL/UNPROVEN`.
- Findings ranked blocker, major, minor, each with a `file:line` citation and a
  suggested fix. Separate spec mismatches from test gaps.
- Spec drift, ambiguities, and assumptions called out plainly.
- A one-line verdict: does the branch meet its intent?

## Guardrails

- Read-only on production code. The deliverable is the report plus test code.
- Never invent a requirement, a test result, or evidence.
- If the target ref is ambiguous or does not resolve, ask before reviewing.
- Review what the branch changed, not the whole repository.
- Hand any FAIL to the owning engineer; do not fix it here.
