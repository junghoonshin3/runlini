package kr.sjh.runlini

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.EventChannel
import kotlin.math.roundToInt

class RunMotionEvidenceStreamHandler(
    private val activity: FlutterFragmentActivity,
) : EventChannel.StreamHandler {
    private var sensorManager: SensorManager? = null
    private var listener: SensorEventListener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        if (!hasActivityRecognitionPermission()) {
            events.success(event("permissionDenied"))
            return
        }
        startSensor(events)
    }

    override fun onCancel(arguments: Any?) {
        listener?.let { sensorManager?.unregisterListener(it) }
        listener = null
        sensorManager = null
    }

    private fun startSensor(events: EventChannel.EventSink) {
        val manager = activity.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val sensor = manager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
        if (manager == null || sensor == null) {
            events.success(event("unavailable"))
            return
        }
        events.success(event("available"))
        sensorManager = manager
        listener = object : SensorEventListener {
            override fun onSensorChanged(sensorEvent: SensorEvent) {
                val stepDelta = sensorEvent.values.firstOrNull()?.roundToInt() ?: 1
                events.success(event("available", stepDelta.coerceAtLeast(1)))
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
        }
        manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    private fun hasActivityRecognitionPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.ACTIVITY_RECOGNITION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun event(
        availability: String,
        stepDelta: Int = 0,
    ): Map<String, Any> {
        return mapOf(
            "availability" to availability,
            "stepDelta" to stepDelta,
            "timestampEpochMs" to System.currentTimeMillis(),
        )
    }
}
