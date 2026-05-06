package kr.sjh.runlini.wear

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class WearRunRecordingService : Service() {
    private val binder = LocalBinder()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private lateinit var controller: HealthServicesRunController
    private var foregroundActive = false

    val state: StateFlow<WearRunState>
        get() = controller.state

    override fun onCreate() {
        super.onCreate()
        controller = HealthServicesRunController(
            context = applicationContext,
            scope = serviceScope,
        )
        controller.recoverActiveRun()
        observeRunState()
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onDestroy() {
        val keepExerciseCallback = controller.state.value.isActive
        controller.dispose(clearExerciseCallback = !keepExerciseCallback)
        serviceScope.cancel()
        super.onDestroy()
    }

    fun startRun() {
        controller.startRun()
    }

    fun startGhostRun() {
        controller.startGhostRun()
    }

    fun pauseRun() {
        controller.pauseRun()
    }

    fun resumeRun() {
        ensureForeground(controller.state.value)
        controller.resumeRun()
    }

    fun stopRun() {
        controller.stopRun()
    }

    fun continueAfterGhostCompletion() {
        controller.continueAfterGhostCompletion()
    }

    fun saveDraft() {
        controller.saveDraft()
    }

    fun discardDraft() {
        controller.discardDraft()
    }

    fun flushPendingDrafts() {
        controller.flushPendingDrafts()
    }

    fun retryPendingDrafts() {
        controller.retryPendingDrafts()
    }

    fun refreshPendingDraftCount() {
        controller.refreshPendingDraftCount()
    }

    fun updateSettings(settings: WearRunSettings) {
        controller.updateSettings(settings)
    }

    fun playVoiceTestCue(volume: Float) {
        controller.playVoiceTestCue(volume)
    }

    fun selectGhostConfig(id: String) {
        controller.selectGhostConfig(id)
    }

    inner class LocalBinder : Binder() {
        fun service(): WearRunRecordingService = this@WearRunRecordingService
    }

    private fun observeRunState() {
        serviceScope.launch {
            controller.state.collect { state ->
                when (state.phase) {
                    WearRunPhase.Running,
                    WearRunPhase.Paused,
                    WearRunPhase.Reviewing,
                    -> if (foregroundActive) {
                        runCatching {
                            NotificationManagerCompat.from(this@WearRunRecordingService)
                                .notify(NotificationId, buildNotification(state))
                        }
                    } else {
                        ensureForeground(state)
                    }
                    WearRunPhase.Ready,
                    WearRunPhase.CountingDown,
                    WearRunPhase.Feedback,
                    -> if (foregroundActive) {
                        foregroundActive = false
                        ServiceCompat.stopForeground(
                            this@WearRunRecordingService,
                            ServiceCompat.STOP_FOREGROUND_REMOVE,
                        )
                        stopSelf()
                    }
                }
            }
        }
    }

    private fun ensureForeground(state: WearRunState) {
        startService(Intent(this, WearRunRecordingService::class.java))
        ensureNotificationChannel()
        ServiceCompat.startForeground(
            this,
            NotificationId,
            buildNotification(state),
            foregroundServiceType(),
        )
        foregroundActive = true
    }

    private fun buildNotification(state: WearRunState): Notification {
        val title = when (state.phase) {
            WearRunPhase.Paused -> "Runlini 일시정지"
            WearRunPhase.Reviewing -> "Runlini 저장 대기"
            else -> "Runlini 기록 중"
        }
        val text = "${WearRunFormatters.distance(state.distanceM)} · ${WearRunFormatters.elapsed(state.elapsedMs)}"
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, ChannelId)
            .setSmallIcon(R.drawable.ic_runlini_notification)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(pendingIntent)
            .setOngoing(state.phase != WearRunPhase.Reviewing)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            ChannelId,
            "러닝 기록",
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    private fun foregroundServiceType(): Int {
        val location = ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        return if (Build.VERSION.SDK_INT >= 34) {
            location or ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
        } else {
            location
        }
    }

    private companion object {
        const val ChannelId = "runlini_wear_recording"
        const val NotificationId = 1001
    }
}
