// 기록 레이스 완료 결과 오버레이를 검증하는 위젯 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_completion_overlay.dart';

void main() {
  testWidgets('shows live result copy and continue/end actions', (
    tester,
  ) async {
    var continued = false;
    var stopped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RunRecordRaceCompletionOverlay(
            summary: _summary(),
            onContinue: () => continued = true,
            onStop: () async => stopped = true,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('record-race-run-completion-dialog')),
      findsOneWidget,
    );
    expect(find.text('기록 레이스 완료'), findsOneWidget);
    expect(find.text('실시간 결과'), findsOneWidget);
    expect(find.text('기록 레이스보다 12초 빨랐어요'), findsOneWidget);
    expect(find.text('러닝 기록은 계속 중입니다.'), findsOneWidget);
    expect(find.text('계속 달리기'), findsOneWidget);
    expect(find.text('러닝 종료'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('continue-after-record-race-completion-button')),
    );
    await tester.pump();
    expect(continued, isTrue);

    await tester.tap(
      find.byKey(const Key('stop-after-record-race-completion-button')),
    );
    await tester.pump();
    expect(stopped, isTrue);
  });
}

RunSessionRecordRaceSummary _summary() {
  return const RunSessionRecordRaceSummary(
    recordRaceSessionId: 'record-race-1',
    recordRaceLabel: 'Morning RecordRace',
    result: RunSessionRecordRaceResult.ahead,
    timeGapMs: 12000,
    distanceGapM: 42,
  );
}
