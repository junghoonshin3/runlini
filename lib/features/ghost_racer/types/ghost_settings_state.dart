import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class GhostSettingsState {
  const GhostSettingsState({
    required this.enabled,
    this.selectedSessionId,
    this.selectedSessionSummary,
  });

  const GhostSettingsState.disabled() : this(enabled: false);

  final bool enabled;
  final String? selectedSessionId;
  final RunSessionSummary? selectedSessionSummary;
}
