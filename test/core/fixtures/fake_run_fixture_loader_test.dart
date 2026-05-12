import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/fixtures/fake_run_fixture_loader.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads the Osaka Namba to Tobita recordRace fixture as a run session',
    () async {
      const loader = FakeRunFixtureLoader();

      final session = await loader.loadOsakaNambaTobitaRecordRace();

      expect(session.id, 'fixture_osaka_namba_tobita_record_race');
      expect(session.distanceM, 2909);
      expect(session.durationMs, 1047240);
      expect(session.averageCadenceSpm, 170);
      expect(session.sourceSummary, contains('cadence-170'));
      expect(session.points, hasLength(212));
      expect(session.points.first.latitude, closeTo(34.6645939, 0.0000001));
      expect(session.points.first.longitude, closeTo(135.5000968, 0.0000001));
      expect(session.points.first.timestampRelMs, 0);
      expect(session.points.first.paceSecPerKm, lessThan(360));
      expect(session.points.first.source, RunPointSource.simulated);
      expect(session.points.last.latitude, closeTo(34.6434216, 0.0000001));
      expect(session.points.last.longitude, closeTo(135.5058512, 0.0000001));
      expect(session.points.last.timestampRelMs, session.durationMs);
      expect(session.points.last.paceSecPerKm, greaterThan(360));
      for (var index = 1; index < session.points.length; index += 1) {
        expect(
          session.points[index].timestampRelMs,
          greaterThanOrEqualTo(session.points[index - 1].timestampRelMs),
        );
      }
    },
  );

  test(
    'loads the Osaka Namba to Kanzakigawa recordRace fixture with varied 7 minute pace',
    () async {
      const loader = FakeRunFixtureLoader();

      final session = await loader.loadOsakaNambaKanzakigawaRecordRace();
      final paces = session.points
          .map((RunPoint point) => point.paceSecPerKm!)
          .toList(growable: false);

      expect(session.id, 'fixture_osaka_namba_kanzakigawa_record_race');
      expect(session.distanceM, 7921);
      expect(session.durationMs, 3326820);
      expect(session.startedAt, DateTime.utc(2026, 4, 20, 7));
      expect(session.averageCadenceSpm, 170);
      expect(session.sourceSummary, contains('pace-7'));
      expect(session.sourceSummary, contains('cadence-170'));
      expect(session.points, hasLength(605));
      expect(session.points.first.latitude, closeTo(34.668446, 0.0000001));
      expect(session.points.first.longitude, closeTo(135.4969528, 0.0000001));
      expect(session.points.first.timestampRelMs, 0);
      expect(session.points.first.source, RunPointSource.simulated);
      expect(session.points.last.latitude, closeTo(34.7330019, 0.0000001));
      expect(session.points.last.longitude, closeTo(135.4791534, 0.0000001));
      expect(session.points.last.timestampRelMs, session.durationMs);
      expect(paces.reduce((a, b) => a < b ? a : b), lessThan(420));
      expect(paces.reduce((a, b) => a > b ? a : b), greaterThan(420));
      expect(paces.map((double pace) => pace.round()).toSet(), hasLength(8));
      for (var index = 1; index < session.points.length; index += 1) {
        expect(
          session.points[index].timestampRelMs,
          greaterThanOrEqualTo(session.points[index - 1].timestampRelMs),
        );
      }
    },
  );

  test(
    'keeps the primary run before the Osaka fixture for fallback maps',
    () async {
      const loader = FakeRunFixtureLoader();

      final sessions = await loader.loadAll();

      expect(sessions.first.id, 'fixture_morning_tempo');
      expect(
        sessions.map((session) => session.id),
        contains('fixture_osaka_namba_tobita_record_race'),
      );
      expect(
        sessions.map((session) => session.id),
        contains('fixture_osaka_namba_kanzakigawa_record_race'),
      );
    },
  );
}
