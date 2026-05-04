import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_interval_panel.dart';

void main() {
  testWidgets('shows current interval step, remaining, and next step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveRunIntervalPanel(
            frame: const RunIntervalFrame(
              step: RunIntervalStep(
                kind: RunIntervalStepKind.work,
                target: RunIntervalTarget.time(60000),
                repeatIndex: 3,
                repeatCount: 8,
              ),
              nextStep: RunIntervalStep(
                kind: RunIntervalStepKind.recovery,
                target: RunIntervalTarget.time(60000),
                repeatIndex: 3,
                repeatCount: 8,
              ),
              remainingMs: 42000,
              remainingM: null,
              progress: 0.3,
            ),
            onAdvance: () {},
          ),
        ),
      ),
    );

    expect(find.text('질주 3/8'), findsOneWidget);
    expect(find.textContaining('남은 42초'), findsOneWidget);
    expect(find.textContaining('다음 휴식'), findsOneWidget);
    expect(
      find.byKey(const Key('live-run-interval-advance-button')),
      findsNothing,
    );
  });

  testWidgets('shows advance button for open interval steps', (
    WidgetTester tester,
  ) async {
    var advanced = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveRunIntervalPanel(
            frame: const RunIntervalFrame(
              step: RunIntervalStep(
                kind: RunIntervalStepKind.warmup,
                target: RunIntervalTarget.open(),
                repeatIndex: null,
                repeatCount: 8,
              ),
              nextStep: RunIntervalStep(
                kind: RunIntervalStepKind.work,
                target: RunIntervalTarget.time(60000),
                repeatIndex: 1,
                repeatCount: 8,
              ),
              remainingMs: null,
              remainingM: null,
              progress: 0,
            ),
            onAdvance: () => advanced = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('live-run-interval-advance-button')));

    expect(advanced, isTrue);
  });
}
