import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

abstract class RunRecorder {
  Stream<RunPoint> watchRun();
  Future<void> start();
  Future<RunSession> stop();
}
