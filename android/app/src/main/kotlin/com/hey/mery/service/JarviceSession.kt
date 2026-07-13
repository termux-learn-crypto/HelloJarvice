package com.hey.mery.service

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.voice.VoiceInteractionSession
import android.view.View
import com.hey.mery.util.JarviceLogger

class JarviceSession(context: Context, sessionId: Int) : VoiceInteractionSession(context) {

    companion object {
        private const val TAG = "JarviceSession"
    }

    private var sessionId: Int = sessionId

    init {
        this.sessionId = sessionId
    }

    override fun onReady() {
        super.onReady()
        JarviceLogger.i(TAG, "onReady", "Session ready id=$sessionId")
    }

    override fun handleAssist(data: AssistData) {
        super.handleAssist(data)
        JarviceLogger.i(TAG, "handleAssist", "text=${data.structuredData?.text}")
    }

    override fun handleAssist(data: AssistData, structure: AssistStructure?, bundle: Bundle?) {
        JarviceLogger.i(TAG, "handleAssist", "Full assist received")
        super.handleAssist(data, structure, bundle)
    }

    override fun onBackInvoked() {
        JarviceLogger.i(TAG, "onBackInvoked", "Back pressed during session")
        finish()
    }

    override fun onCloseSystemDialogs() {
        JarviceLogger.i(TAG, "onCloseSystemDialogs", "Closing")
        finish()
    }

    override fun onFinish() {
        JarviceLogger.i(TAG, "onFinish", "Session finishing")
        super.onFinish()
    }

    override fun onViewDestroyed() {
        JarviceLogger.i(TAG, "onViewDestroyed", "View destroyed")
        super.onViewDestroyed()
    }
}
