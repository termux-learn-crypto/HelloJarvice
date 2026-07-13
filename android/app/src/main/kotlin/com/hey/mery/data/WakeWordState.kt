package com.hey.mery.data

enum class WakeWordState(val value: String) {
    STOPPED("stopped"),
    STARTING("starting"),
    LISTENING("listening"),
    WAKE_WORD_DETECTED("wake_word_detected"),
    PROCESSING_COMMAND("processing_command"),
    PAUSED("paused"),
    ERROR("error");

    fun toMap(): Map<String, Any?> = mapOf("state" to value)
}
