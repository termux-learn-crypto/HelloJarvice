package com.hey.mery.controller

import android.provider.AlarmClock
import android.content.Context
import android.content.Intent
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class AlarmController(private val context: Context) {

    companion object {
        private const val COMPONENT = "AlarmController"
    }

    fun setAlarm(hour: Int, minute: Int, label: String = "Jarvice Alarm"): CommandResult {
        JarviceLogger.i(COMPONENT, "setAlarm", "hour=$hour, minute=$minute, label=$label")
        val clampedHour = hour.coerceIn(0, 23)
        val clampedMinute = minute.coerceIn(0, 59)

        return try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, clampedHour)
                putExtra(AlarmClock.EXTRA_MINUTES, clampedMinute)
                putExtra(AlarmClock.EXTRA_MESSAGE, label)
                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            val timeStr = String.format("%02d:%02d", clampedHour, clampedMinute)
            CommandResult.ok("Alarm set kar diya $timeStr pe")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "setAlarm", "Error: ${e.message}", e)
            CommandResult.error("Alarm set nahi ho paya", "ALARM_FAILED")
        }
    }

    fun setTimer(minutes: Int, label: String = "Jarvice Timer"): CommandResult {
        JarviceLogger.i(COMPONENT, "setTimer", "minutes=$minutes")
        if (minutes <= 0 || minutes > 1440) {
            return CommandResult.error("Timer 1 minute se 24 ghante tak ho sakta hai", "TIMER_INVALID_DURATION")
        }

        return try {
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, minutes * 60)
                putExtra(AlarmClock.EXTRA_MESSAGE, label)
                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            val hrs = minutes / 60
            val mins = minutes % 60
            val durationStr = if (hrs > 0) "${hrs} ghante ${mins} minute" else "${mins} minute"
            CommandResult.ok("Timer set kar diya $durationStr ke liye")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "setTimer", "Error: ${e.message}", e)
            CommandResult.error("Timer set nahi ho paya", "TIMER_FAILED")
        }
    }

    fun showAlarms(): CommandResult {
        return try {
            val intent = Intent(AlarmClock.ACTION_SHOW_ALARMS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Alarms dikha raha hoon")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "showAlarms", "Error: ${e.message}", e)
            CommandResult.error("Alarms nahi dikh paye", "SHOW_ALARMS_FAILED")
        }
    }

    fun parseTimeFromText(text: String): Pair<Int, Int>? {
        val hourPatterns = listOf(
            Regex("(\\d{1,2})\\s*(?:baje|o.?clock)", RegexOption.IGNORE_CASE),
            Regex("(\\d{1,2})\\s*:\\s*(\\d{2})", RegexOption.IGNORE_CASE),
            Regex("(\\d{1,2})\\s*(am|pm)", RegexOption.IGNORE_CASE),
            Regex("(\\d{1,2})\\s*(?:baje|o.?clock)\\s*(am|pm)", RegexOption.IGNORE_CASE),
            Regex("(\\d{1,2})", RegexOption.IGNORE_CASE)
        )

        var hour = -1
        var minute = 0
        var isPm = false

        for (pattern in hourPatterns) {
            val match = pattern.find(text)
            if (match != null) {
                hour = match.groupValues[1].toIntOrNull() ?: continue
                if (match.groupValues.size > 2 && match.groupValues[2].isNotEmpty()) {
                    val secondGroup = match.groupValues[2]
                    if (secondGroup.matches(Regex("\\d{2}"))) {
                        minute = secondGroup.toIntOrNull() ?: 0
                    } else if (secondGroup.lowercase() == "pm") {
                        isPm = true
                    } else if (secondGroup.lowercase() == "am") {
                        isPm = false
                    }
                }
                if (match.groupValues.size > 3 && match.groupValues[3].lowercase() == "pm") {
                    isPm = true
                }
                break
            }
        }

        if (hour < 0) return null

        if (isPm && hour < 12) hour += 12
        else if (!isPm && hour == 12) hour = 0

        hour = hour.coerceIn(0, 23)
        minute = minute.coerceIn(0, 59)

        return Pair(hour, minute)
    }

    fun parseTimerMinutes(text: String): Int? {
        val patterns = listOf(
            Regex("(\\d+)\\s*(?:ghante|hours?|hrs?)", RegexOption.IGNORE_CASE),
            Regex("(\\d+)\\s*(?:minutes?|mins?|minute)", RegexOption.IGNORE_CASE),
            Regex("(\\d+)\\s*(?:sec|seconds?)", RegexOption.IGNORE_CASE)
        )

        var totalMinutes = 0

        for (pattern in patterns) {
            val match = pattern.find(text)
            if (match != null) {
                val value = match.groupValues[1].toIntOrNull() ?: continue
                val fullMatch = match.value.lowercase()
                when {
                    fullMatch.contains("ghant") || fullMatch.contains("hour") || fullMatch.contains("hr") ->
                        totalMinutes += value * 60
                    fullMatch.contains("sec") ->
                        totalMinutes += (value / 60).coerceAtLeast(1)
                    else ->
                        totalMinutes += value
                }
            }
        }

        return if (totalMinutes > 0) totalMinutes else null
    }

    fun dismissAlarm(): CommandResult {
        return try {
            val intent = Intent(AlarmClock.ACTION_DISMISS_ALARM).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Alarm dismiss kar diya")
        } catch (e: Exception) {
            CommandResult.error("Alarm dismiss nahi ho paya: ${e.message}")
        }
    }

    fun snoozeAlarm(): CommandResult {
        return try {
            val intent = Intent(AlarmClock.ACTION_SNOOZE_ALARM).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Alarm snooze kar diya")
        } catch (e: Exception) {
            CommandResult.error("Alarm snooze nahi ho paya: ${e.message}")
        }
    }

    fun openTimer(): CommandResult {
        return showAlarms()
    }

    fun dismissTimer(): CommandResult {
        return try {
            val intent = Intent(AlarmClock.ACTION_DISMISS_TIMER).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Timer dismiss kar diya")
        } catch (e: Exception) {
            CommandResult.error("Timer dismiss nahi ho paya: ${e.message}")
        }
    }
}
