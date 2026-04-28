# App Store Icon Assets

## Purpose

Use the generated Runlini icon as the store-ready app icon source and apply it
to Android and iOS launcher icon assets.

## Context and Orientation

- Generated image source lives under the local Codex generated image folder.
- Project-owned source artwork should live in `assets/branding/`.
- Android currently uses `@mipmap/ic_launcher`.
- iOS currently uses `ios/Runner/Assets.xcassets/AppIcon.appiconset`.

## Progress

- [x] Inspect current launcher icon setup.
- [x] Copy generated source into project assets.
- [x] Generate Android launcher icon sizes.
- [x] Generate iOS AppIcon sizes.
- [x] Document icon identity.
- [x] Run guardrails.
- [x] Run analyzer.
- [x] Run tests.

## Decisions

- Keep a project source copy at `assets/branding/runlini_app_icon_1024.png`.
- Keep a Play Store listing copy at `assets/branding/runlini_play_store_icon_512.png`.
- Do not add a launcher icon generator package for this change.
- Generate platform icon PNGs directly from the source artwork.

## Implementation Steps

1. Copy the generated icon into `assets/branding/`.
2. Resize the source for Android `mipmap-*` launcher icons.
3. Resize the source for all iOS AppIcon entries.
4. Update design docs with the icon visual rule.
5. Validate with guardrails, analyzer, and tests.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.

## Risks or Recovery

- Store artwork can be replaced by overwriting only the `assets/branding`
  source file and regenerating platform sizes.
- Existing unrelated worktree changes are intentionally left untouched.
