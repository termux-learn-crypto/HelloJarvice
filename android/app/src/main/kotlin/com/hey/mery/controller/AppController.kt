package com.hey.mery.controller

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Build
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class AppController(private val context: Context) {

    companion object {
        private const val COMPONENT = "AppController"
    }

    private data class AppInfo(
        val name: String,
        val packageName: String
    )

    fun launchApp(appName: String): CommandResult {
        JarviceLogger.i(COMPONENT, "launchApp", "appName=$appName")
        if (appName.isBlank()) {
            return CommandResult.error("App ka naam nahi diya", "APP_NAME_MISSING")
        }

        val resolved = resolveApp(appName)
        return when {
            resolved.isEmpty() -> {
                CommandResult.error("$appName nahi mila phone mein", "APP_NOT_FOUND")
            }
            resolved.size == 1 -> {
                launchPackage(resolved.first().packageName, resolved.first().name)
            }
            else -> {
                val topThree = resolved.take(3).joinToString(", ") { it.name }
                CommandResult(
                    success = false,
                    message = "$appName ke kitne mila: $topThree. Kaunsa kholna hai?",
                    data = mapOf(
                        "matches" to resolved.map { mapOf("name" to it.name, "package" to it.packageName) }
                    ),
                    errorCode = "MULTIPLE_APPS_FOUND"
                )
            }
        }
    }

    private fun resolveApp(query: String): List<AppInfo> {
        val pm = context.packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolveInfos: List<ResolveInfo> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlagsOf(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(mainIntent, 0)
        }

        val normalizedQuery = query.lowercase().trim()
        val matches = mutableListOf<AppInfo>()

        for (info in resolveInfos) {
            val label = info.loadLabel(pm).toString()
            val pkg = info.activityInfo.packageName
            val normalizedName = label.lowercase()

            if (normalizedName.contains(normalizedQuery) ||
                pkg.lowercase().contains(normalizedQuery) ||
                normalizedName.split(" ").any { it == normalizedQuery }
            ) {
                matches.add(AppInfo(label, pkg))
            }
        }

        return matches.sortedByDescending {
            when {
                it.name.lowercase() == normalizedQuery -> 100
                it.name.lowercase().startsWith(normalizedQuery) -> 80
                it.name.lowercase().contains(normalizedQuery) -> 60
                it.packageName.lowercase().contains(normalizedQuery) -> 40
                else -> 0
            }
        }
    }

    private fun launchPackage(packageName: String, displayName: String): CommandResult {
        return try {
            val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                CommandResult.ok("$displayName khol diya")
            } else {
                CommandResult.error("$displayName nahi khula", "APP_NOT_LAUNCHABLE")
            }
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "launchPackage", "Error: ${e.message}", e)
            CommandResult.error("$displayName nahi khula: ${e.message}", "APP_LAUNCH_ERROR")
        }
    }

    fun searchApps(query: String): CommandResult {
        val matches = resolveApp(query)
        if (matches.isEmpty()) {
            return CommandResult.error("$query se koi app nahi mila", "APP_NOT_FOUND")
        }
        return CommandResult.ok(
            "${matches.size} apps mile",
            "apps" to matches.take(5).map { mapOf("name" to it.name, "package" to it.packageName) }
        )
    }

    fun closeApp(packageName: String): CommandResult {
        return try {
            val resolved = if (packageName.contains(".")) {
                listOf(AppInfo(packageName, packageName))
            } else {
                resolveApp(packageName)
            }
            if (resolved.isEmpty()) {
                return CommandResult.error("App nahi mili: $packageName", "APP_NOT_FOUND")
            }
            val pkg = resolved.first().packageName
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            am.killBackgroundProcesses(pkg)
            CommandResult.ok("App band kar di: $packageName")
        } catch (e: Exception) {
            CommandResult.error("App band nahi hui: ${e.message}")
        }
    }

    fun getForegroundApp(): CommandResult {
        return try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val taskInfo = am.runningAppProcesses?.firstOrNull { it.importance == android.app.RunningAppProcessInfo.IMPORTANCE_FOREGROUND }
            val pkg = taskInfo?.processName?.split(":")?.firstOrNull() ?: "unknown"
            val pm = context.packageManager
            val label = try {
                val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getApplicationInfo(pkg, PackageManager.ApplicationInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getApplicationInfo(pkg, 0)
                }
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) { pkg }
            CommandResult.ok("Foreground app: $label", "package" to pkg, "name" to label)
        } catch (e: Exception) {
            CommandResult.error("Foreground app pata nahi chala: ${e.message}")
        }
    }
}
