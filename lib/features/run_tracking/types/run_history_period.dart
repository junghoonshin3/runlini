enum RunHistoryPeriod { week, month, year }

extension RunHistoryPeriodLabels on RunHistoryPeriod {
  String get controlLabel {
    return switch (this) {
      RunHistoryPeriod.week => '이번주',
      RunHistoryPeriod.month => '이번달',
      RunHistoryPeriod.year => '올해',
    };
  }

  String get distanceLabel {
    return switch (this) {
      RunHistoryPeriod.week => '이번주 달린 거리',
      RunHistoryPeriod.month => '이번달 달린 거리',
      RunHistoryPeriod.year => '올해 달린 거리',
    };
  }

  String get goalLabel {
    return switch (this) {
      RunHistoryPeriod.week => '주간 목표',
      RunHistoryPeriod.month => '월간 목표',
      RunHistoryPeriod.year => '연간 목표',
    };
  }
}
