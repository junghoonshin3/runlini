import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/fake_run_map_surface.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_route_preview.dart';

void main() {
  testWidgets('detail route preview renders pace-colored runner segments', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester, const <RunPoint>[
      RunPoint(
        latitude: 0,
        longitude: 0,
        timestampRelMs: 0,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.001,
        timestampRelMs: 20000,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.002,
        timestampRelMs: 60000,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.003,
        timestampRelMs: 130000,
        source: RunPointSource.simulated,
      ),
    ]);

    final surface = tester.widget<FakeRunMapSurface>(
      find.byType(FakeRunMapSurface),
    );
    final colors = surface.currentRunnerPolylineSegments
        .map((segment) => segment.color)
        .toSet();

    expect(surface.currentRunnerPolylineSegments.length, greaterThan(3));
    expect(colors.length, greaterThan(3));
    expect(colors, contains(AppColors.voltGreen));
    expect(colors, contains(AppColors.electricRed));
  });

  testWidgets('detail route preview keeps GPS breaks as separate polylines', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester, const <RunPoint>[
      RunPoint(
        latitude: 0,
        longitude: 0,
        timestampRelMs: 0,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.001,
        timestampRelMs: 20000,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.02,
        timestampRelMs: 60000,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.021,
        timestampRelMs: 80000,
        source: RunPointSource.deviceGps,
      ),
    ]);

    final surface = tester.widget<FakeRunMapSurface>(
      find.byType(FakeRunMapSurface),
    );

    expect(surface.currentRunnerPolylineSegments, hasLength(2));
    for (final segment in surface.currentRunnerPolylineSegments) {
      final longitudes = segment.points.map((point) => point.longitude);
      expect(
        longitudes.any((longitude) => longitude < 0.005) &&
            longitudes.any((longitude) => longitude > 0.015),
        isFalse,
      );
    }
  });
}

Future<void> _pumpPreview(WidgetTester tester, List<RunPoint> points) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: RunDetailRoutePreview(points: points)),
      ),
    ),
  );
  await tester.pump();
}
