package com.hey.hello_jarvice

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import android.os.Build

class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "com.hey.mery/wake_word"
        const val SYSTEM_CHANNEL = "com.hey.mery/system"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val wakeWordChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        wakeWordChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initEngine" -> {
                    result.success(true)
                }
                "startListening" -> {
                    val intent = Intent(this, WakeWordService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    FlutterEngineCache.getInstance().put("wake_word_engine", flutterEngine)
                    result.success(true)
                }
                "stopListening" -> {
                    val intent = Intent(this, WakeWordService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        val systemChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
        systemChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleWifi" -> {
                    result.success(null)
                }
                "toggleBluetooth" -> {
                    result.success(null)
                }
                "toggleFlashlight" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
