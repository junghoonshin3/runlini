import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class RecordRaceSettingsState {
  const RecordRaceSettingsState({
    required this.enabled,
    this.selectedSessionId,
    this.selectedSessionSummary,
  });

  const RecordRaceSettingsState.disabled() : this(enabled: false);

  final bool enabled;
  final String? selectedSessionId;
  final RunSessionSummary? selectedSessionSummary;
}
