package kr.sjh.runlini.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

class PhoneDraftAckListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val pendingQueue = PendingDraftQueue(WearPendingDraftStore(applicationContext))
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val path = event.dataItem.uri.path ?: continue
            PhoneDraftAckHandler.handlePath(path, pendingQueue)
        }
    }
}

internal object PhoneDraftAckHandler {
    const val AckPathPrefix = "/runlini/phone/draft_acks/"

    fun handlePath(path: String, pendingQueue: PendingDraftQueue): Boolean {
        if (!path.startsWith(AckPathPrefix)) return false
        val draftId = path.substringAfterLast('/').takeIf { it.isNotBlank() }
            ?: return false
        pendingQueue.markAcknowledged(draftId)
        return true
    }
}
