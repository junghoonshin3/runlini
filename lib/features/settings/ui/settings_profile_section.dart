import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class SettingsProfileSection extends ConsumerStatefulWidget {
  const SettingsProfileSection({super.key, required this.settings});

  final RunSettingsState settings;

  @override
  ConsumerState<SettingsProfileSection> createState() =>
      _SettingsProfileSectionState();
}

class _SettingsProfileSectionState
    extends ConsumerState<SettingsProfileSection> {
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _weightText(widget.settings.bodyWeightKg),
    );
  }

  @override
  void didUpdateWidget(SettingsProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.bodyWeightKg != widget.settings.bodyWeightKg) {
      _weightController.text = _weightText(widget.settings.bodyWeightKg);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionPanel(
      title: '프로필',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('체중', style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            key: const Key('runner-weight-input'),
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              suffixText: 'kg',
              hintText: '예: 70',
            ),
          ),
          const SizedBox(height: 10),
          const Text('러닝 활동 칼로리를 계산하는 데 사용해요. 앱 안에만 저장됩니다.', style: _hintStyle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SettingsCompactButton(
                key: const Key('save-runner-weight-button'),
                label: '체중 저장',
                onPressed: () => _saveWeight(context),
              ),
              SettingsCompactButton(
                key: const Key('clear-runner-weight-button'),
                label: '초기화',
                danger: true,
                onPressed: _clearWeight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveWeight(BuildContext context) async {
    final value = double.tryParse(_weightController.text.trim());
    if (value == null ||
        value < runBodyWeightMinKg ||
        value > runBodyWeightMaxKg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('체중은 20kg부터 250kg 사이로 입력해 주세요.')),
      );
      return;
    }
    await ref
        .read(runSettingsControllerProvider.notifier)
        .setBodyWeightKg(value);
  }

  Future<void> _clearWeight() {
    _weightController.clear();
    return ref
        .read(runSettingsControllerProvider.notifier)
        .setBodyWeightKg(null);
  }

  String _weightText(double? weightKg) {
    if (weightKg == null) {
      return '';
    }
    return weightKg.toStringAsFixed(
      weightKg.truncateToDouble() == weightKg ? 0 : 1,
    );
  }
}

const _labelStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);

const _hintStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
  height: 1.35,
);
