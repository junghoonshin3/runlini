# Runlini Animation Rollout v1

## Goal

Apply a restrained motion system to the running, record race, history, detail, and settings flows so state changes are clearer without reducing readability during a run.

## Scope

- Add shared `RunliniMotion` timing and curve constants.
- Update skeleton shimmer and countdown to use shared motion and reduced-motion fallbacks.
- Apply local fade, size, or switcher transitions to the running tab controls, record race picker cards, history calendar and progress ring, detail route preview loading, and settings sync status.
- Keep splash static and avoid new packages.

## Success Criteria

- `MediaQuery.disableAnimations` renders static, readable UI for skeletons, countdown, dashboard expansion, and calendar transitions.
- Magic duration and curve values introduced by this work come from `RunliniMotion`.
- Existing running start, record race selection, history calendar, detail route preview, and settings sync tests keep passing.
- Focused tests cover reduced motion for skeleton and countdown.

## Verification

- `dart run tool/guardrails.dart`.
- `flutter analyze`.
- Focused Flutter tests for skeleton, countdown, record race picker, history calendar, detail route preview, and settings sync.
- Full `flutter test`.
