package com.hey.mery.data

data class CommandResult(
    val success: Boolean,
    val message: String,
    val data: Map<String, Any?> = emptyMap(),
    val errorCode: String? = null,
    val requiresConfirmation: Boolean = false,
    val requiredCapability: String? = null
) {
    fun toMap(): Map<String, Any?> = buildMap {
        put("success", success)
        put("message", message)
        put("data", data)
        errorCode?.let { put("errorCode", it) }
        if (requiresConfirmation) put("requiresConfirmation", true)
        requiredCapability?.let { put("requiredCapability", it) }
    }

    companion object {
        fun ok(message: String, data: Map<String, Any?> = emptyMap()) =
            CommandResult(success = true, message = message, data = data)

        fun ok(message: String, key: String, value: Any?) =
            CommandResult(success = true, message = message, data = mapOf(key to value))

        fun ok(message: String, vararg pairs: Pair<String, Any?>) =
            CommandResult(success = true, message = message, data = mapOf(*pairs))

        fun error(message: String, code: String = "UNKNOWN_ERROR") =
            CommandResult(success = false, message = message, errorCode = code)

        fun error(message: String, code: String, data: Map<String, Any?>) =
            CommandResult(success = false, message = message, data = data, errorCode = code)

        fun needsConfirmation(message: String, pendingActionId: String) =
            CommandResult(
                success = true,
                message = message,
                requiresConfirmation = true,
                data = mapOf("pendingActionId" to pendingActionId)
            )

        fun capabilityRequired(message: String, capability: String) =
            CommandResult(
                success = false,
                message = message,
                requiredCapability = capability,
                errorCode = "CAPABILITY_REQUIRED"
            )
    }
}
