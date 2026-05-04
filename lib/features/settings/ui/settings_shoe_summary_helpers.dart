import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

Map<String, double> shoeDistanceKmById(List<RunSessionSummary> sessions) {
  final totals = <String, double>{};
  for (final summary in sessions) {
    final shoeId = summary.shoeId;
    if (shoeId == null) {
      continue;
    }
    totals[shoeId] = (totals[shoeId] ?? 0) + summary.distanceKm;
  }
  return totals;
}

RunShoe? defaultShoeFor(List<RunShoe> shoes, String? defaultShoeId) {
  if (defaultShoeId == null) {
    return null;
  }
  for (final shoe in shoes) {
    if (shoe.id == defaultShoeId && !shoe.deleted) {
      return shoe;
    }
  }
  return null;
}
