package com.hey.mery.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.os.Build
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.hey.mery.util.JarviceLogger
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class JarviceAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "JarviceAccessibility"
        private const val CHANNEL = "com.hey.mery/accessibility"
        private var instance: JarviceAccessibilityService? = null
        fun getInstance(): JarviceAccessibilityService? = instance
        fun isEnabled(): Boolean = instance != null
    }

    private var methodChannel: MethodChannel? = null
    private val executor = Executors.newSingleThreadExecutor()
    private var currentWindowId: Int = -1

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        JarviceLogger.i(TAG, "onServiceConnected", "Accessibility service connected")
        setupChannel()
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
                    "performBack" -> {
                        result.success(performGlobalAction(GLOBAL_ACTION_BACK))
                    }
                    "performHome" -> {
                        result.success(performGlobalAction(GLOBAL_ACTION_HOME))
                    }
                    "performRecents" -> {
                        result.success(performGlobalAction(GLOBAL_ACTION_RECENTS))
                    }
                    "performNotifications" -> {
                        result.success(performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS))
                    }
                    "performQuickSettings" -> {
                        result.success(performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS))
                    }
                    "performScrollUp" -> {
                        result.success(performScroll(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD))
                    }
                    "performScrollDown" -> {
                        result.success(performScroll(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD))
                    }
                    "performClick" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        result.success(performClick(x, y))
                    }
                    "performSwipe" -> {
                        val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                        val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                        val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                        val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                        result.success(performSwipe(startX, startY, endX, endY))
                    }
                    "getWindowHierarchy" -> {
                        result.success(getWindowHierarchy())
                    }
                    "isEnabled" -> {
                        result.success(true)
                    }
                    "setText" -> {
                        val text = call.argument<String>("text") ?: ""
                        result.success(setTextInFocusedField(text))
                    }
                    "clearText" -> {
                        result.success(clearFocusedField())
                    }
                    "typeText" -> {
                        val text = call.argument<String>("text") ?: ""
                        result.success(typeTextCharByChar(text))
                    }
                    "pressEnter" -> {
                        result.success(pressEnterKey())
                    }
                    else -> result.notImplemented()
                }
            }
        } else {
            JarviceLogger.w(TAG, "setupChannel", "FlutterEngine not cached yet, will retry in 2s")
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ setupChannel() }, 2000)
        }
    }

    private fun performScroll(action: Int): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val scrollable = findScrollableNode(rootNode)
        return scrollable?.performAction(action) ?: false
    }

    private fun findScrollableNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isScrollable) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findScrollableNode(child)
            if (found != null) return found
        }
        return null
    }

    private fun performClick(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val path = Path().apply { moveTo(x, y) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    private fun performSwipe(startX: Float, startY: Float, endX: Float, endY: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 300))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    private fun getWindowHierarchy(): Map<String, Any?> {
        val rootNode = rootInActiveWindow ?: return emptyMap()
        return nodeToMap(rootNode, 0)
    }

    private fun nodeToMap(node: AccessibilityNodeInfo, depth: Int): Map<String, Any?> {
        if (depth > 10) return emptyMap()
        val map = mutableMapOf<String, Any?>(
            "className" to node.className?.toString(),
            "text" to node.text?.toString(),
            "contentDescription" to node.contentDescription?.toString(),
            "isClickable" to node.isClickable,
            "isScrollable" to node.isScrollable,
            "isEnabled" to node.isEnabled,
            "isFocused" to node.isFocused,
            "isEditable" to node.isEditable,
            "bounds" to run {
                val rect = android.graphics.Rect()
                node.getBoundsInScreen(rect)
                mapOf("left" to rect.left, "top" to rect.top, "right" to rect.right, "bottom" to rect.bottom)
            },
            "children" to mutableListOf<Map<String, Any?>>()
        )

        val children = map["children"] as MutableList<Map<String, Any?>>
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            children.add(nodeToMap(child, depth + 1))
        }

        return map
    }

    private fun setTextInFocusedField(text: String): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val focused = findFocusedNode(rootNode) ?: return false
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        return focused.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    private fun clearFocusedField(): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val focused = findFocusedNode(rootNode) ?: return false
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, "")
        }
        return focused.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    private fun findFocusedNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isFocused && node.isEditable) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findFocusedNode(child)
            if (found != null) return found
        }
        return null
    }

    private fun typeTextCharByChar(text: String): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val focused = findFocusedNode(rootNode) ?: return false
        val current = focused.text?.toString() ?: ""
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, current + text)
        }
        return focused.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    private fun pressEnterKey(): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        val focused = findFocusedNode(rootNode) ?: return false
        return focused.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            currentWindowId = it.windowId
        }
    }

    override fun onInterrupt() {
        JarviceLogger.i(TAG, "onInterrupt", "Accessibility service interrupted")
    }

    override fun onDestroy() {
        JarviceLogger.i(TAG, "onDestroy", "Accessibility service destroyed")
        instance = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        executor.shutdown()
        super.onDestroy()
    }
}
