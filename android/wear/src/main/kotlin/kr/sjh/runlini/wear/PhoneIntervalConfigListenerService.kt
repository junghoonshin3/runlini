package kr.sjh.runlini.wear

import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class PhoneIntervalConfigListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val store = WearRunSettingsStore(applicationContext)
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            if (item.uri.path != IntervalConfigPath) continue
            val dataMap = DataMapItem.fromDataItem(item).dataMap
            val json = readAsset(dataMap, "intervalJson") ?: continue
            runCatching {
                val interval = WearIntervalWorkoutJsonMapper.fromJson(json)
                val current = store.current()
                store.save(current.copy(intervalWorkout = interval))
                WearRunSettingsChangeBus.notifyChanged()
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

    companion object {
        const val IntervalConfigPath = "/runlini/phone/interval_config"
    }
}

object WearRunSettingsChangeBus {
    private val _changes = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val changes = _changes.asSharedFlow()

    fun notifyChanged() {
        _changes.tryEmit(Unit)
    }
}
