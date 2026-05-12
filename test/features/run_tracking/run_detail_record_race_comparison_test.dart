import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_record_race_comparison.dart';

void main() {
  testWidgets('shows numeric recordRace comparison rows in Korean', (
    tester,
  ) async {
    await _pumpComparison(tester);

    expect(find.text('기록 레이스 비교'), findsOneWidget);
    expect(find.text('12초 빨랐어요'), findsOneWidget);
    expect(find.text('코스 시간'), findsOneWidget);
    expect(find.text('평균 페이스'), findsOneWidget);
    expect(find.text('평균 속도'), findsOneWidget);
    expect(find.text('거리 차이'), findsOneWidget);
    expect(find.text('RecordRace Compare'), findsNothing);
    expect(find.text('RecordRace ahead'), findsNothing);
    expect(find.text('Time Gap'), findsNothing);
  });

  testWidgets('uses display units for imperial comparison values', (
    tester,
  ) async {
    await _pumpComparison(
      tester,
      displaySettings: const RunDisplaySettings(
        distanceUnit: RunDistanceUnit.mi,
        paceUnit: RunPaceUnit.minPerMi,
        speedUnit: RunSpeedUnit.mph,
      ),
    );

    expect(find.textContaining('/mi'), findsWidgets);
    expect(find.textContaining('mph'), findsWidgets);
    expect(find.textContaining('mi'), findsWidgets);
  });

  testWidgets('uses improvement color for a faster result', (tester) async {
    await _pumpComparison(tester);

    final text = tester.widget<Text>(find.text('12초 빠름'));
    expect(text.style?.color, AppColors.voltGreen);
  });

  testWidgets('long recordRace labels do not overflow on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpComparison(
      tester,
      summary: _summary(
        recordRaceLabel:
            'Health Connect · kr.sjh.runlini · very long original route name',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('detail-record-race-compare')), findsOneWidget);
  });
}

Future<void> _pumpComparison(
  WidgetTester tester, {
  RunSessionRecordRaceSummary? summary,
  RunDisplaySettings displaySettings = const RunDisplaySettings(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.black,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: RunDetailRecordRaceComparison(
            session: _session(durationMs: 700000, distanceM: 1200),
            recordRaceSession: _session(
              id: 'recordRace',
              durationMs: 600000,
              distanceM: 1000,
            ),
            summary: summary ?? _summary(),
            displaySettings: displaySettings,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

RunSession _session({
  String id = 'current',
  int durationMs = 600000,
  double distanceM = 1000,
}) {
  return RunSession(
    id: id,
    startedAt: DateTime.utc(2026, 4, 20, 6),
    durationMs: durationMs,
    distanceM: distanceM,
    sourceSummary: 'fixture:$id',
    points: const [],
  );
}

RunSessionRecordRaceSummary _summary({
  int timeGapMs = 12000,
  String recordRaceLabel = '아침 기록',
}) {
  return RunSessionRecordRaceSummary(
    result: timeGapMs >= 0
        ? RunSessionRecordRaceResult.ahead
        : RunSessionRecordRaceResult.behind,
    timeGapMs: timeGapMs,
    distanceGapM: 0,
    recordRaceSessionId: 'recordRace',
    recordRaceLabel: recordRaceLabel,
  );
}
