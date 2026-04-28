# Ghost Rider Entry UX

## Purpose

Move ghost activation from the dedicated settings screen into the idle running
screen so the runner can choose a ghost right before `START`.

## Progress

- [x] Replace the idle ghost settings flow with a pre-start status chip.
- [x] Keep the left `Settings` button, but convert it to a general settings
  stub.
- [x] Reuse the existing ghost session picker from the chip.
- [x] Simplify the chip to text-only `Ghost Run Off` / `Ghost Run On`.
- [x] Hide the ghost chip during countdown, running, paused, and review states.
- [x] Update widget tests and product docs.

## Validation

- [x] `dart run tool/guardrails.dart`
- [x] `flutter analyze`
- [x] `flutter test`
