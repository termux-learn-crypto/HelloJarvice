package com.hey.mery.controller

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger
import java.util.Calendar

class ReminderController(private val context: Context) {

    companion object {
        private const val COMPONENT = "ReminderController"
        private const val PREFS_NAME = "jarvice_reminders"
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun createReminder(
        title: String,
        hour: Int?,
        minute: Int?,
        duration: Int?,
        relativeTime: String?
    ): CommandResult {
        if (title.isBlank()) {
            return CommandResult.error("Reminder ka title do", "TITLE_MISSING")
        }

        val id = System.currentTimeMillis().toString()
        var targetHour = hour
        var targetMinute = minute

        if (duration != null) {
            val cal = Calendar.getInstance().apply { add(Calendar.SECOND, duration) }
            targetHour = cal.get(Calendar.HOUR_OF_DAY)
            targetMinute = cal.get(Calendar.MINUTE)
        }

        if (relativeTime != null && targetHour == null) {
            val cal = Calendar.getInstance()
            when (relativeTime) {
                "subah" -> { cal.add(Calendar.DAY_OF_YEAR, 1); cal.set(Calendar.HOUR_OF_DAY, 8); cal.set(Calendar.MINUTE, 0) }
                "dopahar" -> { cal.add(Calendar.DAY_OF_YEAR, 1); cal.set(Calendar.HOUR_OF_DAY, 12); cal.set(Calendar.MINUTE, 0) }
                "shaam" -> { cal.set(Calendar.HOUR_OF_DAY, 18); cal.set(Calendar.MINUTE, 0) }
                "raat" -> { cal.set(Calendar.HOUR_OF_DAY, 21); cal.set(Calendar.MINUTE, 0) }
                "kal" -> { cal.add(Calendar.DAY_OF_YEAR, 1); cal.set(Calendar.HOUR_OF_DAY, 9); cal.set(Calendar.MINUTE, 0) }
                "thodi der baad" -> { cal.add(Calendar.MINUTE, 15) }
                else -> { cal.add(Calendar.MINUTE, 30) }
            }
            targetHour = cal.get(Calendar.HOUR_OF_DAY)
            targetMinute = cal.get(Calendar.MINUTE)
        }

        if (targetHour == null) targetHour = 9
        if (targetMinute == null) targetMinute = 0

        val reminderData = mapOf(
            "id" to id,
            "title" to title,
            "hour" to targetHour,
            "minute" to targetMinute,
            "active" to true
        )

        prefs.edit().putString(id, reminderData.toString()).apply()

        scheduleAlarm(id, title, targetHour, targetMinute)

        val timeStr = String.format("%02d:%02d", targetHour, targetMinute)
        JarviceLogger.i(COMPONENT, "createReminder", "Created: $title at $timeStr")
        return CommandResult.ok("Reminder set: $title at $timeStr", "id" to id)
    }

    fun listReminders(): CommandResult {
        val all = prefs.all.filter { it.value.toString().contains("active=true") }
        if (all.isEmpty()) {
            return CommandResult.ok("Koi active reminder nahi hai")
        }
        val summaries = all.map { (key, value) ->
            mapOf("id" to key, "summary" to value.toString())
        }
        return CommandResult.ok("${all.size} active reminders", "reminders" to summaries)
    }

    fun updateReminder(id: String, title: String?, hour: Int?, minute: Int?): CommandResult {
        val existing = prefs.getString(id, null) ?: return CommandResult.error("Reminder nahi mila")
        JarviceLogger.i(COMPONENT, "updateReminder", "id=$id")
        prefs.edit().putString(id, "updated=true,$existing").apply()
        return CommandResult.ok("Reminder update ho gaya")
    }

    fun deleteReminder(id: String): CommandResult {
        prefs.edit().remove(id).apply()
        cancelAlarm(id)
        JarviceLogger.i(COMPONENT, "deleteReminder", "id=$id")
        return CommandResult.ok("Reminder delete ho gaya")
    }

    fun getReminder(id: String): CommandResult {
        val data = prefs.getString(id, null) ?: return CommandResult.error("Reminder nahi mila")
        return CommandResult.ok("Reminder mila", "data" to data)
    }

    fun completeReminder(id: String): CommandResult {
        val existing = prefs.getString(id, null) ?: return CommandResult.error("Reminder nahi mila")
        val updated = existing.replace("active=true", "active=false")
        prefs.edit().putString(id, updated).apply()
        cancelAlarm(id)
        return CommandResult.ok("Reminder complete ho gaya")
    }

    fun snoozeReminder(id: String): CommandResult {
        val cal = Calendar.getInstance().apply { add(Calendar.MINUTE, 10) }
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        scheduleAlarm(id, "Snoozed reminder", hour, minute)
        return CommandResult.ok("10 minute baad reminder aayega")
    }

    private fun scheduleAlarm(id: String, title: String, hour: Int, minute: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra("reminder_id", id)
            putExtra("reminder_title", title)
        }
        val requestCode = id.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pendingIntent)
            }
        } catch (e: SecurityException) {
            JarviceLogger.e(COMPONENT, "scheduleAlarm", "Alarm permission denied: ${e.message}", e)
        }
    }

    private fun cancelAlarm(id: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, id.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
