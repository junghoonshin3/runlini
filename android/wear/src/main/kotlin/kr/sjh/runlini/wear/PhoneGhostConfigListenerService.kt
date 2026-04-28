package kr.sjh.runlini.wear

import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService

class PhoneGhostConfigListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val store = WearGhostConfigStore(applicationContext)
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            val path = item.uri.path ?: continue
            if (!path.startsWith(PhoneGhostConfigHandler.ConfigPath)) continue

            val dataMap = DataMapItem.fromDataItem(item).dataMap
            val enabled = dataMap.getBoolean("enabled", false)
            val json = if (enabled) {
                dataMap.getAsset("ghostJson")?.let { asset ->
                    runCatching {
                        val response = Tasks.await(
                            Wearable.getDataClient(this).getFdForAsset(asset),
                        )
                        response.inputStream.use { stream ->
                            stream.bufferedReader(Charsets.UTF_8).use { reader ->
                                reader.readText()
                            }
                        }
                    }.getOrNull()
                }
            } else {
                null
            }

            PhoneGhostConfigHandler.handle(path, enabled, json, store)
        }
    }
}

internal object PhoneGhostConfigHandler {
    const val ConfigPath = "/runlini/phone/ghost_config"

    fun handle(
        path: String,
        enabled: Boolean,
        json: String?,
        store: WearGhostConfigStore,
    ): Boolean {
        if (!path.startsWith(ConfigPath)) return false
        if (!enabled) {
            store.clear()
            return true
        }
        if (json.isNullOrBlank()) {
            return false
        }
        runCatching { store.save(json) }
        return true
    }
}
