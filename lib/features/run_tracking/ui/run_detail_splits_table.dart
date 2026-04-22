import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/ui/live_run_metrics_formatters.dart';

class RunDetailSplitsTable extends StatelessWidget {
  const RunDetailSplitsTable({super.key, required this.splits});

  final List<RunSplitDetail> splits;

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
        const _SplitHeader(),
        const SizedBox(height: 12),
        ...splits.map(
          (split) => _SplitRow(
            split: split,
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
  const _SplitHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 64, child: _HeaderText('Split')),
        Expanded(child: _HeaderText('Pace (KM)')),
        SizedBox(width: 94, child: _HeaderText('Elev. (M)')),
        SizedBox(width: 74, child: _HeaderText('HR (BPM)')),
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
  const _SplitRow({required this.split, required this.widthFactor});

  final RunSplitDetail split;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text('${split.index}', style: _valueStyle),
          ),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatLiveRunAveragePace(
                      split.paceSecPerKm,
                    ).replaceFirst(' /km', ''),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 94,
            child: Text(
              _formatElevation(split.elevationDeltaM),
              style: _valueStyle,
            ),
          ),
          SizedBox(
            width: 74,
            child: Text(
              split.averageHeartRateBpm?.toString() ?? '--',
              style: _valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatElevation(double? elevation) {
    if (elevation == null) {
      return '--';
    }
    final sign = elevation > 0 ? '+' : '';
    return '$sign${elevation.toStringAsFixed(1)}';
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
