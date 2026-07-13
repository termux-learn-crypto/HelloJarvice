import 'package:flutter/services.dart';

class NativeResult {
  final bool success;
  final String message;
  final Map<String, dynamic> data;
  final String? errorCode;
  final bool requiresConfirmation;
  final String? requiredCapability;

  NativeResult({
    required this.success,
    required this.message,
    this.data = const {},
    this.errorCode,
    this.requiresConfirmation = false,
    this.requiredCapability,
  });

  factory NativeResult.fromMap(Map<dynamic, dynamic> map) {
    return NativeResult(
      success: map['success'] == true,
      message: map['message']?.toString() ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      errorCode: map['errorCode']?.toString(),
      requiresConfirmation: map['requiresConfirmation'] == true,
      requiredCapability: map['requiredCapability']?.toString(),
    );
  }
}

class CommandRouter {
  static const MethodChannel systemChannel = MethodChannel('com.hey.mery/system');
  static const MethodChannel accessibilityChannel = MethodChannel('com.hey.mery/accessibility');
  static const MethodChannel notificationChannel = MethodChannel('com.hey.mery/notifications');
  static const MethodChannel _systemChannel = MethodChannel('com.hey.mery/system');
  static const MethodChannel _accessibilityChannel = MethodChannel('com.hey.mery/accessibility');
  static const MethodChannel _notificationChannel = MethodChannel('com.hey.mery/notifications');

