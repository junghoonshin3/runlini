# Runlini Architecture

Runlini uses an agent-legible Flutter layout.

## Top-Level Modules

- `lib/app`: application bootstrap, routing, theme, and app-wide presentation rules
- `lib/core`: shared adapters and external boundaries
- `lib/features`: product domains

`lib/core` owns the native map bridge, platform configuration checks, and the
app-owned coordinate types passed into map widgets.

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

## Product Domains

- `dashboard`: immediate race-day readability and operator controls
- `run_tracking`: live GPS capture and local persistence
- `ghost_racer`: time-based projection and gap feedback
- `health_sync`: secondary workout import and merge policy

## Guardrails

- Structural rules live in `tool/guardrails.dart`.
- Product and design rules live in `docs/`.
- Multi-step work must be anchored in `docs/exec-plans/active/`.
