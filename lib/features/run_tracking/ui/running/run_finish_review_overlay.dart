import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/ui/runlini_motion.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';

class RunFinishReviewOverlay extends ConsumerWidget {
  const RunFinishReviewOverlay({
    super.key,
    required this.session,
    required this.onSave,
    required this.onDiscard,
  });

  final RunSession session;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final privacySettings = ref.watch(runPrivacySettingsProvider);
    final shoes = ref.watch(runShoeListProvider).value ?? const <RunShoe>[];
    final shoe = _shoeFor(shoes);

    return RunliniOverlayEntrance(
      child: RunFinishReviewPanel(
        session: session,
        displaySettings: displaySettings,
        privacySettings: privacySettings,
        shoeName: shoe == null ? null : '${shoe.brand} ${shoe.name}',
        shoeImagePath: shoe?.imagePath,
        onSave: onSave,
        onDiscard: onDiscard,
      ),
    );
  }

  RunShoe? _shoeFor(List<RunShoe> shoes) {
    final shoeId = session.shoeId;
    if (shoeId == null) {
      return null;
    }
    for (final shoe in shoes) {
      if (shoe.id == shoeId) {
        return shoe;
      }
    }
    return null;
  }
}
