import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

Future<bool> confirmDisableIntervalForRecordRace(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('record-race-interval-conflict-dialog'),
        backgroundColor: AppColors.panel,
        title: const Text('기록 레이스에서는 인터벌을 사용할 수 없어요'),
        content: const Text('기록 레이스와 비교하려면 인터벌을 끄고 시작해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('disable-interval-for-record-race-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('인터벌 끄고 기록 레이스 선택'),
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<bool> confirmDisableRecordRaceForInterval(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('interval-record-race-conflict-dialog'),
        backgroundColor: AppColors.panel,
        title: const Text('인터벌에서는 기록 레이스을 사용할 수 없어요'),
        content: const Text('인터벌 러닝을 사용하려면 기록 레이스 선택을 해제해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('disable-record-race-for-interval-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('기록 레이스 끄고 인터벌 켜기'),
          ),
        ],
      );
    },
  );
  return result == true;
}
