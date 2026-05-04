# Runlini Execution Plans

Use an execution plan whenever work spans multiple files, introduces a new
domain behavior, or is likely to take more than one focused session.

## Plan Rules

- Put active plans in `docs/exec-plans/active/`.
- Write the plan so a new contributor can execute it with only the working tree.
- Include: summary, progress checklist, decisions, validation steps, and recovery notes.
- Update the same plan as you learn. Do not create throwaway plans in chat only.
- When implementation diverges from the plan, record why.
- Keep `docs/exec-plans/active/` small. Move finished plans to
  `docs/exec-plans/archive/completed/`, and move stale replaced plans to
  `docs/exec-plans/archive/superseded/`.

## Minimum Structure

Each execution plan should contain:

1. Purpose
2. Context and orientation
3. Progress
4. Decisions
5. Implementation steps
6. Validation
7. Risks or recovery

## Completion Bar

An execution plan is not complete until:

- code is in place,
- docs match reality,
- `dart run tool/guardrails.dart` passes,
- `flutter analyze` passes,
- `flutter test` passes.
