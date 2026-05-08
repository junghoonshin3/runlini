// 러닝화 기록 화면 로딩 상태를 표현하는 스켈레톤 UI
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_skeleton.dart';

class SettingsShoeCoursesSkeleton extends StatelessWidget {
  const SettingsShoeCoursesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('shoe-courses-skeleton'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        if (index == 0) {
          return RunliniSkeletonPanel(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.chalk.withValues(alpha: 0.22),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RunliniSkeletonText(width: 178, height: 22),
                SizedBox(height: 10),
                RunliniSkeletonText(width: 128, height: 14),
              ],
            ),
          );
        }
        return const RunliniSkeletonTile();
      },
    );
  }
}
