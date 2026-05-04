package kr.sjh.runlini.wear

import android.content.Context
import android.os.Bundle
import android.speech.tts.TextToSpeech
import java.util.Locale

interface WearRunSpeech {
    fun speak(text: String, volume: Float = 1.0f)
    fun shutdown()
}

object NoOpWearRunSpeech : WearRunSpeech {
    override fun speak(text: String, volume: Float) = Unit
    override fun shutdown() = Unit
}

class AndroidWearRunSpeech(context: Context) : WearRunSpeech, TextToSpeech.OnInitListener {
    private var textToSpeech: TextToSpeech? = TextToSpeech(
        context.applicationContext,
        this,
    )
    private var isReady = false
    private var pendingText: String? = null
    private var pendingVolume: Float = 1.0f

    override fun onInit(status: Int) {
        val tts = textToSpeech ?: return
        if (status != TextToSpeech.SUCCESS) {
            shutdown()
            return
        }
        val availability = tts.setLanguage(Locale.KOREAN)
        if (
            availability == TextToSpeech.LANG_MISSING_DATA ||
            availability == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            shutdown()
            return
        }
        tts.setSpeechRate(1.0f)
        isReady = true
        pendingText?.let { speakNow(it, pendingVolume) }
        pendingText = null
        pendingVolume = 1.0f
    }

    override fun speak(text: String, volume: Float) {
        if (text.isBlank()) return
        val safeVolume = volume.coerceIn(0.0f, 1.0f)
        if (!isReady) {
            pendingText = text
            pendingVolume = safeVolume
            return
        }
        speakNow(text, safeVolume)
    }

    override fun shutdown() {
        isReady = false
        pendingText = null
        pendingVolume = 1.0f
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
    }

    private fun speakNow(text: String, volume: Float) {
        val params = Bundle().apply {
            putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume.coerceIn(0.0f, 1.0f))
        }
        textToSpeech?.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            params,
            "runlini-${System.nanoTime()}",
        )
    }
}
