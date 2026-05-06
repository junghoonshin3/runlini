import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

Future<bool> confirmDisableIntervalForGhost(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('ghost-interval-conflict-dialog'),
        backgroundColor: AppColors.panel,
        title: const Text('고스트런에서는 인터벌을 사용할 수 없어요'),
        content: const Text('고스트와 비교하려면 인터벌을 끄고 시작해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('disable-interval-for-ghost-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('인터벌 끄고 고스트 선택'),
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<bool> confirmDisableGhostForInterval(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('interval-ghost-conflict-dialog'),
        backgroundColor: AppColors.panel,
        title: const Text('인터벌에서는 고스트런을 사용할 수 없어요'),
        content: const Text('인터벌 러닝을 사용하려면 고스트 선택을 해제해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('disable-ghost-for-interval-button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('고스트 끄고 인터벌 켜기'),
          ),
        ],
      );
    },
  );
  return result == true;
}
