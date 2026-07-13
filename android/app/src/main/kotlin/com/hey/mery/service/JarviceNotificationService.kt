package com.hey.mery.service

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.hey.mery.util.JarviceLogger
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentLinkedQueue

class JarviceNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "JarviceNotification"
        private const val CHANNEL = "com.hey.mery/notifications"
        private var instance: JarviceNotificationService? = null
        fun isEnabled(): Boolean = instance != null
        private const val MAX_STORED = 20
    }

    private var methodChannel: MethodChannel? = null
    private val recentNotifications = ConcurrentLinkedQueue<StoredNotification>()

    data class StoredNotification(
        val packageName: String,
        val title: String,
        val text: String,
        val timestamp: Long
    )

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        JarviceLogger.i(TAG, "onListenerConnected", "Notification listener connected")
        setupChannel()
        loadActiveNotifications()
    }

    private fun setupChannel() {
        val flutterEngine = FlutterEngineCache.getInstance().get("wake_word_engine")
        if (flutterEngine != null) {
            methodChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRecentNotifications" -> {
                        result.success(getRecentNotifications())
                    }
                    "getNotificationsByApp" -> {
                        val packageName = call.argument<String>("packageName") ?: ""
                        result.success(getNotificationsByApp(packageName))
                    }
                    "dismissNotification" -> {
                        val key = call.argument<String>("key") ?: ""
                        result.success(dismissNotification(key))
                    }
                    "isEnabled" -> {
                        result.success(true)
                    }
                    "openNotification" -> {
                        val key = call.argument<String>("key") ?: ""
                        result.success(openNotification(key))
                    }
                    "dismissAppNotifications" -> {
                        val pkg = call.argument<String>("package") ?: ""
                        result.success(dismissAppNotifications(pkg))
                    }
                    else -> result.notImplemented()
                }
            }
        } else {
            JarviceLogger.w(TAG, "setupChannel", "FlutterEngine not cached yet, will retry in 2s")
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ setupChannel() }, 2000)
        }
    }

    private fun loadActiveNotifications() {
        try {
            val active = activeNotifications
            if (active != null) {
                for (sbn in active.take(MAX_STORED)) {
                    storeNotification(sbn)
                }
            }
        } catch (e: Exception) {
            JarviceLogger.e(TAG, "loadActiveNotifications", "Error: ${e.message}", e)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let {
            storeNotification(it)
            notifyFlutter("onNotificationPosted", it)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        sbn?.let {
            notifyFlutter("onNotificationRemoved", it)
        }
    }

    private fun storeNotification(sbn: StatusBarNotification) {
        if (sbn.packageName == packageName) return

        val notification = sbn.notification
        val extras = notification?.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        if (title.isNotBlank() || text.isNotBlank()) {
            recentNotifications.offer(
                StoredNotification(
                    packageName = sbn.packageName,
                    title = title,
                    text = text,
                    timestamp = sbn.postTime
                )
            )
            while (recentNotifications.size > MAX_STORED) {
                recentNotifications.poll()
            }
        }
    }

    private fun notifyFlutter(method: String, sbn: StatusBarNotification) {
        val extras = sbn.notification?.extras
        val data = mapOf(
            "packageName" to sbn.packageName,
            "title" to (extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""),
            "text" to (extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""),
            "timestamp" to sbn.postTime
        )
        try {
            methodChannel?.invokeMethod(method, data)
        } catch (e: Exception) {
            JarviceLogger.w(TAG, "notifyFlutter", "Failed: ${e.message}")
        }
    }

    private fun getRecentNotifications(): List<Map<String, String?>> {
        return recentNotifications.map { notif ->
            mapOf(
                "packageName" to notif.packageName,
                "title" to notif.title,
                "text" to notif.text,
                "timestamp" to notif.timestamp.toString()
            )
        }.toList().reversed()
    }

    private fun getNotificationsByApp(packageName: String): List<Map<String, String?>> {
        return recentNotifications
            .filter { it.packageName == packageName }
            .map { notif ->
                mapOf(
                    "packageName" to notif.packageName,
                    "title" to notif.title,
                    "text" to notif.text,
                    "timestamp" to notif.timestamp.toString()
                )
            }.reversed()
    }

    private fun dismissNotification(key: String): Boolean {
        return try {
            cancelNotification(key)
            true
        } catch (e: Exception) {
            JarviceLogger.e(TAG, "dismissNotification", "Error: ${e.message}", e)
            false
        }
    }

    private fun openNotification(key: String): Boolean {
        return try {
            val active = activeNotifications
            val sbn = active?.find { it.key == key }
            if (sbn != null) {
                val intent = sbn.notification.contentIntent
                intent?.send()
                true
            } else {
                false
            }
        } catch (e: Exception) {
            JarviceLogger.e(TAG, "openNotification", "Error: ${e.message}", e)
            false
        }
    }

    private fun dismissAppNotifications(packageName: String): Boolean {
        return try {
            val toDismiss = recentNotifications.filter { it.packageName == packageName }
            val active = activeNotifications
            for (sbn in active ?: emptyArray()) {
                if (sbn.packageName == packageName) {
                    cancelNotification(sbn.key)
                }
            }
            recentNotifications.removeAll { it.packageName == packageName }
            true
        } catch (e: Exception) {
            JarviceLogger.e(TAG, "dismissAppNotifications", "Error: ${e.message}", e)
            false
        }
    }

    override fun onListenerDisconnected() {
        JarviceLogger.i(TAG, "onListenerDisconnected", "Notification listener disconnected")
        instance = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onListenerDisconnected()
    }
}
