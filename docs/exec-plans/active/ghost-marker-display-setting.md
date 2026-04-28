# Ghost Marker Display Setting

## Purpose

Reduce running-map noise by hiding the moving ghost marker by default while
keeping ghost comparison calculations and route preview intact.

## Context and Orientation

- `ghostRaceFrameProvider` calculates the ghost's same-elapsed-time marker
  point for comparison logic.
- `ghostAwareRunMapViewStateProvider` is the right place to decide whether the
  marker should be exposed to map surfaces.
- App settings are stored in the existing `app_settings` key/value table.

## Progress

- [x] Add `showGhostMarker` to run settings with default `false`
- [x] Persist the setting without a DB schema migration
- [x] Add a Settings tab switch under the Running section
- [x] Hide or expose `RunMapViewState.ghostMarkerPoint` from settings
- [x] Localize live ghost HUD status labels
- [x] Update tests and product docs
- [x] Run guardrails, analyzer, and tests

## Decisions

- The ghost marker is off by default.
- Ghost route polylines and live ghost gap calculations remain enabled when a
  ghost session is selected.
- Live status labels use Korean: `이기는 중`, `따라가는 중`, `접전`, `경로 이탈`.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
