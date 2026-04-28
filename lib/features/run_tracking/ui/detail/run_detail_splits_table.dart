import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class RunDetailSplitsTable extends StatelessWidget {
  const RunDetailSplitsTable({
    super.key,
    required this.splits,
    this.displaySettings = const RunDisplaySettings(),
    this.privacySettings = const RunPrivacySettings(),
  });

  final List<RunSplitDetail> splits;
  final RunDisplaySettings displaySettings;
  final RunPrivacySettings privacySettings;

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
      return const SizedBox.shrink();
    }
    final fastest = splits.map((split) => split.paceSecPerKm).reduce(math.min);
    final slowest = splits.map((split) => split.paceSecPerKm).reduce(math.max);
    return Column(
      key: const Key('detail-splits-table'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Splits',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.chalk,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        _SplitHeader(displaySettings: displaySettings),
        const SizedBox(height: 12),
        ...splits.map(
          (split) => _SplitRow(
            split: split,
            displaySettings: displaySettings,
            privacySettings: privacySettings,
            widthFactor: _widthFactor(split.paceSecPerKm, fastest, slowest),
          ),
        ),
      ],
    );
  }

  double _widthFactor(double pace, double fastest, double slowest) {
    if (slowest <= fastest) {
      return 0.72;
    }
    final fastScore = 1 - ((pace - fastest) / (slowest - fastest));
    return (0.44 + (fastScore * 0.36)).clamp(0.35, 0.82);
  }
}

class _SplitHeader extends StatelessWidget {
  const _SplitHeader({required this.displaySettings});

  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 64, child: _HeaderText('Split')),
        Expanded(
          child: _HeaderText('Pace (${paceUnitLabel(displaySettings)})'),
        ),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false, style: _headerStyle),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.split,
    required this.displaySettings,
    required this.privacySettings,
    required this.widthFactor,
  });

  final RunSplitDetail split;
  final RunDisplaySettings displaySettings;
  final RunPrivacySettings privacySettings;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Container(
        key: Key('split-row-${split.index}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.chalk.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text('${split.index}', style: _valueStyle),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minWidth = math.min(92.0, constraints.maxWidth);
                      final width = (constraints.maxWidth * widthFactor).clamp(
                        minWidth,
                        constraints.maxWidth,
                      );
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: width,
                          child: _PacePill(
                            label: formatRunPaceCompact(
                              split.paceSecPerKm,
                              displaySettings,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                'Elev. ${_formatElevation(split.elevationDeltaM)} m · '
                'HR ${_formatHeartRate()} bpm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _metaStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHeartRate() {
    if (privacySettings.hideHeartRate) {
      return '--';
    }
    return split.averageHeartRateBpm?.toString() ?? '--';
  }

  String _formatElevation(double? elevation) {
    if (elevation == null) {
      return '--';
    }
    final sign = elevation > 0 ? '+' : '';
    return '$sign${elevation.toStringAsFixed(1)}';
  }
}

class _PacePill extends StatelessWidget {
  const _PacePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cyan,
        borderRadius: BorderRadius.circular(28),
      ),
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w900,
);
const _valueStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);
const _metaStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);
