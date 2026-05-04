# Settings Shoe Management Screen

## Purpose

Move full running shoe management out of the Settings tab into a dedicated
screen, while keeping Settings focused on the current default shoe.

## Progress

- [x] Replace Settings shoe section with default shoe summary.
- [x] Add dedicated shoe management screen.
- [x] Update settings shoe tests.
- [x] Run validation.
- [x] Move this plan to `archive/completed/`.

## Decisions

- Settings shows only default shoe status and a `러닝화 관리` entry point.
- Add/edit/default/retire/delete/history actions live in the management screen.
- Existing shoe form, history screen, storage, and run detail shoe assignment
  contracts stay unchanged.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
