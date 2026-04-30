package kr.sjh.runlini

import android.content.Context
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

class WearGhostConfigSender internal constructor(
    private val transport: WearGhostConfigTransport,
) {
    constructor(
        context: Context,
        dataClient: DataClient = Wearable.getDataClient(context),
    ) : this(DataLayerWearGhostConfigTransport(dataClient))

    fun sendConfig(id: String, json: String) {
        transport.putConfig(
            path = ConfigPath,
            enabled = true,
            ghostSessionId = id,
            json = json,
            updatedAtEpochMs = System.currentTimeMillis(),
        )
    }

    fun clearConfig() {
        transport.putConfig(
            path = ConfigPath,
            enabled = false,
            ghostSessionId = null,
            json = null,
            updatedAtEpochMs = System.currentTimeMillis(),
        )
    }

    fun sendConfigs(activeId: String?, json: String) {
        transport.putConfigs(
            path = ConfigsPath,
            enabled = true,
            activeId = activeId,
            json = json,
            updatedAtEpochMs = System.currentTimeMillis(),
        )
    }

    companion object {
        const val ConfigPath = "/runlini/phone/ghost_config"
        const val ConfigsPath = "/runlini/phone/ghost_configs"
    }
}

internal interface WearGhostConfigTransport {
    fun putConfig(
        path: String,
        enabled: Boolean,
        ghostSessionId: String?,
        json: String?,
        updatedAtEpochMs: Long,
    )

    fun putConfigs(
        path: String,
        enabled: Boolean,
        activeId: String?,
        json: String,
        updatedAtEpochMs: Long,
    )
}

private class DataLayerWearGhostConfigTransport(
    private val dataClient: DataClient,
) : WearGhostConfigTransport {
    override fun putConfig(
        path: String,
        enabled: Boolean,
        ghostSessionId: String?,
        json: String?,
        updatedAtEpochMs: Long,
    ) {
        val request = PutDataMapRequest.create(path).run {
            dataMap.putBoolean("enabled", enabled)
            dataMap.putLong("updatedAtEpochMs", updatedAtEpochMs)
            ghostSessionId?.let { dataMap.putString("ghostSessionId", it) }
            json?.let {
                dataMap.putAsset(
                    "ghostJson",
                    Asset.createFromBytes(it.toByteArray(Charsets.UTF_8)),
                )
            }
            asPutDataRequest().setUrgent()
        }
        dataClient.putDataItem(request)
    }

    override fun putConfigs(
        path: String,
        enabled: Boolean,
        activeId: String?,
        json: String,
        updatedAtEpochMs: Long,
    ) {
        val request = PutDataMapRequest.create(path).run {
            dataMap.putBoolean("enabled", enabled)
            dataMap.putLong("updatedAtEpochMs", updatedAtEpochMs)
            activeId?.let { dataMap.putString("activeId", it) }
            dataMap.putAsset(
                "ghostConfigsJson",
                Asset.createFromBytes(json.toByteArray(Charsets.UTF_8)),
            )
            asPutDataRequest().setUrgent()
        }
        dataClient.putDataItem(request)
    }
}
