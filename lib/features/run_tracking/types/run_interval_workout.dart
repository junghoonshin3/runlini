import 'package:flutter/foundation.dart';

enum RunIntervalTargetType { time, distance, open, skip }

enum RunIntervalStepKind { warmup, work, recovery, cooldown, finished }

@immutable
class RunIntervalTarget {
  const RunIntervalTarget({
    required this.type,
    this.durationMs,
    this.distanceM,
  });

  const RunIntervalTarget.time(int durationMs)
    : this(type: RunIntervalTargetType.time, durationMs: durationMs);

  const RunIntervalTarget.distance(double distanceM)
    : this(type: RunIntervalTargetType.distance, distanceM: distanceM);

  const RunIntervalTarget.open() : this(type: RunIntervalTargetType.open);

  const RunIntervalTarget.skip() : this(type: RunIntervalTargetType.skip);

  final RunIntervalTargetType type;
  final int? durationMs;
  final double? distanceM;

  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.name,
    'durationMs': durationMs,
    'distanceM': distanceM,
  };

  factory RunIntervalTarget.fromJson(Map<String, dynamic> json) {
    final type = RunIntervalTargetType.values.byName(
      json['type'] as String? ?? RunIntervalTargetType.time.name,
    );
    return RunIntervalTarget(
      type: type,
      durationMs: (json['durationMs'] as num?)?.round(),
      distanceM: (json['distanceM'] as num?)?.toDouble(),
    );
  }
}

@immutable
class RunIntervalWorkout {
  const RunIntervalWorkout({
    this.enabled = false,
    this.warmup = const RunIntervalTarget.time(5 * 60 * 1000),
    this.work = const RunIntervalTarget.time(60 * 1000),
    this.recovery = const RunIntervalTarget.time(60 * 1000),
    this.repeatCount = 8,
    this.cooldown = const RunIntervalTarget.time(5 * 60 * 1000),
  });

  final bool enabled;
  final RunIntervalTarget warmup;
  final RunIntervalTarget work;
  final RunIntervalTarget recovery;
  final int repeatCount;
  final RunIntervalTarget cooldown;

  RunIntervalWorkout copyWith({
    bool? enabled,
    RunIntervalTarget? warmup,
    RunIntervalTarget? work,
    RunIntervalTarget? recovery,
    int? repeatCount,
    RunIntervalTarget? cooldown,
  }) {
    return RunIntervalWorkout(
      enabled: enabled ?? this.enabled,
      warmup: warmup ?? this.warmup,
      work: work ?? this.work,
      recovery: recovery ?? this.recovery,
      repeatCount: repeatCount ?? this.repeatCount,
      cooldown: cooldown ?? this.cooldown,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'warmup': warmup.toJson(),
    'work': work.toJson(),
    'recovery': recovery.toJson(),
    'repeatCount': repeatCount,
    'cooldown': cooldown.toJson(),
  };

  factory RunIntervalWorkout.fromJson(Map<String, dynamic> json) {
    return RunIntervalWorkout(
      enabled: json['enabled'] as bool? ?? false,
      warmup: _target(json['warmup'], const RunIntervalTarget.time(300000)),
      work: _target(json['work'], const RunIntervalTarget.time(60000)),
      recovery: _target(json['recovery'], const RunIntervalTarget.time(60000)),
      repeatCount: ((json['repeatCount'] as num?)?.round() ?? 8).clamp(1, 99),
      cooldown: _target(json['cooldown'], const RunIntervalTarget.time(300000)),
    );
  }

  static RunIntervalTarget _target(Object? value, RunIntervalTarget fallback) {
    if (value is Map<String, dynamic>) {
      return RunIntervalTarget.fromJson(value);
    }
    if (value is Map) {
      return RunIntervalTarget.fromJson(Map<String, dynamic>.from(value));
    }
    return fallback;
  }
}
