# Execution Plans

Execution plans are short-lived work logs for multi-file changes.

## Folders

- `active/`: only plans that are currently being implemented or reviewed.
- `archive/completed/`: plans whose implementation and validation are done.
- `archive/superseded/`: old broad plans replaced by narrower plans or product
  docs.

## Rules

- Do not leave completed plans in `active/`.
- When a task is done, move its plan to `archive/completed/`.
- When a plan is no longer the source of truth, move it to
  `archive/superseded/` instead of deleting it.
- New multi-file work should create one focused plan in `active/`.
