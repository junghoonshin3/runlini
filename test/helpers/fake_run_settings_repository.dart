import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

class FakeRunSettingsRepository implements RunSettingsRepository {
  FakeRunSettingsRepository([
    this.settings = const RunSettingsState(),
    List<RunShoe>? shoes,
  ]) : shoes = <RunShoe>[...?shoes];

  RunSettingsState settings;
  final List<RunShoe> shoes;

  @override
  Future<RunSettingsState> loadSettings() async => settings;

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    this.settings = settings;
  }

  @override
  Future<List<RunShoe>> listShoes() async => List<RunShoe>.unmodifiable(shoes);

  @override
  Future<void> saveShoe(RunShoe shoe) async {
    shoes.removeWhere((existing) => existing.id == shoe.id);
    shoes.add(shoe);
  }

  @override
  Future<void> retireShoe(String id) async {
    final index = shoes.indexWhere((shoe) => shoe.id == id);
    if (index >= 0) {
      shoes[index] = shoes[index].copyWith(retired: true);
    }
  }

  @override
  Future<void> deleteShoe(String id) async {
    final index = shoes.indexWhere((shoe) => shoe.id == id);
    if (index >= 0) {
      shoes[index] = shoes[index].copyWith(retired: true, deleted: true);
    }
  }
}
