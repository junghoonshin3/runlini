package kr.sjh.runlini.wear

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

private const val DefaultInjectionTimeoutMs = 10_000L

data class WearDebugGpsSample(
    val latitude: Double,
    val longitude: Double,
    val elapsedMs: Long,
    val distanceM: Double,
    val speedMps: Double?,
    val paceSecPerKm: Double?,
    val accuracyM: Double?,
    val elevationM: Double?,
)

object WearDebugGpsSampleMapper {
    fun fromValues(
        latitude: Double?,
        longitude: Double?,
        elapsedMs: Long?,
        distanceM: Double?,
        speedMps: Double?,
        paceSecPerKm: Double?,
        accuracyM: Double?,
        elevationM: Double?,
    ): WearDebugGpsSample? {
        val lat = latitude?.takeIf { it.isFinite() && it in -90.0..90.0 } ?: return null
        val lng = longitude?.takeIf { it.isFinite() && it in -180.0..180.0 } ?: return null
        val elapsed = elapsedMs?.takeIf { it >= 0L } ?: return null
        val distance = distanceM?.takeIf { it.isFinite() && it >= 0.0 } ?: return null
        return WearDebugGpsSample(
            latitude = lat,
            longitude = lng,
            elapsedMs = elapsed,
            distanceM = distance,
            speedMps = speedMps?.takeIf { it.isFinite() && it >= 0.0 },
            paceSecPerKm = paceSecPerKm?.takeIf { it.isFinite() && it > 0.0 },
            accuracyM = accuracyM?.takeIf { it.isFinite() && it >= 0.0 },
            elevationM = elevationM?.takeIf { it.isFinite() },
        )
    }
}

object WearDebugGpsInjectionBus {
    private val _samples = MutableSharedFlow<WearDebugGpsSample>(extraBufferCapacity = 32)
    val samples: SharedFlow<WearDebugGpsSample> = _samples.asSharedFlow()

    fun tryEmit(sample: WearDebugGpsSample): Boolean = _samples.tryEmit(sample)
}

class WearDebugGpsInjectionMerger(
    private val timeoutMs: Long = DefaultInjectionTimeoutMs,
) {
    private var lastInjectionRealtimeMs: Long? = null

    fun recordInjectedSample(
        sample: WearDebugGpsSample,
        realtimeMs: Long,
    ): WearMetricSample {
        lastInjectionRealtimeMs = realtimeMs
        return WearMetricSample(
            activeDurationMs = sample.elapsedMs,
            distanceM = sample.distanceM,
            paceSecPerKm = sample.paceSecPerKm,
            speedMps = sample.speedMps,
            points = listOf(
                WearRunPoint(
                    latitude = sample.latitude,
                    longitude = sample.longitude,
                    timestampRelMs = sample.elapsedMs,
                    paceSecPerKm = sample.paceSecPerKm,
                    speedMps = sample.speedMps,
                    horizontalAccuracyM = sample.accuracyM,
                    elevationM = sample.elevationM,
                ),
            ),
        )
    }

    fun filterHealthServicesSample(
        sample: WearMetricSample,
        realtimeMs: Long,
    ): WearMetricSample {
        if (!isActive(realtimeMs)) return sample
        return sample.copy(
            activeDurationMs = null,
            distanceM = null,
            paceSecPerKm = null,
            speedMps = null,
            points = emptyList(),
        )
    }

    fun isActive(realtimeMs: Long): Boolean {
        val last = lastInjectionRealtimeMs ?: return false
        return realtimeMs - last <= timeoutMs
    }
}
