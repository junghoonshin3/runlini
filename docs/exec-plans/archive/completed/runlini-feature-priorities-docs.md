# Runlini Feature Priorities Docs

## Purpose

Capture the current product feature priorities for Runlini, separate near-term
scope from later ideas, and keep the product-spec docs easy to browse.

## Context and Orientation

- The source product docs live in `docs/product-specs/`.
- The current roadmap is phase-based, but it does not spell out the concrete
  near-term feature stack for the running, ghost, and analysis experience.
- Recent product discussion clarified that live location sharing should stay out
  of the near-term scope and move into a later-feature backlog.

## Progress

- [x] Confirm where product priority docs should live
- [x] Add a near-term Runlini feature priorities doc
- [x] Add a later-features backlog doc
- [x] Update the product-spec index and roadmap links
- [x] Run guardrails, analyze, and tests

## Decisions

- Keep product docs in English to match the existing repo docs.
- Split "what we want now" from "what can wait" into separate files.
- Treat real-time location sharing as a later feature, not a near-term one.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- If later priorities shift, update the backlog doc instead of bloating the
  near-term priorities file.
