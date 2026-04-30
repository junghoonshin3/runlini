package kr.sjh.runlini.wear

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WearDebugGpsInjectionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ActionGpsSample) return
        val sample = WearDebugGpsSampleMapper.fromValues(
            latitude = intent.doubleExtraOrNull("lat"),
            longitude = intent.doubleExtraOrNull("lng"),
            elapsedMs = intent.longExtraOrNull("elapsedMs"),
            distanceM = intent.doubleExtraOrNull("distanceM"),
            speedMps = intent.doubleExtraOrNull("speedMps"),
            paceSecPerKm = intent.doubleExtraOrNull("paceSecPerKm"),
            accuracyM = intent.doubleExtraOrNull("accuracyM"),
            elevationM = intent.doubleExtraOrNull("elevationM"),
        ) ?: return
        WearDebugGpsInjectionBus.tryEmit(sample)
    }

    private fun Intent.doubleExtraOrNull(name: String): Double? {
        val value = extras?.get(name) as? Number ?: return null
        return value.toDouble()
    }

    private fun Intent.longExtraOrNull(name: String): Long? {
        val value = extras?.get(name) as? Number ?: return null
        return value.toLong()
    }

    companion object {
        const val ActionGpsSample = "kr.sjh.runlini.wear.debug.GPS_SAMPLE"
    }
}
