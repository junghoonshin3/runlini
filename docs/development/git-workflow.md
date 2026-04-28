# Git Workflow

Runlini uses Git as a lightweight collaboration log for humans and agents. The
workflow should protect the codebase without slowing down fast iteration.

## Branch Strategy

- Use a mixed strategy.
- Small, focused work can happen on the current branch or directly on `main`.
- Create a short-lived branch for risky or long-running work:
  - database migrations
  - large refactors
  - native platform changes
  - multi-session features
  - work that needs review before it lands on `main`
- Keep branch names short and purpose-driven:
  - `feature/wear-ghost-start`
  - `fix/history-today-filter`
  - `docs/git-workflow`

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

Allowed default types:

- `feat`
- `fix`
- `docs`
- `refactor`
- `test`
- `chore`

Scopes are optional. Prefer short messages:

```text
feat: 기록탭 오늘 기록 표시
fix: 워치 일시정지 화면 간격 조정
docs: Git 워크플로우 정리
test: 기록탭 오늘 보기 검증 추가
```

Avoid vague messages such as `update`, `fix`, or `changes`.

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
- Fast local work can be merged directly only when the user asks for it.
- If no remote exists, configure `origin` intentionally before pushing.
- New GitHub repositories default to private unless the user says otherwise.

## Agent Safety Rules

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
- With multiple agents, assign disjoint file ownership and integrate results
  before committing.
