# Git Workflow Docs

## Purpose

Document how humans and agents should use Git in Runlini: branch choices,
commit boundaries, validation, push behavior, and safety rules for dirty
worktrees.

## Context And Orientation

- Runlini already has agent-first guidance in `AGENTS.md`, `README.md`, and
  `PLANS.md`.
- The repo uses `main` with `origin` on GitHub.
- Agents frequently work in a dirty worktree, so Git rules must be explicit
  about not reverting unrelated changes.

## Progress

- [x] Inspect existing repo guide docs.
- [x] Add `docs/development/git-workflow.md`.
- [x] Link the Git workflow from `AGENTS.md` and `README.md`.
- [x] Run lightweight verification.
- [x] Rework the draft after collaborative decisions.

## Decisions

- Use a mixed branch strategy: small work may stay on the current branch or
  `main`, while risky or long-running work uses a short-lived branch.
- Commit boundaries follow the user request: small requests become one commit,
  while large features may split into 2-3 meaningful commits.
- `커밋해줘` means current task changes only; `전부 커밋해줘` means the full
  worktree except local/generated/secret files.
- Commit messages use Conventional Commit types with Korean summaries.
- Push remains an explicit user action, and feature branches prefer PRs.

## Implementation Steps

1. Create a development docs folder for Git workflow guidance.
2. Describe pre-commit checks, branch naming, staging rules, commit message
   style, push rules, and recovery safety.
3. Add concise links from the top-level guides.

## Validation

- `dart run tool/guardrails.dart`

## Risks Or Recovery

- If the workflow becomes too strict for fast solo iteration, keep the safety
  rules but loosen branch requirements in the docs.
