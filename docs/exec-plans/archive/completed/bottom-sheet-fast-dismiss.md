# Bottom Sheet Fast Dismiss

## Purpose

Make interval and ghost picker sheets dismiss quickly without changing their
full-screen-only behavior.

## Progress

- [x] Shorten modal reverse animation.
- [x] Shorten draggable snap animation.
- [x] Run focused and full validation.
- [x] Move this plan to `archive/completed/`.

## Decisions

- Keep full-screen open and no partial resting state.
- Keep status bar safe area behavior.
- Change only animation timing, not sheet content.
