---
description: Review code changes before they land — staged, unstaged, a commit range, or a local branch about to merge — and report ranked findings.
allowed-tools: Read, Grep, Glob, Bash, Agent
---

Review the changes described by: $ARGUMENTS — if empty, pick the default scope below. Use the `code-reviewer` subagent (Agent tool) to do the review; this command selects the scope and hands it over.

Decide what to review, in this order:

1. **Explicit target.** If `$ARGUMENTS` names a branch, a range (`a..b`), a commit, or several commits, review exactly that.
   - A single branch name means a PR-style review: the branch is the head, and the base is its merge target. Resolve the target as the repository default branch — `git symbolic-ref refs/remotes/origin/HEAD`, else `main`, else `master`. Compute the common ancestor with `git merge-base <base> <branch>` and review the full diff `<merge-base>..<branch>`.
   - If `$ARGUMENTS` gives two refs, treat them as `<head> <base>` and review `git merge-base <base> <head>` .. `<head>`.
   - For any range or branch, list the commits first (`git log --oneline <range>`) and review the change as one unit, not commit by commit.
2. **Staged changes.** Otherwise, if `git diff --cached` is non-empty, review the staged changes.
3. **Unstaged changes.** Otherwise, review the working tree with `git diff`.

Then run the code-reviewer workflow: read the diff, read the surrounding code needed to judge it in context, and report findings ranked **blocker / major / minor**, each with a `file:line` citation and a suggested fix. Call out embedded hazards where relevant. If the change is clean, say so plainly.

## Guardrails

- Never edit code — the deliverable is the review report.
- If the selected scope is empty, say so; do not invent a review.
- Ask before guessing when a ref is ambiguous or does not resolve.
- Review what changed, not the whole repository; pre-existing issues get at most a brief note.