  static Future<NativeResult> call(MethodChannel channel, String method, [Map<String, dynamic>? args]) async {
    try {
      final result = await channel.invokeMethod(method, args);
      if (result is Map) {
        return NativeResult.fromMap(result);
      }
      return NativeResult(success: true, message: result?.toString() ?? 'Done');
    } on PlatformException catch (e) {
      return NativeResult(
        success: false,
        message: 'Command failed: ${e.message}',
        errorCode: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return NativeResult(
        success: false,
        message: 'Unexpected error: $e',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  // System
  static Future<NativeResult> toggleWiFi(bool on) => call(_systemChannel, 'toggleWifi', {'state': on});
  static Future<NativeResult> toggleBluetooth(bool on) => call(_systemChannel, 'toggleBluetooth', {'state': on});
  static Future<NativeResult> toggleFlashlight(bool on) => call(_systemChannel, 'toggleFlashlight', {'state': on});
  static Future<NativeResult> torchOn() => call(_systemChannel, 'torchOn');
  static Future<NativeResult> torchOff() => call(_systemChannel, 'torchOff');
  static Future<NativeResult> torchToggle() => call(_systemChannel, 'torchToggle');

  // App
  static Future<NativeResult> launchApp(String name) => call(_systemChannel, 'launchApp', {'package': name});
  static Future<NativeResult> searchApps(String query) => call(_systemChannel, 'searchApps', {'query': query});

  // Audio
  static Future<NativeResult> volumeUp({String stream = 'music'}) =>
      call(_systemChannel, 'volumeUp', {'stream': stream});
  static Future<NativeResult> volumeDown({String stream = 'music'}) =>
      call(_systemChannel, 'volumeDown', {'stream': stream});
  static Future<NativeResult> setVolume(int percent, {String stream = 'music'}) =>
      call(_systemChannel, 'setVolume', {'percent': percent, 'stream': stream});
  static Future<NativeResult> muteVolume({String stream = 'music'}) =>
      call(_systemChannel, 'muteVolume', {'stream': stream});
  static Future<NativeResult> unmuteVolume({String stream = 'music'}) =>
      call(_systemChannel, 'unmuteVolume', {'stream': stream});
  static Future<NativeResult> maxVolume({String stream = 'music'}) =>
      call(_systemChannel, 'maxVolume', {'stream': stream});
  static Future<NativeResult> getVolumeInfo({String stream = 'music'}) =>
      call(_systemChannel, 'getVolumeInfo', {'stream': stream});

  // Media
  static Future<NativeResult> mediaPlay() => call(_systemChannel, 'mediaPlay');
  static Future<NativeResult> mediaPause() => call(_systemChannel, 'mediaPause');
  static Future<NativeResult> mediaStop() => call(_systemChannel, 'mediaStop');
  static Future<NativeResult> mediaNext() => call(_systemChannel, 'mediaNext');
  static Future<NativeResult> mediaPrevious() => call(_systemChannel, 'mediaPrevious');
  static Future<NativeResult> getPlaybackState() => call(_systemChannel, 'getPlaybackState');

  // Call
  static Future<NativeResult> makeCall(String target) => call(_systemChannel, 'makeCall', {'target': target});
  static Future<NativeResult> lookupContact(String query) =>
      call(_systemChannel, 'lookupContact', {'query': query});
  static Future<NativeResult> dialNumber(String number) =>
      call(_systemChannel, 'dialNumber', {'number': number});

  // SMS
  static Future<NativeResult> composeSms(String recipient, String message) =>
      call(_systemChannel, 'composeSms', {'recipient': recipient, 'message': message});

  // Alarm
  static Future<NativeResult> setAlarm(int hour, int minute, {String label = 'Jarvice Alarm'}) =>
      call(_systemChannel, 'setAlarm', {'hour': hour, 'minute': minute, 'label': label});
  static Future<NativeResult> setTimer(int minutes, {String label = 'Jarvice Timer'}) =>
      call(_systemChannel, 'setTimer', {'minutes': minutes, 'label': label});
  static Future<NativeResult> showAlarms() => call(_systemChannel, 'showAlarms');
  static Future<NativeResult> parseAlarmTime(String text) =>
      call(_systemChannel, 'parseAlarmTime', {'text': text});
  static Future<NativeResult> parseTimerMinutes(String text) =>
      call(_systemChannel, 'parseTimerMinutes', {'text': text});

  // Settings
  static Future<NativeResult> openSettings(String section) =>
      call(_systemChannel, 'openSettings', {'section': section});

  // Device
  static Future<NativeResult> getDeviceInfo() => call(_systemChannel, 'getDeviceInfo');
  static Future<NativeResult> getBatteryLevel() => call(_systemChannel, 'getBatteryLevel');
  static Future<NativeResult> openBatterySettings() => call(_systemChannel, 'openBatterySettings');
  static Future<NativeResult> checkBatteryOptimization() => call(_systemChannel, 'checkBatteryOptimization');

  // Accessibility
  static Future<NativeResult> performBack() => call(_accessibilityChannel, 'performBack');
  static Future<NativeResult> performHome() => call(_accessibilityChannel, 'performHome');
  static Future<NativeResult> performRecents() => call(_accessibilityChannel, 'performRecents');
  static Future<NativeResult> performNotifications() => call(_accessibilityChannel, 'performNotifications');
  static Future<NativeResult> performQuickSettings() => call(_accessibilityChannel, 'performQuickSettings');
  static Future<NativeResult> performScrollUp() => call(_accessibilityChannel, 'performScrollUp');
  static Future<NativeResult> performScrollDown() => call(_accessibilityChannel, 'performScrollDown');
  static Future<NativeResult> performClick(double x, double y) =>
      call(_accessibilityChannel, 'performClick', {'x': x, 'y': y});
  static Future<NativeResult> performSwipe(double sx, double sy, double ex, double ey) =>
      call(_accessibilityChannel, 'performSwipe', {'startX': sx, 'startY': sy, 'endX': ex, 'endY': ey});
  static Future<NativeResult> getWindowHierarchy() => call(_accessibilityChannel, 'getWindowHierarchy');
  static Future<NativeResult> isAccessibilityEnabled() async {
    try {
      final result = await _accessibilityChannel.invokeMethod('isEnabled');
      return NativeResult(success: true, message: result == true ? 'Enabled' : 'Disabled',
          data: {'enabled': result == true});
    } catch (e) {
      return NativeResult(success: true, message: 'Disabled', data: {'enabled': false});
    }
  }

  // Notifications
  static Future<NativeResult> getRecentNotifications() =>
      call(_notificationChannel, 'getRecentNotifications');
  static Future<NativeResult> getNotificationsByApp(String packageName) =>
      call(_notificationChannel, 'getNotificationsByApp', {'packageName': packageName});
  static Future<NativeResult> dismissNotification(String key) =>
      call(_notificationChannel, 'dismissNotification', {'key': key});
  static Future<NativeResult> isNotificationListenerEnabled() async {
    try {
      final result = await _notificationChannel.invokeMethod('isEnabled');
      return NativeResult(success: true, message: result == true ? 'Enabled' : 'Disabled',
          data: {'enabled': result == true});
    } catch (e) {
      return NativeResult(success: true, message: 'Disabled', data: {'enabled': false});
    }
  }

  // Web/Time (Flutter-side, uses launchApp on native)
  static Future<NativeResult> searchGoogle(String query) =>
      call(_systemChannel, 'searchGoogle', {'query': query});
  static Future<NativeResult> getCurrentTime() async {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return NativeResult(success: true, message: 'Abhi $h:$m baj rahe hain');
  }
  static Future<NativeResult> openYouTube() =>
      call(_systemChannel, 'launchApp', {'package': 'youtube'});
  static Future<NativeResult> openYouTubeSearch(String query) =>
      call(_systemChannel, 'searchYouTube', {'query': query});

  // Shizuku & Root (handled via system channel on native side)
  static Future<NativeResult> getShizukuStatus() => call(_systemChannel, 'getShizukuStatus');
  static Future<NativeResult> getRootStatus() => call(_systemChannel, 'getRootStatus');

  // Application (extended)
  static Future<NativeResult> closeApp(String package) =>
      call(_systemChannel, 'closeApp', {'package': package});
  static Future<NativeResult> getForegroundApp() =>
      call(_systemChannel, 'getForegroundApp');
  static Future<NativeResult> openAppInfo(String package) =>
      call(_systemChannel, 'openAppInfo', {'package': package});
  static Future<NativeResult> openAppNotificationSettings(String package) =>
      call(_systemChannel, 'openAppNotificationSettings', {'package': package});
  static Future<NativeResult> openAppPermissionSettings(String package) =>
      call(_systemChannel, 'openAppPermissionSettings', {'package': package});
  static Future<NativeResult> openDefaultAppSettings() =>
      call(_systemChannel, 'openDefaultAppSettings');
  static Future<NativeResult> openUrl(String url) =>
      call(_systemChannel, 'openUrl', {'url': url});
  static Future<NativeResult> openDeepLink(String uri) =>
      call(_systemChannel, 'openDeepLink', {'uri': uri});
  static Future<NativeResult> shareText(String text) =>
      call(_systemChannel, 'shareText', {'text': text});
  static Future<NativeResult> shareFile(String path) =>
      call(_systemChannel, 'shareFile', {'path': path});

  // Contact (extended)
  static Future<NativeResult> openContact(String name) =>
      call(_systemChannel, 'openContact', {'name': name});
  static Future<NativeResult> createContact(String name, {String phone = ''}) =>
      call(_systemChannel, 'createContact', {'name': name, 'phone': phone});
  static Future<NativeResult> openContactPicker() =>
      call(_systemChannel, 'openContactPicker');

  // Call (extended)
  static Future<NativeResult> redialLast() =>
      call(_systemChannel, 'redialLast');
  static Future<NativeResult> openDialer() =>
      call(_systemChannel, 'openDialer');

  // WhatsApp
  static Future<NativeResult> openWhatsAppChat(String contact) =>
      call(_systemChannel, 'openWhatsAppChat', {'contact': contact});
  static Future<NativeResult> openWhatsAppChatById(String phone) =>
      call(_systemChannel, 'openWhatsAppChatById', {'phone': phone});
  static Future<NativeResult> prepareWhatsAppMessage(String contact, String message) =>
      call(_systemChannel, 'prepareWhatsAppMessage', {'contact': contact, 'message': message});
  static Future<NativeResult> whatsappAudioCall(String contact) =>
      call(_systemChannel, 'whatsappAudioCall', {'contact': contact});
  static Future<NativeResult> whatsappVideoCall(String contact) =>
      call(_systemChannel, 'whatsappVideoCall', {'contact': contact});
  static Future<NativeResult> openWhatsAppCamera() =>
      call(_systemChannel, 'openWhatsAppCamera');

  // SMS (extended)
  static Future<NativeResult> openSmsComposer({String recipient = ''}) =>
      call(_systemChannel, 'openSmsComposer', {'recipient': recipient});

  // Brightness (extended)
  static Future<NativeResult> increaseBrightness() =>
      call(_systemChannel, 'increaseBrightness');
  static Future<NativeResult> decreaseBrightness() =>
      call(_systemChannel, 'decreaseBrightness');
  static Future<NativeResult> setAutoBrightness(bool enabled) =>
      call(_systemChannel, 'setAutoBrightness', {'enabled': enabled});

  // Torch (extended)
  static Future<NativeResult> getTorchState() =>
      call(_systemChannel, 'getTorchState');

  // Media (extended)
  static Future<NativeResult> getCurrentMediaApp() =>
      call(_systemChannel, 'getMediaApp');
  static Future<NativeResult> playMediaQuery(String query) =>
      call(_systemChannel, 'playMediaQuery', {'query': query});

  // Alarm (extended)
  static Future<NativeResult> dismissAlarm() =>
      call(_systemChannel, 'dismissAlarm');
  static Future<NativeResult> snoozeAlarm() =>
      call(_systemChannel, 'snoozeAlarm');

  // Timer (extended)
  static Future<NativeResult> openTimer() =>
      call(_systemChannel, 'openTimer');
  static Future<NativeResult> dismissTimer() =>
      call(_systemChannel, 'dismissTimer');

  // Reminder
  static Future<NativeResult> createReminder(String title, {int? hour, int? minute, int? duration, String? relativeTime}) =>
      call(_systemChannel, 'createReminder', {
        'title': title,
        if (hour != null) 'hour': hour,
        if (minute != null) 'minute': minute,
        if (duration != null) 'duration': duration,
        if (relativeTime != null) 'relativeTime': relativeTime,
      });
  static Future<NativeResult> listReminders() =>
      call(_systemChannel, 'listReminders');

  // WiFi (extended)
  static Future<NativeResult> getWifiState() =>
      call(_systemChannel, 'getWifiState');
  static Future<NativeResult> getConnectedWifi() =>
      call(_systemChannel, 'getConnectedWifi');

  // Bluetooth (extended)
  static Future<NativeResult> getBluetoothState() =>
      call(_systemChannel, 'getBluetoothState');
  static Future<NativeResult> getBondedDevices() =>
      call(_systemChannel, 'getBondedDevices');

  // Network
  static Future<NativeResult> getNetworkState() =>
      call(_systemChannel, 'getNetworkState');

  // Location
  static Future<NativeResult> getCurrentLocation() =>
      call(_systemChannel, 'getCurrentLocation');
  static Future<NativeResult> getLocationState() =>
      call(_systemChannel, 'getLocationState');
  static Future<NativeResult> navigateTo(String destination) =>
      call(_systemChannel, 'navigateTo', {'destination': destination});
  static Future<NativeResult> searchPlace(String query) =>
      call(_systemChannel, 'searchPlace', {'query': query});

  // Device (extended)
  static Future<NativeResult> getChargingState() =>
      call(_systemChannel, 'getChargingState');
  static Future<NativeResult> getStorageInfo() =>
      call(_systemChannel, 'getStorageInfo');
  static Future<NativeResult> getMemoryInfo() =>
      call(_systemChannel, 'getMemoryInfo');

  // Screen Control
  static Future<NativeResult> wakeScreen() =>
      call(_systemChannel, 'wakeScreen');
  static Future<NativeResult> keepScreenAwake(bool enabled) =>
      call(_systemChannel, 'keepScreenAwake', {'enabled': enabled});
  static Future<NativeResult> getScreenState() =>
      call(_systemChannel, 'getScreenState');

  // Rotation
  static Future<NativeResult> getRotationState() =>
      call(_systemChannel, 'getRotationState');
  static Future<NativeResult> setAutoRotate(bool enabled) =>
      call(_systemChannel, 'setAutoRotate', {'enabled': enabled});
  static Future<NativeResult> setOrientation(String orientation) =>
      call(_systemChannel, 'setOrientation', {'orientation': orientation});

  // DND
  static Future<NativeResult> getDndState() =>
      call(_systemChannel, 'getDndState');
  static Future<NativeResult> setDnd(bool enabled) =>
      call(_systemChannel, 'setDnd', {'enabled': enabled});

  // Clipboard
  static Future<NativeResult> copyToClipboard(String text) =>
      call(_systemChannel, 'copyToClipboard', {'text': text});
  static Future<NativeResult> getClipboardText() =>
      call(_systemChannel, 'getClipboardText');
  static Future<NativeResult> clearClipboard() =>
      call(_systemChannel, 'clearClipboard');

  // Camera
  static Future<NativeResult> openCamera({String facing = 'rear', String mode = 'photo'}) =>
      call(_systemChannel, 'openCamera', {'facing': facing, 'mode': mode});

  // File
  static Future<NativeResult> openFile(String path) =>
      call(_systemChannel, 'openFile', {'path': path});
  static Future<NativeResult> openDownloads() =>
      call(_systemChannel, 'openDownloads');
  static Future<NativeResult> openDocumentPicker() =>
      call(_systemChannel, 'openDocumentPicker');

  // Weather
  static Future<NativeResult> getWeather({String? city}) =>
      call(_systemChannel, 'getWeather', city != null ? {'city': city} : null);
  static Future<NativeResult> getWeatherForecast({String? city}) =>
      call(_systemChannel, 'getWeatherForecast', city != null ? {'city': city} : null);
}
