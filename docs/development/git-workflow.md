# Git Workflow

Runlini uses Git as a lightweight collaboration log. The workflow should protect
the codebase without slowing down fast iteration.

## Branch Strategy

- Runlini uses a lightweight `develop -> main` release gate.
- `main` is the stable release branch. It should contain only versions that are
  ready to ship or field-test as a completed build.
- `develop` is the integration branch for current development. It should stay
  buildable, but it may contain work that is still being tested.
- Feature and fix branches start from `develop` and merge back into `develop`
  by PR.
- Tested release candidates merge from `develop` into `main` by PR.
- One task branch should represent one coherent task, fix, or docs update.
- Start each new task by checking the worktree:

```bash
git status --short --branch
```

- Start normal development work from `develop`:

```bash
git switch develop
git pull --ff-only
git switch -c feature/some-work
```

- If the worktree is dirty, decide whether the existing changes belong to the
  new task before creating or switching branches.
- If the existing changes do not belong to the new task, first commit them,
  stash them, or move them to their own branch.
- Do not create an independent task branch from a dirty worktree. `git switch
  -c` carries uncommitted changes into the new branch, which mixes unrelated
  work and makes review harder.
- Short-lived branches are required for:
  - database migrations
  - large refactors
  - native platform changes
  - multi-session features
  - work that needs review before it lands on `develop`
- Small docs-only edits may happen on the current branch only when the worktree
  is clean or the docs edit clearly belongs to that branch.
- Keep branch names short and purpose-driven:
  - `feature/wear-ghost-start`
  - `fix/history-today-filter`
  - `docs/git-workflow`
- Use `hotfix/*` only for urgent fixes based on `main`. Hotfixes must merge
  back into both `main` and `develop`.
- Use `release/*` only when a release needs a separate stabilization branch.
  Otherwise, stabilize directly on `develop` and merge `develop` to `main`.
- If a branch name no longer describes the work on it, stop and split the work
  before adding more commits.

## Commit Boundaries

- Small user requests should usually become one commit.
- Larger features can be split into 2-3 meaningful commits when the boundary is
  obvious, such as implementation, tests, and docs.
- `커밋해줘` means commit only the changes from the current task.
- `전부 커밋해줘` means commit the full worktree, except ignored local files,
  generated output, caches, secrets, and machine-specific files.
- If unrelated changes are mixed into the worktree, leave them alone unless the
  user explicitly asks to include them.

## Commit Messages

Use Conventional Commit types with Korean summaries.

Format:

```text
<type>(optional-scope): <Korean summary>
```

Allowed default types:

- `feat`
- `fix`
- `docs`
- `refactor`
- `test`
- `chore`

Message rules:

- Write the type in English and the summary in Korean.
- Keep the first line short and specific. Aim for 50 characters or fewer after
  the type.
- Describe what changed, not what command was run.
- Use a noun-style or concise action-style Korean summary:
  - good: `기록탭 오늘 기록 표시`
  - good: `워치 재진입 복구`
  - bad: `수정함`
  - bad: `테스트 돌림`
- Do not end the subject with a period.
- Use a scope only when it makes the affected area clearer:
  - `feat(wear): 러닝 재진입 복구`
  - `fix(history): Health 기록 로컬 날짜 표시`
- Add a commit body only when the title cannot explain the risk or intent.
  Keep the body focused on why the change exists and any important validation.

Prefer short messages:

```text
feat: 기록탭 오늘 기록 표시
fix: 워치 일시정지 화면 간격 조정
docs: Git 워크플로우 정리
test: 기록탭 오늘 보기 검증 추가
```

Avoid vague messages such as `update`, `fix`, `changes`, `wip`, or `작업`.

## Validation

Choose checks by the files changed.

Docs-only changes:

```bash
dart run tool/guardrails.dart
```

Flutter or Dart code changes:

```bash
dart run tool/guardrails.dart
flutter analyze
flutter test
```

Wear OS changes:

```bash
dart run tool/guardrails.dart
flutter analyze
flutter test
./gradlew :wear:testDebugUnitTest
./gradlew :wear:assembleDebug
```

Android phone native changes should add the relevant app Gradle test or build,
such as:

```bash
./gradlew :app:testDebugUnitTest
./gradlew :app:assembleDebug
```

When Android phone and Wear code both change, also run:

```bash
./gradlew :app:assembleDebug :wear:assembleDebug
```

If a command cannot be run, record the exact command and the reason.

## Release Flow

Feature and fix branches merge into `develop` after the relevant validation
passes. Use `develop` for emulator, device, and integration testing.

When `develop` is ready to promote:

```bash
git switch develop
git pull --ff-only
dart run tool/guardrails.dart
flutter analyze
flutter test
```

Run Wear or Android Gradle checks when those areas changed. Then open a PR from
`develop` to `main`. After merge, tag the release when appropriate:

```bash
git switch main
git pull --ff-only
git tag v1.2.0
git push origin v1.2.0
```

## Push And PR

- Push only when the user explicitly asks.
- `커밋해줘` stops at the local commit.
- `커밋하고 푸쉬해줘` commits and pushes to the configured remote.
- Check the remote and branch before pushing:

```bash
git remote -v
git status --short --branch
```

- Feature branches should be merged through PR by default.
- Feature and fix PRs target `develop`.
- Release PRs target `main` and should normally come from `develop`.
- Fast local work can be merged directly only when the user asks for it.
- If no remote exists, configure `origin` intentionally before pushing.
- New GitHub repositories default to private unless the user says otherwise.

## Safety Rules

- Never use destructive Git commands such as `git reset --hard`,
  `git checkout --`, or force-push unless the user explicitly asks.
- Do not revert unrelated user changes to make the worktree clean.
- Before staging, inspect:

```bash
git status --short
git diff --stat
```

- Stage only task-related files unless the user asks for all changes.
- Keep `local.properties`, `.gradle/`, `.dart_tool/`, `build/`, generated
  platform output, secrets, and SDK paths out of commits.
