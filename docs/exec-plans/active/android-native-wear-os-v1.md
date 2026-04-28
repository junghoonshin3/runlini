# Android Native Wear OS V1

## Purpose

Add the first native Wear OS app for Runlini. The watch app records an
independent run, saves a completed draft locally, and syncs that draft to the
Android phone where the Flutter app imports it as a normal local run.

## Context And Orientation

- The phone Flutter app remains the Runlini source of truth.
- Existing Dart watch contracts already model `WatchRunDraft`,
  `WatchRunSnapshot`, and `WatchRunEvent`.
- Android Wear OS is implemented as a native Gradle module under `android/`.
- V1 excludes live phone mirroring, maps, history, shoes, settings, and direct
  Health Connect writes from the watch.

## Progress

- [x] Add the `:wear` Gradle module.
- [x] Implement Wear OS run recording UI and Health Services adapter.
- [x] Persist pending watch drafts and send them with Wear OS Data Layer.
- [x] Add Android phone Data Layer receiver and Flutter method channel.
- [x] Add Dart pending draft import service and startup drain.
- [x] Add Kotlin and Dart tests.
- [x] Run validation commands.
- [x] Keep watch drafts pending until phone import ack.
- [x] Add manual Wear draft sync in Settings > 연동.
- [x] Show watch pending status and retry send action.

## Decisions

- Wear module `applicationId` stays `kr.sjh.runlini` so Data Layer package and
  signature matching works with the phone app.
- Data Layer path prefix is `/runlini/wear/drafts/`.
- Draft JSON is the existing `WatchRunDraft` wire shape with
  `platform = wearOs`.
- The phone acknowledges a draft only after the Dart import path processes it.
- Failed native inbox reads do not block app startup.
- Phone ack path is `/runlini/phone/draft_acks/{draftId}`.
- Manual phone sync belongs in Settings > 연동 only.

## Implementation Steps

1. Add Wear OS build files, manifest, launcher resources, and Kotlin sources.
2. Add Health Services reducer / controller, draft mapper, pending draft queue,
   and Data Layer sender.
3. Add phone-side `WearableListenerService`, pending file store, and
   `runlini/wear_drafts` method channel.
4. Add Dart `WearDraftInboxClient`, sync service, provider, and startup trigger.
5. Add tests for reducer, draft mapping, pending queue, and Dart import drain.
6. Add the two-phase ack flow so watch pending drafts survive Data Layer enqueue
   and are deleted only after phone import ack.
7. Add manual phone sync and watch retry controls for pending drafts.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :app:assembleDebug :wear:assembleDebug`

## Risks Or Recovery

- Wear OS dependencies may require Gradle downloads in a network-enabled run.
- Emulator validation covers UI, synthetic Health Services data, and Data Layer
  basics; real Galaxy Watch behavior remains a follow-up gate.
