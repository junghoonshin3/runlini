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
    }

    companion object {
        private const val MAP_CONFIG_CHANNEL = "runlini/map_config"
    }
}
