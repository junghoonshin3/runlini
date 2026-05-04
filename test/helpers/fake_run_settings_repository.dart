import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

class FakeRunSettingsRepository implements RunSettingsRepository {
  FakeRunSettingsRepository([this.settings = const RunSettingsState()]);

  RunSettingsState settings;

  @override
  Future<RunSettingsState> loadSettings() async => settings;

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    this.settings = settings;
  }

  @override
  Future<List<RunShoe>> listShoes() async => const <RunShoe>[];

  @override
  Future<void> saveShoe(RunShoe shoe) async {}

  @override
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> deleteShoe(String id) async {}
}
