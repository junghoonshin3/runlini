package kr.sjh.runlini.wear

import android.content.Context
import android.os.Build
import android.os.SystemClock
import androidx.health.services.client.ExerciseClient
import androidx.health.services.client.ExerciseUpdateCallback
import androidx.health.services.client.HealthServices
import androidx.health.services.client.clearUpdateCallback
import androidx.health.services.client.endExercise
import androidx.health.services.client.getCapabilities
import androidx.health.services.client.pauseExercise
import androidx.health.services.client.resumeExercise
import androidx.health.services.client.startExercise
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.ExerciseConfig
import androidx.health.services.client.data.ExerciseEvent
import androidx.health.services.client.data.ExerciseLapSummary
import androidx.health.services.client.data.ExerciseState
import androidx.health.services.client.data.ExerciseType
import androidx.health.services.client.data.LocationAccuracy
import androidx.health.services.client.data.LocationData
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.roundToInt

class HealthServicesRunController(
    context: Context,
    private val scope: CoroutineScope,
    private val reducer: WearRunStateReducer = WearRunStateReducer(),
    private val exerciseClient: ExerciseClient =
        HealthServices.getClient(context).exerciseClient,
    private val pendingQueue: PendingDraftQueue =
        PendingDraftQueue(WearPendingDraftStore(context)),
    private val draftSender: WearDraftSender = WearDraftSender(context),
    private val ghostStore: WearGhostConfigStore = WearGhostConfigStore(context),
    private val ghostGapCalculator: WearGhostGapCalculator = WearGhostGapCalculator(),
    private val deviceName: String =
        "${Build.MANUFACTURER.trim()} ${Build.MODEL.trim()}".trim(),
) {
    private val _state = MutableStateFlow(
        WearRunState(
            pendingDraftCount = pendingQueue.pendingCount(),
            ghostConfig = ghostStore.current(),
        ),
    )
    val state: StateFlow<WearRunState> = _state.asStateFlow()

    private var tickerJob: Job? = null

    private val callback = object : ExerciseUpdateCallback {
        override fun onExerciseUpdateReceived(update: androidx.health.services.client.data.ExerciseUpdate) {
            val phase = when {
                update.exerciseStateInfo.state.isPaused -> WearRunPhase.Paused
                update.exerciseStateInfo.state.isEnded -> WearRunPhase.Reviewing
                else -> WearRunPhase.Running
            }
            val sample = update.latestMetrics.toMetricSample(
                activeDurationMs = update.activeDurationCheckpoint
                    ?.activeDuration
                    ?.toMillis(),
            )
            val next = reducer.applyMetrics(
                _state.value.copy(phase = phase),
                sample,
                nowRealtimeMs(),
            )
            _state.value = applyGhostFrame(next)
        }

        override fun onAvailabilityChanged(
            dataType: androidx.health.services.client.data.DataType<*, *>,
            availability: Availability,
        ) = Unit

        override fun onExerciseEventReceived(event: ExerciseEvent) = Unit

        override fun onLapSummaryReceived(lapSummary: ExerciseLapSummary) = Unit

        override fun onRegistered() = Unit

        override fun onRegistrationFailed(throwable: Throwable) {
            _state.value = reducer.fail(_state.value, "센서 연결 실패")
        }
    }

    fun startRun() {
        startRunInternal(ghostConfig = null)
    }

    fun startGhostRun() {
        val config = ghostStore.current() ?: _state.value.ghostConfig
        if (config == null) {
            startRun()
            return
        }
        startRunInternal(ghostConfig = config)
    }

    private fun startRunInternal(ghostConfig: WearGhostConfig?) {
        scope.launch {
            val startedAt = System.currentTimeMillis()
            _state.value = reducer.start(
                _state.value,
                startedAt,
                nowRealtimeMs(),
                ghostConfig,
            )
            startTicker()
            try {
                exerciseClient.setUpdateCallback(callback)
                exerciseClient.startExercise(buildExerciseConfig())
            } catch (error: Throwable) {
                stopTicker()
                runCatching { exerciseClient.clearUpdateCallback(callback) }
                _state.value = reducer.fail(
                    WearRunState(
                        pendingDraftCount = pendingQueue.pendingCount(),
                        ghostConfig = ghostStore.current(),
                    ),
                    error.shortMessage("러닝 시작 실패"),
                )
            }
        }
    }

    fun pauseRun() {
        scope.launch {
            runCatching { exerciseClient.pauseExercise() }
            _state.value = reducer.pause(_state.value, nowRealtimeMs())
        }
    }

    fun resumeRun() {
        scope.launch {
            runCatching { exerciseClient.resumeExercise() }
            _state.value = reducer.resume(_state.value, nowRealtimeMs())
            startTicker()
        }
    }

    fun stopRun() {
        scope.launch {
            runCatching { exerciseClient.endExercise() }
            _state.value = applyGhostFrame(
                reducer.review(
                    _state.value,
                    System.currentTimeMillis(),
                    nowRealtimeMs(),
                ),
            )
            stopTicker()
        }
    }

    fun saveDraft() {
        scope.launch {
            val draft = WearRunDraftPayload.fromState(_state.value, deviceName)
            pendingQueue.enqueue(draft)
            val message = runCatching {
                val count = withContext(Dispatchers.IO) {
                    draftSender.sendPending(pendingQueue)
                }
                if (count > 0) "저장됨 · 폰 확인 대기" else "저장됨"
            }.getOrElse {
                "저장됨 · 폰 연결 시 전송"
            }
            clearCallback()
            _state.value = reducer.ready(
                message,
                pendingQueue.pendingCount(),
                ghostStore.current(),
            )
        }
    }

    fun discardDraft() {
        scope.launch {
            clearCallback()
            _state.value = reducer.ready(
                "삭제됨",
                pendingQueue.pendingCount(),
                ghostStore.current(),
            )
        }
    }

    fun flushPendingDrafts() {
        flushPendingDrafts(showStatus = false)
    }

    fun retryPendingDrafts() {
        flushPendingDrafts(showStatus = true)
    }

    fun refreshPendingDraftCount() {
        _state.value = _state.value.copy(
            pendingDraftCount = pendingQueue.pendingCount(),
            ghostConfig = if (_state.value.isActive) {
                _state.value.ghostConfig
            } else {
                ghostStore.current()
            },
        )
    }

    private fun flushPendingDrafts(showStatus: Boolean) {
        scope.launch {
            val result = runCatching {
                withContext(Dispatchers.IO) { draftSender.sendPending(pendingQueue) }
            }
            val pendingCount = pendingQueue.pendingCount()
            val current = _state.value
            if (current.phase != WearRunPhase.Ready) {
                _state.value = current.copy(pendingDraftCount = pendingCount)
                return@launch
            }
            val message = if (showStatus) {
                result.fold(
                    onSuccess = { sent ->
                        if (pendingCount == 0) {
                            "전송 대기 없음"
                        } else if (sent > 0) {
                            "다시 전송함 · 폰 확인 대기"
                        } else {
                            "전송 대기 없음"
                        }
                    },
                    onFailure = { "폰 연결 시 전송" },
                )
            } else {
                current.statusMessage
            }
            _state.value = current.copy(
                pendingDraftCount = pendingCount,
                ghostConfig = ghostStore.current(),
                statusMessage = message,
                errorMessage = null,
            )
        }
    }

    fun dispose() {
        stopTicker()
        scope.launch { clearCallback() }
    }

    private suspend fun clearCallback() {
        stopTicker()
        runCatching { exerciseClient.clearUpdateCallback(callback) }
    }

    private suspend fun buildExerciseConfig(): ExerciseConfig {
        val desired = setOf(
            DataType.HEART_RATE_BPM,
            DataType.CALORIES_TOTAL,
            DataType.DISTANCE_TOTAL,
            DataType.LOCATION,
            DataType.PACE,
            DataType.SPEED,
        )
        val supported = runCatching {
            exerciseClient
                .getCapabilities()
                .getExerciseTypeCapabilities(ExerciseType.RUNNING)
                .supportedDataTypes
        }.getOrDefault(desired)
        val dataTypes = desired.filter { type -> supported.contains(type) }.toSet()
        return ExerciseConfig(
            exerciseType = ExerciseType.RUNNING,
            dataTypes = dataTypes,
            isAutoPauseAndResumeEnabled = false,
            isGpsEnabled = true,
        )
    }

    private fun startTicker() {
        if (tickerJob?.isActive == true) return
        tickerJob = scope.launch {
            while (_state.value.phase == WearRunPhase.Running) {
                _state.value = applyGhostFrame(
                    reducer.tick(_state.value, nowRealtimeMs()),
                )
                delay(1000)
            }
        }
    }

    private fun applyGhostFrame(state: WearRunState): WearRunState {
        val config = state.ghostConfig
        if (!state.isGhostRun || config == null || state.points.isEmpty()) {
            return state
        }
        return reducer.applyGhostFrame(
            state,
            ghostGapCalculator.calculate(
                runnerPoint = state.points.last(),
                ghostConfig = config,
                runnerElapsedMs = state.elapsedMs,
            ),
        )
    }

    private fun stopTicker() {
        tickerJob?.cancel()
        tickerJob = null
    }

    private fun DataPointContainer.toMetricSample(activeDurationMs: Long?): WearMetricSample {
        val heartRate = getData(DataType.HEART_RATE_BPM).lastOrNull()?.value?.roundToInt()
        val calories = getData(DataType.CALORIES_TOTAL)?.total?.toDouble()
        val distance = getData(DataType.DISTANCE_TOTAL)?.total?.toDouble()
        val pace = getData(DataType.PACE).lastOrNull()?.value?.let { value ->
            value / 1000.0
        }
        val speed = getData(DataType.SPEED).lastOrNull()?.value
        val points = getData(DataType.LOCATION).map { point ->
            val location: LocationData = point.value
            val accuracy = point.accuracy as? LocationAccuracy
            WearRunPoint(
                latitude = location.latitude,
                longitude = location.longitude,
                timestampRelMs = activeDurationMs ?: _state.value.elapsedMs,
                paceSecPerKm = pace,
                speedMps = speed,
                horizontalAccuracyM = accuracy?.horizontalPositionErrorMeters,
                elevationM = location.altitude.takeIf { altitude -> altitude.isFinite() },
                heartRateBpm = heartRate,
            )
        }
        return WearMetricSample(
            activeDurationMs = activeDurationMs,
            distanceM = distance,
            paceSecPerKm = pace,
            speedMps = speed,
            heartRateBpm = heartRate,
            caloriesKcal = calories,
            points = points,
        )
    }

    private fun nowRealtimeMs(): Long = SystemClock.elapsedRealtime()

    private fun Throwable.shortMessage(prefix: String): String {
        val detail = message?.takeIf { it.isNotBlank() }
        return if (detail == null) prefix else "$prefix: $detail"
    }
}
