# Runlini Store Screenshots Design

## Goal

Build an editable App Store and Google Play screenshot workspace for Runlini, seeded with real Android captures when available and Runlini-specific marketing copy.

## Assumptions

- App name is `Runlini`.
- App icon comes from `assets/branding/runlini_app_icon_1024.png`, with Google Play also able to use `assets/branding/runlini_play_store_icon_512.png`.
- Store targets are Apple App Store and Google Play.
- Initial locale is English because the screenshot template defaults to `en`; the deck remains editable for Korean or other locales later.
- Visual style follows existing Runlini docs: true black, volt green, electric red, oversized blunt typography, bordered surfaces, and direct copy.
- Actual screenshots are not available yet, so Android emulator captures are the first source. iPhone and iPad decks can reuse those captures as placeholders until iOS screenshots are captured.

## Deck Narrative

The first deck should sell one idea per slide.

1. Hero benefit: race your own record, not a generic leaderboard.
2. Live clarity: see ahead or behind while running.
3. Route memory: reuse real past routes for the next effort.
4. Review: inspect pace, route, and splits after the run.
5. Backup and devices: Health sync, watch-ready flows, and voice cues.

The Play Store feature graphic should focus on the same hero idea: `Race your record`.

## Architecture

Use the existing `app-store-screenshots` Next.js template rather than building export logic by hand. Copy template source into the repository without overwriting the Flutter README or root `.gitignore`. Seed `src/lib/defaults.ts` and `src/lib/constants.ts` with Runlini defaults, copy app icons into `public/`, and place captured screenshots under the template's expected `public/screenshots/.../en/` folders.

The Flutter app remains unchanged unless a capture blocker is found. Marketing assets and the editor are independent of the app runtime.

## Files

- Create or modify `package.json`, `bun.lock`, Next.js config files, `src/`, and `public/` from the template.
- Modify `src/lib/defaults.ts` to seed Runlini copy and screenshot paths.
- Modify `src/lib/constants.ts` to add a Runlini theme.
- Copy app icons into `public/app-icon.png` and optionally `public/play-store-icon.png`.
- Add screenshots to `public/screenshots/android/phone/en/` after emulator capture.
- Update `checklist.md` and `context-notes.md` as work progresses.

## Verification

- Run Android device discovery with `adb devices`, `flutter devices`, and AVD listing as needed.
- Capture at least one Android screen with `adb exec-out screencap -p` if an emulator or device is available.
- Install web editor dependencies with the detected package manager.
- Run the editor build command, expected to be `bun run build` or the detected package manager equivalent.
- Start the local dev server and provide the URL if the build succeeds.

## Non-Goals

- Do not redesign Runlini app screens during this task.
- Do not add new Flutter features for marketing screenshots.
- Do not overwrite unrelated root project files from the template.
