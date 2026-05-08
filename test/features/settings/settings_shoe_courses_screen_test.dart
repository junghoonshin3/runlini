// 러닝화 기록 화면의 스켈레톤 로딩 상태를 검증한다
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/settings/ui/settings_shoe_courses_screen.dart';

void main() {
  testWidgets('shoe courses screen shows skeleton while sessions load', (
    WidgetTester tester,
  ) async {
    final pending = Completer<List<RunSession>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionListProvider.overrideWith((ref) => pending.future),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: SettingsShoeCoursesScreen(shoe: _shoe()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('shoe-courses-skeleton')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

RunShoe _shoe() {
  return RunShoe(
    id: 'shoe-1',
    name: 'Pegasus',
    brand: 'Nike',
    distanceLimitKm: 700,
    retired: false,
    createdAt: DateTime(2026, 5, 1),
  );
}
