import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

Map<String, double> shoeDistanceKmById(List<RunSession> sessions) {
  final totals = <String, double>{};
  for (final session in sessions) {
    final shoeId = session.shoeId;
    if (shoeId == null) {
      continue;
    }
    totals[shoeId] = (totals[shoeId] ?? 0) + (session.distanceM / 1000);
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
