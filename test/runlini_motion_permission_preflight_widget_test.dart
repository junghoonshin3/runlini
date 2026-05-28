// 러닝 시작 전 움직임 감지 권한 안내 플로우를 검증한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/motion/run_motion_permission_client.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets(
    'motion permission preflight appears before countdown and can be skipped',
    (WidgetTester tester) async {
      final motionPermissionClient = TestRunMotionPermissionClient(
        checkStatus: RunMotionPermissionStatus.denied,
      );
      await _pumpRunningTab(tester, motionPermissionClient);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('motion-permission-preflight-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );
      expect(motionPermissionClient.requestCalls, 0);

      await tester.tap(
        find.byKey(const Key('motion-permission-skip-start-button')),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('motion-permission-preflight-dialog')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );
      expect(motionPermissionClient.requestCalls, 0);

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
    },
  );

  testWidgets(
    'motion permission allow action requests before countdown starts',
    (WidgetTester tester) async {
      final motionPermissionClient = TestRunMotionPermissionClient(
        checkStatus: RunMotionPermissionStatus.denied,
        requestStatus: RunMotionPermissionStatus.granted,
      );
      await _pumpRunningTab(tester, motionPermissionClient);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('motion-permission-allow-start-button')),
      );
      await tester.pump();

      expect(motionPermissionClient.requestCalls, 1);
      expect(
        find.byKey(const Key('motion-permission-preflight-dialog')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
    },
  );

  testWidgets(
    'permanently denied motion permission still starts GPS-only countdown',
    (WidgetTester tester) async {
      final motionPermissionClient = TestRunMotionPermissionClient(
        checkStatus: RunMotionPermissionStatus.permanentlyDenied,
      );
      await _pumpRunningTab(tester, motionPermissionClient);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(motionPermissionClient.requestCalls, 0);
      expect(
        find.byKey(const Key('motion-permission-preflight-dialog')),
        findsNothing,
      );
      expect(find.text('설정'), findsOneWidget);
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();

      expect(motionPermissionClient.settingsCalls, 1);
    },
  );
}

Future<void> _pumpRunningTab(
  WidgetTester tester,
  TestRunMotionPermissionClient motionPermissionClient,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disableStartupWeightPromptOverride,
        staticMapStateOverride(
          fallbackMapCenter: const MapCoordinate(
            latitude: 37.0,
            longitude: 127.0,
          ),
        ),
        deviceLocationClientProvider.overrideWithValue(
          FakeDeviceLocationClient(
            lastKnownSample: sample(latitude: 37.55, longitude: 126.97),
          ),
        ),
        locationStreamClientProvider.overrideWithValue(
          const SilentLocationStreamClient(),
        ),
        runMotionPermissionClientProvider.overrideWithValue(
          motionPermissionClient,
        ),
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
      child: const RunliniApp(),
    ),
  );
  await tester.pump();
  await openRunningTab(tester);
  await pumpUntilFound(tester, find.byKey(const Key('run-map')));
}

class TestRunMotionPermissionClient implements RunMotionPermissionClient {
  TestRunMotionPermissionClient({
    required this.checkStatus,
    this.requestStatus = RunMotionPermissionStatus.denied,
  });

  final RunMotionPermissionStatus checkStatus;
  final RunMotionPermissionStatus requestStatus;
  int checkCalls = 0;
  int requestCalls = 0;
  int settingsCalls = 0;

  @override
  Future<RunMotionPermissionStatus> checkActivityRecognitionPermission() async {
    checkCalls += 1;
    return checkStatus;
  }

  @override
  Future<RunMotionPermissionStatus>
  requestActivityRecognitionPermission() async {
    requestCalls += 1;
    return requestStatus;
  }

  @override
  Future<void> openAppSettings() async {
    settingsCalls += 1;
  }
}
