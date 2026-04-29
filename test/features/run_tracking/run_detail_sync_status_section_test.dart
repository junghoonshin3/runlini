import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_sync_status_section.dart';

void main() {
  testWidgets('uses Android destination for retry action', (tester) async {
    await _pumpSection(tester, TargetPlatform.android);

    expect(find.text('Health Connect 전송 실패'), findsOneWidget);
    expect(find.text('Health Connect로 다시 보내기'), findsOneWidget);
  });

  testWidgets('uses iOS destination for retry action', (tester) async {
    await _pumpSection(tester, TargetPlatform.iOS);

    expect(find.text('건강 앱 전송 실패'), findsOneWidget);
    expect(find.text('건강 앱으로 다시 보내기'), findsOneWidget);
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  TargetPlatform targetPlatform,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RunDetailSyncStatusSection(
          status: RunSessionSyncStatus.syncFailed,
          targetPlatform: targetPlatform,
          onRetry: () {},
        ),
      ),
    ),
  );
}
