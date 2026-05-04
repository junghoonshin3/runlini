package kr.sjh.runlini

import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAP_CONFIG_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAndroidGoogleMapsConfigured" -> {
                    result.success(BuildConfig.GOOGLE_MAPS_API_KEY.isNotBlank())
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WEAR_DRAFTS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val store = WearDraftInboxStore(applicationContext)
            when (call.method) {
                "pendingWearDrafts" -> result.success(store.pending())
                "ackWearDraft" -> {
                    val id = call.argument<String>("id")
                    if (id == null) {
                        result.error(
                            "missing_id",
                            "ackWearDraft requires an id argument.",
                            null,
                        )
                    } else {
                        store.ack(id)
                        runCatching {
                            WearDraftAckSender(applicationContext).sendAck(id)
                        }
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WATCH_CONNECTION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "connectionStatus" -> {
                    Wearable.getNodeClient(applicationContext)
                        .connectedNodes
                        .addOnSuccessListener { nodes ->
                            result.success(if (nodes.isNotEmpty()) "connected" else "disconnected")
                        }
                        .addOnFailureListener {
                            result.success("disconnected")
                        }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WEAR_GHOST_CONFIG_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val sender = WearGhostConfigSender(applicationContext)
            when (call.method) {
                "sendGhostConfig" -> {
                    val id = call.argument<String>("id")
                    val json = call.argument<String>("json")
                    if (id == null || json == null) {
                        result.error(
                            "missing_config",
                            "sendGhostConfig requires id and json arguments.",
                            null,
                        )
                    } else {
                        sender.sendConfig(id, json)
                        result.success(null)
                    }
                }
                "sendGhostConfigs" -> {
                    val activeId = call.argument<String>("activeId")
                    val json = call.argument<String>("json")
                    if (json == null) {
                        result.error(
                            "missing_configs",
                            "sendGhostConfigs requires a json argument.",
                            null,
                        )
                    } else {
                        sender.sendConfigs(activeId, json)
                        result.success(null)
                    }
                }
                "clearGhostConfig" -> {
                    sender.clearConfig()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WEAR_INTERVAL_CONFIG_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val sender = WearIntervalConfigSender(applicationContext)
            when (call.method) {
                "sendIntervalConfig" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val json = call.argument<String>("json")
                    if (json == null) {
                        result.error(
                            "missing_interval_config",
                            "sendIntervalConfig requires a json argument.",
                            null,
                        )
                    } else {
                        sender.sendConfig(enabled, json)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WEAR_VOICE_SETTINGS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val sender = WearVoiceSettingsSender(applicationContext)
            when (call.method) {
                "sendVoiceSettings" -> {
                    val voiceCueEnabled = call.argument<Boolean>("voiceCueEnabled") ?: true
                    val kmVoiceCueEnabled = call.argument<Boolean>("kmVoiceCueEnabled") ?: true
                    val ghostVoiceCueEnabled = call.argument<Boolean>("ghostVoiceCueEnabled") ?: false
                    val volume = call.argument<Double>("volume")
                    val playTestCue = call.argument<Boolean>("playTestCue") ?: false
                    if (volume == null) {
                        result.error(
                            "missing_voice_settings",
                            "sendVoiceSettings requires a volume argument.",
                            null,
                        )
                    } else {
                        sender.send(
                            voiceCueEnabled = voiceCueEnabled,
                            kmVoiceCueEnabled = kmVoiceCueEnabled,
                            ghostVoiceCueEnabled = ghostVoiceCueEnabled,
                            volume = volume,
                            playTestCue = playTestCue,
                        )
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val MAP_CONFIG_CHANNEL = "runlini/map_config"
        private const val WEAR_DRAFTS_CHANNEL = "runlini/wear_drafts"
        private const val WATCH_CONNECTION_CHANNEL = "runlini/watch_connection"
        private const val WEAR_GHOST_CONFIG_CHANNEL = "runlini/wear_ghost_config"
        private const val WEAR_INTERVAL_CONFIG_CHANNEL = "runlini/wear_interval_config"
        private const val WEAR_VOICE_SETTINGS_CHANNEL = "runlini/wear_voice_settings"
    }
}
