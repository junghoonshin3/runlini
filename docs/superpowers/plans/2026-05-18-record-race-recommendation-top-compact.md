# Record Race Recommendation Top Compact Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show today's record race recommendation as a smaller top overlay before a run starts.

**Architecture:** Keep the existing recommendation provider, selection behavior, and empty/loading states. Move the overlay placement in `RunningTabScreen` from the lower control cluster to the top safe area, then reduce the card density in `RunRecordRaceRecommendationCard`.

**Tech Stack:** Flutter, Riverpod, Flutter widget tests.

---

### Task 1: Top Compact Recommendation Card

**Files:**
- Modify: `test/features/run_tracking/run_record_race_recommendation_card_test.dart`
- Modify: `lib/features/run_tracking/ui/running/running_tab_screen.dart`
- Modify: `lib/features/run_tracking/ui/running/run_record_race_recommendation_card.dart`

- [x] **Step 1: Write the failing widget assertion**

Add assertions to the existing recommendation test so it expects the card near the top and compact enough to avoid the lower start controls.

```dart
final top = tester.getTopLeft(
  find.byKey(const Key('record-race-recommendation-card')),
).dy;
final height = tester.getSize(
  find.byKey(const Key('record-race-recommendation-card')),
).height;

expect(top, lessThan(80));
expect(height, lessThanOrEqualTo(76));
```

- [x] **Step 2: Verify the test fails**

Run: `flutter test test/features/run_tracking/run_record_race_recommendation_card_test.dart`

Expected: Fail because the current card is positioned near the bottom or is too tall.

- [x] **Step 3: Move the overlay and tighten the card**

Move `RunRecordRaceRecommendationCard` to a `Positioned` with `top: 12`, `left: 20`, and `right: 20`. In `_RunRecordRaceRecommendationShell`, reduce max width, padding, border width, font scale, and icon size while keeping `InkWell` and existing colors.

- [x] **Step 4: Verify focused tests pass**

Run: `flutter test test/features/run_tracking/run_record_race_recommendation_card_test.dart`

Expected: Pass.

- [x] **Step 5: Run static and broader checks**

Run: `flutter analyze`

Run: `flutter test`

Expected: Both pass, or report the exact unrelated failure.

- [ ] **Step 6: Commit the logical change**

Run: `git add docs/superpowers/plans/2026-05-18-record-race-recommendation-top-compact.md checklist.md context-notes.md test/features/run_tracking/run_record_race_recommendation_card_test.dart lib/features/run_tracking/ui/running/running_tab_screen.dart lib/features/run_tracking/ui/running/run_record_race_recommendation_card.dart`

Run: `git commit -m "추천 기록 상단 compact 노출"`
