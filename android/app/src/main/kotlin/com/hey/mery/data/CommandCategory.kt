package com.hey.mery.data

enum class CommandCategory(val value: String) {
    APP("APP"),
    AUDIO("AUDIO"),
    MEDIA("MEDIA"),
    DEVICE("DEVICE"),
    CALL("CALL"),
    MESSAGE("MESSAGE"),
    ALARM("ALARM"),
    SYSTEM("SYSTEM"),
    WEB("WEB"),
    UTILITY("UTILITY"),
    ACCESSIBILITY("ACCESSIBILITY"),
    NOTIFICATION("NOTIFICATION"),
    SHIZUKU("SHIZUKU"),
    ROOT("ROOT"),
    UNKNOWN("UNKNOWN");

    fun toMap(): Map<String, String> = mapOf("category" to value)
}
