import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_motion.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

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
        onSetBodyWeightForCalories: session.caloriesKcal == null
            ? () => _showBodyWeightPrompt(context, ref)
            : null,
      ),
    );
  }

  Future<void> _showBodyWeightPrompt(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final weightKg = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      builder: (context) => const _CalorieWeightPromptSheet(),
    );
    if (weightKg == null) {
      return;
    }
    await ref
        .read(runSettingsControllerProvider.notifier)
        .setBodyWeightKg(weightKg);
    ref
        .read(runPlaybackControllerProvider.notifier)
        .applyBodyWeightToPendingFinishedRun(weightKg);
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

class _CalorieWeightPromptSheet extends StatefulWidget {
  const _CalorieWeightPromptSheet();

  @override
  State<_CalorieWeightPromptSheet> createState() =>
      _CalorieWeightPromptSheetState();
}

class _CalorieWeightPromptSheetState extends State<_CalorieWeightPromptSheet> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insetBottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        key: const Key('calorie-weight-input-sheet'),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + insetBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '몸무게 입력',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.chalk,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text('이번 기록의 칼로리 계산에만 사용돼요.', style: _hintStyle),
            const SizedBox(height: 16),
            TextField(
              key: const Key('calorie-weight-input'),
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                suffixText: 'kg',
                hintText: '예: 70',
                errorText: _errorText,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SettingsCompactButton(
                    key: const Key('calorie-weight-save-button'),
                    label: '저장',
                    selected: true,
                    expand: true,
                    onPressed: _save,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SettingsCompactButton(
                    key: const Key('calorie-weight-skip-button'),
                    label: '나중에',
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null ||
        value < runBodyWeightMinKg ||
        value > runBodyWeightMaxKg) {
      setState(() {
        _errorText = '20kg부터 250kg 사이로 입력해 주세요.';
      });
      return;
    }
    Navigator.of(context).pop(value);
  }
}

const _hintStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
  height: 1.35,
);
