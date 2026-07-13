package com.hey.mery.controller

import android.content.Context
import android.media.AudioManager
import android.os.Build
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class AudioController(context: Context) {

    companion object {
        private const val COMPONENT = "AudioController"
    }

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    fun volumeUp(stream: String = "music"): CommandResult {
        val streamType = getStreamType(stream)
        val maxVol = audioManager.getStreamMaxVolume(streamType)
        val currentVol = audioManager.getStreamVolume(streamType)

        if (currentVol >= maxVol) {
            return CommandResult.ok("Volume already maximum hai")
        }

        audioManager.adjustStreamVolume(streamType, AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI)
        val newVol = audioManager.getStreamVolume(streamType)
        val percent = (newVol * 100) / maxVol
        JarviceLogger.i(COMPONENT, "volumeUp", "Stream=$stream, $currentVol->$newVol ($percent%)")
        return CommandResult.ok("Volume badha diya: $percent%", mapOf("volume" to percent))
    }

    fun volumeDown(stream: String = "music"): CommandResult {
        val streamType = getStreamType(stream)
        val maxVol = audioManager.getStreamMaxVolume(streamType)
        val currentVol = audioManager.getStreamVolume(streamType)

        if (currentVol <= 0) {
            return CommandResult.ok("Volume already minimum hai")
        }

        audioManager.adjustStreamVolume(streamType, AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI)
        val newVol = audioManager.getStreamVolume(streamType)
        val percent = (newVol * 100) / maxVol
        JarviceLogger.i(COMPONENT, "volumeDown", "Stream=$stream, $currentVol->$newVol ($percent%)")
        return CommandResult.ok("Volume kam kiya: $percent%", mapOf("volume" to percent))
    }

    fun setVolume(percent: Int, stream: String = "music"): CommandResult {
        val streamType = getStreamType(stream)
        val maxVol = audioManager.getStreamMaxVolume(streamType)
        val clampedPercent = percent.coerceIn(0, 100)
        val targetVol = (clampedPercent * maxVol) / 100

        audioManager.setStreamVolume(streamType, targetVol, AudioManager.FLAG_SHOW_UI)
        val actualPercent = (targetVol * 100) / maxVol
        JarviceLogger.i(COMPONENT, "setVolume", "Stream=$stream, target=$clampedPercent%, actual=$actualPercent%")
        return CommandResult.ok("Volume $actualPercent% pe set kar diya", mapOf("volume" to actualPercent))
    }

    fun mute(stream: String = "music"): CommandResult {
        val streamType = getStreamType(stream)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioManager.adjustStreamVolume(streamType, AudioManager.ADJUST_MUTE, 0)
        } else {
            @Suppress("DEPRECATION")
            audioManager.setStreamMute(streamType, true)
        }
        JarviceLogger.i(COMPONENT, "mute", "Stream=$stream muted")
        return CommandResult.ok("Volume mute kar diya")
    }

    fun unmute(stream: String = "music"): CommandResult {
        val streamType = getStreamType(stream)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioManager.adjustStreamVolume(streamType, AudioManager.ADJUST_UNMUTE, 0)
        } else {
            @Suppress("DEPRECATION")
            audioManager.setStreamMute(streamType, false)
        }
        JarviceLogger.i(COMPONENT, "unmute", "Stream=$stream unmuted")
        return CommandResult.ok("Volume unmute kar diya")
    }

    fun maxVolume(stream: String = "music"): CommandResult {
        val streamType = getStreamType(stream)
        val maxVol = audioManager.getStreamMaxVolume(streamType)
        audioManager.setStreamVolume(streamType, maxVol, AudioManager.FLAG_SHOW_UI)
        JarviceLogger.i(COMPONENT, "maxVolume", "Stream=$stream set to max=$maxVol")
        return CommandResult.ok("Volume maximum kar diya")
    }

    fun getVolumeInfo(stream: String = "music"): CommandResult {
        val streamType = getStreamType(stream)
        val currentVol = audioManager.getStreamVolume(streamType)
        val maxVol = audioManager.getStreamMaxVolume(streamType)
        val percent = if (maxVol > 0) (currentVol * 100) / maxVol else 0
        return CommandResult.ok(
            "Volume $percent% hai",
            mapOf(
                "current" to currentVol,
                "max" to maxVol,
                "percent" to percent,
                "isMuted" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        audioManager.isStreamMute(streamType))
            )
        )
    }

    private fun getStreamType(stream: String): Int {
        return when (stream.lowercase()) {
            "ring", "ringtone" -> AudioManager.STREAM_RING
            "alarm" -> AudioManager.STREAM_ALARM
            "notification" -> AudioManager.STREAM_NOTIFICATION
            "system" -> AudioManager.STREAM_SYSTEM
            "voice" -> AudioManager.STREAM_VOICE_CALL
            else -> AudioManager.STREAM_MUSIC
        }
    }
}
