package kr.sjh.runlini

import android.content.Context
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

class WearRecordRaceConfigSender internal constructor(
    private val transport: WearRecordRaceConfigTransport,
) {
    constructor(
        context: Context,
        dataClient: DataClient = Wearable.getDataClient(context),
    ) : this(DataLayerWearRecordRaceConfigTransport(dataClient))

    fun sendConfig(id: String, json: String) {
        transport.putConfig(
            path = ConfigPath,
            enabled = true,
            recordRaceSessionId = id,
            json = json,
            updatedAtEpochMs = System.currentTimeMillis(),
        )
    }

    fun clearConfig() {
        transport.putConfig(
            path = ConfigPath,
            enabled = false,
            recordRaceSessionId = null,
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
        const val ConfigPath = "/runlini/phone/record_race_config"
        const val ConfigsPath = "/runlini/phone/record_race_configs"
    }
}

internal interface WearRecordRaceConfigTransport {
    fun putConfig(
        path: String,
        enabled: Boolean,
        recordRaceSessionId: String?,
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

private class DataLayerWearRecordRaceConfigTransport(
    private val dataClient: DataClient,
) : WearRecordRaceConfigTransport {
    override fun putConfig(
        path: String,
        enabled: Boolean,
        recordRaceSessionId: String?,
        json: String?,
        updatedAtEpochMs: Long,
    ) {
        val request = PutDataMapRequest.create(path).run {
            dataMap.putBoolean("enabled", enabled)
            dataMap.putLong("updatedAtEpochMs", updatedAtEpochMs)
            recordRaceSessionId?.let { dataMap.putString("recordRaceSessionId", it) }
            json?.let {
                dataMap.putAsset(
                    "recordRaceJson",
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
                "recordRaceConfigsJson",
                Asset.createFromBytes(json.toByteArray(Charsets.UTF_8)),
            )
            asPutDataRequest().setUrgent()
        }
        dataClient.putDataItem(request)
    }
}
