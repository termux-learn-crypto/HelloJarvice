package com.hey.mery.controller

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class SmsController(private val context: Context) {

    companion object {
        private const val COMPONENT = "SmsController"
    }

    fun composeSms(recipient: String, message: String): CommandResult {
        JarviceLogger.i(COMPONENT, "composeSms", "recipient=$recipient, msgLen=${message.length}")

        if (recipient.isBlank()) {
            return CommandResult.error("Kisko bhejna hai? Naam ya number batao", "SMS_RECIPIENT_MISSING")
        }
        if (message.isBlank()) {
            return CommandResult.error("Kya likhna hai message mein?", "SMS_MESSAGE_MISSING")
        }

        return try {
            val cleanNumber = if (isPhoneNumber(recipient)) {
                recipient.replaceAll("[^\\d+]", "")
            } else {
                recipient
            }

            val uri = if (isPhoneNumber(cleanNumber)) {
                Uri.parse("smsto:$cleanNumber")
            } else {
                Uri.parse("smsto:")
            }

            val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
                putExtra("sms_body", message)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)

            CommandResult.ok("'$message' bhej raha hoon $recipient ko")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "composeSms", "Error: ${e.message}", e)
            CommandResult.error("SMS nahi bhej paya: ${e.message}", "SMS_FAILED")
        }
    }

    private fun isPhoneNumber(input: String): Boolean {
        val cleaned = input.replaceAll("[\\s\\-\\(\\)]", "")
        return cleaned.matches(Regex("^\\+?\\d{7,15}$"))
    }
}
