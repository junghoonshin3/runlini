import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_route_speed_tooltip.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';

void main() {
  testWidgets('history detail shows route speed info tooltip', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester, showRouteSpeedTooltip: true);

    expect(find.byKey(const Key('route-speed-info-button')), findsOneWidget);

    await _showTooltip(tester);

    expect(find.byKey(const Key('route-speed-info-popover')), findsOneWidget);
    expect(find.byKey(const Key('route-speed-row-fast')), findsOneWidget);
    expect(find.byKey(const Key('route-speed-row-average')), findsOneWidget);
    expect(find.byKey(const Key('route-speed-row-slow')), findsOneWidget);
    expect(find.text('빠름'), findsOneWidget);
    expect(find.text('평균'), findsOneWidget);
    expect(find.text('느림'), findsOneWidget);
    expect(find.text('20.0 km/h'), findsOneWidget);
    expect(find.text('0.1 km'), findsWidgets);
    expect(find.textContaining('초록 · 빠른 구간'), findsNothing);
  });

  testWidgets('finish review hides route speed info tooltip by default', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(tester);

    expect(find.byKey(const Key('route-speed-info-button')), findsNothing);
  });

  testWidgets('route speed info tooltip follows imperial display settings', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(
      tester,
      showRouteSpeedTooltip: true,
      displaySettings: const RunDisplaySettings(
        distanceUnit: RunDistanceUnit.mi,
        paceUnit: RunPaceUnit.minPerMi,
        speedUnit: RunSpeedUnit.mph,
      ),
    );

    await _showTooltip(tester);

    expect(find.text('12.4 mph'), findsOneWidget);
    expect(find.text('0.07 mi'), findsWidgets);
  });

  testWidgets('route speed info tooltip shows empty message without data', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(
      tester,
      showRouteSpeedTooltip: true,
      session: _session(
        points: const <RunPoint>[
          RunPoint(
            latitude: 0,
            longitude: 0,
            timestampRelMs: 0,
            source: RunPointSource.simulated,
          ),
        ],
      ),
    );

    await _showTooltip(tester);

    expect(find.byKey(const Key('route-speed-empty-popover')), findsOneWidget);
    expect(find.text('속도 데이터 부족'), findsOneWidget);
  });

  testWidgets('route speed info popover stays inside a narrow viewport', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(280, 420));
    await _pumpInfoButtonHarness(tester, alignment: Alignment.topRight);

    await _showTooltip(tester);

    final rect = tester.getRect(
      find.byKey(const Key('route-speed-info-popover')),
    );
    expect(rect.left, greaterThanOrEqualTo(12));
    expect(rect.right, lessThanOrEqualTo(268));
  });

  testWidgets(
    'route speed info popover moves above when below space is short',
    (WidgetTester tester) async {
      _setViewport(tester, const Size(320, 260));
      await _pumpInfoButtonHarness(tester, alignment: Alignment.bottomRight);

      final buttonRect = tester.getRect(
        find.byKey(const Key('route-speed-info-button')),
      );
      await _showTooltip(tester);

      final popoverRect = tester.getRect(
        find.byKey(const Key('route-speed-info-popover')),
      );
      expect(popoverRect.bottom, lessThanOrEqualTo(buttonRect.top));
    },
  );
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  bool showRouteSpeedTooltip = false,
  RunDisplaySettings displaySettings = const RunDisplaySettings(),
  RunSession? session,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RunFinishReviewPanel(
          session: session ?? _session(),
          displaySettings: displaySettings,
          showRouteSpeedTooltip: showRouteSpeedTooltip,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpInfoButtonHarness(
  WidgetTester tester, {
  Alignment alignment = Alignment.topRight,
  RunDisplaySettings displaySettings = const RunDisplaySettings(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: alignment,
            child: RunDetailRouteSpeedInfoButton(
              points: _session().points,
              displaySettings: displaySettings,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _showTooltip(WidgetTester tester) async {
  final button = find.byKey(const Key('route-speed-info-button'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump(const Duration(milliseconds: 250));
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

RunSession _session({List<RunPoint>? points}) {
  return RunSession(
    id: 'tooltip-run',
    startedAt: DateTime.utc(2026, 5, 6, 6),
    distanceM: 333,
    durationMs: 130000,
    sourceSummary: 'fixture:test',
    points:
        points ??
        const <RunPoint>[
          RunPoint(
            latitude: 0,
            longitude: 0,
            timestampRelMs: 0,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.001,
            timestampRelMs: 20000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.002,
            timestampRelMs: 60000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.003,
            timestampRelMs: 130000,
            source: RunPointSource.simulated,
          ),
        ],
  );
}
