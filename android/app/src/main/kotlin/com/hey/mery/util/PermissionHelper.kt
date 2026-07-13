package com.hey.mery.util

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object PermissionHelper {

    fun hasPermission(context: Context, permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }

    fun hasAnyPermission(context: Context, vararg permissions: String): Boolean {
        return permissions.any { hasPermission(context, it) }
    }

    fun hasAllPermissions(context: Context, vararg permissions: String): Boolean {
        return permissions.all { hasPermission(context, it) }
    }

    fun shouldShowRationale(context: Context, permission: String): Boolean {
        if (context is android.app.Activity) {
            return ActivityCompat.shouldShowRequestPermissionRationale(context, permission)
        }
        return false
    }

    fun isPermanentlyDenied(context: Context, permission: String): Boolean {
        if (context is android.app.Activity) {
            return !hasPermission(context, permission) &&
                !ActivityCompat.shouldShowRequestPermissionRationale(context, permission)
        }
        return false
    }

    fun getMissingPermissions(context: Context, vararg permissions: String): List<String> {
        return permissions.filter { !hasPermission(context, it) }
    }

    fun getPermissionStatus(context: Context, permission: String): String {
        return when {
            hasPermission(context, permission) -> "granted"
            isPermanentlyDenied(context, permission) -> "permanently_denied"
            else -> "denied"
        }
    }

    fun getAudioRecordPermission(): String = android.Manifest.permission.RECORD_AUDIO
    fun getReadContactsPermission(): String = android.Manifest.permission.READ_CONTACTS
    fun getCallPhonePermission(): String = android.Manifest.permission.CALL_PHONE
    fun getSmsPermission(): String = android.Manifest.permission.SEND_SMS
    fun getCameraPermission(): String = android.Manifest.permission.CAMERA
    fun getLocationPermission(): String = android.Manifest.permission.ACCESS_COARSE_LOCATION
    fun getBluetoothPermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            android.Manifest.permission.BLUETOOTH_CONNECT
        } else {
            android.Manifest.permission.BLUETOOTH
        }
    }
}
