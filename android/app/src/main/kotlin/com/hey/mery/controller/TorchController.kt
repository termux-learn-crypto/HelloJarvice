package com.hey.mery.controller

import android.content.Context
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraManager
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class TorchController(context: Context) {

    companion object {
        private const val COMPONENT = "TorchController"
    }

    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private var torchCallbackRegistered = false
    private var currentTorchState = false

    fun turnOn(): CommandResult {
        return try {
            val cameraId = getFlashCameraId()
            if (cameraId == null) {
                return CommandResult.error("Is phone mein flashlight nahi hai", "NO_FLASH")
            }
            cameraManager.setTorchMode(cameraId, true)
            currentTorchState = true
            JarviceLogger.i(COMPONENT, "turnOn", "Torch ON, cameraId=$cameraId")
            CommandResult.ok("Flashlight on kar diya")
        } catch (e: CameraAccessException) {
            JarviceLogger.e(COMPONENT, "turnOn", "Camera access error: ${e.message}", e)
            CommandResult.error("Flashlight on nahi ho paya", "FLASHLIGHT_ACCESS_ERROR")
        } catch (e: SecurityException) {
            JarviceLogger.e(COMPONENT, "turnOn", "Camera permission denied: ${e.message}", e)
            CommandResult.error("Camera permission chahiye flashlight ke liye", "CAMERA_PERMISSION_DENIED", "CAMERA_PERMISSION_DENIED")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "turnOn", "Error: ${e.message}", e)
            CommandResult.error("Flashlight on nahi ho paya", "FLASHLIGHT_ERROR")
        }
    }

    fun turnOff(): CommandResult {
        return try {
            val cameraId = getFlashCameraId()
            if (cameraId == null) {
                return CommandResult.error("Is phone mein flashlight nahi hai", "NO_FLASH")
            }
            cameraManager.setTorchMode(cameraId, false)
            currentTorchState = false
            JarviceLogger.i(COMPONENT, "turnOff", "Torch OFF")
            CommandResult.ok("Flashlight band kar diya")
        } catch (e: CameraAccessException) {
            JarviceLogger.e(COMPONENT, "turnOff", "Camera access error: ${e.message}", e)
            CommandResult.error("Flashlight band nahi ho paya", "FLASHLIGHT_ACCESS_ERROR")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "turnOff", "Error: ${e.message}", e)
            CommandResult.error("Flashlight band nahi ho paya", "FLASHLIGHT_ERROR")
        }
    }

    fun toggle(): CommandResult {
        return if (currentTorchState) turnOff() else turnOn()
    }

    fun isOn(): Boolean = currentTorchState

    private fun getFlashCameraId(): String? {
        return try {
            for (id in cameraManager.cameraIdList) {
                val chars = cameraManager.getCameraCharacteristics(id)
                val hasFlash = chars.get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE)
                if (hasFlash == true) return id
            }
            null
        } catch (e: CameraAccessException) {
            JarviceLogger.e(COMPONENT, "getFlashCameraId", "Error: ${e.message}", e)
            null
        }
    }

    fun getState(): CommandResult {
        val on = isOn()
        return CommandResult.ok(
            if (on) "Torch on hai" else "Torch band hai",
            "enabled" to on
        )
    }
}
