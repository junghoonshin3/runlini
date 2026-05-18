# Store Screenshots Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local Next.js editor for Runlini App Store and Google Play screenshots, seeded with Runlini branding, copy, and Android emulator captures.

**Architecture:** Keep the Flutter app unchanged. Use the existing app-store-screenshots template for editor, device frames, storage, and export logic, then seed Runlini-specific defaults and assets. Avoid copying template root files that would overwrite the Flutter README or `.gitignore`.

**Tech Stack:** Flutter, Android Emulator, ADB, Next.js 15, React, TypeScript, Tailwind, html-to-image.

---

### Task 1: Capture Source Screens

**Files:**
- Create: `public/screenshots/android/phone/en/01.png`
- Create: `public/screenshots/android/phone/en/02.png`
- Create: `public/screenshots/android/phone/en/03.png`
- Create: `public/screenshots/android/phone/en/04.png`
- Create: `public/screenshots/android/phone/en/05.png`

- [ ] **Step 1: Check connected Android targets**

Run: `~/Library/Android/sdk/platform-tools/adb devices`
Expected: one `device` target or no targets.

- [ ] **Step 2: Check Flutter targets**

Run: `flutter devices`
Expected: emulator or Android device appears after boot, or only desktop/browser targets if no emulator is ready.

- [ ] **Step 3: Check available AVDs if needed**

Run: `~/Library/Android/sdk/emulator/emulator -list-avds`
Expected: at least one AVD name, preferably `Medium_Phone_API_36.0`.

- [ ] **Step 4: Run the app on the chosen Android target**

Run: `flutter run -d emulator-5554`
Expected: Runlini launches on the emulator.

- [ ] **Step 5: Capture screenshots**

Run: `~/Library/Android/sdk/platform-tools/adb -s emulator-5554 exec-out screencap -p > public/screenshots/android/phone/en/01.png`
Expected: PNG file is written and `file public/screenshots/android/phone/en/01.png` reports a PNG image.

Repeat after navigating to the next four representative screens: running tab, history or detail, settings, and a record-race related state.

### Task 2: Scaffold The Editor

**Files:**
- Create: `package.json`
- Create: `bun.lock`
- Create: `components.json`
- Create: `next.config.mjs`
- Create: `postcss.config.mjs`
- Create: `tailwind.config.ts`
- Create: `tsconfig.json`
- Create: `src/**`
- Create: `public/mockup.png`
- Create: `public/app-icon.png`
- Create: `public/play-store-icon.png`

- [ ] **Step 1: Detect package manager**

Run: `which bun`
Expected: prints a bun path. If not, run `which pnpm`, `which yarn`, then use `npm`.

- [ ] **Step 2: Copy template files without overwriting Flutter root docs**

Copy template app files from `.agents/skills/app-store-screenshots/template/` into the repository, excluding template `README.md` and template `.gitignore`.
Expected: Next.js editor files exist and the existing Flutter README and `.gitignore` remain unchanged.

- [ ] **Step 3: Copy branding assets**

Run: `cp assets/branding/runlini_app_icon_1024.png public/app-icon.png`
Expected: `public/app-icon.png` exists.

Run: `cp assets/branding/runlini_play_store_icon_512.png public/play-store-icon.png`
Expected: `public/play-store-icon.png` exists.

### Task 3: Seed Runlini Defaults

**Files:**
- Modify: `src/lib/defaults.ts`
- Modify: `src/lib/constants.ts`

- [ ] **Step 1: Add Runlini theme**

Add a theme with true black background, volt green accent, electric red alternate accent by extending `THEMES` in `src/lib/constants.ts`.
Expected: `themeId: "runlini-dark"` can be used by defaults.

- [ ] **Step 2: Seed copy and screenshot paths**

Set `DEFAULT_PROJECT.appName` to `Runlini`, `themeId` to `runlini-dark`, `appIcon` to `/app-icon.png`, and slides to the five-slide narrative from the design spec.
Expected: the first page of the editor opens with Runlini copy instead of template placeholder copy.

### Task 4: Verify Editor

**Files:**
- Modify: `checklist.md`
- Modify: `context-notes.md`

- [ ] **Step 1: Install dependencies**

Run: `bun install`
Expected: dependencies resolve and lockfile is current.

- [ ] **Step 2: Build the editor**

Run: `bun run build`
Expected: Next.js production build succeeds.

- [ ] **Step 3: Start the editor**

Run: `bun run dev`
Expected: editor is available at `http://localhost:3000` or the next available port.

- [ ] **Step 4: Report verification**

Update `checklist.md` and `context-notes.md` with the exact checks and any capture limitations.
Expected: final response reports commands that passed or failed and the editor URL.
