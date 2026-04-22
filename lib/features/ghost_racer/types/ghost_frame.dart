import 'package:runlini/features/run_tracking/types/run_point.dart';

enum GhostRelativeState { ahead, behind, level }

class GhostFrame {
  const GhostFrame({
    required this.runnerPoint,
    required this.ghostPoint,
    required this.gapMeters,
    required this.relativeState,
  });

  final RunPoint runnerPoint;
  final RunPoint ghostPoint;
  final double gapMeters;
  final GhostRelativeState relativeState;
}
