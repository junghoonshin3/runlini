import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';

class AppTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.history;

  void setTab(AppTab tab) {
    state = tab;
  }
}

final appTabProvider = NotifierProvider<AppTabNotifier, AppTab>(
  AppTabNotifier.new,
);

final startupWeightPromptEnabledProvider = Provider<bool>((Ref ref) => true);
