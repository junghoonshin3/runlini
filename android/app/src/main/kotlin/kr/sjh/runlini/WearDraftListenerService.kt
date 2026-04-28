package kr.sjh.runlini

import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService

class WearDraftListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val store = WearDraftInboxStore(applicationContext)
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            val path = item.uri.path ?: continue
            if (!path.startsWith(DraftPathPrefix)) continue

            val dataMap = DataMapItem.fromDataItem(item).dataMap
            val id = dataMap.getString("draftId") ?: path.substringAfterLast('/')
            val asset = dataMap.getAsset("draftJson") ?: continue
            val json = runCatching {
                val response = Tasks.await(
                    Wearable.getDataClient(this).getFdForAsset(asset),
                )
                response.inputStream.use { stream ->
                    stream.bufferedReader(Charsets.UTF_8).use { reader ->
                        reader.readText()
                    }
                }
            }.getOrNull()

            if (!json.isNullOrBlank()) {
                store.save(id, json)
            }
        }
    }

    companion object {
        private const val DraftPathPrefix = "/runlini/wear/drafts/"
    }
}
