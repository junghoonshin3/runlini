# Ghost Run TTS V1

## Purpose

Re-enable ghost-run TTS with event-based cues that stay useful without becoming
noisy.

## Progress

- [x] Allow phone ghost runs to speak 1km summaries again.
- [x] Add phone ghost cues for stable off-route, return, crossing, and course
  completion events.
- [x] Allow Wear ghost runs to speak 1km summaries again.
- [x] Add Wear ghost cues for stable off-route, return, crossing, and course
  completion events.
- [x] Speak `고스트런 시작` once when a phone or Wear ghost run actually starts.
- [x] Add finish-gate diagnostics so near-finish tests explain why completion
  was blocked.
- [x] Keep interval cues silent during ghost runs.
- [x] Add Flutter and Wear regression tests.

## Decisions

- `음성 안내` is the TTS master switch.
- `1km 안내` controls ghost-run kilometer summaries.
- `고스트 음성` controls start, off-route, return, crossing, and completion
  cues.
- Off-route and return cues require 10 seconds of stable status.
- Ahead/behind crossing cues require 15 seconds of stable status.
- Level/contact status does not speak.
- Ghost completion speaks once and does not auto-stop the run.
- Completion thresholds stay conservative: finish proximity alone is not enough
  when accepted runner distance is below 90% of the ghost route.
