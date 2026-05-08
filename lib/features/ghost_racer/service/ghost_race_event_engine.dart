// 고스트런 라이브 이벤트 안정화와 중복 억제를 담당하는 엔진
import 'package:flutter/foundation.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';

enum GhostRaceEventType {
  offRoute,
  backOnRoute,
  overtake,
  lostLead,
  last500m,
  last200m,
  completed,
}

@immutable
class GhostRaceEvent {
  const GhostRaceEvent({required this.type, required this.frame});

  final GhostRaceEventType type;
  final GhostRaceFrame frame;
}

class GhostRaceEventEngine {
  GhostRaceEventEngine({
    this.offRouteStableDuration = const Duration(seconds: 10),
    this.leadStableDuration = const Duration(seconds: 15),
  });

  final Duration offRouteStableDuration;
  final Duration leadStableDuration;

  String? _sessionId;
  DateTime? _offRouteSince;
  DateTime? _backOnRouteSince;
  bool _offRouteAlerted = false;
  bool _backOnRouteAlerted = false;
  GhostRaceStatus? _leadCandidate;
  DateTime? _leadCandidateSince;
  GhostRaceStatus? _stableLeadStatus;
  bool _last500mAlerted = false;
  bool _last200mAlerted = false;
  bool _completedAlerted = false;

  List<GhostRaceEvent> eventsFor({
    required String sessionId,
    required GhostRaceFrame? frame,
    required bool isRunning,
    required DateTime now,
    bool completionPending = false,
  }) {
    if (_sessionId != sessionId) {
      reset();
      _sessionId = sessionId;
    }
    if (!isRunning || frame == null) {
      return const <GhostRaceEvent>[];
    }
    if (frame.status == GhostRaceStatus.unavailable) {
      return const <GhostRaceEvent>[];
    }

    final events = <GhostRaceEvent>[];
    events.addAll(_routeEvents(frame, now));
    events.addAll(_leadEvents(frame, now));
    events.addAll(_finalStretchEvents(frame));
    if (completionPending && !_completedAlerted) {
      _completedAlerted = true;
      events.add(
        GhostRaceEvent(type: GhostRaceEventType.completed, frame: frame),
      );
    }
    return events;
  }

  void reset() {
    _sessionId = null;
    _offRouteSince = null;
    _backOnRouteSince = null;
    _offRouteAlerted = false;
    _backOnRouteAlerted = false;
    _leadCandidate = null;
    _leadCandidateSince = null;
    _stableLeadStatus = null;
    _last500mAlerted = false;
    _last200mAlerted = false;
    _completedAlerted = false;
  }

  List<GhostRaceEvent> _routeEvents(GhostRaceFrame frame, DateTime now) {
    final events = <GhostRaceEvent>[];
    if (frame.isOffRoute || frame.status == GhostRaceStatus.offRoute) {
      _backOnRouteSince = null;
      _backOnRouteAlerted = false;
      _offRouteSince ??= now;
      if (!_offRouteAlerted &&
          now.difference(_offRouteSince!) >= offRouteStableDuration) {
        _offRouteAlerted = true;
        events.add(
          GhostRaceEvent(type: GhostRaceEventType.offRoute, frame: frame),
        );
      }
      return events;
    }

    _offRouteSince = null;
    if (_offRouteAlerted && !_backOnRouteAlerted) {
      _backOnRouteSince ??= now;
      if (now.difference(_backOnRouteSince!) >= offRouteStableDuration) {
        _backOnRouteAlerted = true;
        _offRouteAlerted = false;
        events.add(
          GhostRaceEvent(type: GhostRaceEventType.backOnRoute, frame: frame),
        );
      }
    }
    return events;
  }

  List<GhostRaceEvent> _leadEvents(GhostRaceFrame frame, DateTime now) {
    final status = frame.status;
    if (status != GhostRaceStatus.ahead && status != GhostRaceStatus.behind) {
      _leadCandidate = null;
      _leadCandidateSince = null;
      return const <GhostRaceEvent>[];
    }

    if (_leadCandidate != status) {
      _leadCandidate = status;
      _leadCandidateSince = now;
      return const <GhostRaceEvent>[];
    }

    final since = _leadCandidateSince ?? now;
    if (now.difference(since) < leadStableDuration ||
        _stableLeadStatus == status) {
      return const <GhostRaceEvent>[];
    }

    final previous = _stableLeadStatus;
    _stableLeadStatus = status;
    if (previous == null) {
      return const <GhostRaceEvent>[];
    }

    return [
      GhostRaceEvent(
        type: status == GhostRaceStatus.ahead
            ? GhostRaceEventType.overtake
            : GhostRaceEventType.lostLead,
        frame: frame,
      ),
    ];
  }

  List<GhostRaceEvent> _finalStretchEvents(GhostRaceFrame frame) {
    if (frame.isOffRoute ||
        frame.status == GhostRaceStatus.offRoute ||
        !frame.distanceToFinishM.isFinite ||
        frame.totalRouteDistanceM <= 0) {
      return const <GhostRaceEvent>[];
    }

    final events = <GhostRaceEvent>[];
    if (!_last500mAlerted &&
        frame.totalRouteDistanceM > 500 &&
        frame.distanceToFinishM <= 500) {
      _last500mAlerted = true;
      events.add(
        GhostRaceEvent(type: GhostRaceEventType.last500m, frame: frame),
      );
    }
    if (!_last200mAlerted &&
        frame.totalRouteDistanceM > 200 &&
        frame.distanceToFinishM <= 200) {
      _last200mAlerted = true;
      events.add(
        GhostRaceEvent(type: GhostRaceEventType.last200m, frame: frame),
      );
    }
    return events;
  }
}
