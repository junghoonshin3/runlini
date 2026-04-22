import 'package:flutter/foundation.dart';

@immutable
class RunStartCountdownState {
  const RunStartCountdownState._({
    required this.isActive,
    required this.remainingSeconds,
  });

  const RunStartCountdownState.inactive()
    : this._(isActive: false, remainingSeconds: null);

  const RunStartCountdownState.active({required int remainingSeconds})
    : this._(isActive: true, remainingSeconds: remainingSeconds);

  final bool isActive;
  final int? remainingSeconds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RunStartCountdownState &&
        other.isActive == isActive &&
        other.remainingSeconds == remainingSeconds;
  }

  @override
  int get hashCode => Object.hash(isActive, remainingSeconds);
}
