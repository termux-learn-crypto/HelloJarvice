package com.hey.mery

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import com.hey.mery.wake_word.WakeWordEngine
import java.util.concurrent.atomic.AtomicBoolean

class WakeWordService : Service() {
    companion object {
        const val CHANNEL_ID = "wake_word_channel"
        const val NOTIFICATION_ID = 1
        const val TAG = "WakeWordService"
        const val SAMPLE_RATE = 16000
        const val CHUNK_SAMPLES = 1280
    }

    private var audioRecord: AudioRecord? = null
    private val isRunning = AtomicBoolean(false)
    private var wakeWordEngine: WakeWordEngine? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate() {
        super.onCreate()
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
            Log.d(TAG, "Wake word detected! Confidence: $confidence")
            methodChannel?.invokeMethod("onWakeWordDetected", null)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        if (!isRunning.get()) {
            startListening()
        }
        return START_STICKY
    }

    private fun startListening() {
        if (isRunning.getAndSet(true)) return

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

        try {
            audioRecord?.startRecording()
            isRunning.set(true)

            Thread {
                android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO)
                val tempBuffer = ShortArray(CHUNK_SAMPLES * 2)
                var accumulated = 0
                val chunkBuffer = ShortArray(CHUNK_SAMPLES)

                while (isRunning.get()) {
                    val read = audioRecord?.read(tempBuffer, accumulated, CHUNK_SAMPLES * 2 - accumulated) ?: 0
                    if (read > 0) {
                        accumulated += read
                    }

                    while (accumulated >= CHUNK_SAMPLES) {
                        System.arraycopy(tempBuffer, 0, chunkBuffer, 0, CHUNK_SAMPLES)
                        System.arraycopy(tempBuffer, CHUNK_SAMPLES, tempBuffer, 0, accumulated - CHUNK_SAMPLES)
                        accumulated -= CHUNK_SAMPLES

                        wakeWordEngine?.processAudio(chunkBuffer)
                    }
                }
            }.start()

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording: ${e.message}")
            isRunning.set(false)
        }
    }

    private fun stopListening() {
        isRunning.set(false)
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping: ${e.message}")
        }
        audioRecord = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Wake Word Detection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background wake word listening"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Hello Jarvice")
            .setContentText("Listening... Say 'Hey Jarvis'")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopListening()
        wakeWordEngine?.release()
        super.onDestroy()
    }
}
