package com.hey.mery

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import com.hey.mery.data.WakeWordState
import com.hey.mery.util.JarviceLogger
import com.hey.mery.wake_word.WakeWordEngine
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class WakeWordService : Service() {
    companion object {
        const val CHANNEL_ID = "wake_word_channel"
        const val NOTIFICATION_ID = 1
        const val TAG = "WakeWordService"
        const val SAMPLE_RATE = 16000
        const val CHUNK_SAMPLES = 1280
        const val ACTION_STOP = "com.hey.mery.STOP_WAKE_WORD"
        const val ACTION_PAUSE = "com.hey.mery.PAUSE_WAKE_WORD"
        const val ACTION_RESUME = "com.hey.mery.RESUME_WAKE_WORD"
    }

    private var audioRecord: AudioRecord? = null
    private val isRecording = AtomicBoolean(false)
    private val isPaused = AtomicBoolean(false)
    private var wakeWordEngine: WakeWordEngine? = null
    private var methodChannel: MethodChannel? = null
    private var audioExecutor: ExecutorService? = null
    private val micLock = ReentrantLock()
    @Volatile
    private var currentState = WakeWordState.STOPPED

    override fun onCreate() {
        super.onCreate()
        JarviceLogger.i(TAG, "onCreate", "Service creating")
        createNotificationChannel()
        wakeWordEngine = WakeWordEngine()
        wakeWordEngine?.initialize(this)

        val flutterEngine = FlutterEngineCache.getInstance().get("wake_word_engine")
        if (flutterEngine != null) {
            methodChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "com.hey.mery/wake_word"
            )
        }

        wakeWordEngine?.setOnWakeWordListener { confidence ->
            JarviceLogger.i(TAG, "onWakeWord", "Detected confidence=$confidence")
            updateState(WakeWordState.WAKE_WORD_DETECTED)
            methodChannel?.invokeMethod("onWakeWordDetected", mapOf("confidence" to confidence))
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                JarviceLogger.i(TAG, "onStartCommand", "Stop action received")
                pauseListening()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_PAUSE -> {
                JarviceLogger.i(TAG, "onStartCommand", "Pause action received")
                pauseListening()
                updateNotification()
                return START_STICKY
            }
            ACTION_RESUME -> {
                JarviceLogger.i(TAG, "onStartCommand", "Resume action received")
                resumeListening()
                updateNotification()
                return START_STICKY
            }
            "com.hey.mery.COMMAND_PROCESSING_STARTED" -> {
                JarviceLogger.i(TAG, "onStartCommand", "Command processing started")
                onCommandProcessingStarted()
                updateNotification()
                return START_STICKY
            }
            "com.hey.mery.COMMAND_PROCESSING_FINISHED" -> {
                JarviceLogger.i(TAG, "onStartCommand", "Command processing finished")
                onCommandProcessingFinished()
                updateNotification()
                return START_STICKY
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO)
                != PackageManager.PERMISSION_GRANTED
            ) {
                JarviceLogger.e(TAG, "onStartCommand", "RECORD_AUDIO not granted")
                updateState(WakeWordState.ERROR)
                stopSelf()
                return START_NOT_STICKY
            }
        }

        try {
            startForeground(NOTIFICATION_ID, createNotification())
        } catch (e: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                e is android.app.ForegroundServiceStartNotAllowedException
            ) {
                JarviceLogger.e(TAG, "onStartCommand", "ForegroundServiceStartNotAllowed: ${e.message}", e)
                updateState(WakeWordState.ERROR)
                return START_NOT_STICKY
            }
            JarviceLogger.e(TAG, "onStartCommand", "startForeground failed: ${e.message}", e)
            updateState(WakeWordState.ERROR)
            return START_NOT_STICKY
        }

        if (!isRecording.get() && !isPaused.get()) {
            startListening()
        }
        return START_STICKY
    }

    private fun startListening() {
        if (isRecording.getAndSet(true)) return
        updateState(WakeWordState.STARTING)

        micLock.withLock {
            try {
                val bufferSize = AudioRecord.getMinBufferSize(
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                )

                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )

                audioRecord?.startRecording()
                isRecording.set(true)
                isPaused.set(false)
                updateState(WakeWordState.LISTENING)
                JarviceLogger.i(TAG, "startListening", "AudioRecord started")

                audioExecutor = Executors.newSingleThreadExecutor { r ->
                    Thread(r, "JarviceAudioThread").apply {
                        priority = android.os.Process.THREAD_PRIORITY_URGENT_AUDIO
                    }
                }

                audioExecutor?.execute { audioCaptureLoop() }

            } catch (e: SecurityException) {
                JarviceLogger.e(TAG, "startListening", "Mic permission denied: ${e.message}", e)
                isRecording.set(false)
                updateState(WakeWordState.ERROR)
                stopSelf()
            } catch (e: Exception) {
                JarviceLogger.e(TAG, "startListening", "Failed: ${e.message}", e)
                isRecording.set(false)
                updateState(WakeWordState.ERROR)
            }
        }
    }

    private fun audioCaptureLoop() {
        val tempBuffer = ShortArray(CHUNK_SAMPLES * 2)
        var accumulated = 0
        val chunkBuffer = ShortArray(CHUNK_SAMPLES)

        while (isRecording.get() && !Thread.currentThread().isInterrupted) {
            if (isPaused.get()) {
                try {
                    Thread.sleep(100)
                } catch (_: InterruptedException) {
                    break
                }
                continue
            }

            try {
                val read = audioRecord?.read(tempBuffer, accumulated, CHUNK_SAMPLES * 2 - accumulated) ?: 0
                if (read > 0) {
                    accumulated += read
                }

                while (accumulated >= CHUNK_SAMPLES && isRecording.get() && !isPaused.get()) {
                    System.arraycopy(tempBuffer, 0, chunkBuffer, 0, CHUNK_SAMPLES)
                    System.arraycopy(tempBuffer, CHUNK_SAMPLES, tempBuffer, 0, accumulated - CHUNK_SAMPLES)
                    accumulated -= CHUNK_SAMPLES

                    if (currentState == WakeWordState.LISTENING) {
                        wakeWordEngine?.processAudio(chunkBuffer)
                    }
                }
            } catch (e: Exception) {
                if (isRecording.get()) {
                    JarviceLogger.e(TAG, "audioCaptureLoop", "Read error: ${e.message}", e)
                }
                break
            }
        }
        JarviceLogger.i(TAG, "audioCaptureLoop", "Audio capture loop ended")
    }

    fun pauseListening() {
        if (!isRecording.get()) return
        JarviceLogger.i(TAG, "pauseListening", "Pausing")
        isPaused.set(true)
        updateState(WakeWordState.PAUSED)
    }

    fun resumeListening() {
        if (!isRecording.get()) {
            startListening()
            return
        }
        JarviceLogger.i(TAG, "resumeListening", "Resuming")
        isPaused.set(false)
        updateState(WakeWordState.LISTENING)
    }

    fun onCommandProcessingStarted() {
        JarviceLogger.i(TAG, "onCommandProcessing", "Command processing started")
        isPaused.set(true)
        updateState(WakeWordState.PROCESSING_COMMAND)
    }

    fun onCommandProcessingFinished() {
        JarviceLogger.i(TAG, "onCommandProcessing", "Command processing finished")
        isPaused.set(false)
        updateState(WakeWordState.LISTENING)
    }

    private fun stopAudioCapture() {
        micLock.withLock {
            try {
                audioRecord?.stop()
            } catch (e: Exception) {
                JarviceLogger.e(TAG, "stopAudioCapture", "Stop error: ${e.message}", e)
            }
            try {
                audioRecord?.release()
            } catch (e: Exception) {
                JarviceLogger.e(TAG, "stopAudioCapture", "Release error: ${e.message}", e)
            }
            audioRecord = null
        }

        audioExecutor?.let { executor ->
            executor.shutdownNow()
            try {
                if (!executor.awaitTermination(2, java.util.concurrent.TimeUnit.SECONDS)) {
                    JarviceLogger.w(TAG, "stopAudioCapture", "Executor did not terminate in time")
                }
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            }
        }
        audioExecutor = null
        isRecording.set(false)
        isPaused.set(false)
    }

    private fun updateState(newState: WakeWordState) {
        currentState = newState
        JarviceLogger.d(TAG, "updateState", "State -> ${newState.value}")
        try {
            methodChannel?.invokeMethod("onWakeWordStateChanged", newState.toMap())
        } catch (e: Exception) {
            JarviceLogger.w(TAG, "updateState", "Failed to notify Flutter: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Jarvice Wake Word",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background wake word listening"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val stopIntent = Intent(this, WakeWordService::class.java).apply { action = ACTION_STOP }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseIntent = Intent(this, WakeWordService::class.java).apply { action = ACTION_PAUSE }
        val pausePendingIntent = PendingIntent.getService(
            this, 1, pauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val resumeIntent = Intent(this, WakeWordService::class.java).apply { action = ACTION_RESUME }
        val resumePendingIntent = PendingIntent.getService(
            this, 2, resumeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 3, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val isCurrentlyPaused = isPaused.get()
        val contentText = when (currentState) {
            WakeWordState.LISTENING -> "Listening... Say 'Hey Jarvis'"
            WakeWordState.PAUSED -> "Paused"
            WakeWordState.PROCESSING_COMMAND -> "Processing command..."
            WakeWordState.WAKE_WORD_DETECTED -> "Wake word detected!"
            WakeWordState.STARTING -> "Starting..."
            WakeWordState.ERROR -> "Error - tap to open app"
            WakeWordState.STOPPED -> "Stopped"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Jarvice is listening")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openAppPendingIntent)
            .setOngoing(true)

        if (isCurrentlyPaused || currentState == WakeWordState.PAUSED) {
            builder.addAction(android.R.drawable.ic_media_play, "Resume", resumePendingIntent)
        } else {
            builder.addAction(android.R.drawable.ic_media_pause, "Pause", pausePendingIntent)
        }
        builder.addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)

        return builder.build()
    }

    private fun updateNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, createNotification())
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        JarviceLogger.i(TAG, "onDestroy", "Service destroying")
        stopAudioCapture()
        wakeWordEngine?.release()
        wakeWordEngine = null
        updateState(WakeWordState.STOPPED)
        super.onDestroy()
    }
}
