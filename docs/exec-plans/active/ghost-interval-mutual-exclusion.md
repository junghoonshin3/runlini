# Ghost Interval Mutual Exclusion

## Purpose

Keep Runlini V1 training modes simple by allowing only one active mode per run:
ghost run or interval.

## Progress

- [x] Add phone prompts for ghost/interval conflicts.
- [x] Add start-time stale-state guard before countdown.
- [x] Make phone interval frames null during ghost runs.
- [x] Make Wear interval frames null during ghost runs.
- [x] Keep ghost-run TTS fully silent while preserving normal-run cues.
- [x] Add Flutter and Wear regression tests.
- [x] Run guardrails, analyze, Flutter tests, and Wear tests.

## Decisions

- Phone users resolve conflicts explicitly with a dialog.
- Wear ghost runs silently ignore interval settings for the active run.
- Persisted interval and ghost settings schemas do not change.
- Ghost-run TTS remains disabled until the policy is redesigned.
