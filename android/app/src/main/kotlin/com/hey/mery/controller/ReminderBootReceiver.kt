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
                JarviceLogger.i(TAG, "rescheduleReminders", "Re-scheduling: $key")
            }
        }
    }
}
