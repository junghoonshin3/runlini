// 설정탭 정보 구조의 섹션 순서를 검증한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';

import '../../helpers/fake_run_settings_repository.dart';
import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('shows reorganized settings sections in MVP order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSettingsRepositoryProvider.overrideWithValue(
            FakeRunSettingsRepository(),
          ),
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SettingsTabScreen()),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('settings-tab-screen')));

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('러닝 추적'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    for (final title in [
      '러닝 화면과 안내',
      '기록 목표와 표시',
      '내 정보',
      '러닝화',
      '연동과 백업',
      '개인정보 보호',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        180,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
  });
}
