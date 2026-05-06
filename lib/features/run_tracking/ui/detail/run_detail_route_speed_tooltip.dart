import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/route_speed_insight_builder.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_route_speed_popover_layout.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class RunDetailRouteSpeedInfoButton extends StatefulWidget {
  const RunDetailRouteSpeedInfoButton({
    super.key,
    required this.points,
    required this.displaySettings,
  });

  final List<RunPoint> points;
  final RunDisplaySettings displaySettings;

  @override
  State<RunDetailRouteSpeedInfoButton> createState() =>
      _RunDetailRouteSpeedInfoButtonState();
}

class _RunDetailRouteSpeedInfoButtonState
    extends State<RunDetailRouteSpeedInfoButton> {
  final _buttonKey = GlobalKey();
  OverlayEntry? _popover;

  @override
  void dispose() {
    _hidePopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _buttonKey,
      child: IconButton(
        key: const Key('route-speed-info-button'),
        visualDensity: VisualDensity.compact,
        onPressed: _togglePopover,
        icon: const Icon(
          Icons.info_outline_rounded,
          color: AppColors.muted,
          size: 21,
        ),
      ),
    );
  }

  void _togglePopover() {
    if (_popover != null) {
      _hidePopover();
      return;
    }
    _showPopover();
  }

  void _showPopover() {
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final buttonBox = _buttonKey.currentContext?.findRenderObject();
    if (overlayBox == null || buttonBox is! RenderBox) {
      return;
    }
    final insights = _insights();
    final buttonTopLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final anchor = buttonTopLeft & buttonBox.size;
    _popover = OverlayEntry(
      builder: (context) {
        final media = MediaQuery.of(context);
        final placement = routeSpeedPopoverPlacement(
          anchor: anchor,
          viewport: media.size,
          safePadding: media.padding,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hidePopover,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: placement.left,
              top: placement.top,
              width: placement.width,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: placement.maxHeight),
                  child: _RouteSpeedPopover(
                    insights: insights,
                    displaySettings: widget.displaySettings,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_popover!);
  }

  void _hidePopover() {
    _popover?.remove();
    _popover = null;
  }

  List<RouteSpeedInsight> _insights() {
    final route = const RunRouteSegmenter().segment(widget.points);
    return const RouteSpeedInsightBuilder().build(route.segments);
  }
}

class _RouteSpeedPopover extends StatelessWidget {
  const _RouteSpeedPopover({
    required this.insights,
    required this.displaySettings,
  });

  final List<RouteSpeedInsight> insights;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('route-speed-info-popover'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: insights.isEmpty
            ? const _RouteSpeedEmptyState()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < insights.length; index += 1) ...[
                    _RouteSpeedInsightRow(
                      insight: insights[index],
                      displaySettings: displaySettings,
                    ),
                    if (index < insights.length - 1) const SizedBox(height: 6),
                  ],
                ],
              ),
      ),
    );
  }
}

class _RouteSpeedInsightRow extends StatelessWidget {
  const _RouteSpeedInsightRow({
    required this.insight,
    required this.displaySettings,
  });

  final RouteSpeedInsight insight;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('route-speed-row-${insight.bucket.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 30,
            decoration: BoxDecoration(
              color: insight.bucket.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.bucket.shortLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.chalk,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatRunSpeed(insight.speedKmh, displaySettings),
                    maxLines: 1,
                    style: TextStyle(
                      color: insight.bucket.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatDistance(insight.distanceM, displaySettings),
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double distanceM, RunDisplaySettings settings) {
    final decimals = settings.distanceUnit == RunDistanceUnit.mi ? 2 : 1;
    return formatRunDistance(distanceM, settings, decimals: decimals);
  }
}

class _RouteSpeedEmptyState extends StatelessWidget {
  const _RouteSpeedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('route-speed-empty-popover'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '속도 데이터 부족',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

extension on RouteSpeedInsightBucket {
  String get shortLabel {
    return switch (this) {
      RouteSpeedInsightBucket.fast => '빠름',
      RouteSpeedInsightBucket.average => '평균',
      RouteSpeedInsightBucket.slow => '느림',
    };
  }
}
