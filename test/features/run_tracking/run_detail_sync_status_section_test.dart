import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_sync_status_section.dart';

void main() {
  testWidgets('shows Android send action for local-only app records', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      TargetPlatform.android,
      status: RunSessionSyncStatus.localOnly,
    );

    expect(find.text('앱에만 저장됨'), findsOneWidget);
    expect(find.text('Health Connect로 보내기'), findsOneWidget);
  });

  testWidgets('shows iOS send action for skipped app records', (tester) async {
    await _pumpSection(
      tester,
      TargetPlatform.iOS,
      status: RunSessionSyncStatus.syncSkipped,
    );

    expect(find.text('앱에만 저장됨'), findsOneWidget);
    expect(find.text('건강 앱으로 보내기'), findsOneWidget);
  });

  testWidgets('uses Android destination for retry action', (tester) async {
    await _pumpSection(
      tester,
      TargetPlatform.android,
      status: RunSessionSyncStatus.syncFailed,
    );

    expect(find.text('Health Connect 전송 실패'), findsOneWidget);
    expect(find.text('Health Connect로 다시 보내기'), findsOneWidget);
  });

  testWidgets('uses iOS destination for retry action', (tester) async {
    await _pumpSection(
      tester,
      TargetPlatform.iOS,
      status: RunSessionSyncStatus.syncFailed,
    );

    expect(find.text('건강 앱 전송 실패'), findsOneWidget);
    expect(find.text('건강 앱으로 다시 보내기'), findsOneWidget);
  });

  testWidgets('hides action for synced app records', (tester) async {
    await _pumpSection(
      tester,
      TargetPlatform.android,
      status: RunSessionSyncStatus.synced,
    );

    expect(find.text('Health Connect에 저장됨'), findsOneWidget);
    expect(find.byKey(const Key('send-health-workout-button')), findsNothing);
  });

  testWidgets('hides action for imported Health records', (tester) async {
    await _pumpSection(
      tester,
      TargetPlatform.android,
      status: RunSessionSyncStatus.synced,
      recordSource: RunSessionRecordSource.healthConnect,
    );

    expect(find.text('Health Connect에서 가져옴'), findsOneWidget);
    expect(find.byKey(const Key('send-health-workout-button')), findsNothing);
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  TargetPlatform targetPlatform, {
  required RunSessionSyncStatus status,
  RunSessionRecordSource recordSource = RunSessionRecordSource.appLocal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RunDetailSyncStatusSection(
          status: status,
          recordSource: recordSource,
          targetPlatform: targetPlatform,
          onRetry: () {},
        ),
      ),
    ),
  );
}
