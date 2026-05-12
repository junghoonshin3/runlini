// 시간 기반 기록 레이스 투영 결과를 표현한다.
import 'package:runlini/features/run_tracking/types/run_point.dart';

enum RecordRaceRelativeState { ahead, behind, level }

class RecordRaceProjectionFrame {
  const RecordRaceProjectionFrame({
    required this.runnerPoint,
    required this.recordRacePoint,
    required this.gapMeters,
    required this.relativeState,
  });

  final RunPoint runnerPoint;
  final RunPoint recordRacePoint;
  final double gapMeters;
  final RecordRaceRelativeState relativeState;
}
