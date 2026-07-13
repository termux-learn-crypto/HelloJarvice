package com.hey.mery.controller

import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telephony.PhoneNumberUtils
import com.hey.mery.data.CommandResult
import com.hey.mery.util.JarviceLogger

class CallController(private val context: Context) {

    companion object {
        private const val COMPONENT = "CallController"
    }

    data class ContactMatch(
        val name: String,
        val phoneNumber: String,
        val contactId: Long
    )

    fun lookupContact(query: String): CommandResult {
        JarviceLogger.i(COMPONENT, "lookupContact", "query=$query")
        if (query.isBlank()) {
            return CommandResult.error("Naam ya number nahi diya", "CONTACT_QUERY_MISSING")
        }

        if (isPhoneNumber(query)) {
            return CommandResult.ok("Number mila", "number" to query, "name" to query)
        }

        val matches = findContacts(query)
        return when {
            matches.isEmpty() -> {
                CommandResult.error("$query se koi contact nahi mila", "CONTACT_NOT_FOUND")
            }
            matches.size == 1 -> {
                val contact = matches.first()
                CommandResult.ok(
                    "${contact.name} mila",
                    "name" to contact.name,
                    "number" to contact.phoneNumber,
                    "contactId" to contact.contactId
                )
            }
            else -> {
                val names = matches.take(5).joinToString(", ") { it.name }
                CommandResult(
                    success = false,
                    message = "$query ke kitne contacts mile: $names. Kaunsa chahiye?",
                    data = mapOf(
                        "matches" to matches.take(5).map {
                            mapOf("name" to it.name, "number" to it.phoneNumber, "contactId" to it.contactId)
                        }
                    ),
                    errorCode = "MULTIPLE_CONTACTS_FOUND"
                )
            }
        }
    }

    fun makeCall(contactNameOrNumber: String): CommandResult {
        JarviceLogger.i(COMPONENT, "makeCall", "target=$contactNameOrNumber")

        if (isPhoneNumber(contactNameOrNumber)) {
            return dialNumber(contactNameOrNumber)
        }

        val matches = findContacts(contactNameOrNumber)
        return when {
            matches.isEmpty() -> {
                CommandResult.error("$contactNameOrNumber nahi mila", "CONTACT_NOT_FOUND")
            }
            matches.size == 1 -> {
                dialNumber(matches.first().phoneNumber, matches.first().name)
            }
            else -> {
                val names = matches.take(3).joinToString(", ") { it.name }
                CommandResult(
                    success = false,
                    message = "Kitne contacts mile: $names. Kaunsa call karna hai?",
                    data = mapOf(
                        "matches" to matches.take(5).map {
                            mapOf("name" to it.name, "number" to it.phoneNumber)
                        }
                    ),
                    errorCode = "MULTIPLE_CONTACTS_FOUND"
                )
            }
        }
    }

    fun dialNumber(number: String, displayName: String? = null): CommandResult {
        return try {
            val cleanNumber = number.replaceAll("[^\\d+]", "")
            val uri = Uri.parse("tel:$cleanNumber")
            val intent = Intent(Intent.ACTION_DIAL, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            val name = displayName ?: number
            CommandResult.ok("$name ko call kar raha hoon")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "dialNumber", "Error: ${e.message}", e)
            CommandResult.error("Call nahi ho paya: ${e.message}", "CALL_FAILED")
        }
    }

    private fun findContacts(query: String): List<ContactMatch> {
        val matches = mutableListOf<ContactMatch>()
        val normalizedQuery = query.lowercase().trim()

        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )

        val selection = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?"
        val selectionArgs = arrayOf("%$normalizedQuery%")

        var cursor: Cursor? = null
        try {
            cursor = context.contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )

            cursor?.let {
                val idIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
                val nameIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val numberIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

                while (it.moveToNext()) {
                    val id = it.getLong(idIndex)
                    val name = it.getString(nameIndex) ?: "Unknown"
                    val number = it.getString(numberIndex) ?: ""

                    if (number.isNotBlank()) {
                        matches.add(ContactMatch(name, number, id))
                    }
                }
            }
        } catch (e: SecurityException) {
            JarviceLogger.e(COMPONENT, "findContacts", "READ_CONTACTS permission denied", e)
            return emptyList()
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "findContacts", "Error: ${e.message}", e)
        } finally {
            cursor?.close()
        }

        return matches.sortedByDescending {
            val nameScore = when {
                it.name.lowercase() == normalizedQuery -> 100
                it.name.lowercase().startsWith(normalizedQuery) -> 80
                it.name.lowercase().contains(normalizedQuery) -> 60
                else -> 0
            }
            nameScore
        }
    }

    private fun isPhoneNumber(input: String): Boolean {
        val cleaned = input.replaceAll("[\\s\\-\\(\\)]", "")
        return cleaned.matches(Regex("^\\+?\\d{7,15}$"))
    }

    fun redialLast(): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_DIAL).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Dialer khol diya, last call redial karo")
        } catch (e: Exception) {
            CommandResult.error("Redial nahi ho paya: ${e.message}")
        }
    }
}
