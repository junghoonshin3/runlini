// Android 활동 인식 권한 상태와 요청을 처리하는 MethodChannel 핸들러
package kr.sjh.runlini

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class RunMotionPermissionHandler(
    private val activity: FlutterFragmentActivity,
) {
    private var pendingRequestResult: MethodChannel.Result? = null
    private val preferences =
        activity.getSharedPreferences("run_motion_permissions", Context.MODE_PRIVATE)

    fun checkActivityRecognitionPermission(): String {
        return activityRecognitionStatus()
    }

    fun requestActivityRecognitionPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || hasPermission()) {
            result.success(GRANTED)
            return
        }
        if (pendingRequestResult != null) {
            result.error(
                "request_in_progress",
                "Activity recognition permission request is already in progress.",
                null,
            )
            return
        }

        pendingRequestResult = result
        preferences.edit().putBoolean(ACTIVITY_RECOGNITION_REQUESTED_KEY, true).apply()
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.ACTIVITY_RECOGNITION),
            ACTIVITY_RECOGNITION_REQUEST_CODE,
        )
    }

    fun openAppSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", activity.packageName, null),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activity.startActivity(intent)
    }

    fun onRequestPermissionsResult(requestCode: Int): Boolean {
        if (requestCode != ACTIVITY_RECOGNITION_REQUEST_CODE) return false
        pendingRequestResult?.success(activityRecognitionStatus())
        pendingRequestResult = null
        return true
    }

    private fun activityRecognitionStatus(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return GRANTED
        if (hasPermission()) return GRANTED
        val wasRequested = preferences.getBoolean(ACTIVITY_RECOGNITION_REQUESTED_KEY, false)
        return if (
            wasRequested &&
            !ActivityCompat.shouldShowRequestPermissionRationale(
                activity,
                Manifest.permission.ACTIVITY_RECOGNITION,
            )
        ) {
            PERMANENTLY_DENIED
        } else {
            DENIED
        }
    }

    private fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.ACTIVITY_RECOGNITION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    companion object {
        const val ACTIVITY_RECOGNITION_REQUEST_CODE = 7301
        private const val ACTIVITY_RECOGNITION_REQUESTED_KEY = "activity_recognition_requested"
        private const val GRANTED = "granted"
        private const val DENIED = "denied"
        private const val PERMANENTLY_DENIED = "permanentlyDenied"
    }
}
