package kr.sjh.runlini.wear

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.IBinder
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { RunliniWearApp() }
    }
}

@Composable
private fun RunliniWearApp() {
    val context = LocalContext.current
    var recordingService by remember { mutableStateOf<WearRunRecordingService?>(null) }
    val lifecycleOwner = LocalLifecycleOwner.current
    val fallbackState = remember {
        kotlinx.coroutines.flow.MutableStateFlow(
            WearRunState(statusMessage = "준비 중"),
        )
    }
    val state by (recordingService?.state ?: fallbackState).collectAsState()
    var hasPermissions by remember { mutableStateOf(context.hasRunPermissions()) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { results ->
        hasPermissions = runPermissions().all { permission ->
            results[permission] == true ||
                ContextCompat.checkSelfPermission(context, permission) == PERMISSION_GRANTED
        }
    }
    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { }

    DisposableEffect(context) {
        val intent = Intent(context, WearRunRecordingService::class.java)
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                recordingService = (binder as? WearRunRecordingService.LocalBinder)?.service()
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                recordingService = null
            }
        }
        context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
        onDispose {
            recordingService = null
            runCatching { context.unbindService(connection) }
        }
    }

    LaunchedEffect(hasPermissions) {
        if (
            hasPermissions &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PERMISSION_GRANTED
        ) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    LaunchedEffect(recordingService) {
        val service = recordingService ?: return@LaunchedEffect
        service.flushPendingDrafts()
        while (true) {
            delay(2_000L)
            service.refreshPendingDraftCount()
        }
    }

    DisposableEffect(lifecycleOwner, recordingService) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                recordingService?.refreshPendingDraftCount()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    RunliniWearTheme {
        if (!hasPermissions) {
            WearPermissionScreen(
                onRequest = {
                    permissionLauncher.launch(runPermissions())
                },
            )
        } else {
            WearRunScreen(
                state = state,
                actions = recordingService?.actions() ?: WearRunActions.NoOp,
            )
        }
    }
}

private fun WearRunRecordingService.actions(): WearRunActions {
    return WearRunActions(
        onStart = ::startRun,
        onGhostStart = ::startGhostRun,
        onPause = ::pauseRun,
        onStop = ::stopRun,
        onResume = ::resumeRun,
        onSave = ::saveDraft,
        onDiscard = ::discardDraft,
        onCountdownEnabledChange = { enabled ->
            updateSettings(state.value.settings.copy(countdownEnabled = enabled))
        },
        onAutoPauseEnabledChange = { enabled ->
            updateSettings(state.value.settings.copy(autoPauseEnabled = enabled))
        },
        onVibrationEnabledChange = { enabled ->
            updateSettings(state.value.settings.copy(vibrationEnabled = enabled))
        },
        onKmAlertEnabledChange = { enabled ->
            updateSettings(state.value.settings.copy(kmAlertEnabled = enabled))
        },
        onVoiceCueEnabledChange = { enabled ->
            updateSettings(state.value.settings.copy(voiceCueEnabled = enabled))
        },
        onVoiceCueVolumeChange = { volume ->
            val safeVolume = WearRunSettingsDefaults.clampVoiceVolume(volume)
            updateSettings(
                state.value.settings.copy(
                    voiceCueVolume = safeVolume,
                ),
            )
            playVoiceTestCue(safeVolume)
        },
        onGhostVoiceCueEnabledChange = { enabled ->
            updateSettings(state.value.settings.copy(ghostVoiceCueEnabled = enabled))
        },
        onIntervalWorkoutChange = { workout ->
            updateSettings(
                state.value.settings.copy(
                    intervalWorkout = WearIntervalQuickSettings.normalize(workout),
                ),
            )
        },
        onGhostSelect = ::selectGhostConfig,
    )
}

private fun runPermissions(): Array<String> {
    return buildList {
        add(Manifest.permission.ACTIVITY_RECOGNITION)
        add(Manifest.permission.ACCESS_FINE_LOCATION)
        if (Build.VERSION.SDK_INT >= 36) {
            add("android.permission.health.READ_HEART_RATE")
        } else {
            add(Manifest.permission.BODY_SENSORS)
        }
    }.toTypedArray()
}

private fun android.content.Context.hasRunPermissions(): Boolean {
    return runPermissions().all { permission ->
        ContextCompat.checkSelfPermission(this, permission) == PERMISSION_GRANTED
    }
}
