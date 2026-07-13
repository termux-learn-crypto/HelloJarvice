package com.hey.mery.controller

import android.content.Context
import android.content.Intent
import android.provider.Settings
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class SettingsController(private val context: Context) {

    companion object {
        private const val COMPONENT = "SettingsController"
    }

    fun openSettings(section: String?): CommandResult {
        JarviceLogger.d(COMPONENT, "openSettings", "section=$section")
        return try {
            val intent = when (section) {
                "wifi" -> Intent(Settings.ACTION_WIFI_SETTINGS)
                "bluetooth" -> Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                "location" -> Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                "sound" -> Intent(Settings.ACTION_SOUND_SETTINGS)
                "display" -> Intent(Settings.ACTION_DISPLAY_SETTINGS)
                "battery" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                "app" -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = android.net.Uri.parse("package:${context.packageName}")
                }
                "accessibility" -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                "notification" -> Intent(Settings.ACTION_SETTINGS)
                "security" -> Intent(Settings.ACTION_SECURITY_SETTINGS)
                "data" -> Intent(Settings.ACTION_DATA_ROAMING_SETTINGS)
                "data_usage" -> Intent(Settings.ACTION_DATA_USAGE_SETTINGS)
                "developer" -> Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                "datetime" -> Intent(Settings.ACTION_DATE_SETTINGS)
                "language" -> Intent(Settings.ACTION_LOCALE_SETTINGS)
                "network" -> Intent(Settings.ACTION_DATA_ROAMING_SETTINGS)
                "airplane" -> Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS)
                "dnd_access" -> Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                "apps" -> Intent(Settings.ACTION_APPLICATION_SETTINGS)
                null, "" -> Intent(Settings.ACTION_SETTINGS)
                else -> Intent(Settings.ACTION_SETTINGS)
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            CommandResult.ok("Settings khol diye: ${section ?: "main"}")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "openSettings", "Failed: ${e.message}", e)
            CommandResult.error("Settings nahi khule: ${e.message}")
        }
    }
}
