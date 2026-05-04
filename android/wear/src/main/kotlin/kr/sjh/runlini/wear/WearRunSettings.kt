package kr.sjh.runlini.wear

import android.content.Context
import org.json.JSONObject
import java.io.File

data class WearRunSettings(
    val countdownEnabled: Boolean = true,
    val vibrationEnabled: Boolean = true,
    val kmAlertEnabled: Boolean = false,
    val voiceCueEnabled: Boolean = true,
    val voiceCueVolume: Float = WearRunSettingsDefaults.DefaultVoiceCueVolume,
    val ghostVoiceCueEnabled: Boolean = false,
    val autoPauseEnabled: Boolean = false,
    val intervalWorkout: WearIntervalWorkout = WearIntervalWorkout(),
)

object WearRunSettingsDefaults {
    const val DefaultVoiceCueVolume = 1.0f
    const val VoiceCueVolumeStep = 0.1f

    fun clampVoiceVolume(volume: Float): Float {
        return volume.coerceIn(0.0f, 1.0f)
    }
}

interface WearRunSettingsPersistence {
    fun read(): String?
    fun write(json: String)
}

class WearRunSettingsStore(
    private val persistence: WearRunSettingsPersistence,
) {
    constructor(context: Context) : this(FileWearRunSettingsPersistence(context))

    fun current(): WearRunSettings {
        val json = persistence.read() ?: return WearRunSettings()
        return runCatching {
            WearRunSettingsJsonMapper.fromJson(json)
        }.getOrDefault(WearRunSettings())
    }

    fun save(settings: WearRunSettings) {
        persistence.write(WearRunSettingsJsonMapper.toJson(settings))
    }
}

object WearRunSettingsJsonMapper {
    fun toJson(settings: WearRunSettings): String {
        return JSONObject()
            .put("countdownEnabled", settings.countdownEnabled)
            .put("vibrationEnabled", settings.vibrationEnabled)
            .put("kmAlertEnabled", settings.kmAlertEnabled)
            .put("voiceCueEnabled", settings.voiceCueEnabled)
            .put("voiceCueVolume", WearRunSettingsDefaults.clampVoiceVolume(settings.voiceCueVolume))
            .put("ghostVoiceCueEnabled", settings.ghostVoiceCueEnabled)
            .put("autoPauseEnabled", settings.autoPauseEnabled)
            .put(
                "intervalWorkout",
                JSONObject(WearIntervalWorkoutJsonMapper.toJson(settings.intervalWorkout)),
            )
            .toString()
    }

    fun fromJson(json: String): WearRunSettings {
        val objectJson = JSONObject(json)
        return WearRunSettings(
            countdownEnabled = objectJson.optBoolean("countdownEnabled", true),
            vibrationEnabled = objectJson.optBoolean("vibrationEnabled", true),
            kmAlertEnabled = objectJson.optBoolean("kmAlertEnabled", false),
            voiceCueEnabled = objectJson.optBoolean("voiceCueEnabled", true),
            voiceCueVolume = WearRunSettingsDefaults.clampVoiceVolume(
                objectJson.optDouble(
                    "voiceCueVolume",
                    WearRunSettingsDefaults.DefaultVoiceCueVolume.toDouble(),
                ).toFloat(),
            ),
            ghostVoiceCueEnabled = objectJson.optBoolean("ghostVoiceCueEnabled", false),
            autoPauseEnabled = objectJson.optBoolean("autoPauseEnabled", false),
            intervalWorkout = objectJson.optJSONObject("intervalWorkout")?.let {
                WearIntervalWorkoutJsonMapper.fromJson(it.toString())
            } ?: WearIntervalWorkout(),
        )
    }
}

private class FileWearRunSettingsPersistence(
    context: Context,
) : WearRunSettingsPersistence {
    private val file = File(context.filesDir, "wear_run_settings.json")

    override fun read(): String? {
        if (!file.exists()) return null
        return file.readText(Charsets.UTF_8).takeIf { it.isNotBlank() }
    }

    override fun write(json: String) {
        file.parentFile?.mkdirs()
        file.writeText(json, Charsets.UTF_8)
    }
}

object WearRunStartPolicy {
    fun shouldUseCountdown(settings: WearRunSettings): Boolean {
        return settings.countdownEnabled
    }
}
