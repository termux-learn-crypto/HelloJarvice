package com.hey.mery.service

import android.service.voice.VoiceInteractionSession
import android.service.voice.VoiceInteractionSessionService
import com.hey.mery.util.JarviceLogger

class JarviceSessionService : VoiceInteractionSessionService() {

    companion object {
        private const val TAG = "JarviceSessionService"
    }

    override fun onCreateSession(sessionId: Int): VoiceInteractionSession {
        JarviceLogger.i(TAG, "onCreateSession", "Creating session id=$sessionId")
        return JarviceSession(this, sessionId)
    }

    override fun onDestroy() {
        JarviceLogger.i(TAG, "onDestroy", "SessionService destroyed")
        super.onDestroy()
    }
}
