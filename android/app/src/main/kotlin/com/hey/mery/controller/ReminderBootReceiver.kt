package com.hey.mery.controller

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.hey.mery.util.JarviceLogger

class ReminderBootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "ReminderBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            JarviceLogger.i(TAG, "onReceive", "Boot completed, re-scheduling reminders")
            rescheduleReminders(context)
        }
    }

    private fun rescheduleReminders(context: Context) {
        val prefs = context.getSharedPreferences("jarvice_reminders", Context.MODE_PRIVATE)
        val controller = ReminderController(context)

        for ((key, value) in prefs.all) {
            val data = value.toString()
            if (data.contains("active=true")) {
                try {
                    val hour = Regex("hour=(\\d+)").find(data)?.groupValues?.get(1)?.toIntOrNull()
                    val minute = Regex("minute=(\\d+)").find(data)?.groupValues?.get(1)?.toIntOrNull()
                    val title = Regex("title=([^,}]+)").find(data)?.groupValues?.get(1)?.trim() ?: key
                    if (hour != null && minute != null) {
                        controller.createReminder(title, hour, minute, null, null)
                        JarviceLogger.i(TAG, "rescheduleReminders", "Re-scheduled: $key at $hour:$minute")
                    }
                } catch (e: Exception) {
                    JarviceLogger.e(TAG, "rescheduleReminders", "Failed to reschedule $key: ${e.message}", e)
                }
            }
        }
    }
}
