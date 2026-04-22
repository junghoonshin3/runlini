enum RunPointSource { deviceGps, healthKit, healthConnect, merged, simulated }

class RunPoint {
  const RunPoint({
    required this.latitude,
    required this.longitude,
    required this.timestampRelMs,
    required this.source,
    this.paceSecPerKm,
    this.speedMps,
    this.elevationM,
    this.heartRateBpm,
  });

  final double latitude;
  final double longitude;
  final int timestampRelMs;
  final double? paceSecPerKm;
  final double? speedMps;
  final double? elevationM;
  final int? heartRateBpm;
  final RunPointSource source;

  RunPoint copyWith({
    double? latitude,
    double? longitude,
    int? timestampRelMs,
    double? paceSecPerKm,
    double? speedMps,
    double? elevationM,
    int? heartRateBpm,
    RunPointSource? source,
  }) {
    return RunPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestampRelMs: timestampRelMs ?? this.timestampRelMs,
      paceSecPerKm: paceSecPerKm ?? this.paceSecPerKm,
      speedMps: speedMps ?? this.speedMps,
      elevationM: elevationM ?? this.elevationM,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      source: source ?? this.source,
    );
  }

  factory RunPoint.fromJson(Map<String, dynamic> json) {
    return RunPoint(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      timestampRelMs: json['timestampRelMs'] as int,
      paceSecPerKm: (json['paceSecPerKm'] as num?)?.toDouble(),
      speedMps: (json['speedMps'] as num?)?.toDouble(),
      elevationM: (json['elevationM'] as num?)?.toDouble(),
      heartRateBpm: (json['heartRateBpm'] as num?)?.round(),
      source: RunPointSource.values.byName(json['source'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lat': latitude,
      'lng': longitude,
      'timestampRelMs': timestampRelMs,
      'paceSecPerKm': paceSecPerKm,
      'speedMps': speedMps,
      'elevationM': elevationM,
      'heartRateBpm': heartRateBpm,
      'source': source.name,
    };
  }
}
