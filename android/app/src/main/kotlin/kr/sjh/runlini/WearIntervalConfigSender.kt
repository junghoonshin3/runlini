package kr.sjh.runlini

import android.content.Context
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

class WearIntervalConfigSender(
    context: Context,
    private val dataClient: DataClient = Wearable.getDataClient(context),
) {
    fun sendConfig(enabled: Boolean, json: String) {
        val request = PutDataMapRequest.create(ConfigPath).run {
            dataMap.putBoolean("enabled", enabled)
            dataMap.putLong("updatedAtEpochMs", System.currentTimeMillis())
            dataMap.putAsset(
                "intervalJson",
                Asset.createFromBytes(json.toByteArray(Charsets.UTF_8)),
            )
            asPutDataRequest().setUrgent()
        }
        dataClient.putDataItem(request)
    }

    companion object {
        const val ConfigPath = "/runlini/phone/interval_config"
    }
}
