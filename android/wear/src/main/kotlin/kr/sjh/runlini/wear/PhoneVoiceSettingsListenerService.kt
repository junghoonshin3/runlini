package kr.sjh.runlini.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class PhoneVoiceSettingsListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val store = WearRunSettingsStore(applicationContext)
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            if (item.uri.path != VoiceSettingsPath) continue
            val dataMap = DataMapItem.fromDataItem(item).dataMap
            val current = store.current()
            val volume = WearRunSettingsDefaults.clampVoiceVolume(
                dataMap.getDouble("volume", current.voiceCueVolume.toDouble()).toFloat(),
            )
            store.save(
                current.copy(
                    voiceCueEnabled = dataMap.getBoolean(
                        "voiceCueEnabled",
                        current.voiceCueEnabled,
                    ),
                    kmAlertEnabled = dataMap.getBoolean(
                        "kmVoiceCueEnabled",
                        current.kmAlertEnabled,
                    ),
                    ghostVoiceCueEnabled = dataMap.getBoolean(
                        "ghostVoiceCueEnabled",
                        current.ghostVoiceCueEnabled,
                    ),
                    autoPauseEnabled = dataMap.getBoolean(
                        "autoPauseEnabled",
                        current.autoPauseEnabled,
                    ),
                    voiceCueVolume = volume,
                ),
            )
            WearRunSettingsChangeBus.notifyChanged()
            if (dataMap.getBoolean("playTestCue", false)) {
                WearVoiceTestCue.play(applicationContext, volume)
            }
        }
    }

    companion object {
        const val VoiceSettingsPath = "/runlini/phone/voice_settings"
    }
}
