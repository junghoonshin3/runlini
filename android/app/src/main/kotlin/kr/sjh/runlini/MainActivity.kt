package kr.sjh.runlini

import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val motionEvidenceStreamHandler = RunMotionEvidenceStreamHandler(this)
    private val motionPermissionHandler = RunMotionPermissionHandler(this)

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

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MOTION_EVIDENCE_CHANNEL,
        ).setStreamHandler(motionEvidenceStreamHandler)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MOTION_PERMISSION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkActivityRecognitionPermission" -> {
                    result.success(motionPermissionHandler.checkActivityRecognitionPermission())
                }
                "requestActivityRecognitionPermission" -> {
                    motionPermissionHandler.requestActivityRecognitionPermission(result)
                }
                "openAppSettings" -> {
                    motionPermissionHandler.openAppSettings()
                    result.success(null)
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
            WEAR_RECORD_RACE_CONFIG_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val sender = WearRecordRaceConfigSender(applicationContext)
            when (call.method) {
                "sendRecordRaceConfig" -> {
                    val id = call.argument<String>("id")
                    val json = call.argument<String>("json")
                    if (id == null || json == null) {
                        result.error(
                            "missing_config",
                            "sendRecordRaceConfig requires id and json arguments.",
                            null,
                        )
                    } else {
                        sender.sendConfig(id, json)
                        result.success(null)
                    }
                }
                "sendRecordRaceConfigs" -> {
                    val activeId = call.argument<String>("activeId")
                    val json = call.argument<String>("json")
                    if (json == null) {
                        result.error(
                            "missing_configs",
                            "sendRecordRaceConfigs requires a json argument.",
                            null,
                        )
                    } else {
                        sender.sendConfigs(activeId, json)
                        result.success(null)
                    }
                }
                "clearRecordRaceConfig" -> {
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
                    val recordRaceVoiceCueEnabled = call.argument<Boolean>("recordRaceVoiceCueEnabled") ?: false
                    val autoPauseEnabled = call.argument<Boolean>("autoPauseEnabled") ?: false
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
                            recordRaceVoiceCueEnabled = recordRaceVoiceCueEnabled,
                            autoPauseEnabled = autoPauseEnabled,
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (!motionPermissionHandler.onRequestPermissionsResult(requestCode)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    companion object {
        private const val MAP_CONFIG_CHANNEL = "runlini/map_config"
        private const val MOTION_EVIDENCE_CHANNEL = "runlini/motion_evidence"
        private const val MOTION_PERMISSION_CHANNEL = "runlini/motion_permission"
        private const val WEAR_DRAFTS_CHANNEL = "runlini/wear_drafts"
        private const val WATCH_CONNECTION_CHANNEL = "runlini/watch_connection"
        private const val WEAR_RECORD_RACE_CONFIG_CHANNEL = "runlini/wear_record_race_config"
        private const val WEAR_INTERVAL_CONFIG_CHANNEL = "runlini/wear_interval_config"
        private const val WEAR_VOICE_SETTINGS_CHANNEL = "runlini/wear_voice_settings"
    }
}
