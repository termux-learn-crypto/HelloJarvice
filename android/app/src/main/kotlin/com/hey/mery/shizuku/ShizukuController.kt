package com.hey.mery.shizuku

import android.content.Context
import android.content.pm.PackageManager
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class ShizukuController(private val context: Context) {

    companion object {
        private const val TAG = "ShizukuController"
        private const val SHIZUKU_PACKAGE = "moe.shizuku.privileged.api"
    }

    enum class ShizukuStatus {
        NOT_INSTALLED,
        NOT_RUNNING,
        PERMISSION_REQUIRED,
        CONNECTED
    }

    fun getStatus(): ShizukuStatus {
        return try {
            val pm = context.packageManager
            try {
                pm.getPackageInfo(SHIZUKU_PACKAGE, 0)
            } catch (_: PackageManager.NameNotFoundException) {
                return ShizukuStatus.NOT_INSTALLED
            }

            try {
                val binder = getShizukuBinder()
                if (binder != null) {
                    ShizukuStatus.CONNECTED
                } else {
                    ShizukuStatus.NOT_RUNNING
                }
            } catch (e: Exception) {
                ShizukuStatus.PERMISSION_REQUIRED
            }
        } catch (e: Exception) {
            JarviceLogger.e(TAG, "getStatus", "Error: ${e.message}", e)
            ShizukuStatus.NOT_INSTALLED
        }
    }

    private fun getShizukuBinder(): android.os.IBinder? {
        return try {
            val serviceManager = Class.forName("android.os.ServiceManager")
            val getService = serviceManager.getMethod("getService", String::class.java)
            getService.invoke(null, "moe.shizuku.server") as? android.os.IBinder
        } catch (e: Exception) {
            null
        }
    }

    fun isAvailable(): Boolean {
        return getStatus() == ShizukuStatus.CONNECTED
    }

    fun getResult(): CommandResult {
        val status = getStatus()
        return when (status) {
            ShizukuStatus.CONNECTED -> CommandResult.ok("Shizuku connected hai")
            ShizukuStatus.NOT_INSTALLED -> CommandResult(
                success = false,
                message = "Shizuku install nahi hai. Play Store se install karein.",
                errorCode = "SHIZUKU_NOT_INSTALLED",
                requiredCapability = "shizuku"
            )
            ShizukuStatus.NOT_RUNNING -> CommandResult(
                success = false,
                message = "Shizuku running nahi hai. Pehle Shizuku start karein.",
                errorCode = "SHIZUKU_NOT_RUNNING",
                requiredCapability = "shizuku"
            )
            ShizukuStatus.PERMISSION_REQUIRED -> CommandResult(
                success = false,
                message = "Shizuku permission chahiye. App ko permission dein.",
                errorCode = "SHIZUKU_PERMISSION_DENIED",
                requiredCapability = "shizuku"
            )
        }
    }
}
