package com.hey.mery.service

import android.content.Intent
import android.os.IBinder
import android.service.voice.VoiceInteractionService
import android.service.voice.VoiceInteractionSession
import android.util.Log
import com.hey.mery.util.JarviceLogger

class JarviceInteractionService : VoiceInteractionService() {

    companion object {
        private const val TAG = "JarviceInteractionService"
    }

    override fun onCreate() {
        super.onCreate()
        JarviceLogger.i(TAG, "onCreate", "VoiceInteractionService created")
    }

    override fun onAssist(data: AssistData) {
        super.onAssist(data)
        JarviceLogger.i(TAG, "onAssist", "text=${data.structuredData?.text}")
    }

    override fun onAssist(data: AssistStructure, dataBundle: android.os.Bundle?) {
        super.onAssist(data, dataBundle)
        JarviceLogger.i(TAG, "onAssist", "AssistStructure received")
    }

    override fun onHandleAssist(data: AssistData?, structure: AssistStructure?, bundle: Bundle?) {
        JarviceLogger.i(TAG, "onHandleAssist", "handling assist")
        super.onHandleAssist(data, structure, bundle)
    }

    override fun onCreateSession(sessionId: Int, taskStackBuilder: android.app.TaskStackBuilder): VoiceInteractionSession {
        JarviceLogger.i(TAG, "onCreateSession", "Creating session id=$sessionId")
        return JarviceSession(this, sessionId)
    }

    override fun onDestroy() {
        JarviceLogger.i(TAG, "onDestroy", "VoiceInteractionService destroyed")
        super.onDestroy()
    }
}
