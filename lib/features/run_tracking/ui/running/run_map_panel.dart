import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/apple_run_map_view.dart';
import 'package:runlini/core/map/fake_run_map_surface.dart';
import 'package:runlini/core/map/google_run_map_view.dart';
import 'package:runlini/core/map/map_config_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/run_map_view_state.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

class RunMapPanel extends ConsumerWidget {
  const RunMapPanel({super.key, required this.mapViewState});

  final RunMapViewState mapViewState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recenterTick = ref.watch(runMapRecenterTickProvider);

    if (_isFlutterTest || (!Platform.isAndroid && !Platform.isIOS)) {
      return FakeRunMapSurface(
        mapCenter: mapViewState.mapCenter,
        runnerMarkerPoint: mapViewState.runnerMarkerPoint,
        ghostMarkerPoint: mapViewState.ghostMarkerPoint,
        currentRunnerPolylinePoints: mapViewState.currentRunnerPolylinePoints,
        currentRunnerPolylineSegments:
            mapViewState.currentRunnerPolylineSegments,
        ghostPolylinePoints: mapViewState.ghostPolylinePoints,
        ghostPolylineSegments: mapViewState.ghostPolylineSegments,
        ghostRouteEndpointMarkers: mapViewState.ghostRouteEndpointMarkers,
      );
    }

    if (Platform.isIOS) {
      return AppleRunMapView(
        mapCenter: mapViewState.mapCenter,
        runnerMarkerPoint: mapViewState.runnerMarkerPoint,
        ghostMarkerPoint: mapViewState.ghostMarkerPoint,
        recenterTargetPoint: mapViewState.recenterTargetPoint,
        currentRunnerPolylinePoints: mapViewState.currentRunnerPolylinePoints,
        currentRunnerPolylineSegments:
            mapViewState.currentRunnerPolylineSegments,
        ghostPolylinePoints: mapViewState.ghostPolylinePoints,
        ghostPolylineSegments: mapViewState.ghostPolylineSegments,
        ghostRouteEndpointMarkers: mapViewState.ghostRouteEndpointMarkers,
        recenterTick: recenterTick,
      );
    }

    final configuredAsync = ref.watch(androidGoogleMapsConfiguredProvider);
    return configuredAsync.when(
      data: (bool configured) {
        if (!configured) {
          return const _AndroidMapKeyMissingState();
        }

        return GoogleRunMapView(
          mapCenter: mapViewState.mapCenter,
          runnerMarkerPoint: mapViewState.runnerMarkerPoint,
          ghostMarkerPoint: mapViewState.ghostMarkerPoint,
          recenterTargetPoint: mapViewState.recenterTargetPoint,
          currentRunnerPolylinePoints: mapViewState.currentRunnerPolylinePoints,
          currentRunnerPolylineSegments:
              mapViewState.currentRunnerPolylineSegments,
          ghostPolylinePoints: mapViewState.ghostPolylinePoints,
          ghostPolylineSegments: mapViewState.ghostPolylineSegments,
          ghostRouteEndpointMarkers: mapViewState.ghostRouteEndpointMarkers,
          recenterTick: recenterTick,
        );
      },
      loading: () => const ColoredBox(color: AppColors.black),
      error: (Object error, StackTrace stackTrace) => const _MapStatusPanel(
        headline: 'MAP SETUP ERROR',
        message: 'Android map configuration could not be read.',
      ),
    );
  }
}

class _AndroidMapKeyMissingState extends StatelessWidget {
  const _AndroidMapKeyMissingState();

  @override
  Widget build(BuildContext context) {
    return const _MapStatusPanel(
      key: Key('android-map-config-error'),
      headline: 'GOOGLE MAPS KEY REQUIRED',
      message:
          'Add GOOGLE_MAPS_API_KEY to android/local.properties to render the Android running map.',
    );
  }
}

class _MapStatusPanel extends StatelessWidget {
  const _MapStatusPanel({
    super.key,
    required this.headline,
    required this.message,
  });

  final String headline;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.graphite,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.92),
            border: Border.all(color: AppColors.chalk, width: 3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.voltGreen),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.chalk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
