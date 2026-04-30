package kr.sjh.runlini.wear

import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMap
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
            if (!PhoneGhostConfigHandler.isSupportedPath(path)) continue

            val dataMap = DataMapItem.fromDataItem(item).dataMap
            val enabled = dataMap.getBoolean("enabled", false)
            val assetName = if (PhoneGhostConfigHandler.isBatchPath(path)) {
                "ghostConfigsJson"
            } else {
                "ghostJson"
            }
            val json = if (enabled) readAsset(dataMap, assetName) else null

            if (PhoneGhostConfigHandler.handle(path, enabled, json, store)) {
                WearGhostConfigChangeBus.notifyChanged()
            }
        }
    }

    private fun readAsset(dataMap: DataMap, name: String): String? {
        return dataMap.getAsset(name)?.let { asset ->
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
    }
}

internal object PhoneGhostConfigHandler {
    const val ConfigPath = "/runlini/phone/ghost_config"
    const val ConfigsPath = "/runlini/phone/ghost_configs"

    fun isBatchPath(path: String): Boolean = path == ConfigsPath
    fun isSupportedPath(path: String): Boolean {
        return path == ConfigPath || path == ConfigsPath
    }

    fun handle(
        path: String,
        enabled: Boolean,
        json: String?,
        store: WearGhostConfigStore,
    ): Boolean {
        if (path == ConfigsPath) {
            return handleBatch(enabled, json, store)
        }
        if (path != ConfigPath) return false
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

    private fun handleBatch(
        enabled: Boolean,
        json: String?,
        store: WearGhostConfigStore,
    ): Boolean {
        if (!enabled) {
            store.clear()
            return true
        }
        if (json.isNullOrBlank()) {
            return false
        }
        runCatching {
            val cache = WearGhostConfigCacheJsonMapper.fromJson(json)
            store.replace(cache.configs, cache.activeId)
        }
        return true
    }
}
