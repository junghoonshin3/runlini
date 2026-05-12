package kr.sjh.runlini.wear

import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService

class PhoneRecordRaceConfigListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val store = WearRecordRaceConfigStore(applicationContext)
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            val path = item.uri.path ?: continue
            if (!PhoneRecordRaceConfigHandler.isSupportedPath(path)) continue

            val dataMap = DataMapItem.fromDataItem(item).dataMap
            val enabled = dataMap.getBoolean("enabled", false)
            val json = if (!enabled) {
                null
            } else if (PhoneRecordRaceConfigHandler.isBatchPath(path)) {
                readAsset(dataMap, "recordRaceConfigsJson")
                    ?: readAsset(dataMap, "ghostConfigsJson")
            } else {
                readAsset(dataMap, "recordRaceJson")
                    ?: readAsset(dataMap, "ghostJson")
            }

            if (PhoneRecordRaceConfigHandler.handle(path, enabled, json, store)) {
                WearRecordRaceConfigChangeBus.notifyChanged()
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

internal object PhoneRecordRaceConfigHandler {
    const val ConfigPath = "/runlini/phone/record_race_config"
    const val ConfigsPath = "/runlini/phone/record_race_configs"
    private const val LegacyConfigPath = "/runlini/phone/ghost_config"
    private const val LegacyConfigsPath = "/runlini/phone/ghost_configs"

    fun isBatchPath(path: String): Boolean = path == ConfigsPath || path == LegacyConfigsPath
    fun isSupportedPath(path: String): Boolean {
        return path == ConfigPath ||
            path == ConfigsPath ||
            path == LegacyConfigPath ||
            path == LegacyConfigsPath
    }

    fun handle(
        path: String,
        enabled: Boolean,
        json: String?,
        store: WearRecordRaceConfigStore,
    ): Boolean {
        if (isBatchPath(path)) {
            return handleBatch(enabled, json, store)
        }
        if (path != ConfigPath && path != LegacyConfigPath) return false
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
        store: WearRecordRaceConfigStore,
    ): Boolean {
        if (!enabled) {
            store.clear()
            return true
        }
        if (json.isNullOrBlank()) {
            return false
        }
        runCatching {
            val cache = WearRecordRaceConfigCacheJsonMapper.fromJson(json)
            store.replace(cache.configs, cache.activeId)
        }
        return true
    }
}
