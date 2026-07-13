package com.hey.mery.util

import android.util.Log

object JarviceLogger {
    private const val TAG_PREFIX = "Jarvice"
    private var minLevel = Level.DEBUG

    enum class Level { DEBUG, INFO, WARN, ERROR }

    fun setMinLevel(level: Level) {
        minLevel = level
    }

    fun d(component: String, method: String, message: String) {
        if (minLevel.ordinal <= Level.DEBUG.ordinal) {
            Log.d("$TAG_PREFIX/$component", "$method: $message")
        }
    }

    fun i(component: String, method: String, message: String) {
        if (minLevel.ordinal <= Level.INFO.ordinal) {
            Log.i("$TAG_PREFIX/$component", "$method: $message")
        }
    }

    fun w(component: String, method: String, message: String) {
        if (minLevel.ordinal <= Level.WARN.ordinal) {
            Log.w("$TAG_PREFIX/$component", "$method: $message")
        }
    }

    fun e(component: String, method: String, message: String, throwable: Throwable? = null) {
        if (minLevel.ordinal <= Level.ERROR.ordinal) {
            if (throwable != null) {
                Log.e("$TAG_PREFIX/$component", "$method: $message", throwable)
            } else {
                Log.e("$TAG_PREFIX/$component", "$method: $message")
            }
        }
    }
}
