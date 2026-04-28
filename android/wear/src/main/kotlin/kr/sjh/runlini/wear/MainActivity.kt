package kr.sjh.runlini.wear

import android.Manifest
import android.content.pm.PackageManager.PERMISSION_GRANTED
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
import androidx.compose.runtime.rememberCoroutineScope
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
    val scope = rememberCoroutineScope()
    val controller = remember {
        HealthServicesRunController(context.applicationContext, scope)
    }
    val lifecycleOwner = LocalLifecycleOwner.current
    val state by controller.state.collectAsState()
    var hasPermissions by remember { mutableStateOf(context.hasRunPermissions()) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { results ->
        hasPermissions = runPermissions().all { permission ->
            results[permission] == true ||
                ContextCompat.checkSelfPermission(context, permission) == PERMISSION_GRANTED
        }
    }

    LaunchedEffect(Unit) {
        controller.flushPendingDrafts()
        while (true) {
            delay(2_000L)
            controller.refreshPendingDraftCount()
        }
    }

    DisposableEffect(Unit) {
        onDispose { controller.dispose() }
    }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                controller.refreshPendingDraftCount()
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
            WearRunScreen(state = state, controller = controller)
        }
    }
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
