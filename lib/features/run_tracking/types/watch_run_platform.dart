import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

enum WatchRunPlatform { wearOs, watchOs }

extension WatchRunPlatformMapping on WatchRunPlatform {
  RunSessionCaptureSource get captureSource {
    return switch (this) {
      WatchRunPlatform.wearOs => RunSessionCaptureSource.wearOs,
      WatchRunPlatform.watchOs => RunSessionCaptureSource.watchOs,
    };
  }

  RunPointSource get pointSource {
    return switch (this) {
      WatchRunPlatform.wearOs => RunPointSource.wearOs,
      WatchRunPlatform.watchOs => RunPointSource.watchOs,
    };
  }

  String get label {
    return switch (this) {
      WatchRunPlatform.wearOs => 'Wear OS',
      WatchRunPlatform.watchOs => 'Apple Watch',
    };
  }
}
