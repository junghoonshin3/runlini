import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_dashboard_sections.dart';

class LiveRunDashboardOverlay extends StatefulWidget {
  const LiveRunDashboardOverlay({
    super.key,
    required this.sessionId,
    required this.metrics,
    required this.displaySettings,
    required this.onAdvanceInterval,
    this.recordRace,
    this.intervalFrame,
  });

  final String? sessionId;
  final LiveRunMetrics metrics;
  final RunDisplaySettings displaySettings;
  final RecordRaceFrame? recordRace;
  final RunIntervalFrame? intervalFrame;
  final VoidCallback onAdvanceInterval;

  @override
  State<LiveRunDashboardOverlay> createState() =>
      _LiveRunDashboardOverlayState();
}

class _LiveRunDashboardOverlayState extends State<LiveRunDashboardOverlay> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant LiveRunDashboardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _expanded
        ? LiveRunDashboardExpanded(
            metrics: widget.metrics,
            displaySettings: widget.displaySettings,
            recordRace: widget.recordRace,
            intervalFrame: widget.intervalFrame,
            onAdvanceInterval: widget.onAdvanceInterval,
          )
        : LiveRunDashboardCollapsed(
            metrics: widget.metrics,
            displaySettings: widget.displaySettings,
            recordRace: widget.recordRace,
          );

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        key: const Key('live-run-dashboard-overlay'),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.88),
          border: Border.all(color: AppColors.chalk, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Padding(
              padding: _expanded
                  ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
                  : const EdgeInsets.fromLTRB(12, 10, 46, 10),
              child: child,
            ),
            Positioned(
              top: _expanded ? 6 : 8,
              right: 6,
              child: IconButton(
                key: const Key('live-run-dashboard-toggle'),
                visualDensity: VisualDensity.compact,
                iconSize: 22,
                color: AppColors.chalk,
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
