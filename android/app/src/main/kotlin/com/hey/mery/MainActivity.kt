package com.hey.mery

import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraManager
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

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
                    val state = call.argument<Boolean>("state") ?: false
                    toggleWifi(state)
                    result.success(null)
                }
                "toggleBluetooth" -> {
                    val state = call.argument<Boolean>("state") ?: false
                    toggleBluetooth(state)
                    result.success(null)
                }
                "toggleFlashlight" -> {
                    val state = call.argument<Boolean>("state") ?: false
                    toggleFlashlight(state)
                    result.success(null)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("package") ?: ""
                    val launched = launchApp(packageName)
                    result.success(launched)
                }
                "openSettings" -> {
                    val section = call.argument<String>("section")
                    openDeviceSettings(section)
                    result.success(null)
                }
                "setAlarm" -> {
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val label = call.argument<String>("label") ?: "Alarm"
                    setAlarm(hour, minute, label)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun toggleWifi(enable: Boolean) {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifiManager.isWifiEnabled = enable
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    @Suppress("DEPRECATION")
    private fun toggleBluetooth(enable: Boolean) {
        try {
            val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter != null) {
                if (enable && !bluetoothAdapter.isEnabled) {
                    bluetoothAdapter.enable()
                } else if (!enable && bluetoothAdapter.isEnabled) {
                    bluetoothAdapter.disable()
                }
            } else {
                val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    private fun toggleFlashlight(enable: Boolean) {
        try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull() ?: return
            cameraManager.setTorchMode(cameraId, enable)
        } catch (_: Exception) {}
    }

    private fun launchApp(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun openDeviceSettings(section: String?) {
        try {
            val intent = when (section) {
                "wifi" -> Intent(Settings.ACTION_WIFI_SETTINGS)
                "bluetooth" -> Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                "location" -> Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                "sound" -> Intent(Settings.ACTION_SOUND_SETTINGS)
                "display" -> Intent(Settings.ACTION_DISPLAY_SETTINGS)
                "battery" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                else -> Intent(Settings.ACTION_SETTINGS)
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (_: Exception) {}
    }

    private fun setAlarm(hour: Int, minute: Int, label: String) {
        try {
            val intent = Intent(android.provider.AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(android.provider.AlarmClock.EXTRA_HOUR, hour)
                putExtra(android.provider.AlarmClock.EXTRA_MINUTES, minute)
                putExtra(android.provider.AlarmClock.EXTRA_MESSAGE, label)
                putExtra(android.provider.AlarmClock.EXTRA_SKIP_UI, true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {}
    }
}
