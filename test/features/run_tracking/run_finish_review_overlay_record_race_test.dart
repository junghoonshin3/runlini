// 완료 리뷰 오버레이의 기록 레이스 비교 데이터 로딩을 검증하는 위젯 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/running/run_finish_review_overlay.dart';

import '../../helpers/fake_run_settings_repository.dart';
import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('finish review overlay resolves recordRace comparison rows', (
    WidgetTester tester,
  ) async {
    final originalRecordRace = recordRaceSession();
    await _pumpOverlay(
      tester,
      session: _recordRaceFinishedSession(originalRecordRace),
      sessionRepository: FakeRunSessionRepository([originalRecordRace]),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('기록 레이스 비교'), findsOneWidget);
    expect(find.text('코스 시간'), findsOneWidget);
    expect(find.text('평균 페이스'), findsOneWidget);
    expect(find.text('km당 10초 느림'), findsOneWidget);
    expect(find.text('시간 차이'), findsNothing);
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required RunSession session,
  required FakeRunSessionRepository sessionRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runSettingsRepositoryProvider.overrideWithValue(
          FakeRunSettingsRepository(),
        ),
        runDisplaySettingsProvider.overrideWithValue(
          const RunDisplaySettings(),
        ),
        runPrivacySettingsProvider.overrideWithValue(
          const RunPrivacySettings(),
        ),
        runShoeListProvider.overrideWith((ref) async => const <RunShoe>[]),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: RunFinishReviewOverlay(
              session: session,
              onSave: () {},
              onDiscard: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

RunSession _recordRaceFinishedSession(RunSession recordRaceSession) {
  return recordRaceSession.copyWith(
    id: 'finished-record-race',
    startedAt: DateTime.utc(2026, 4, 20, 6),
    endedAt: DateTime.utc(2026, 4, 20, 6, 10, 10),
    durationMs: recordRaceSession.durationMs + 10000,
    sourceSummary: 'device:gps',
    recordRaceSummary: RunSessionRecordRaceSummary(
      result: RunSessionRecordRaceResult.behind,
      timeGapMs: -10000,
      distanceGapM: 0,
      recordRaceSessionId: recordRaceSession.id,
      recordRaceLabel: recordRaceSession.sourceSummary,
    ),
  );
}
