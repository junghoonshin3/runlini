import 'package:flutter/foundation.dart';

String healthDestinationLabel(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.android => 'Health Connect',
    TargetPlatform.iOS => '건강 앱',
    _ => 'Health',
  };
}

String healthDestinationSendTarget(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.iOS => '건강 앱으로',
    TargetPlatform.android => 'Health Connect로',
    _ => 'Health로',
  };
}

String healthDestinationSavedLabel(TargetPlatform platform) {
  return '${healthDestinationLabel(platform)}에 저장됨';
}

String healthDestinationFailedLabel(TargetPlatform platform) {
  return '${healthDestinationLabel(platform)} 전송 실패';
}

String healthDestinationRetryLabel(TargetPlatform platform) {
  return '${healthDestinationSendTarget(platform)} 다시 보내기';
}
