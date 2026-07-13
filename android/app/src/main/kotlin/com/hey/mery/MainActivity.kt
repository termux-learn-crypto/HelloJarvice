package com.hey.mery

import android.content.Context
import android.content.Intent
import android.os.Build
import com.hey.mery.controller.MobileController
import com.hey.mery.util.JarviceLogger
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val WAKE_WORD_CHANNEL = "com.hey.mery/wake_word"
        private const val SYSTEM_CHANNEL = "com.hey.mery/system"
    }

    private var mobileController: MobileController? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        JarviceLogger.i(TAG, "configureFlutterEngine", "Starting")

        FlutterEngineCache.getInstance().put("wake_word_engine", flutterEngine)
        mobileController = MobileController(applicationContext)

        val wakeWordChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKE_WORD_CHANNEL)
        wakeWordChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initEngine" -> {
                    result.success(true)
                }
                "startListening" -> {
                    try {
                        val intent = Intent(this, WakeWordService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        JarviceLogger.e(TAG, "startListening", "Failed: ${e.message}", e)
                        result.success(false)
                    }
                }
                "stopListening" -> {
                    try {
                        val intent = Intent(this, WakeWordService::class.java).apply {
                            action = WakeWordService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        JarviceLogger.e(TAG, "stopListening", "Failed: ${e.message}", e)
                        result.success(false)
                    }
                }
                "pauseListening" -> {
                    try {
                        val intent = Intent(this, WakeWordService::class.java).apply {
                            action = WakeWordService.ACTION_PAUSE
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        JarviceLogger.e(TAG, "pauseListening", "Failed: ${e.message}", e)
                        result.success(false)
                    }
                }
                "resumeListening" -> {
                    try {
                        val intent = Intent(this, WakeWordService::class.java).apply {
                            action = WakeWordService.ACTION_RESUME
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        JarviceLogger.e(TAG, "resumeListening", "Failed: ${e.message}", e)
                        result.success(false)
                    }
                }
                "onCommandProcessingStarted" -> {
                    try {
                        val intent = Intent(this, WakeWordService::class.java).apply {
                            action = "com.hey.mery.COMMAND_PROCESSING_STARTED"
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "onCommandProcessingFinished" -> {
                    try {
                        val intent = Intent(this, WakeWordService::class.java).apply {
                            action = "com.hey.mery.COMMAND_PROCESSING_FINISHED"
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val systemChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
        systemChannel.setMethodCallHandler(mobileController)
    }

    override fun onDestroy() {
        try {
            val intent = Intent(this, WakeWordService::class.java).apply {
                action = WakeWordService.ACTION_STOP
            }
            startService(intent)
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
