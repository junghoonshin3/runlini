# Ghost Interval Mutual Exclusion

## Purpose

Keep Runlini V1 training modes simple by allowing only one active mode per run:
ghost run or interval.

## Progress

- [x] Add phone prompts for ghost/interval conflicts.
- [x] Add start-time stale-state guard before countdown.
- [x] Make phone interval frames null during ghost runs.
- [x] Make Wear interval frames null during ghost runs.
- [x] Initially keep ghost-run TTS silent while preserving normal-run cues.
- [x] Add Flutter and Wear regression tests.
- [x] Run guardrails, analyze, Flutter tests, and Wear tests.

## Decisions

- Phone users resolve conflicts explicitly with a dialog.
- Wear ghost runs silently ignore interval settings for the active run.
- Persisted interval and ghost settings schemas do not change.
- Ghost-run TTS is handled by `ghost-run-live-experience-v1.md`: kilometer
  summaries and event-gated ghost speech can run, while interval speech remains
  disabled during ghost runs.
- As of 2026-05-11, interval is product-locked. Saved interval settings remain
  intact, but phone runtime and Wear sync treat interval as disabled, so
  ghost/interval conflict dialogs are bypassed while the lock is active.
