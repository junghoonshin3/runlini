# Running Shoe Add Screen

## Purpose

Move running-shoe creation out of the settings section dialog and into a
dedicated screen so gear setup has enough room for clear labels, validation,
and future fields.

## Decisions

- Settings > 러닝화 keeps the compact list and `추가` entry point.
- Tapping `추가` opens a full `러닝화 추가` screen instead of an alert dialog.
- v1 fields remain compatible with the existing `RunShoe` model:
  - brand
  - model / nickname
  - replacement distance in km
  - default shoe toggle
- First shoe still becomes the default automatically because no other default
  exists. The explicit default toggle lets a later shoe replace the current
  default.
- The screen keeps existing test keys: `shoe-brand-field`, `shoe-name-field`,
  `shoe-limit-field`, and `save-shoe-button`.
- Settings uses the user-facing word `삭제` for removing shoes. Internally this
  is a soft delete (`retired = true`) so past run records that already reference
  the shoe can keep resolving the shoe name.
- Deleted shoes disappear from the active settings list and cannot be chosen as
  the default shoe. Past accumulated mileage is not removed from run history.

## Reference Notes

- Strava gear setup uses brand, name/model, notifications, default sports, and
  separate retire/delete controls.
- Garmin gear setup focuses on brand/model, max distance, default activity
  assignment, and separate retire/delete management.
- Runlini v1 keeps only the fields already supported locally and avoids adding
  schema fields before there is a real edit/detail flow.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
