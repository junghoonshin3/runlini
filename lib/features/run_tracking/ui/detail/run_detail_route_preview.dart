import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_skeleton.dart';
import 'package:runlini/core/map/fake_run_map_surface.dart';
import 'package:runlini/core/map/map_config_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/features/run_tracking/service/pace_colored_route_segment_builder.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_route_maps.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

class RunDetailRoutePreview extends ConsumerWidget {
  const RunDetailRoutePreview({
    super.key,
    required this.points,
    this.debugUseConfiguredMap = false,
    this.debugForceLoading = false,
  });

  final List<RunPoint> points;
  @visibleForTesting
  final bool debugUseConfiguredMap;
  @visibleForTesting
  final bool debugForceLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = const RunRouteSegmenter().segment(points);
    final routeSegments = const PaceColoredRouteSegmentBuilder()
        .buildRouteSegments(route.segments);
    final routePoints = routeSegments
        .expand((segment) => segment.points)
        .toList(growable: false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        key: const Key('finish-route-preview'),
        height: 210,
        width: double.infinity,
        child: _RoutePreviewBody(
          routePoints: routePoints,
          routeSegments: routeSegments,
          debugUseConfiguredMap: debugUseConfiguredMap,
          debugForceLoading: debugForceLoading,
        ),
      ),
    );
  }
}

class _RoutePreviewBody extends ConsumerWidget {
  const _RoutePreviewBody({
    required this.routePoints,
    required this.routeSegments,
    required this.debugUseConfiguredMap,
    required this.debugForceLoading,
  });

  final List<MapCoordinate> routePoints;
  final List<MapPolylineSegment> routeSegments;
  final bool debugUseConfiguredMap;
  final bool debugForceLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routePoints.length < 2) {
      return const _RoutePreviewFallback(message: '경로 데이터가 부족해요.');
    }
    if (debugForceLoading) {
      return const _RoutePreviewSkeleton();
    }

    if (!debugUseConfiguredMap &&
        (_isFlutterTest || (!Platform.isAndroid && !Platform.isIOS))) {
      return FakeRunMapSurface(
        mapCenter: centerOfRoute(routePoints),
        currentRunnerPolylinePoints: routePoints,
        currentRunnerPolylineSegments: routeSegments,
        recordRacePolylinePoints: const <MapCoordinate>[],
        recordRacePolylineSegments: const [],
      );
    }

    if (Platform.isIOS) {
      return AppleDetailRouteMap(
        routePoints: routePoints,
        routeSegments: routeSegments,
      );
    }

    final configuredAsync = ref.watch(androidGoogleMapsConfiguredProvider);
    return configuredAsync.when(
      data: (configured) {
        if (!configured) {
          return const _RoutePreviewFallback(
            message: 'Google Maps 키가 설정되지 않았어요.',
          );
        }
        return GoogleDetailRouteMap(
          routePoints: routePoints,
          routeSegments: routeSegments,
        );
      },
      loading: () => const _RoutePreviewSkeleton(),
      error: (_, _) =>
          const _RoutePreviewFallback(message: '지도 설정을 확인하지 못했어요.'),
    );
  }
}

class _RoutePreviewSkeleton extends StatelessWidget {
  const _RoutePreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: Key('route-preview-skeleton'),
      color: AppColors.panel,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: RunliniSkeletonBox(height: 210, borderRadius: 8),
            ),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 170,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RunliniSkeletonText(width: 138, height: 14),
                    SizedBox(height: 10),
                    RunliniSkeletonText(width: 96, height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePreviewFallback extends StatelessWidget {
  const _RoutePreviewFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.panel,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
