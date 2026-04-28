package kr.sjh.runlini

import android.content.Context
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

class WearDraftAckSender internal constructor(
    private val transport: WearDraftAckTransport,
) {
    constructor(
        context: Context,
        dataClient: DataClient = Wearable.getDataClient(context),
    ) : this(DataLayerWearDraftAckTransport(dataClient))

    fun sendAck(id: String) {
        val ackAt = System.currentTimeMillis()
        transport.putAck(
            path = "$AckPathPrefix$id",
            draftId = id,
            ackAtEpochMs = ackAt,
        )
    }

    companion object {
        const val AckPathPrefix = "/runlini/phone/draft_acks/"
    }
}

internal interface WearDraftAckTransport {
    fun putAck(path: String, draftId: String, ackAtEpochMs: Long)
}

private class DataLayerWearDraftAckTransport(
    private val dataClient: DataClient,
) : WearDraftAckTransport {
    override fun putAck(path: String, draftId: String, ackAtEpochMs: Long) {
        val request = PutDataMapRequest.create(path).run {
            dataMap.putString("draftId", draftId)
            dataMap.putLong("ackAtEpochMs", ackAtEpochMs)
            asPutDataRequest().setUrgent()
        }
        dataClient.putDataItem(request)
    }
}
