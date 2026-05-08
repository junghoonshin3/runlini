// 기록 상세 막대 차트 동작을 검증하는 테스트
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_bar_chart.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_chart_haptic_layer.dart';

void main() {
  testWidgets('metric charts render as bars and taps stay silent', (
    tester,
  ) async {
    final hapticCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const MaterialApp(home: _ChartHarness()));
    await tester.pump();

    expect(find.byType(LineChart), findsNothing);
    expect(find.byType(BarChart), findsWidgets);

    final chart = tester.widget<BarChart>(find.byType(BarChart).first);
    expect(chart.data.barGroups, isNotEmpty);
    expect(chart.data.barTouchData.touchExtraThreshold.horizontal, 16);
    expect(chart.data.extraLinesData.horizontalLines, isNotEmpty);

    await tester.tap(find.byType(RunDetailChartHapticLayer).first);
    await tester.pump();

    expect(hapticCalls, isEmpty);
  });

  testWidgets('tiny chart movements do not trigger haptics', (tester) async {
    final hapticCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const MaterialApp(home: _ChartHarness()));
    await tester.pump();

    final chartRect = tester.getRect(
      find.byType(RunDetailChartHapticLayer).first,
    );
    final gesture = await tester.startGesture(
      Offset(chartRect.left + 20, chartRect.center.dy),
    );
    await tester.pump();
    await gesture.moveTo(Offset(chartRect.left + 23, chartRect.center.dy));
    await tester.pump();
    await gesture.up();

    expect(hapticCalls, isEmpty);
  });

  testWidgets('dragging across chart surface triggers haptics', (tester) async {
    final hapticCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const MaterialApp(home: _ChartHarness()));
    await tester.pump();

    final chartRect = tester.getRect(
      find.byType(RunDetailChartHapticLayer).first,
    );
    final gesture = await tester.startGesture(
      Offset(chartRect.left + 1, chartRect.center.dy),
    );
    await tester.pump();
    await gesture.moveTo(Offset(chartRect.left + 2, chartRect.center.dy));
    await tester.pump();
    await gesture.moveTo(Offset(chartRect.center.dx, chartRect.center.dy));
    await tester.pump();
    await gesture.moveTo(Offset(chartRect.right - 2, chartRect.center.dy));
    await tester.pump();
    await gesture.up();

    expect(hapticCalls.length, greaterThanOrEqualTo(2));
    expect(
      hapticCalls.map((call) => call.arguments),
      everyElement('HapticFeedbackType.lightImpact'),
    );
  });
}

class _ChartHarness extends StatelessWidget {
  const _ChartHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: RunDetailBarChart(
            title: 'Pace (min/km)',
            samples: const [
              RunMetricSample(elapsedMs: 0, value: 420),
              RunMetricSample(elapsedMs: 300000, value: 410),
              RunMetricSample(elapsedMs: 600000, value: 400),
            ],
            color: Colors.cyan,
            emptyLabel: '페이스 데이터가 아직 없어요.',
            durationMs: 600000,
            valueFormatter: (value) => '${value.round()}',
            summaryFormatter: (average, min, max) =>
                'Avg ${average.round()} · ${min.round()}-${max.round()}',
          ),
        ),
      ),
    );
  }
}
