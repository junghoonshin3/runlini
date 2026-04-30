package kr.sjh.runlini

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
    }

    companion object {
        private const val MAP_CONFIG_CHANNEL = "runlini/map_config"
        private const val WEAR_DRAFTS_CHANNEL = "runlini/wear_drafts"
        private const val WEAR_GHOST_CONFIG_CHANNEL = "runlini/wear_ghost_config"
    }
}
