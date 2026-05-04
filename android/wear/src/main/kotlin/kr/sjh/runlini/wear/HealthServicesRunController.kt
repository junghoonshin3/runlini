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
import androidx.health.services.client.getCurrentExerciseInfo
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
import androidx.health.services.client.data.ExerciseTrackedStatus
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
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.roundToInt

private const val CountdownSeconds = 3
private const val CompletionFeedbackMs = 1_000L

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
    private val activeRunStore: WearActiveRunStore = WearActiveRunStore(context),
    private val settingsStore: WearRunSettingsStore = WearRunSettingsStore(context),
    private val alertController: WearRunAlertController =
        WearRunAlertController(
            haptics = AndroidWearRunHaptics(context),
            speech = AndroidWearRunSpeech(context),
        ),
    private val ghostGapCalculator: WearGhostGapCalculator = WearGhostGapCalculator(),
    private val debugGpsInjectionMerger: WearDebugGpsInjectionMerger =
        WearDebugGpsInjectionMerger(),
    private val deviceName: String =
        "${Build.MANUFACTURER.trim()} ${Build.MODEL.trim()}".trim(),
) {
    private val _state = MutableStateFlow(
        WearRunState(
            settings = settingsStore.current(),
            pendingDraftCount = pendingQueue.pendingCount(),
            ghostConfig = ghostStore.current(),
            ghostConfigs = ghostStore.cached(),
        ),
    )
    val state: StateFlow<WearRunState> = _state.asStateFlow()

    private var tickerJob: Job? = null
    private var countdownJob: Job? = null
    private var feedbackJob: Job? = null
    private var lastCheckpointRealtimeMs: Long = 0L

    init {
        if (BuildConfig.DEBUG) {
            observeDebugGpsInjection()
        }
        observeGhostConfigChanges()
        observeSettingsChanges()
    }

    private val callback = object : ExerciseUpdateCallback {
        override fun onExerciseUpdateReceived(update: androidx.health.services.client.data.ExerciseUpdate) {
            val now = nowRealtimeMs()
            val phase = when {
                update.exerciseStateInfo.state.isPaused -> WearRunPhase.Paused
                update.exerciseStateInfo.state.isEnded -> WearRunPhase.Reviewing
                else -> WearRunPhase.Running
            }
            val sample = debugGpsInjectionMerger.filterHealthServicesSample(
                update.latestMetrics.toMetricSample(
                    activeDurationMs = update.activeDurationCheckpoint
                        ?.activeDuration
                        ?.toMillis(),
                ),
                now,
            )
            val next = reducer.applyMetrics(
                _state.value.copy(phase = phase),
                sample,
                now,
            )
            val framed = applyGhostFrame(next)
            emitRunAlerts(framed)
            setState(framed)
        }

        override fun onAvailabilityChanged(
            dataType: androidx.health.services.client.data.DataType<*, *>,
            availability: Availability,
        ) = Unit

        override fun onExerciseEventReceived(event: ExerciseEvent) = Unit

        override fun onLapSummaryReceived(lapSummary: ExerciseLapSummary) = Unit

        override fun onRegistered() = Unit

        override fun onRegistrationFailed(throwable: Throwable) {
            setState(reducer.fail(_state.value, "센서 연결 실패"))
        }
    }

    fun recoverActiveRun() {
        scope.launch {
            val pendingCount = pendingQueue.pendingCount()
            val ghostConfigs = ghostStore.cached()
            val ghostConfig = ghostStore.current()
            val settings = settingsStore.current()
            val recovered = activeRunStore.restore(
                nowRealtimeMs = nowRealtimeMs(),
                pendingDraftCount = pendingCount,
                fallbackGhostConfig = ghostConfig,
            )?.copy(settings = settings, ghostConfigs = ghostConfigs)

            val exerciseInfo = runCatching {
                exerciseClient.getCurrentExerciseInfo()
            }.getOrNull()
            when (exerciseInfo?.exerciseTrackedStatus) {
                ExerciseTrackedStatus.OTHER_APP_IN_PROGRESS -> {
                    stopTicker()
                    _state.value = reducer.fail(
                        reducer.ready(
                            pendingDraftCount = pendingCount,
                            ghostConfig = ghostConfig,
                            ghostConfigs = ghostConfigs,
                            settings = settings,
                        ),
                        "다른 운동이 진행 중이에요",
                    )
                    return@launch
                }
                ExerciseTrackedStatus.OWNED_EXERCISE_IN_PROGRESS -> {
                    if (
                        exerciseInfo.exerciseType == ExerciseType.RUNNING &&
                        recovered != null &&
                        recovered.phase != WearRunPhase.Reviewing
                    ) {
                        val callbackRegistered = runCatching {
                            exerciseClient.setUpdateCallback(callback)
                        }.isSuccess
                        if (!callbackRegistered) {
                            restoreCheckpointWithoutExercise(recovered)
                            return@launch
                        }
                        setState(applyGhostFrame(recovered), forceCheckpoint = true)
                        if (recovered.phase == WearRunPhase.Running) {
                            startTicker()
                        }
                    } else if (recovered == null) {
                        _state.value = reducer.fail(
                            reducer.ready(
                                pendingDraftCount = pendingCount,
                                ghostConfig = ghostConfig,
                                ghostConfigs = ghostConfigs,
                                settings = settings,
                            ),
                            "진행 중 기록 복구 정보가 없어요",
                        )
                    } else {
                        restoreCheckpointWithoutExercise(recovered)
                    }
                }
                else -> {
                    if (recovered != null) {
                        restoreCheckpointWithoutExercise(recovered)
                    } else {
                        refreshPendingDraftCount()
                    }
                }
            }
        }
    }

    fun startRun() {
        startCountdown(ghostConfig = null)
    }

    fun startGhostRun() {
        val config = _state.value.ghostConfig ?: ghostStore.current()
        if (config == null) {
            startRun()
            return
        }
        startCountdown(ghostConfig = config)
    }

    private fun startCountdown(ghostConfig: WearGhostConfig?) {
        if (_state.value.phase != WearRunPhase.Ready || countdownJob?.isActive == true) {
            return
        }
        feedbackJob?.cancel()
        val settings = settingsStore.current()
        if (!WearRunStartPolicy.shouldUseCountdown(settings)) {
            startRunInternal(ghostConfig)
            return
        }
        countdownJob = scope.launch {
            for (remaining in CountdownSeconds downTo 1) {
                _state.value = reducer.countdown(
                    _state.value.copy(settings = settings),
                    remainingSeconds = remaining,
                    ghostConfig = ghostConfig,
                )
                delay(1_000L)
            }
            countdownJob = null
            startRunInternal(ghostConfig)
        }
    }

    private fun startRunInternal(ghostConfig: WearGhostConfig?) {
        scope.launch {
            alertController.reset()
            val startedAt = System.currentTimeMillis()
            setState(
                reducer.start(
                    _state.value.copy(settings = settingsStore.current()),
                    startedAt,
                    nowRealtimeMs(),
                    ghostConfig,
                ),
                forceCheckpoint = true,
            )
            startTicker()
            try {
                exerciseClient.setUpdateCallback(callback)
                exerciseClient.startExercise(buildExerciseConfig())
            } catch (error: Throwable) {
                stopTicker()
                runCatching { exerciseClient.clearUpdateCallback(callback) }
                activeRunStore.clear()
                _state.value = reducer.fail(
                    WearRunState(
                        settings = settingsStore.current(),
                        pendingDraftCount = pendingQueue.pendingCount(),
                        ghostConfig = ghostStore.current(),
                        ghostConfigs = ghostStore.cached(),
                    ),
                    error.shortMessage("러닝 시작 실패"),
                )
            }
        }
    }

    fun pauseRun() {
        scope.launch {
            countdownJob?.cancel()
            runCatching { exerciseClient.pauseExercise() }
            setState(reducer.pause(_state.value, nowRealtimeMs()), forceCheckpoint = true)
        }
    }

    fun resumeRun() {
        scope.launch {
            runCatching { exerciseClient.resumeExercise() }
            setState(reducer.resume(_state.value, nowRealtimeMs()), forceCheckpoint = true)
            startTicker()
        }
    }

    fun stopRun() {
        scope.launch {
            countdownJob?.cancel()
            runCatching { exerciseClient.endExercise() }
            setState(
                applyGhostFrame(
                    reducer.review(
                        _state.value,
                        System.currentTimeMillis(),
                        nowRealtimeMs(),
                    ),
                ),
                forceCheckpoint = true,
            )
            stopTicker()
        }
    }

    fun saveDraft() {
        scope.launch {
            countdownJob?.cancel()
            feedbackJob?.cancel()
            val draft = WearRunDraftPayload.fromState(_state.value, deviceName)
            pendingQueue.enqueue(draft)
            runCatching {
                withContext(Dispatchers.IO) {
                    draftSender.sendPending(pendingQueue)
                }
            }
            clearCallback()
            activeRunStore.clear()
            showCompletionFeedback(WearRunFeedbackType.Saved)
        }
    }

    fun discardDraft() {
        scope.launch {
            countdownJob?.cancel()
            feedbackJob?.cancel()
            clearCallback()
            activeRunStore.clear()
            showCompletionFeedback(WearRunFeedbackType.Discarded)
        }
    }

    fun flushPendingDrafts() {
        flushPendingDraftsInternal()
    }

    fun retryPendingDrafts() {
        flushPendingDraftsInternal()
    }

    fun refreshPendingDraftCount() {
        val cachedGhosts = ghostStore.cached()
        _state.value = _state.value.copy(
            settings = if (_state.value.isActive) {
                _state.value.settings
            } else {
                settingsStore.current()
            },
            pendingDraftCount = pendingQueue.pendingCount(),
            ghostConfig = if (_state.value.isActive) {
                _state.value.ghostConfig
            } else {
                ghostStore.current()
            },
            ghostConfigs = if (_state.value.isActive) {
                _state.value.ghostConfigs
            } else {
                cachedGhosts
            },
        )
    }

    fun refreshGhostConfigCache() {
        if (_state.value.phase != WearRunPhase.Ready) {
            return
        }
        val cached = ghostStore.cached()
        _state.value = _state.value.copy(
            ghostConfig = ghostStore.current(),
            ghostConfigs = cached,
            errorMessage = null,
        )
    }

    private fun flushPendingDraftsInternal() {
        scope.launch {
            runCatching {
                withContext(Dispatchers.IO) { draftSender.sendPending(pendingQueue) }
            }
            val pendingCount = pendingQueue.pendingCount()
            val current = _state.value
            if (current.phase != WearRunPhase.Ready) {
                setState(current.copy(pendingDraftCount = pendingCount))
                return@launch
            }
            _state.value = current.copy(
                settings = settingsStore.current(),
                pendingDraftCount = pendingCount,
                ghostConfig = ghostStore.current(),
                ghostConfigs = ghostStore.cached(),
                statusMessage = current.statusMessage,
                errorMessage = null,
            )
        }
    }

    private fun showCompletionFeedback(type: WearRunFeedbackType) {
        _state.value = reducer.feedback(
            type = type,
            pendingDraftCount = pendingQueue.pendingCount(),
            ghostConfig = ghostStore.current(),
            ghostConfigs = ghostStore.cached(),
            settings = settingsStore.current(),
        )
        feedbackJob = scope.launch {
            delay(CompletionFeedbackMs)
            val current = _state.value
            if (current.phase == WearRunPhase.Feedback && current.feedbackType == type) {
                _state.value = reducer.ready(
                    pendingDraftCount = pendingQueue.pendingCount(),
                    ghostConfig = ghostStore.current(),
                    ghostConfigs = ghostStore.cached(),
                    settings = settingsStore.current(),
                )
            }
        }
    }

    fun selectGhostConfig(id: String) {
        if (_state.value.phase != WearRunPhase.Ready) {
            return
        }
        val selected = ghostStore.select(id) ?: return
        val cached = ghostStore.cached()
        _state.value = _state.value.copy(
            ghostConfig = selected,
            ghostConfigs = cached,
            statusMessage = null,
            errorMessage = null,
        )
    }

    fun updateSettings(settings: WearRunSettings) {
        settingsStore.save(settings)
        _state.value = withCurrentIntervalFrame(_state.value.copy(settings = settings))
        WearRunSettingsChangeBus.notifyChanged()
    }

    fun playVoiceTestCue(volume: Float) {
        alertController.playVoiceTestCue(volume)
    }

    private fun observeGhostConfigChanges() {
        scope.launch {
            WearGhostConfigChangeBus.changes.collect {
                refreshGhostConfigCache()
            }
        }
    }

    private fun observeSettingsChanges() {
        scope.launch {
            WearRunSettingsChangeBus.changes.collect {
                val settings = settingsStore.current()
                _state.value = withCurrentIntervalFrame(
                    _state.value.copy(settings = settings),
                )
            }
        }
    }

    private fun withCurrentIntervalFrame(state: WearRunState): WearRunState {
        if (!state.isActive) return state.copy(intervalFrame = null)
        return state.copy(
            intervalFrame = WearIntervalWorkoutCalculator().calculate(
                workout = state.settings.intervalWorkout,
                elapsedMs = state.elapsedMs,
                distanceM = state.distanceM,
            ),
        )
    }

    fun dispose(clearExerciseCallback: Boolean = true) {
        countdownJob?.cancel()
        countdownJob = null
        feedbackJob?.cancel()
        feedbackJob = null
        stopTicker()
        if (clearExerciseCallback) {
            scope.launch { clearCallback() }
        }
        alertController.shutdown()
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
            DataType.STEPS_PER_MINUTE,
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
                val next = applyGhostFrame(
                    reducer.tick(_state.value, nowRealtimeMs()),
                )
                emitRunAlerts(next)
                _state.value = next
                persistActiveState(next)
                delay(1000)
            }
        }
    }

    private fun observeDebugGpsInjection() {
        scope.launch {
            WearDebugGpsInjectionBus.samples.collect { sample ->
                if (_state.value.phase != WearRunPhase.Running) return@collect
                val now = nowRealtimeMs()
                val metricSample = debugGpsInjectionMerger.recordInjectedSample(sample, now)
                val next = reducer.applyMetrics(_state.value, metricSample, now)
                val framed = applyGhostFrame(next)
                emitRunAlerts(framed)
                setState(framed)
            }
        }
    }

    private fun emitRunAlerts(state: WearRunState) {
        alertController.onDistanceChanged(
            distanceM = state.distanceM,
            averagePaceSecPerKm = state.averagePaceSecPerKm,
            settings = state.settings,
            elapsedMs = state.elapsedMs,
        )
        alertController.onGhostFrame(
            frame = state.ghostFrame,
            settings = state.settings,
            isGhostRun = state.isGhostRun,
        )
        alertController.onIntervalFrame(
            frame = state.intervalFrame,
            settings = state.settings,
        )
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

    private fun setState(state: WearRunState, forceCheckpoint: Boolean = false) {
        _state.value = state
        persistActiveState(state, forceCheckpoint)
    }

    private fun persistActiveState(state: WearRunState, force: Boolean = false) {
        if (
            state.phase == WearRunPhase.Ready ||
            state.phase == WearRunPhase.CountingDown ||
            state.phase == WearRunPhase.Feedback
        ) {
            return
        }
        val now = nowRealtimeMs()
        if (!force && state.phase == WearRunPhase.Running && now - lastCheckpointRealtimeMs < 5_000L) {
            return
        }
        activeRunStore.save(state, now)
        lastCheckpointRealtimeMs = now
    }

    private fun restoreCheckpointWithoutExercise(recovered: WearRunState) {
        stopTicker()
        val hasRecordData = recovered.elapsedMs > 0 || recovered.distanceM > 0 || recovered.points.isNotEmpty()
        if (!hasRecordData) {
            activeRunStore.clear()
            _state.value = reducer.ready(
                pendingDraftCount = pendingQueue.pendingCount(),
                ghostConfig = ghostStore.current(),
                ghostConfigs = ghostStore.cached(),
                settings = settingsStore.current(),
            )
            return
        }
        val reviewState = recovered.copy(
            settings = settingsStore.current(),
            ghostConfigs = ghostStore.cached(),
            phase = WearRunPhase.Reviewing,
            endedAtEpochMs = recovered.endedAtEpochMs ?: System.currentTimeMillis(),
            elapsedBeforeActiveSegmentMs = recovered.elapsedMs,
            activeSegmentStartedRealtimeMs = null,
            statusMessage = "기록 복구됨",
            errorMessage = null,
        )
        setState(applyGhostFrame(reviewState), forceCheckpoint = true)
    }

    private fun DataPointContainer.toMetricSample(activeDurationMs: Long?): WearMetricSample {
        val heartRate = getData(DataType.HEART_RATE_BPM).lastOrNull()?.value?.roundToInt()
        val calories = getData(DataType.CALORIES_TOTAL)?.total?.toDouble()
        val distance = getData(DataType.DISTANCE_TOTAL)?.total?.toDouble()
        val pace = getData(DataType.PACE).lastOrNull()?.value?.let { value ->
            value / 1000.0
        }
        val speed = getData(DataType.SPEED).lastOrNull()?.value
        val cadence = getData(DataType.STEPS_PER_MINUTE).lastOrNull()?.value?.toDouble()
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
            cadenceSpm = cadence,
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
