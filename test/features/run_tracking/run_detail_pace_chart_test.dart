import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';

void main() {
  testWidgets('pace chart uses session average and hides outlier samples', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RunFinishReviewPanel(session: _session())),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Avg 10:00 /km'), findsOneWidget);
    expect(find.textContaining('204'), findsNothing);

    final chart = tester.widget<LineChart>(find.byType(LineChart).first);
    expect(chart.data.extraLinesData.horizontalLines.single.y, 600);
  });

  testWidgets('shows cadence metric and chart when cadence samples exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RunFinishReviewPanel(session: _cadenceSession())),
      ),
    );
    await tester.pump();

    expect(find.text('Avg. Cadence (spm)'), findsOneWidget);
    expect(find.text('172'), findsOneWidget);
    expect(find.byKey(const Key('detail-chart-cadence')), findsOneWidget);
    expect(find.textContaining('Avg 172 spm'), findsOneWidget);
  });

  testWidgets('shows empty cadence chart when only average cadence exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RunFinishReviewPanel(session: _cadenceAverageOnlySession()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Avg. Cadence (spm)'), findsOneWidget);
    expect(find.text('170'), findsOneWidget);
    expect(find.text('케이던스 데이터가 아직 없어요.'), findsOneWidget);
  });
}

RunSession _session() {
  return RunSession(
    id: 'pace-outlier-session',
    startedAt: DateTime.utc(2026, 4, 21, 6),
    endedAt: DateTime.utc(2026, 4, 21, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'fixture:test',
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        paceSecPerKm: 12266,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.0,
        longitude: 127.00225,
        timestampRelMs: 30000,
        paceSecPerKm: 420,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.0,
        longitude: 127.0045,
        timestampRelMs: 60000,
        paceSecPerKm: 410,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.0,
        longitude: 127.00675,
        timestampRelMs: 90000,
        paceSecPerKm: 405,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.0,
        longitude: 127.009,
        timestampRelMs: 120000,
        paceSecPerKm: 400,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.0,
        longitude: 127.01125,
        timestampRelMs: 150000,
        paceSecPerKm: 395,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}

RunSession _cadenceSession() {
  return RunSession(
    id: 'cadence-session',
    startedAt: DateTime.utc(2026, 4, 21, 6),
    endedAt: DateTime.utc(2026, 4, 21, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'fixture:test',
    averageCadenceSpm: 171.6,
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        cadenceSpm: 168,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.001,
        longitude: 127.001,
        timestampRelMs: 300000,
        cadenceSpm: 172,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.002,
        longitude: 127.002,
        timestampRelMs: 600000,
        cadenceSpm: 176,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}

RunSession _cadenceAverageOnlySession() {
  return RunSession(
    id: 'cadence-average-only-session',
    startedAt: DateTime.utc(2026, 4, 21, 6),
    endedAt: DateTime.utc(2026, 4, 21, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'Health Connect',
    averageCadenceSpm: 170,
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        source: RunPointSource.healthConnect,
      ),
    ],
  );
}
