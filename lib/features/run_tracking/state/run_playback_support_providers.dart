import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/service/finished_run_session_builder.dart';
import 'package:runlini/features/run_tracking/service/run_health_export_status_mapper.dart';
import 'package:runlini/features/run_tracking/state/run_playback_core_providers.dart';

final finishedRunSessionBuilderProvider = Provider<FinishedRunSessionBuilder>(
  (Ref ref) => FinishedRunSessionBuilder(
    routeSegmenter: ref.watch(runRouteSegmenterProvider),
  ),
);

final runHealthExportStatusMapperProvider =
    Provider<RunHealthExportStatusMapper>(
      (Ref ref) => const RunHealthExportStatusMapper(),
    );
