import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:runlini/features/run_tracking/types/watch_run_draft.dart';

class WearDraftEnvelope {
  const WearDraftEnvelope({required this.id, required this.draft});

  final String id;
  final WatchRunDraft draft;
}

abstract class WearDraftInboxClient {
  Future<List<WearDraftEnvelope>> pendingWearDrafts();
  Future<void> ackWearDraft(String id);
}

class MethodChannelWearDraftInboxClient implements WearDraftInboxClient {
  const MethodChannelWearDraftInboxClient();

  static const MethodChannel _channel = MethodChannel('runlini/wear_drafts');

  @override
  Future<List<WearDraftEnvelope>> pendingWearDrafts() async {
    if (!Platform.isAndroid) {
      return const <WearDraftEnvelope>[];
    }

    try {
      final drafts = await _channel.invokeMethod<List<dynamic>>(
        'pendingWearDrafts',
      );
      return (drafts ?? const <dynamic>[])
          .map(_decodeEnvelope)
          .toList(growable: false);
    } on MissingPluginException {
      return const <WearDraftEnvelope>[];
    }
  }

  @override
  Future<void> ackWearDraft(String id) async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('ackWearDraft', <String, Object?>{
        'id': id,
      });
    } on MissingPluginException {
      return;
    }
  }

  WearDraftEnvelope _decodeEnvelope(dynamic value) {
    final envelope = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
    final id = envelope['id'] as String;
    final json = jsonDecode(envelope['json'] as String) as Map<String, dynamic>;
    return WearDraftEnvelope(id: id, draft: WatchRunDraft.fromJson(json));
  }
}
