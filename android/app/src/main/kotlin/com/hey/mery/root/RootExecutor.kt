package com.hey.mery.root

import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger
import java.io.BufferedReader
import java.io.InputStreamReader

class RootController {

    companion object {
        private const val TAG = "RootController"
        private var rootAvailable: Boolean? = null
    }

    fun isAvailable(): Boolean {
        if (rootAvailable != null) return rootAvailable ?: false

        rootAvailable = try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = reader.readLine() ?: ""
            reader.close()
            process.waitFor()
            output.contains("uid=0")
        } catch (e: Exception) {
            JarviceLogger.i(TAG, "isAvailable", "Root not available: ${e.message}")
            false
        }

        return rootAvailable ?: false
    }

    fun execute(command: String): CommandResult {
        if (!isAvailable()) {
            return CommandResult(
                success = false,
                message = "Root available nahi hai",
                errorCode = "ROOT_UNAVAILABLE",
                requiredCapability = "root"
            )
        }

        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val errorReader = BufferedReader(InputStreamReader(process.errorStream))

            val output = reader.readText()
            val error = errorReader.readText()
            val exitCode = process.waitFor()

            reader.close()
            errorReader.close()

            if (exitCode == 0) {
                CommandResult.ok(output.ifBlank { "Command execute ho gaya" })
            } else {
                CommandResult.error(
                    "Root command fail: $error",
                    "ROOT_COMMAND_FAILED"
                )
            }
        } catch (e: Exception) {
            JarviceLogger.e(TAG, "execute", "Error: ${e.message}", e)
            CommandResult.error("Root command error: ${e.message}", "ROOT_ERROR")
        }
    }

    fun getResult(): CommandResult {
        return if (isAvailable()) {
            CommandResult.ok("Root available hai")
        } else {
            CommandResult(
                success = false,
                message = "Root available nahi hai. Magisk ya similar root solution chahiye.",
                errorCode = "ROOT_UNAVAILABLE",
                requiredCapability = "root"
            )
        }
    }
}
