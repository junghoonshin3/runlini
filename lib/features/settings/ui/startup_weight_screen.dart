import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class StartupWeightScreen extends ConsumerStatefulWidget {
  const StartupWeightScreen({super.key});

  @override
  ConsumerState<StartupWeightScreen> createState() =>
      _StartupWeightScreenState();
}

class _StartupWeightScreenState extends ConsumerState<StartupWeightScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('startup-weight-screen'),
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                '체중을 입력해 주세요',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              const Text(
                '러닝 활동 칼로리를 계산하는 데 사용해요. 앱 안에만 저장됩니다.',
                style: _hintStyle,
              ),
              const SizedBox(height: 28),
              TextField(
                key: const Key('startup-weight-input'),
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
              const SizedBox(height: 18),
              SettingsCompactButton(
                key: const Key('startup-weight-save-button'),
                label: _saving ? '저장 중' : '저장하고 시작하기',
                selected: true,
                onPressed: _saving ? null : _save,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final value = double.tryParse(_controller.text.trim());
    if (value == null ||
        value < runBodyWeightMinKg ||
        value > runBodyWeightMaxKg) {
      setState(() {
        _errorText = '20kg부터 250kg 사이로 입력해 주세요.';
      });
      return;
    }
    setState(() {
      _errorText = null;
      _saving = true;
    });
    await ref
        .read(runSettingsControllerProvider.notifier)
        .setBodyWeightKg(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
  }
}

const _hintStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
  height: 1.35,
);
