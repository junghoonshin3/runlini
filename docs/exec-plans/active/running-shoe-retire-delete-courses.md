# Running Shoe Retire, Delete, and Courses

## Purpose

Separate running-shoe `은퇴` and `삭제` so the user can either keep a shoe visible
as retired or hide it from active settings while preserving historical run
records. Add a shoe-specific courses screen that shows the runs recorded with a
shoe.

## Context and Orientation

- `RunShoe` currently has `retired` only, which cannot represent both retired
  and deleted user states.
- Run records store `shoeId`; deleting the row physically would make historical
  detail screens lose the shoe name.
- Settings UI lives in `lib/features/settings/ui`.
- Shoe persistence remains in `run_tracking` because run sessions own the
  relationship to shoes.

## Progress

- [x] Add `deleted` state to `RunShoe` and sqflite persistence.
- [x] Add `retire` and `delete` controls to the shoe list.
- [x] Keep retired shoes visible but unavailable for default selection.
- [x] Hide deleted shoes from settings while keeping historical lookup intact.
- [x] Add shoe courses screen.
- [x] Update widget/repository tests.
- [x] Add running-shoe edit flow.
- [x] Add saved-run detail shoe assignment flow.
- [x] Add optional running-shoe image selection and thumbnails.
- [x] Cache shoe form providers before async/dispose cleanup to avoid unmounted
  `ref` access.
- [x] Re-run guardrails, analyze, and tests.

## Decisions

- `은퇴`: visible in the shoe list, not selectable as the default shoe.
- `삭제`: hidden from the shoe list, internally retained for past run detail
  lookup.
- Past run records and accumulated mileage are never removed by shoe deletion.
- A shoe-specific courses screen lists saved runs where `session.shoeId` matches
  the shoe.
- Running-shoe edit reuses the add screen so brand, name, replacement distance,
  and default status can be changed without duplicating form logic.
- Saved-run detail can assign an existing active shoe or create a new shoe and
  immediately attach that record to the shoe mileage total.
- Running-shoe images are local-only. The app stores an internal file path on
  `RunShoe.imagePath` and does not sync shoe images to Health.
- Shoe form async and dispose cleanup must not call `ref.read`; cache provider
  objects in `initState` and use those fields after picker/save awaits.

## Implementation Steps

1. Add `deleted` to `RunShoe` with a default `false`.
2. Bump `runlini.db` and add `run_shoes.deleted`.
3. Add `deleteShoe` to the settings repository and controller.
4. Update settings shoe UI to show `은퇴`, `삭제`, and `코스 보기`.
5. Add `SettingsShoeCoursesScreen`.
6. Update tests and fake repositories.
7. Extend the add shoe screen into an add/edit screen.
8. Add shoe assignment from saved-run detail.
9. Add optional gallery image selection and show thumbnails in shoe list/detail.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- If old local DBs fail migration, inspect `RunliniDatabase._upgrade` and clear
  development app data only as a last resort.
- If settings UI grows too large, split shoe tiles or course list rows into
  separate files before adding more fields.
