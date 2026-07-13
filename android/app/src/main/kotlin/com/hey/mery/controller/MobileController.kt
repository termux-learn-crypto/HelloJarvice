package com.hey.mery.controller

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipboardManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import android.provider.AlarmClockContracts
import android.provider.CalendarContract
import android.provider.ContactsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import android.view.WindowManager
import com.hey.mery.data.CommandResult
import com.hey.mery.shizuku.ShizukuController
import com.hey.mery.root.RootExecutor
import com.hey.mery.util.JarviceLogger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.hardware.camera2.CameraManager
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import org.json.JSONObject

class MobileController(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val COMPONENT = "MobileController"
    }

    val appController = AppController(context)
    val audioController = AudioController(context)
    val mediaController = MediaController(context)
    val callController = CallController(context)
    val smsController = SmsController(context)
    val alarmController = AlarmController(context)
    val deviceController = DeviceController(context)
    val torchController = TorchController(context)
    val settingsController = SettingsController(context)
    val shizukuController = ShizukuController(context)
    val rootController = RootExecutor()
    val reminderController = ReminderController(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        JarviceLogger.d(COMPONENT, "onMethodCall", "method=${call.method}")
        val commandResult = handleMethodCall(call)
        result.success(commandResult.toMap())
    }

    private fun handleMethodCall(call: MethodCall): CommandResult {
        return when (call.method) {
            // System
            "toggleWifi" -> {
                val state = call.argument<Boolean>("state") ?: false
                toggleWifi(state)
            }
            "toggleBluetooth" -> {
                val state = call.argument<Boolean>("state") ?: false
                toggleBluetooth(state)
            }

            // Torch
            "toggleFlashlight" -> {
                val state = call.argument<Boolean>("state") ?: false
                if (state) torchController.turnOn() else torchController.turnOff()
            }
            "torchOn" -> torchController.turnOn()
            "torchOff" -> torchController.turnOff()
            "torchToggle" -> torchController.toggle()

            // App
            "launchApp" -> {
                val appName = call.argument<String>("package") ?: call.argument<String>("appName") ?: ""
                appController.launchApp(appName)
            }
            "searchApps" -> {
                val query = call.argument<String>("query") ?: ""
                appController.searchApps(query)
            }

            // Audio
            "volumeUp" -> {
                val stream = call.argument<String>("stream") ?: "music"
                audioController.volumeUp(stream)
            }
            "volumeDown" -> {
                val stream = call.argument<String>("stream") ?: "music"
                audioController.volumeDown(stream)
            }
            "setVolume" -> {
                val percent = call.argument<Int>("percent") ?: 50
                val stream = call.argument<String>("stream") ?: "music"
                audioController.setVolume(percent, stream)
            }
            "muteVolume" -> {
                val stream = call.argument<String>("stream") ?: "music"
                audioController.mute(stream)
            }
            "unmuteVolume" -> {
                val stream = call.argument<String>("stream") ?: "music"
                audioController.unmute(stream)
            }
            "maxVolume" -> {
                val stream = call.argument<String>("stream") ?: "music"
                audioController.maxVolume(stream)
            }
            "getVolumeInfo" -> {
                val stream = call.argument<String>("stream") ?: "music"
                audioController.getVolumeInfo(stream)
            }

            // Media
            "mediaPlay" -> mediaController.play()
            "mediaPause" -> mediaController.pause()
            "mediaStop" -> mediaController.stop()
            "mediaNext" -> mediaController.next()
            "mediaPrevious" -> mediaController.previous()
            "getPlaybackState" -> mediaController.getPlaybackState()

            // Call
            "makeCall" -> {
                val target = call.argument<String>("target") ?: ""
                callController.makeCall(target)
            }
            "lookupContact" -> {
                val query = call.argument<String>("query") ?: ""
                callController.lookupContact(query)
            }
            "dialNumber" -> {
                val number = call.argument<String>("number") ?: ""
                callController.dialNumber(number)
            }

            // SMS
            "composeSms" -> {
                val recipient = call.argument<String>("recipient") ?: ""
                val message = call.argument<String>("message") ?: ""
                smsController.composeSms(recipient, message)
            }

            // Alarm
            "setAlarm" -> {
                val hour = call.argument<Int>("hour") ?: 0
                val minute = call.argument<Int>("minute") ?: 0
                val label = call.argument<String>("label") ?: "Jarvice Alarm"
                alarmController.setAlarm(hour, minute, label)
            }
            "setTimer" -> {
                val minutes = call.argument<Int>("minutes") ?: 0
                val label = call.argument<String>("label") ?: "Jarvice Timer"
                alarmController.setTimer(minutes, label)
            }
            "showAlarms" -> alarmController.showAlarms()
            "parseAlarmTime" -> {
                val text = call.argument<String>("text") ?: ""
                val parsed = alarmController.parseTimeFromText(text)
                if (parsed != null) {
                    CommandResult.ok("Time parsed", "hour" to parsed.first, "minute" to parsed.second)
                } else {
                    CommandResult.error("Time parse nahi ho paya", "TIME_PARSE_FAILED")
                }
            }
            "parseTimerMinutes" -> {
                val text = call.argument<String>("text") ?: ""
                val parsed = alarmController.parseTimerMinutes(text)
                if (parsed != null) {
                    CommandResult.ok("Timer parsed", "minutes" to parsed)
                } else {
                    CommandResult.error("Timer parse nahi ho paya", "TIMER_PARSE_FAILED")
                }
            }

            // Device
            "getDeviceInfo" -> deviceController.getDeviceInfo()
            "getBatteryLevel" -> deviceController.getBatteryLevel()
            "openBatterySettings" -> deviceController.openBatterySettings()
            "getScreenBrightness" -> deviceController.getScreenBrightness()
            "setScreenBrightness" -> {
                val percent = call.argument<Int>("percent") ?: 50
                deviceController.setScreenBrightness(percent)
            }
            "checkBatteryOptimization" -> deviceController.checkBatteryOptimization()

            // Settings
            "openSettings" -> {
                val section = call.argument<String>("section")
                settingsController.openSettings(section)
            }

            // Shizuku
            "getShizukuStatus" -> {
                val status = shizukuController.getStatus()
                CommandResult.ok(
                    when (status) {
                        ShizukuController.ShizukuStatus.CONNECTED -> "Connected"
                        ShizukuController.ShizukuStatus.NOT_INSTALLED -> "Not Installed"
                        ShizukuController.ShizukuStatus.NOT_RUNNING -> "Not Running"
                        ShizukuController.ShizukuStatus.PERMISSION_REQUIRED -> "Permission Required"
                    },
                    "status" to status.name.lowercase()
                )
            }

            // Root
            "getRootStatus" -> {
                val available = rootController.isAvailable()
                CommandResult.ok(
                    if (available) "Root available hai" else "Root available nahi hai",
                    "available" to available
                )
            }

            // Application (extended)
            "closeApp" -> {
                val pkg = call.argument<String>("package") ?: ""
                appController.closeApp(pkg)
            }
            "getForegroundApp" -> appController.getForegroundApp()
            "openAppInfo" -> {
                val pkg = call.argument<String>("package") ?: ""
                openAppInfo(pkg)
            }
            "openAppNotificationSettings" -> {
                val pkg = call.argument<String>("package") ?: ""
                openAppNotificationSettings(pkg)
            }
            "openAppPermissionSettings" -> {
                val pkg = call.argument<String>("package") ?: ""
                openAppPermissionSettings(pkg)
            }
            "openDefaultAppSettings" -> openDefaultAppSettings()
            "openUrl" -> {
                val url = call.argument<String>("url") ?: ""
                openUrl(url)
            }
            "openDeepLink" -> {
                val uri = call.argument<String>("uri") ?: ""
                openDeepLink(uri)
            }
            "openFileWith" -> {
                val path = call.argument<String>("path") ?: ""
                val appName = call.argument<String>("app") ?: ""
                openFileWith(path, appName)
            }
            "shareText" -> {
                val text = call.argument<String>("text") ?: ""
                shareText(text)
            }
            "shareFile" -> {
                val path = call.argument<String>("path") ?: ""
                shareFile(path)
            }

            // Contact (extended)
            "openContact" -> {
                val name = call.argument<String>("name") ?: ""
                openContact(name)
            }
            "createContact" -> {
                val name = call.argument<String>("name") ?: ""
                val phone = call.argument<String>("phone") ?: ""
                createContact(name, phone)
            }
            "editContact" -> {
                val name = call.argument<String>("name") ?: ""
                editContact(name)
            }
            "openContactPicker" -> openContactPicker()

            // Call (extended)
            "redialLast" -> callController.redialLast()
            "openDialer" -> openDialer()

            // WhatsApp
            "openWhatsAppChat" -> {
                val contact = call.argument<String>("contact") ?: ""
                openWhatsAppChat(contact)
            }
            "openWhatsAppChatById" -> {
                val phone = call.argument<String>("phone") ?: ""
                openWhatsAppChatById(phone)
            }
            "prepareWhatsAppMessage" -> {
                val contact = call.argument<String>("contact") ?: ""
                val message = call.argument<String>("message") ?: ""
                prepareWhatsAppMessage(contact, message)
            }
            "whatsappAudioCall" -> {
                val contact = call.argument<String>("contact") ?: ""
                whatsappAudioCall(contact)
            }
            "whatsappVideoCall" -> {
                val contact = call.argument<String>("contact") ?: ""
                whatsappVideoCall(contact)
            }
            "openWhatsAppCamera" -> openWhatsAppCamera()

            // SMS (extended)
            "openSmsComposer" -> {
                val recipient = call.argument<String>("recipient") ?: ""
                openSmsComposer(recipient)
            }

            // Brightness (extended)
            "increaseBrightness" -> deviceController.increaseBrightness()
            "decreaseBrightness" -> deviceController.decreaseBrightness()
            "setAutoBrightness" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                deviceController.setAutoBrightness(enabled)
            }

            // Torch (extended)
            "getTorchState" -> torchController.getState()

            // Media (extended)
            "getMediaApp" -> mediaController.getCurrentMediaApp()
            "playMediaQuery" -> {
                val query = call.argument<String>("query") ?: ""
                mediaController.playMediaQuery(query)
            }

            // Alarm (extended)
            "dismissAlarm" -> alarmController.dismissAlarm()
            "snoozeAlarm" -> alarmController.snoozeAlarm()

            // Timer (extended)
            "openTimer" -> alarmController.openTimer()
            "dismissTimer" -> alarmController.dismissTimer()

            // Reminder
            "createReminder" -> {
                val title = call.argument<String>("title") ?: ""
                val hour = call.argument<Int>("hour")
                val minute = call.argument<Int>("minute")
                val duration = call.argument<Int>("duration")
                val relativeTime = call.argument<String>("relativeTime")
                reminderController.createReminder(title, hour, minute, duration, relativeTime)
            }
            "listReminders" -> reminderController.listReminders()
            "updateReminder" -> {
                val id = call.argument<String>("id") ?: ""
                val title = call.argument<String>("title")
                val hour = call.argument<Int>("hour")
                val minute = call.argument<Int>("minute")
                reminderController.updateReminder(id, title, hour, minute)
            }
            "deleteReminder" -> {
                val id = call.argument<String>("id") ?: ""
                reminderController.deleteReminder(id)
            }
            "getReminder" -> {
                val id = call.argument<String>("id") ?: ""
                reminderController.getReminder(id)
            }
            "completereminder" -> {
                val id = call.argument<String>("id") ?: ""
                reminderController.completeReminder(id)
            }
            "snoozereminder" -> {
                val id = call.argument<String>("id") ?: ""
                reminderController.snoozeReminder(id)
            }

            // WiFi (extended)
            "getWifiState" -> getWifiState()
            "getConnectedWifi" -> getConnectedWifi()

            // Bluetooth (extended)
            "getBluetoothState" -> getBluetoothState()
            "getBondedDevices" -> getBondedDevices()

            // Network
            "getNetworkState" -> getNetworkState()

            // Location
            "getCurrentLocation" -> getCurrentLocation()
            "getLocationState" -> getLocationState()
            "navigateTo" -> {
                val dest = call.argument<String>("destination") ?: ""
                navigateTo(dest)
            }
            "searchPlace" -> {
                val query = call.argument<String>("query") ?: ""
                searchPlace(query)
            }

            // Device (extended)
            "getChargingState" -> getChargingState()
            "getStorageInfo" -> getStorageInfo()
            "getMemoryInfo" -> getMemoryInfo()
            "getNetworkInfo" -> getNetworkInfo()

            // Screen Control
            "wakeScreen" -> wakeScreen()
            "keepScreenAwake" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                keepScreenAwake(enabled)
            }
            "getScreenState" -> getScreenState()

            // Rotation
            "getRotationState" -> getRotationState()
            "setAutoRotate" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                setAutoRotate(enabled)
            }
            "setOrientation" -> {
                val orientation = call.argument<String>("orientation") ?: "portrait"
                setOrientation(orientation)
            }

            // DND
            "getDndState" -> getDndState()
            "setDnd" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                setDnd(enabled)
            }

            // Clipboard
            "copyToClipboard" -> {
                val text = call.argument<String>("text") ?: ""
                copyToClipboard(text)
            }
            "getClipboardText" -> getClipboardText()
            "clearClipboard" -> clearClipboard()

            // Camera
            "openCamera" -> {
                val facing = call.argument<String>("facing") ?: "rear"
                val mode = call.argument<String>("mode") ?: "photo"
                openCamera(facing, mode)
            }

            // File
            "openFile" -> {
                val path = call.argument<String>("path") ?: ""
                openFile(path)
            }
            "openDownloads" -> openDownloads()
            "openDocumentPicker" -> openDocumentPicker()
            "searchFiles" -> {
                val query = call.argument<String>("query") ?: ""
                searchFiles(query)
            }

            // Weather
            "getWeather" -> {
                val city = call.argument<String>("city")
                getWeather(city)
            }
            "getWeatherForecast" -> {
                val city = call.argument<String>("city")
                getWeatherForecast(city)
            }

            // Settings (extended)
            "datetime" -> {
                settingsController.openSettings("datetime")
            }
            "dnd_access" -> {
                settingsController.openSettings("dnd_access")
            }
            "language" -> {
                settingsController.openSettings("language")
            }
            "data_usage" -> {
                settingsController.openSettings("data_usage")
            }
            "airplane" -> {
                settingsController.openSettings("airplane")
            }
            "network" -> {
                settingsController.openSettings("network")
            }
            "apps" -> {
                settingsController.openSettings("apps")
            }

            // Web search
            "searchGoogle" -> {
                val query = call.argument<String>("query") ?: ""
                searchGoogle(query)
            }
            "searchYouTube" -> {
                val query = call.argument<String>("query") ?: ""
                searchYouTube(query)
            }

            else -> CommandResult.error("Unknown method: ${call.method}", "METHOD_NOT_FOUND")
        }
    }

    private fun toggleWifi(enable: Boolean): CommandResult {
        JarviceLogger.i(COMPONENT, "toggleWifi", "enable=$enable")
        return try {
            @Suppress("DEPRECATION")
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val success = wifiManager.setWifiEnabled(enable)
            if (success) {
                CommandResult.ok(if (enable) "WiFi on kar diya" else "WiFi band kar diya")
            } else {
                openSettingsFallback("wifi")
                CommandResult.ok(if (enable) "WiFi on karne ki koshish ki" else "WiFi band karne ki koshish ki")
            }
        } catch (e: SecurityException) {
            JarviceLogger.e(COMPONENT, "toggleWifi", "Permission denied: ${e.message}", e)
            openSettingsFallback("wifi")
            CommandResult.ok("WiFi settings khol diye")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "toggleWifi", "Error: ${e.message}", e)
            openSettingsFallback("wifi")
            CommandResult.ok("WiFi settings khol diye")
        }
    }

    @Suppress("DEPRECATION")
    private fun toggleBluetooth(enable: Boolean): CommandResult {
        JarviceLogger.i(COMPONENT, "toggleBluetooth", "enable=$enable")
        return try {
            val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter != null) {
                if (enable && !bluetoothAdapter.isEnabled) {
                    bluetoothAdapter.enable()
                    CommandResult.ok("Bluetooth on kar diya")
                } else if (!enable && bluetoothAdapter.isEnabled) {
                    bluetoothAdapter.disable()
                    CommandResult.ok("Bluetooth band kar diya")
                } else {
                    CommandResult.ok(if (enable) "Bluetooth pehle se on hai" else "Bluetooth pehle se band hai")
                }
            } else {
                openSettingsFallback("bluetooth")
                CommandResult.ok("Bluetooth settings khol diye")
            }
        } catch (e: SecurityException) {
            JarviceLogger.e(COMPONENT, "toggleBluetooth", "Permission denied: ${e.message}", e)
            openSettingsFallback("bluetooth")
            CommandResult.ok("Bluetooth settings khol diye")
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "toggleBluetooth", "Error: ${e.message}", e)
            openSettingsFallback("bluetooth")
            CommandResult.ok("Bluetooth settings khol diye")
        }
    }

    private fun openSettingsFallback(section: String) {
        try {
            val intent = when (section) {
                "wifi" -> Intent(Settings.ACTION_WIFI_SETTINGS)
                "bluetooth" -> Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                else -> Intent(Settings.ACTION_SETTINGS)
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "openSettingsFallback", "Failed: ${e.message}", e)
        }
    }

    private fun openAppInfo(pkg: String): CommandResult {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$pkg")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("App info khol diya: $pkg")
        } catch (e: Exception) {
            CommandResult.error("App info nahi khula: ${e.message}")
        }
    }

    private fun openAppNotificationSettings(pkg: String): CommandResult {
        return try {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Notification settings khol diye: $pkg")
        } catch (e: Exception) {
            CommandResult.error("Notification settings nahi khule: ${e.message}")
        }
    }

    private fun openAppPermissionSettings(pkg: String): CommandResult {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$pkg#permissions")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Permission settings khol diye: $pkg")
        } catch (e: Exception) {
            CommandResult.error("Permission settings nahi khule: ${e.message}")
        }
    }

    private fun openDefaultAppSettings(): CommandResult {
        return try {
            val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Default app settings khol diye")
        } catch (e: Exception) {
            CommandResult.error("Default app settings nahi khule: ${e.message}")
        }
    }

    private fun openUrl(url: String): CommandResult {
        return try {
            val finalUrl = if (!url.startsWith("http://") && !url.startsWith("https://")) "https://$url" else url
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(finalUrl)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("URL khol diya: $finalUrl")
        } catch (e: Exception) {
            CommandResult.error("URL nahi khula: ${e.message}")
        }
    }

    private fun openDeepLink(uri: String): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Deep link khol diya: $uri")
        } catch (e: Exception) {
            CommandResult.error("Deep link nahi khula: ${e.message}")
        }
    }

    private fun openFileWith(path: String, appName: String): CommandResult {
        return try {
            val uri = Uri.parse(path)
            val mimeType = context.contentResolver.getType(uri) ?: "*/*"
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (appName.isNotEmpty()) {
                    val pm = context.packageManager
                    val resolvedActivity = pm.queryIntentActivities(this, 0)
                    val match = resolvedActivity.find {
                        it.loadLabel(pm).toString().contains(appName, ignoreCase = true)
                    }
                    if (match != null) {
                        setClassName(match.activityInfo.packageName, match.activityInfo.name)
                    }
                }
            }
            context.startActivity(intent)
            CommandResult.ok("File khol diya${if (appName.isNotEmpty()) " $appName se" else ""}")
        } catch (e: Exception) {
            CommandResult.error("File nahi khula: ${e.message}")
        }
    }

    private fun shareText(text: String): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(Intent.createChooser(intent, "Share via"))
            CommandResult.ok("Text share kar diya")
        } catch (e: Exception) {
            CommandResult.error("Share nahi ho paya: ${e.message}")
        }
    }

    private fun shareFile(path: String): CommandResult {
        return try {
            val uri = Uri.parse(path)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = context.contentResolver.getType(uri) ?: "*/*"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_ACTIVITY_READABLE_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(Intent.createChooser(intent, "Share file via"))
            CommandResult.ok("File share ho gayi")
        } catch (e: Exception) {
            CommandResult.error("File share nahi hui: ${e.message}")
        }
    }

    private fun openContact(name: String): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_FILTER_URI, Uri.encode(name))
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Contact khol diya: $name")
        } catch (e: Exception) {
            CommandResult.error("Contact nahi mila: ${e.message}")
        }
    }

    private fun createContact(name: String, phone: String): CommandResult {
        return try {
            val intent = Intent(ContactsContract.Intents.Insert.ACTION).apply {
                type = ContactsContract.Contacts.CONTENT_TYPE
                putExtra(ContactsContract.Intents.Insert.NAME, name)
                if (phone.isNotEmpty()) putExtra(ContactsContract.Intents.Insert.PHONE, phone)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Contact bana raha hoon: $name")
        } catch (e: Exception) {
            CommandResult.error("Contact nahi bana: ${e.message}")
        }
    }

    private fun editContact(name: String): CommandResult {
        return openContact(name)
    }

    private fun openContactPicker(): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Contact picker khol diya")
        } catch (e: Exception) {
            CommandResult.error("Contact picker nahi khula: ${e.message}")
        }
    }

    private fun openDialer(): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_DIAL).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Dialer khol diya")
        } catch (e: Exception) {
            CommandResult.error("Dialer nahi khula: ${e.message}")
        }
    }

    private fun resolveContactPhone(contactName: String): String {
        if (contactName.isBlank()) return ""
        return try {
            val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.NUMBER)
            val selection = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?"
            val selectionArgs = arrayOf("%$contactName%")
            context.contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                projection, selection, selectionArgs, null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)) ?: ""
                } else ""
            } ?: ""
        } catch (e: Exception) { "" }
    }

    private fun openWhatsAppChat(contact: String): CommandResult {
        val phone = resolveContactPhone(contact)
        val uri = if (phone.isNotEmpty())
            Uri.parse("whatsapp://send?phone=${Uri.encode(phone)}")
        else
            Uri.parse("whatsapp://send?contact=${Uri.encode(contact)}")
        return try {
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("WhatsApp khol raha hoon: $contact")
        } catch (e: Exception) {
            val fallback = Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/${phone.replace(Regex("[^0-9]"), "")}")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(fallback)
                CommandResult.ok("WhatsApp web pe khol raha hoon: $contact")
            } catch (e2: Exception) {
                CommandResult.error("WhatsApp nahi khula: ${e.message}")
            }
        }
    }

    private fun openWhatsAppChatById(phone: String): CommandResult {
        return try {
            val cleanPhone = phone.replace(Regex("[^0-9+]"), "")
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("whatsapp://send?phone=$cleanPhone")).apply {
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("WhatsApp khol raha hoon: $phone")
        } catch (e: Exception) {
            CommandResult.error("WhatsApp nahi khula: ${e.message}")
        }
    }

    private fun prepareWhatsAppMessage(contact: String, message: String): CommandResult {
        val phone = resolveContactPhone(contact)
        val uri = if (phone.isNotEmpty())
            Uri.parse("whatsapp://send?phone=${Uri.encode(phone)}&text=${Uri.encode(message)}")
        else
            Uri.parse("whatsapp://send?text=${Uri.encode(message)}")
        return try {
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("WhatsApp message ready hai: $contact ke liye")
        } catch (e: Exception) {
            val fallback = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, message)
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(fallback)
                CommandResult.ok("Message ready hai (share sheet)")
            } catch (e2: Exception) {
                CommandResult.error("Message nahi bhej paya: ${e.message}")
            }
        }
    }

    private fun whatsappAudioCall(contact: String): CommandResult {
        val phone = resolveContactPhone(contact)
        val uri = if (phone.isNotEmpty())
            Uri.parse("whatsapp://send?phone=${Uri.encode(phone)}")
        else
            Uri.parse("whatsapp://send?contact=${Uri.encode(contact)}")
        return try {
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("WhatsApp call: $contact ka chat khula hai, call button dabayein")
        } catch (e: Exception) {
            CommandResult.error("WhatsApp call nahi ho payi: ${e.message}")
        }
    }

    private fun whatsappVideoCall(contact: String): CommandResult {
        val phone = resolveContactPhone(contact)
        val uri = if (phone.isNotEmpty())
            Uri.parse("whatsapp://send?phone=${Uri.encode(phone)}")
        else
            Uri.parse("whatsapp://send?contact=${Uri.encode(contact)}")
        return try {
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("WhatsApp video call: $contact ka chat khula hai, video call button dabayein")
        } catch (e: Exception) {
            CommandResult.error("WhatsApp video call nahi ho payi: ${e.message}")
        }
    }

    private fun openWhatsAppCamera(): CommandResult {
        return try {
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("WhatsApp camera khol diya")
        } catch (e: Exception) {
            CommandResult.error("WhatsApp camera nahi khula: ${e.message}")
        }
    }

    private fun openSmsComposer(recipient: String): CommandResult {
        return try {
            val intent = if (recipient.isNotEmpty()) {
                Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:${Uri.encode(recipient)}"))
            } else {
                Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:"))
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            CommandResult.ok("SMS composer khol diya")
        } catch (e: Exception) {
            CommandResult.error("SMS composer nahi khula: ${e.message}")
        }
    }

    private fun getWifiState(): CommandResult {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val isOn = wifiManager.isWifiEnabled
            CommandResult.ok(
                if (isOn) "WiFi on hai" else "WiFi band hai",
                "enabled" to isOn
            )
        } catch (e: Exception) {
            CommandResult.error("WiFi state pata nahi chala: ${e.message}")
        }
    }

    private fun getConnectedWifi(): CommandResult {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            val info = wifiManager.connectionInfo
            val ssid = info?.ssid?.replace("\"", "") ?: "Unknown"
            val rssi = info?.rssi ?: 0
            val level = WifiManager.calculateSignalLevel(rssi, 5)
            CommandResult.ok(
                "Connected to: $ssid",
                "ssid" to ssid,
                "rssi" to rssi,
                "signalLevel" to level
            )
        } catch (e: Exception) {
            CommandResult.error("WiFi info nahi mil payi: ${e.message}")
        }
    }

    private fun getBluetoothState(): CommandResult {
        return try {
            val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
            val isOn = adapter?.isEnabled ?: false
            CommandResult.ok(
                if (isOn) "Bluetooth on hai" else "Bluetooth band hai",
                "enabled" to isOn
            )
        } catch (e: Exception) {
            CommandResult.error("Bluetooth state pata nahi chala: ${e.message}")
        }
    }

    @Suppress("DEPRECATION")
    private fun getBondedDevices(): CommandResult {
        return try {
            val adapter = BluetoothAdapter.getDefaultAdapter()
            val devices = adapter?.bondedDevices?.map { device ->
                mapOf(
                    "name" to (device.name ?: "Unknown"),
                    "address" to device.address
                )
            } ?: emptyList()
            CommandResult.ok("${devices.size} devices paired", "devices" to devices)
        } catch (e: Exception) {
            CommandResult.error("Devices nahi mil paye: ${e.message}")
        }
    }

    private fun getNetworkState(): CommandResult {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork
            val caps = network?.let { cm.getNetworkCapabilities(it) }
            val type = when {
                caps == null -> "none"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                else -> "other"
            }
            val connected = type != "none"
            CommandResult.ok(
                if (connected) "Connected via $type" else "No connection",
                "type" to type,
                "connected" to connected
            )
        } catch (e: Exception) {
            CommandResult.error("Network state pata nahi chala: ${e.message}")
        }
    }

    private fun getCurrentLocation(): CommandResult {
        return try {
            val fusedClient = com.google.android.gms.location.LocationServices.getFusedLocationProviderClient(context)
            @Suppress("MissingPermission")
            val locationTask = fusedClient.lastLocation
            locationTask.addOnSuccessListener { location ->
                if (location != null) {
                    val lat = location.latitude
                    val lng = location.longitude
                    JarviceLogger.i(COMPONENT, "getCurrentLocation", "Got location: $lat, $lng")
                } else {
                    JarviceLogger.w(COMPONENT, "getCurrentLocation", "Last location is null")
                }
            }
            locationTask.addOnFailureListener { e ->
                JarviceLogger.e(COMPONENT, "getCurrentLocation", "Failed: ${e.message}", e)
            }
            CommandResult.ok("Location fetch ho raha hai")
        } catch (e: Exception) {
            CommandResult.error("Location nahi mil payi: ${e.message}")
        }
    }

    private fun getLocationState(): CommandResult {
        return try {
            val isOn = Settings.Secure.getInt(
                context.contentResolver,
                Settings.Secure.LOCATION_MODE, 0
            ) != 0
            CommandResult.ok(
                if (isOn) "Location on hai" else "Location band hai",
                "enabled" to isOn
            )
        } catch (e: Exception) {
            CommandResult.error("Location state pata nahi chala: ${e.message}")
        }
    }

    private fun navigateTo(destination: String): CommandResult {
        return try {
            val uri = Uri.parse("google.navigation:q=${Uri.encode(destination)}")
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Navigate kar raha hoon: $destination")
        } catch (e: Exception) {
            CommandResult.error("Navigation nahi ho payi: ${e.message}")
        }
    }

    private fun searchPlace(query: String): CommandResult {
        return try {
            val uri = Uri.parse("geo:0,0?q=${Uri.encode(query)}")
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Place dhoondh raha hoon: $query")
        } catch (e: Exception) {
            CommandResult.error("Place nahi mila: ${e.message}")
        }
    }

    private fun getChargingState(): CommandResult {
        return try {
            val intentFilter = Intent(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = context.registerReceiver(null, intentFilter)
            val status = batteryStatus?.getIntExtra("status", -1) ?: -1
            val isCharging = status == 2 || status == 5
            CommandResult.ok(
                if (isCharging) "Charge ho raha hai" else "Charge nahi ho raha",
                "charging" to isCharging
            )
        } catch (e: Exception) {
            CommandResult.error("Charging state pata nahi chala: ${e.message}")
        }
    }

    private fun getStorageInfo(): CommandResult {
        return try {
            val stat = StatFs(Environment.getDataDirectory().path)
            val total = stat.totalBytes
            val free = stat.availableBytes
            val used = total - free
            val totalGB = total / (1024.0 * 1024 * 1024)
            val usedGB = used / (1024.0 * 1024 * 1024)
            val freeGB = free / (1024.0 * 1024 * 1024)
            CommandResult.ok(
                "Storage: ${"%.1f".format(usedGB)}GB used of ${"%.1f".format(totalGB)}GB",
                "totalGB" to totalGB,
                "usedGB" to usedGB,
                "freeGB" to freeGB
            )
        } catch (e: Exception) {
            CommandResult.error("Storage info nahi mil payi: ${e.message}")
        }
    }

    private fun getMemoryInfo(): CommandResult {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val memInfo = android.app.ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memInfo)
            val totalMB = memInfo.totalMem / (1024 * 1024)
            val freeMB = memInfo.availMem / (1024 * 1024)
            val usedMB = totalMB - freeMB
            CommandResult.ok(
                "RAM: ${usedMB}MB used of ${totalMB}MB",
                "totalMB" to totalMB,
                "usedMB" to usedMB,
                "freeMB" to freeMB
            )
        } catch (e: Exception) {
            CommandResult.error("Memory info nahi mil payi: ${e.message}")
        }
    }

    private fun getNetworkInfo(): CommandResult {
        return getNetworkState()
    }

    private fun wakeScreen(): CommandResult {
        return try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val isScreenOn = powerManager.isInteractive
            if (!isScreenOn) {
                val window = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    PixelFormat.TRANSLUCENT
                )
                window.addView(android.view.View(context), params)
                window.removeView(android.view.View(context))
            }
            CommandResult.ok("Screen on kar diya")
        } catch (e: Exception) {
            CommandResult.error("Screen nahi jaag payi: ${e.message}")
        }
    }

    private var keepAwakeView: android.view.View? = null

    private fun keepScreenAwake(enabled: Boolean): CommandResult {
        return try {
            val window = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            if (enabled && keepAwakeView == null) {
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    PixelFormat.TRANSLUCENT
                )
                val view = android.view.View(context)
                window.addView(view, params)
                keepAwakeView = view
                CommandResult.ok("Screen hamesha on rahegi")
            } else if (!enabled && keepAwakeView != null) {
                window.removeView(keepAwakeView)
                keepAwakeView = null
                CommandResult.ok("Screen hamesha on band")
            } else {
                CommandResult.ok("Already set hai")
            }
        } catch (e: Exception) {
            CommandResult.error("Screen setting nahi badli: ${e.message}")
        }
    }

    private fun getScreenState(): CommandResult {
        return try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val isOn = powerManager.isInteractive
            CommandResult.ok(
                if (isOn) "Screen on hai" else "Screen band hai",
                "screenOn" to isOn
            )
        } catch (e: Exception) {
            CommandResult.error("Screen state pata nahi chala: ${e.message}")
        }
    }

    private fun getRotationState(): CommandResult {
        return try {
            val rotation = Settings.System.getInt(
                context.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION, 0
            )
            val isAuto = rotation == 1
            CommandResult.ok(
                if (isAuto) "Auto rotation on hai" else "Auto rotation band hai",
                "autoRotate" to isAuto
            )
        } catch (e: Exception) {
            CommandResult.error("Rotation state pata nahi chala: ${e.message}")
        }
    }

    private fun setAutoRotate(enabled: Boolean): CommandResult {
        return try {
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION,
                if (enabled) 1 else 0
            )
            CommandResult.ok(if (enabled) "Auto rotation on kar diya" else "Auto rotation band kar diya")
        } catch (e: Exception) {
            CommandResult.error("Auto rotation nahi badla: ${e.message}")
        }
    }

    private fun setOrientation(orientation: String): CommandResult {
        return try {
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION, 0
            )
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.USER_ROTATION,
                when (orientation) {
                    "landscape" -> 1
                    else -> 0
                }
            )
            CommandResult.ok("Orientation set kar diya: $orientation")
        } catch (e: Exception) {
            CommandResult.error("Orientation nahi badla: ${e.message}")
        }
    }

    private fun getDndState(): CommandResult {
        return try {
            val current = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                notificationManager.currentInterruptionFilter
            } else {
                0
            }
            val isOn = current != 0
            CommandResult.ok(
                if (isOn) "DND on hai" else "DND band hai",
                "enabled" to isOn
            )
        } catch (e: Exception) {
            CommandResult.error("DND state pata nahi chala: ${e.message}")
        }
    }

    private fun setDnd(enabled: Boolean): CommandResult {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                if (notificationManager.isNotificationPolicyAccessGranted) {
                    notificationManager.setInterruptionFilter(
                        if (enabled) android.app.NotificationManager.INTERRUPTION_FILTER_PRIORITY
                        else android.app.NotificationManager.INTERRUPTION_FILTER_ALL
                    )
                    CommandResult.ok(if (enabled) "DND on kar diya" else "DND band kar diya")
                } else {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                    CommandResult.error("DND permission chahiye", "DND_PERMISSION_REQUIRED")
                }
            } else {
                CommandResult.error("DND is Android 6.0+ only")
            }
        } catch (e: Exception) {
            CommandResult.error("DND nahi badla: ${e.message}")
        }
    }

    private fun copyToClipboard(text: String): CommandResult {
        return try {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("Jarvice", text)
            clipboard.setPrimaryClip(clip)
            CommandResult.ok("Text copy ho gaya clipboard mein")
        } catch (e: Exception) {
            CommandResult.error("Copy nahi ho paya: ${e.message}")
        }
    }

    private fun getClipboardText(): CommandResult {
        return try {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = clipboard.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0).text?.toString() ?: ""
                CommandResult.ok("Clipboard mein: $text", "text" to text)
            } else {
                CommandResult.ok("Clipboard khali hai", "text" to "")
            }
        } catch (e: Exception) {
            CommandResult.error("Clipboard padh nahi paya: ${e.message}")
        }
    }

    private fun clearClipboard(): CommandResult {
        return try {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
            CommandResult.ok("Clipboard saaf kar diya")
        } catch (e: Exception) {
            CommandResult.error("Clipboard saaf nahi hua: ${e.message}")
        }
    }

    private fun openCamera(facing: String, mode: String): CommandResult {
        return try {
            val intent = when (mode) {
                "video" -> Intent(MediaStore.ACTION_VIDEO_CAPTURE)
                else -> Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            }
            if (facing == "front") {
                val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                try {
                    for (cameraId in cameraManager.cameraIdList) {
                        val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                        val lensFacing = characteristics.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING)
                        if (lensFacing == android.hardware.camera2.CameraCharacteristics.LENS_FACING_FRONT) {
                            intent.putExtra("android.intent.extras.CAMERA_FACING", 1)
                            break
                        }
                    }
                } catch (e: Exception) {
                    JarviceLogger.w(COMPONENT, "openCamera", "Could not detect front camera: ${e.message}")
                }
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            CommandResult.ok("Camera khol diya ($facing, $mode)")
        } catch (e: Exception) {
            CommandResult.error("Camera nahi khula: ${e.message}")
        }
    }

    private fun openFile(path: String): CommandResult {
        return try {
            val uri = Uri.parse(path)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, context.contentResolver.getType(uri))
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("File khol diya")
        } catch (e: Exception) {
            CommandResult.error("File nahi khula: ${e.message}")
        }
    }

    private fun openDownloads(): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("content://com.android.providers.downloads.documents/")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Downloads khol diye")
        } catch (e: Exception) {
            CommandResult.error("Downloads nahi khule: ${e.message}")
        }
    }

    private fun openDocumentPicker(): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Document picker khol diya")
        } catch (e: Exception) {
            CommandResult.error("Document picker nahi khula: ${e.message}")
        }
    }

    private fun searchFiles(query: String): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.parse("content://com.android.externalstorage.documents/document/primary:"), "*/*")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (query.isNotEmpty()) {
                    putExtra("android.provider.extra.SHOW_ADVANCED", true)
                    putExtra("android.provider.extra.INITIAL_URI", Uri.parse("content://com.android.externalstorage.documents/document/primary:"))
                }
            }
            context.startActivity(intent)
            CommandResult.ok("File manager khol diya: $query")
        } catch (e: Exception) {
            val fallback = Intent(Intent.ACTION_VIEW, Uri.parse("content://com.android.fileexplorer/")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(fallback)
                CommandResult.ok("File manager khol diya: $query")
            } catch (e2: Exception) {
                CommandResult.error("File manager nahi khula: ${e.message}")
            }
        }
    }

    private fun searchGoogle(query: String): CommandResult {
        return try {
            val url = "https://www.google.com/search?q=${Uri.encode(query)}"
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            CommandResult.ok("Google pe search kar raha hoon: $query")
        } catch (e: Exception) {
            CommandResult.error("Google search nahi ho paya: ${e.message}")
        }
    }

    private fun searchYouTube(query: String): CommandResult {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.youtube.com/results?search_query=${Uri.encode(query)}")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(intent)
            } catch (_: Exception) {
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.youtube.com/results?search_query=${Uri.encode(query)}")).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(webIntent)
            }
            CommandResult.ok("YouTube pe search kar raha hoon: $query")
        } catch (e: Exception) {
            CommandResult.error("YouTube search nahi ho paya: ${e.message}")
        }
    }

    private fun getWeather(city: String?): CommandResult {
        val query = city ?: "auto:ip"
        return try {
            val url = URL("https://wttr.in/${Uri.encode(query)}?format=j1")
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.setRequestProperty("User-Agent", "Jarvice/1.0")
            val response = connection.inputStream.bufferedReader().readText()
            connection.disconnect()
            val json = JSONObject(response)
            val current = json.getJSONObject("current_condition").let {
                if (it.has("0")) it.getJSONObject("0") else it
            }
            val tempC = current.optString("temp_C", "")
            val feelsLike = current.optString("FeelsLikeC", "")
            val humidity = current.optString("humidity", "")
            val windKmph = current.optString("windspeedKmph", "")
            val desc = current.getJSONArray("weatherDesc").let {
                if (it.has(0)) it.getJSONObject(0).optString("value", "") else ""
            }
            val area = json.getJSONObject("nearest_area").let {
                if (it.has("0")) it.getJSONObject("0") else it
            }
            val areaName = area.getJSONArray("areaName").let {
                if (it.has(0)) it.getJSONObject(0).optString("value", query) else query
            }
            val country = area.getJSONArray("country").let {
                if (it.has(0)) it.getJSONObject(0).optString("value", "") else ""
            }
            CommandResult.ok(
                "$desc, $tempC°C (feels like $feelsLike°C) in $areaName, $country. Humidity: $humidity%, Wind: ${windKmph}km/h",
                "temp_c" to tempC,
                "feels_like_c" to feelsLike,
                "humidity" to humidity,
                "wind_kmph" to windKmph,
                "description" to desc,
                "city" to areaName,
                "country" to country,
                "query" to query
            )
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "getWeather", "Error: ${e.message}", e)
            CommandResult.error("Weather nahi mil paya: ${e.message}")
        }
    }

    private fun getWeatherForecast(city: String?): CommandResult {
        val query = city ?: "auto:ip"
        return try {
            val url = URL("https://wttr.in/${Uri.encode(query)}?format=j1")
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.setRequestProperty("User-Agent", "Jarvice/1.0")
            val response = connection.inputStream.bufferedReader().readText()
            connection.disconnect()
            val json = JSONObject(response)
            val weatherArray = json.getJSONArray("weather")
            val forecasts = mutableListOf<String>()
            for (i in 0 until minOf(weatherArray.length(), 3)) {
                val day = weatherArray.getJSONObject(i)
                val date = day.optString("date", "")
                val maxTemp = day.optString("maxtempC", "")
                val minTemp = day.optString("mintempC", "")
                val descArr = day.getJSONArray("hourly")
                val desc = if (descArr.length() > 4) {
                    descArr.getJSONObject(4).getJSONArray("weatherDesc").let {
                        if (it.length() > 0) it.getJSONObject(0).optString("value", "") else ""
                    }
                } else ""
                forecasts.add("$date: $desc, $minTemp°C - $maxTemp°C")
            }
            val forecastText = forecasts.joinToString("\n")
            CommandResult.ok(
                "Weather forecast for $query:\n$forecastText",
                mapOf("forecasts" to forecasts, "query" to query)
            )
        } catch (e: Exception) {
            JarviceLogger.e(COMPONENT, "getWeatherForecast", "Error: ${e.message}", e)
            CommandResult.error("Weather forecast nahi mil payi: ${e.message}")
        }
    }
}
