package com.hey.mery.controller

import android.content.Context
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.os.Build
import android.view.KeyEvent
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class MediaController(context: Context) {

    companion object {
        private const val COMPONENT = "MediaController"
    }

    private val mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as? MediaSessionManager

    private fun getActiveController(): MediaController? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val sessions = mediaSessionManager?.getActiveSessions(null)
                sessions?.firstOrNull()
            } else {
                null
            }
        } catch (e: SecurityException) {
            JarviceLogger.w(COMPONENT, "getActiveController", "NotificationListener not enabled: ${e.message}")
            null
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "getActiveController", "Error: ${e.message}", e)
            null
        }
    }

    fun play(): CommandResult {
        val controller = getActiveController()
            ?: return CommandResult.error(
                "Koi media session nahi mila. Pehle koi gaana chalao.",
                "NO_MEDIA_SESSION"
            )
        controller.transportControls.play()
        JarviceLogger.i(COMPONENT, "play", "Play sent")
        return CommandResult.ok("Chala diya")
    }

    fun pause(): CommandResult {
        val controller = getActiveController()
            ?: return CommandResult.error("Koi media session nahi mila", "NO_MEDIA_SESSION")
        controller.transportControls.pause()
        JarviceLogger.i(COMPONENT, "pause", "Pause sent")
        return CommandResult.ok("Rok diya")
    }

    fun stop(): CommandResult {
        val controller = getActiveController()
            ?: return CommandResult.error("Koi media session nahi mila", "NO_MEDIA_SESSION")
        controller.transportControls.stop()
        JarviceLogger.i(COMPONENT, "stop", "Stop sent")
        return CommandResult.ok("Band kar diya")
    }

    fun next(): CommandResult {
        val controller = getActiveController()
            ?: return CommandResult.error("Koi media session nahi mila", "NO_MEDIA_SESSION")
        controller.transportControls.skipToNext()
        JarviceLogger.i(COMPONENT, "next", "Next sent")
        return CommandResult.ok("Agla gaana")
    }

    fun previous(): CommandResult {
        val controller = getActiveController()
            ?: return CommandResult.error("Koi media session nahi mila", "NO_MEDIA_SESSION")
        controller.transportControls.skipToPrevious()
        JarviceLogger.i(COMPONENT, "previous", "Previous sent")
        return CommandResult.ok("Pichla gaana")
    }

    fun getPlaybackState(): CommandResult {
        val controller = getActiveController()
            ?: return CommandResult.ok(
                "Koi active media nahi",
                "playing" to false,
                "hasSession" to false
            )
        val state = controller.playbackState
        val isPlaying = state?.state == android.media.session.PlaybackState.STATE_PLAYING
        val metadata = controller.metadata
        val title = metadata?.getString(android.media.MediaMetadata.METADATA_KEY_TITLE)
        val artist = metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST)
        return CommandResult.ok(
            if (isPlaying) "Chal raha hai" else "Ruka hua hai",
            "playing" to isPlaying,
            "title" to title,
            "artist" to artist,
            "hasSession" to true
        )
    }

    fun getCurrentMediaApp(): CommandResult {
        val controller = getActiveController()
            ?: return CommandResult.ok("Koi active media nahi", "package" to "")
        val pkg = controller.packageName
        return CommandResult.ok("Media app: $pkg", "package" to pkg)
    }

    fun playMediaQuery(query: String): CommandResult {
        return try {
            val intent = android.content.Intent(android.content.Intent.ACTION_WEB_SEARCH).apply {
                putExtra("query", "play $query")
                addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Media search kar raha hoon: $query")
        } catch (e: Exception) {
            CommandResult.error("Media search nahi ho paya: ${e.message}")
        }
    }
}
