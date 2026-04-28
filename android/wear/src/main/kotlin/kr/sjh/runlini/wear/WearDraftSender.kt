package kr.sjh.runlini.wear

import android.content.Context
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.tasks.await

class WearDraftSender internal constructor(
    private val transport: WearDraftTransport,
) {
    constructor(
        context: Context,
        dataClient: DataClient = Wearable.getDataClient(context),
    ) : this(DataLayerWearDraftTransport(dataClient))

    suspend fun sendPending(queue: PendingDraftQueue): Int {
        var sent = 0
        for (draft in queue.pending()) {
            send(draft)
            sent += 1
        }
        return sent
    }

    private suspend fun send(draft: PendingWearDraft) {
        transport.putDraft(
            path = "$DraftPathPrefix${draft.id}",
            draftId = draft.id,
            json = draft.json,
            attemptedAtEpochMs = System.currentTimeMillis(),
        )
    }

    companion object {
        const val DraftPathPrefix = "/runlini/wear/drafts/"
    }
}

internal interface WearDraftTransport {
    suspend fun putDraft(
        path: String,
        draftId: String,
        json: String,
        attemptedAtEpochMs: Long,
    )
}

private class DataLayerWearDraftTransport(
    private val dataClient: DataClient,
) : WearDraftTransport {
    override suspend fun putDraft(
        path: String,
        draftId: String,
        json: String,
        attemptedAtEpochMs: Long,
    ) {
        val request = PutDataMapRequest.create(path).run {
            dataMap.putString("draftId", draftId)
            dataMap.putLong("createdAtEpochMs", System.currentTimeMillis())
            dataMap.putLong("attemptedAtEpochMs", attemptedAtEpochMs)
            dataMap.putAsset(
                "draftJson",
                Asset.createFromBytes(json.toByteArray(Charsets.UTF_8)),
            )
            asPutDataRequest().setUrgent()
        }
        dataClient.putDataItem(request).await()
    }
}
