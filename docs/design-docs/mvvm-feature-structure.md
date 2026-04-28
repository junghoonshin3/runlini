# MVVM Feature Structure

Runlini keeps Flutter features readable by applying MVVM to the existing
layered folders.

## Roles

- Model: `types`, `repo`, and `service`
  - Data shape, persistence, platform adapters, and domain calculations.
- ViewModel: `state`
  - Riverpod providers/controllers that expose screen-ready values and actions.
- View: `ui`
  - Stateless or stateful widgets that render data and forward user intent.

## UI Folder Shape

Feature UI folders should be grouped by screen surface when they grow:

- `ui/running`: live run screen, controls, map panel, and run-only prompts.
- `ui/history`: saved-run list, history settings, and list tiles.
- `ui/detail`: saved-run or finish-review detail panels, charts, splits, maps.
- `ui/common`: reusable visual primitives shared by multiple surfaces.
- `ui/formatters`: display-only formatters for labels, units, and chart values.

Widgets should not own data fetching or persistence. If a widget needs derived
data that is not purely visual, add it to `state` or `service` first and pass
the ready value into the widget.
