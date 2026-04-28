import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

abstract interface class RunSettingsRepository {
  Future<RunSettingsState> loadSettings();

  Future<void> saveSettings(RunSettingsState settings);

  Future<List<RunShoe>> listShoes();

  Future<void> saveShoe(RunShoe shoe);

  Future<void> retireShoe(String id);

  Future<void> deleteShoe(String id);
}
