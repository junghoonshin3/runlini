# Runlini Architecture

Runlini uses an agent-legible Flutter layout.

## Top-Level Modules

- `lib/app`: application bootstrap, routing, theme, and app-wide presentation rules
- `lib/core`: shared adapters and external boundaries
- `lib/features`: product domains

`lib/core` owns the native map bridge, platform configuration checks, and the
app-owned coordinate types passed into map widgets. Media adapters such as
gallery image picking and local image persistence also live in `core`, while
features store only app-owned file paths in their domain models.

## Feature Layers

Each feature is organized as:

`types -> repo -> service -> state -> ui`

Allowed dependencies move only toward earlier layers:

- `types`: local models and enums only
- `repo`: can depend on `types`
- `service`: can depend on `repo` and `types`
- `state`: can depend on `service`, `repo`, and `types`
- `ui`: can depend on `state`, `service`, `repo`, and `types`

`core` may be imported by any feature. `core` may depend on feature `types`
when an external boundary needs domain language, but it must not import feature
`repo`, `service`, `state`, or `ui`.

## MVVM Mapping

Runlini uses MVVM inside the layered feature structure without adding a separate
`view_model` folder.

- Model: `types`, `repo`, and `service`
  - `types` define immutable data contracts and enums.
  - `repo` reads and writes data from local or external sources.
  - `service` owns domain calculations and business rules.
- ViewModel: `state`
  - Riverpod providers/controllers prepare screen-ready state.
  - ViewModels consume model layers and expose user-intent methods.
  - ViewModels should not render widgets or own visual layout decisions.
- View: `ui`
  - Widgets render state, collect user input, and call ViewModel methods.
  - Screen folders group views by user surface, such as `running`, `history`,
    and `detail`.
  - Shared presentation primitives live under `ui/common`.
  - Formatting helpers that are purely presentational live under
    `ui/formatters`.

For run tracking, this means live GPS capture and saved-run calculations remain
in `service`/`state`, while route previews, charts, history tiles, and settings
screens stay in the appropriate `ui` screen folder.

## Product Domains

- `dashboard`: immediate race-day readability and operator controls
- `run_tracking`: live GPS capture and local persistence
- `ghost_racer`: time-based projection and gap feedback
- `health_sync`: secondary workout import and merge policy
- `settings`: app-level preferences and settings surfaces

The `settings` feature is an app-level view layer. It may consume settings
providers owned by product domains, but it should not own their persistence or
business rules.

## Guardrails

- Structural rules live in `tool/guardrails.dart`.
- Product and design rules live in `docs/`.
- Multi-step work must be anchored in `docs/exec-plans/active/`.
