import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class SettingsDistanceGoalSection extends ConsumerStatefulWidget {
  const SettingsDistanceGoalSection({super.key, required this.settings});

  final RunSettingsState settings;

  @override
  ConsumerState<SettingsDistanceGoalSection> createState() =>
      _SettingsDistanceGoalSectionState();
}

class _SettingsDistanceGoalSectionState
    extends ConsumerState<SettingsDistanceGoalSection> {
  late final TextEditingController _weeklyController;
  late final TextEditingController _monthlyController;
  late final TextEditingController _yearlyController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weeklyController = TextEditingController();
    _monthlyController = TextEditingController();
    _yearlyController = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant SettingsDistanceGoalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didGoalDisplayChange(oldWidget.settings, widget.settings)) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = distanceUnitLabel(widget.settings.display);
    return SettingsSectionPanel(
      title: '기록 목표',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록탭 원형 진행률에 사용할 목표 거리를 정해요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          _GoalInput(
            fieldKey: const Key('weekly-distance-goal-input'),
            label: '주간 목표 ($unit)',
            controller: _weeklyController,
          ),
          const SizedBox(height: 10),
          _GoalInput(
            fieldKey: const Key('monthly-distance-goal-input'),
            label: '월간 목표 ($unit)',
            controller: _monthlyController,
          ),
          const SizedBox(height: 10),
          _GoalInput(
            fieldKey: const Key('yearly-distance-goal-input'),
            label: '연간 목표 ($unit)',
            controller: _yearlyController,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const Key('distance-goals-error'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.electricRed,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SettingsCompactButton(
            key: const Key('save-distance-goals-button'),
            label: '목표 저장',
            onPressed: _saveGoals,
          ),
        ],
      ),
    );
  }

  void _syncControllers() {
    _weeklyController.text = _formatGoal(
      widget.settings.distanceGoals.weeklyGoalM,
    );
    _monthlyController.text = _formatGoal(
      widget.settings.distanceGoals.monthlyGoalM,
    );
    _yearlyController.text = _formatGoal(
      widget.settings.distanceGoals.yearlyGoalM,
    );
  }

  bool _didGoalDisplayChange(
    RunSettingsState oldSettings,
    RunSettingsState newSettings,
  ) {
    return oldSettings.display.distanceUnit !=
            newSettings.display.distanceUnit ||
        oldSettings.distanceGoals.weeklyGoalM !=
            newSettings.distanceGoals.weeklyGoalM ||
        oldSettings.distanceGoals.monthlyGoalM !=
            newSettings.distanceGoals.monthlyGoalM ||
        oldSettings.distanceGoals.yearlyGoalM !=
            newSettings.distanceGoals.yearlyGoalM;
  }

  String _formatGoal(double distanceM) {
    final value = distanceForDisplay(distanceM, widget.settings.display);
    final formatted = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }

  Future<void> _saveGoals() async {
    final weeklyM = _parseGoal(
      label: '주간 목표',
      controller: _weeklyController,
      minM: runWeeklyDistanceGoalMinM,
      maxM: runWeeklyDistanceGoalMaxM,
    );
    final monthlyM = _parseGoal(
      label: '월간 목표',
      controller: _monthlyController,
      minM: runMonthlyDistanceGoalMinM,
      maxM: runMonthlyDistanceGoalMaxM,
    );
    final yearlyM = _parseGoal(
      label: '연간 목표',
      controller: _yearlyController,
      minM: runYearlyDistanceGoalMinM,
      maxM: runYearlyDistanceGoalMaxM,
    );
    if (weeklyM == null || monthlyM == null || yearlyM == null) {
      return;
    }
    setState(() => _error = null);
    await ref
        .read(runSettingsControllerProvider.notifier)
        .setDistanceGoals(
          RunDistanceGoalSettings(
            weeklyGoalM: weeklyM,
            monthlyGoalM: monthlyM,
            yearlyGoalM: yearlyM,
          ),
        );
  }

  double? _parseGoal({
    required String label,
    required TextEditingController controller,
    required double minM,
    required double maxM,
  }) {
    final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) {
      setState(() => _error = '$label은 숫자로 입력해줘.');
      return null;
    }
    final meters = distanceMetersFromDisplay(value, widget.settings.display);
    if (meters < minM || meters > maxM) {
      setState(() => _error = '$label은 ${_rangeLabel(minM, maxM)} 사이로 입력해줘.');
      return null;
    }
    return meters;
  }

  String _rangeLabel(double minM, double maxM) {
    final min = _formatRangeValue(minM);
    final max = _formatRangeValue(maxM);
    return '$min-$max ${distanceUnitLabel(widget.settings.display)}';
  }

  String _formatRangeValue(double distanceM) {
    final value = distanceForDisplay(distanceM, widget.settings.display);
    return value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _GoalInput extends StatelessWidget {
  const _GoalInput({
    required this.fieldKey,
    required this.label,
    required this.controller,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.muted),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.voltGreen, width: 2),
        ),
      ),
    );
  }
}
