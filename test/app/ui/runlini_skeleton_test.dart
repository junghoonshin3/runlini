// Runlini 스켈레톤 컴포넌트의 동작을 검증한다
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/ui/runlini_skeleton.dart';

void main() {
  testWidgets('skeleton honors reduce motion as a static placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: RunliniSkeletonBox(height: 24)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RunliniSkeletonBox), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
