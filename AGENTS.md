# Runlini Agents Guide

Runlini is an agent-first Flutter app. Keep this file short, stable, and
discoverable. Treat it as a map, not an encyclopedia.

## Start Here

1. Read `README.md` for the repo purpose and local commands.
2. Read `ARCHITECTURE.md` before touching `lib/`.
3. Read `PLANS.md` before any multi-file feature, refactor, or debugging task.
4. Read `docs/development/git-workflow.md` before committing or pushing.
5. Treat `docs/` as the source of truth for product, design, reliability, and
   platform decisions.

## Non-Negotiables

- For multi-file work, create or update an execution plan in
  `docs/exec-plans/active/`.
- Run `dart run tool/guardrails.dart`, `flutter analyze`, and `flutter test`
  before closing a task.
- Keep the layered feature structure intact:
  `types -> repo -> service -> state -> ui`.
- Put adapters for location, health, haptics, maps, and persistence in `core/`.
- When a rule becomes recurring, encode it in docs, tests, or tooling.
- If behavior changes, update the matching doc in `docs/` in the same change.
- Commit or push only when the user explicitly asks.

## UX Defaults

- Instant readability beats information density.
- Default to true black backgrounds, sharp borders, big typography, and short text.
- Use `AppColors.voltGreen` when the runner is ahead and `AppColors.electricRed`
  when the ghost is ahead.

## Where Things Live

- `lib/app`: app bootstrapping and theme
- `lib/core`: external adapters and shared fixtures
- `lib/features`: product domains
- `tool/guardrails.dart`: mechanical structure checks
- `docs/design-docs`: design identity and core beliefs
- `docs/development`: Git and development workflow rules
- `docs/product-specs`: user-facing product plans
- `docs/platform`: platform policy and permission notes
- `docs/testing`: field-test protocol

## Quality Gates

- Prefer small, layered files over wide utility dumping grounds.
- Keep Dart files at or below 300 lines; guardrails fail anything longer.
- Avoid feature-to-feature imports unless the dependency is deliberate and documented.
