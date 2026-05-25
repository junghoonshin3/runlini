// 러닝 컨트롤 버튼의 고정 geometry 회귀를 검증한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/ui/running/run_control_buttons.dart';

void main() {
  testWidgets('run control buttons keep fixed geometry with reduce motion', (
    WidgetTester tester,
  ) async {
    var startStopPressed = 0;
    var pauseResumePressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            size: Size(390, 844),
          ),
          child: Scaffold(
            body: Column(
              children: [
                RunStartStopButton(
                  showsStopAction: false,
                  onPressed: () => startStopPressed += 1,
                ),
                RunPauseResumeButton(
                  isPaused: false,
                  onPressed: () => pauseResumePressed += 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('start-stop-button'))),
      const Size(120, 120),
    );
    expect(
      tester.getSize(find.byKey(const Key('pause-run-button'))),
      const Size(68, 68),
    );
    for (final switcher in tester.widgetList<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    )) {
      expect(switcher.duration, Duration.zero);
    }

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.tap(find.byKey(const Key('pause-run-button')));
    expect(startStopPressed, 1);
    expect(pauseResumePressed, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            size: Size(390, 844),
          ),
          child: Scaffold(
            body: Column(
              children: [
                RunStartStopButton(
                  showsStopAction: true,
                  onPressed: () => startStopPressed += 1,
                ),
                RunPauseResumeButton(
                  isPaused: true,
                  onPressed: () => pauseResumePressed += 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('start-stop-button'))),
      const Size(120, 120),
    );
    expect(
      tester.getSize(find.byKey(const Key('resume-run-button'))),
      const Size(68, 68),
    );
    await tester.pump();
    for (final switcher in tester.widgetList<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    )) {
      expect(switcher.duration, Duration.zero);
    }
  });
}
