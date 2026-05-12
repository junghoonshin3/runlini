import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:runlini/core/fixtures/google_route_run_session_factory.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class FakeRunFixtureLoader {
  const FakeRunFixtureLoader();

  static const String _assetPath = 'assets/fixtures/fake_run_session.json';
  static const String _osakaTobitaRouteAssetPath =
      'assets/fixtures/osaka_namba_tobita_route.json';
  static const String _osakaKanzakigawaRouteAssetPath =
      'assets/fixtures/osaka_namba_kanzakigawa_route.json';
  static const GoogleRouteRunSessionFactory _routeSessionFactory =
      GoogleRouteRunSessionFactory();

  Future<RunSession> loadDefault() async {
    final rawJson = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return RunSession.fromJson(decoded);
  }

  Future<RunSession> loadOsakaNambaTobitaRecordRace() async {
    final rawJson = await rootBundle.loadString(_osakaTobitaRouteAssetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return _routeSessionFactory.fromGoogleRoutesResponse(
      decoded,
      id: 'fixture_osaka_namba_tobita_record_race',
      startedAt: DateTime.utc(2026, 4, 18, 7, 30),
      sourceSummary: 'fixture:osaka-namba-tobita:pace-6:cadence-170',
      averagePaceSecPerKm: 360,
      averageCadenceSpm: 170,
    );
  }

  Future<RunSession> loadOsakaNambaKanzakigawaRecordRace() async {
    final rawJson = await rootBundle.loadString(
      _osakaKanzakigawaRouteAssetPath,
    );
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return _routeSessionFactory.fromGoogleRoutesResponse(
      decoded,
      id: 'fixture_osaka_namba_kanzakigawa_record_race',
      startedAt: DateTime.utc(2026, 4, 20, 7),
      sourceSummary: 'fixture:osaka-namba-kanzakigawa:pace-7:cadence-170',
      averagePaceSecPerKm: 420,
      averageCadenceSpm: 170,
      paceBands: GoogleRouteRunSessionFactory.rollingPaceBands,
    );
  }

  Future<List<RunSession>> loadAll() async {
    final primary = await loadDefault();
    final osakaTobitaRecordRace = await loadOsakaNambaTobitaRecordRace();
    final osakaKanzakigawaRecordRace =
        await loadOsakaNambaKanzakigawaRecordRace();

    return <RunSession>[
      primary,
      osakaTobitaRecordRace,
      osakaKanzakigawaRecordRace,
      _variant(
        primary,
        id: 'fixture_han_river_push',
        startedAt: primary.startedAt.subtract(const Duration(days: 1)),
        latOffset: 0.0036,
        lngOffset: -0.0022,
        distanceMultiplier: 1.55,
        durationMultiplier: 1.42,
        paceOffsetSecPerKm: -10,
        sourceSummary: 'fixture:simulated-river',
      ),
      _variant(
        primary,
        id: 'fixture_evening_hill',
        startedAt: primary.startedAt.subtract(
          const Duration(days: 3, hours: 12),
        ),
        latOffset: -0.0041,
        lngOffset: 0.0034,
        distanceMultiplier: 2.1,
        durationMultiplier: 2.25,
        paceOffsetSecPerKm: 16,
        sourceSummary: 'fixture:simulated-hill',
      ),
    ];
  }

  RunSession _variant(
    RunSession base, {
    required String id,
    required DateTime startedAt,
    required double latOffset,
    required double lngOffset,
    required double distanceMultiplier,
    required double durationMultiplier,
    required double paceOffsetSecPerKm,
    required String sourceSummary,
  }) {
    final points = base.points
        .map((RunPoint point) {
          return RunPoint(
            latitude: point.latitude + latOffset,
            longitude: point.longitude + lngOffset,
            timestampRelMs: (point.timestampRelMs * durationMultiplier).round(),
            paceSecPerKm: point.paceSecPerKm == null
                ? null
                : point.paceSecPerKm! + paceOffsetSecPerKm,
            source: point.source,
          );
        })
        .toList(growable: false);

    return RunSession(
      id: id,
      startedAt: startedAt,
      endedAt: startedAt.add(
        Duration(milliseconds: points.last.timestampRelMs),
      ),
      distanceM: base.distanceM * distanceMultiplier,
      durationMs: points.last.timestampRelMs,
      sourceSummary: sourceSummary,
      points: points,
    );
  }
}
