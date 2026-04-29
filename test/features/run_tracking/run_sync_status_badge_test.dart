import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/common/run_sync_status_badge.dart';

void main() {
  test('keeps app-local Health backup labels', () {
    expect(runSyncStatusLabel(RunSessionSyncStatus.synced), 'Health 백업됨');
    expect(runSyncStatusLabel(RunSessionSyncStatus.syncFailed), '백업 실패');
  });

  test('labels imported Health records by their source', () {
    expect(
      runSyncStatusLabel(
        RunSessionSyncStatus.synced,
        recordSource: RunSessionRecordSource.healthConnect,
        sourceSummary: 'Health Connect · Samsung Health',
      ),
      'Samsung Health에서 가져옴',
    );
    expect(
      runSyncStatusLabel(
        RunSessionSyncStatus.synced,
        recordSource: RunSessionRecordSource.healthConnect,
        sourceSummary: 'Health Connect · com.example.run',
      ),
      'Health Connect에서 가져옴',
    );
    expect(
      runSyncStatusLabel(
        RunSessionSyncStatus.synced,
        recordSource: RunSessionRecordSource.healthKit,
        sourceSummary: 'Apple Health',
      ),
      '건강 앱에서 가져옴',
    );
  });
}
