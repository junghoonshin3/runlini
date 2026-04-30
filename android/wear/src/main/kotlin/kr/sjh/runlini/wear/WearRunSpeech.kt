package kr.sjh.runlini.wear

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

interface WearRunSpeech {
    fun speak(text: String)
    fun shutdown()
}

object NoOpWearRunSpeech : WearRunSpeech {
    override fun speak(text: String) = Unit
    override fun shutdown() = Unit
}

class AndroidWearRunSpeech(context: Context) : WearRunSpeech, TextToSpeech.OnInitListener {
    private var textToSpeech: TextToSpeech? = TextToSpeech(
        context.applicationContext,
        this,
    )
    private var isReady = false
    private var pendingText: String? = null

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
        pendingText?.let(::speakNow)
        pendingText = null
    }

    override fun speak(text: String) {
        if (text.isBlank()) return
        if (!isReady) {
            pendingText = text
            return
        }
        speakNow(text)
    }

    override fun shutdown() {
        isReady = false
        pendingText = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
    }

    private fun speakNow(text: String) {
        textToSpeech?.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            null,
            "runlini-${System.nanoTime()}",
        )
    }
}
