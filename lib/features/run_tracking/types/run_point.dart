enum RunPointSource {
  deviceGps,
  healthKit,
  healthConnect,
  merged,
  simulated,
  wearOs,
  watchOs,
}

class RunPoint {
  const RunPoint({
    required this.latitude,
    required this.longitude,
    required this.timestampRelMs,
    required this.source,
    this.paceSecPerKm,
    this.speedMps,
    this.horizontalAccuracyM,
    this.speedAccuracyMps,
    this.elevationM,
    this.heartRateBpm,
  });

  final double latitude;
  final double longitude;
  final int timestampRelMs;
  final double? paceSecPerKm;
  final double? speedMps;
  final double? horizontalAccuracyM;
  final double? speedAccuracyMps;
  final double? elevationM;
  final int? heartRateBpm;
  final RunPointSource source;

  RunPoint copyWith({
    double? latitude,
    double? longitude,
    int? timestampRelMs,
    double? paceSecPerKm,
    double? speedMps,
    double? horizontalAccuracyM,
    double? speedAccuracyMps,
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
      horizontalAccuracyM: horizontalAccuracyM ?? this.horizontalAccuracyM,
      speedAccuracyMps: speedAccuracyMps ?? this.speedAccuracyMps,
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
      horizontalAccuracyM: (json['horizontalAccuracyM'] as num?)?.toDouble(),
      speedAccuracyMps: (json['speedAccuracyMps'] as num?)?.toDouble(),
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
      'horizontalAccuracyM': horizontalAccuracyM,
      'speedAccuracyMps': speedAccuracyMps,
      'elevationM': elevationM,
      'heartRateBpm': heartRateBpm,
      'source': source.name,
    };
  }
}
