package kr.sjh.runlini

import android.content.Context
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

class WearVoiceSettingsSender(
    context: Context,
    private val dataClient: DataClient = Wearable.getDataClient(context),
) {
    fun send(
        voiceCueEnabled: Boolean,
        kmVoiceCueEnabled: Boolean,
        ghostVoiceCueEnabled: Boolean,
        volume: Double,
        playTestCue: Boolean = false,
    ) {
        val request = PutDataMapRequest.create(ConfigPath).run {
            dataMap.putBoolean("voiceCueEnabled", voiceCueEnabled)
            dataMap.putBoolean("kmVoiceCueEnabled", kmVoiceCueEnabled)
            dataMap.putBoolean("ghostVoiceCueEnabled", ghostVoiceCueEnabled)
            dataMap.putDouble("volume", volume.coerceIn(0.0, 1.0))
            dataMap.putBoolean("playTestCue", playTestCue)
            dataMap.putLong("updatedAtEpochMs", System.currentTimeMillis())
            asPutDataRequest().setUrgent()
        }
        dataClient.putDataItem(request)
    }

    companion object {
        const val ConfigPath = "/runlini/phone/voice_settings"
    }
}
