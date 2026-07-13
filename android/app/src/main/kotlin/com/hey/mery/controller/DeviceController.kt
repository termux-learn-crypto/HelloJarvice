package com.hey.mery.controller

import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class DeviceController(private val context: Context) {

    companion object {
        private const val COMPONENT = "DeviceController"
    }

    fun getDeviceInfo(): CommandResult {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = batteryManager.isCharging

        return CommandResult.ok(
            "Device info",
            mapOf(
                "manufacturer" to Build.MANUFACTURER,
                "model" to Build.MODEL,
                "sdkVersion" to Build.VERSION.SDK_INT,
                "releaseVersion" to Build.VERSION.RELEASE,
                "batteryLevel" to batteryLevel,
                "isCharging" to isCharging
            )
        )
    }

    fun getBatteryLevel(): CommandResult {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = batteryManager.isCharging
        val status = if (isCharging) "charge ho raha hai" else "battery use ho rahi hai"
        return CommandResult.ok("Battery $batteryLevel% hai, $status", "level" to batteryLevel, "charging" to isCharging)
    }

    fun openBatterySettings(): CommandResult {
        return try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Battery settings khol diye")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "openBatterySettings", "Error: ${e.message}", e)
            CommandResult.error("Battery settings nahi khule", "BATTERY_SETTINGS_FAILED")
        }
    }

    fun getScreenBrightness(): CommandResult {
        return try {
            val brightness = Settings.System.getInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS
            )
            val maxBrightness = 255
            val percent = (brightness * 100) / maxBrightness
            CommandResult.ok("Screen brightness $percent% hai", "brightness" to percent)
        } catch (e: SecurityException) {
            CommandResult.error("Brightness padh nahi payi", "SETTINGS_PERMISSION_DENIED")
        }
    }

    fun setScreenBrightness(percent: Int): CommandResult {
        val clamped = percent.coerceIn(0, 100)
        val brightness = (clamped * 255) / 100
        return try {
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                brightness
            )
            CommandResult.ok("Brightness $clamped% pe set kar diya", "brightness" to clamped)
        } catch (e: SecurityException) {
            CommandResult.error("Brightness change nahi ho payi", "SETTINGS_PERMISSION_DENIED")
        }
    }

    fun openPowerMenu(): CommandResult {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val intent = Intent("android.globalActions").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                CommandResult.ok("Power menu khol diya")
            } else {
                CommandResult.error("Is Android version pe power menu nahi khulega", "UNSUPPORTED_API")
            }
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "openPowerMenu", "Error: ${e.message}", e)
            CommandResult.error("Power menu nahi khula", "POWER_MENU_FAILED")
        }
    }

    fun checkBatteryOptimization(): CommandResult {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val isIgnoringBattery = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            true
        }

        return if (isIgnoringBattery) {
            CommandResult.ok("Battery optimization chhutti hai Jarvice ke liye", "ignored" to true)
        } else {
            CommandResult(
                success = false,
                message = "Battery optimization on hai. Disable karna hai?",
                data = mapOf("ignored" to false),
                errorCode = "BATTERY_OPTIMIZATION_ACTIVE",
                requiresConfirmation = true
            )
        }
    }

    fun increaseBrightness(): CommandResult {
        return try {
            val current = Settings.System.getInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS)
            val newBrightness = (current + 25).coerceAtMost(255)
            Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, newBrightness)
            val percent = (newBrightness * 100) / 255
            CommandResult.ok("Brightness badha diya: $percent%", "brightness" to percent)
        } catch (e: SecurityException) {
            CommandResult.error("Brightness change nahi ho payi", "SETTINGS_PERMISSION_DENIED")
        }
    }

    fun decreaseBrightness(): CommandResult {
        return try {
            val current = Settings.System.getInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS)
            val newBrightness = (current - 25).coerceAtLeast(0)
            Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, newBrightness)
            val percent = (newBrightness * 100) / 255
            CommandResult.ok("Brightness ghata di: $percent%", "brightness" to percent)
        } catch (e: SecurityException) {
            CommandResult.error("Brightness change nahi ho payi", "SETTINGS_PERMISSION_DENIED")
        }
    }

    fun setAutoBrightness(enabled: Boolean): CommandResult {
        return try {
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                if (enabled) Settings.System.SCREEN_BRIGHTNESS_MODE_AUTOMATIC
                else Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
            )
            CommandResult.ok(if (enabled) "Auto brightness on kar diya" else "Auto brightness band kar diya")
        } catch (e: SecurityException) {
            CommandResult.error("Auto brightness change nahi ho payi", "SETTINGS_PERMISSION_DENIED")
        }
    }
}
