// 러닝 시작 전 움직임 감지 권한 안내와 요청 흐름을 담당한다
part of 'running_tab_screen.dart';

enum _MotionPermissionPreflightDecision { request, skip }

extension _RunningTabScreenMotionPreflight on _RunningTabScreenState {
  Future<bool> _prepareMotionPermissionForStart(BuildContext context) async {
    final client = ref.read(runMotionPermissionClientProvider);
    final status = await client.checkActivityRecognitionPermission();
    if (!context.mounted) {
      return false;
    }
    if (_canStartWithoutMotionPrompt(status)) {
      return true;
    }
    if (status == RunMotionPermissionStatus.permanentlyDenied) {
      _showMotionPermissionSettingsSnackBar(context);
      return true;
    }

    final decision = await _showMotionPermissionPreflightDialog(context);
    if (!context.mounted) {
      return false;
    }
    if (decision != _MotionPermissionPreflightDecision.request) {
      return true;
    }

    final requestStatus = await client.requestActivityRecognitionPermission();
    if (!context.mounted) {
      return false;
    }
    if (requestStatus == RunMotionPermissionStatus.permanentlyDenied) {
      _showMotionPermissionSettingsSnackBar(context);
    }
    return true;
  }

  bool _canStartWithoutMotionPrompt(RunMotionPermissionStatus status) {
    return status == RunMotionPermissionStatus.granted ||
        status == RunMotionPermissionStatus.unavailable;
  }

  Future<_MotionPermissionPreflightDecision?>
  _showMotionPermissionPreflightDialog(BuildContext context) {
    return showDialog<_MotionPermissionPreflightDecision>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('motion-permission-preflight-dialog'),
          backgroundColor: AppColors.panel,
          title: const Text('움직임 감지를 준비할게요'),
          content: const Text(
            '허용하면 자동 일시정지, 케이던스, 걸음 기반 보정이 더 안정적으로 동작해요. '
            '거부해도 GPS 러닝은 시작할 수 있어요.',
          ),
          actions: [
            TextButton(
              key: const Key('motion-permission-skip-start-button'),
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_MotionPermissionPreflightDecision.skip),
              child: const Text('건너뛰고 시작'),
            ),
            TextButton(
              key: const Key('motion-permission-allow-start-button'),
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_MotionPermissionPreflightDecision.request),
              child: const Text('허용하고 시작'),
            ),
          ],
        );
      },
    );
  }

  void _showMotionPermissionSettingsSnackBar(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('움직임 감지 권한은 설정에서 다시 켤 수 있어요. GPS 러닝은 계속 시작합니다.'),
        action: SnackBarAction(
          label: '설정',
          onPressed: () {
            unawaited(
              ref.read(runMotionPermissionClientProvider).openAppSettings(),
            );
          },
        ),
      ),
    );
  }
}
