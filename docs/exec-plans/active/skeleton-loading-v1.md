# Runlini Skeleton Loading V1

## Summary

- Replace user-visible loading spinners with Runlini skeleton surfaces.
- Use subtle graphite shimmer on true black.
- Scope is screen/card loading states. Busy button labels remain explicit text.

## Scope

- History tab summary loading.
- Running shoe course loading.
- Detail route map configuration loading.
- Ghost selection chip summary loading.
- Settings sync status value loading.

## Decisions

- Skeletons should resemble the final layout instead of showing generic loaders.
- Errors, empty states, permission states, and busy actions stay text-first.
- `MediaQuery.disableAnimations` renders a static skeleton without shimmer.
- No external shimmer dependency is added.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
