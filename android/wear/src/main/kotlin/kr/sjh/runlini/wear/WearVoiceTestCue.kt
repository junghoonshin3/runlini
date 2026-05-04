package kr.sjh.runlini.wear

import android.content.Context
import android.os.Handler
import android.os.Looper

internal object WearVoiceTestCue {
    const val Text = "음량 테스트"
    private const val ShutdownDelayMs = 3_000L

    fun play(context: Context, volume: Float) {
        val safeVolume = WearRunSettingsDefaults.clampVoiceVolume(volume)
        val handler = Handler(Looper.getMainLooper())
        handler.post {
            val speech = AndroidWearRunSpeech(context)
            speech.speak(Text, safeVolume)
            handler.postDelayed({ speech.shutdown() }, ShutdownDelayMs)
        }
    }
}
