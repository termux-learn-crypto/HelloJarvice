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

  static Future<NativeResult> call(MethodChannel channel, String method, [Map<String, dynamic>? args]) async {
    const maxRetries = 2;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await channel.invokeMethod(method, args);
        if (result is Map) {
          return NativeResult.fromMap(result);
        }
        return NativeResult(success: true, message: result?.toString() ?? 'Done');
      } on PlatformException catch (e) {
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
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
    return NativeResult(success: false, message: 'Max retries exceeded', errorCode: 'MAX_RETRIES');
  }

  // System
  static Future<NativeResult> toggleWiFi(bool on) => call(systemChannel, 'toggleWifi', {'state': on});
  static Future<NativeResult> toggleBluetooth(bool on) => call(systemChannel, 'toggleBluetooth', {'state': on});
  static Future<NativeResult> toggleFlashlight(bool on) => call(systemChannel, 'toggleFlashlight', {'state': on});
  static Future<NativeResult> torchOn() => call(systemChannel, 'torchOn');
  static Future<NativeResult> torchOff() => call(systemChannel, 'torchOff');
  static Future<NativeResult> torchToggle() => call(systemChannel, 'torchToggle');

  // App
  static Future<NativeResult> launchApp(String name) => call(systemChannel, 'launchApp', {'package': name});
  static Future<NativeResult> searchApps(String query) => call(systemChannel, 'searchApps', {'query': query});

  // Audio
  static Future<NativeResult> volumeUp({String stream = 'music'}) =>
      call(systemChannel, 'volumeUp', {'stream': stream});
  static Future<NativeResult> volumeDown({String stream = 'music'}) =>
      call(systemChannel, 'volumeDown', {'stream': stream});
  static Future<NativeResult> setVolume(int percent, {String stream = 'music'}) =>
      call(systemChannel, 'setVolume', {'percent': percent, 'stream': stream});
  static Future<NativeResult> muteVolume({String stream = 'music'}) =>
      call(systemChannel, 'muteVolume', {'stream': stream});
  static Future<NativeResult> unmuteVolume({String stream = 'music'}) =>
      call(systemChannel, 'unmuteVolume', {'stream': stream});
  static Future<NativeResult> maxVolume({String stream = 'music'}) =>
      call(systemChannel, 'maxVolume', {'stream': stream});
  static Future<NativeResult> getVolumeInfo({String stream = 'music'}) =>
      call(systemChannel, 'getVolumeInfo', {'stream': stream});

  // Media
  static Future<NativeResult> mediaPlay() => call(systemChannel, 'mediaPlay');
  static Future<NativeResult> mediaPause() => call(systemChannel, 'mediaPause');
  static Future<NativeResult> mediaStop() => call(systemChannel, 'mediaStop');
  static Future<NativeResult> mediaNext() => call(systemChannel, 'mediaNext');
  static Future<NativeResult> mediaPrevious() => call(systemChannel, 'mediaPrevious');
  static Future<NativeResult> getPlaybackState() => call(systemChannel, 'getPlaybackState');

  // Call
  static Future<NativeResult> makeCall(String target) => call(systemChannel, 'makeCall', {'target': target});
  static Future<NativeResult> lookupContact(String query) =>
      call(systemChannel, 'lookupContact', {'query': query});
  static Future<NativeResult> dialNumber(String number) =>
      call(systemChannel, 'dialNumber', {'number': number});

  // SMS
  static Future<NativeResult> composeSms(String recipient, String message) =>
      call(systemChannel, 'composeSms', {'recipient': recipient, 'message': message});

  // Alarm
  static Future<NativeResult> setAlarm(int hour, int minute, {String label = 'Jarvice Alarm'}) =>
      call(systemChannel, 'setAlarm', {'hour': hour, 'minute': minute, 'label': label});
  static Future<NativeResult> setTimer(int minutes, {String label = 'Jarvice Timer'}) =>
      call(systemChannel, 'setTimer', {'minutes': minutes, 'label': label});
  static Future<NativeResult> showAlarms() => call(systemChannel, 'showAlarms');
  static Future<NativeResult> parseAlarmTime(String text) =>
      call(systemChannel, 'parseAlarmTime', {'text': text});
  static Future<NativeResult> parseTimerMinutes(String text) =>
      call(systemChannel, 'parseTimerMinutes', {'text': text});

  // Settings
  static Future<NativeResult> openSettings(String section) =>
      call(systemChannel, 'openSettings', {'section': section});

  // Device
  static Future<NativeResult> getDeviceInfo() => call(systemChannel, 'getDeviceInfo');
  static Future<NativeResult> getBatteryLevel() => call(systemChannel, 'getBatteryLevel');
  static Future<NativeResult> openBatterySettings() => call(systemChannel, 'openBatterySettings');
  static Future<NativeResult> checkBatteryOptimization() => call(systemChannel, 'checkBatteryOptimization');

  // Accessibility
  static Future<NativeResult> performBack() => call(accessibilityChannel, 'performBack');
  static Future<NativeResult> performHome() => call(accessibilityChannel, 'performHome');
  static Future<NativeResult> performRecents() => call(accessibilityChannel, 'performRecents');
  static Future<NativeResult> performNotifications() => call(accessibilityChannel, 'performNotifications');
  static Future<NativeResult> performQuickSettings() => call(accessibilityChannel, 'performQuickSettings');
  static Future<NativeResult> performScrollUp() => call(accessibilityChannel, 'performScrollUp');
  static Future<NativeResult> performScrollDown() => call(accessibilityChannel, 'performScrollDown');
  static Future<NativeResult> performClick(double x, double y) =>
      call(accessibilityChannel, 'performClick', {'x': x, 'y': y});
  static Future<NativeResult> performSwipe(double sx, double sy, double ex, double ey) =>
      call(accessibilityChannel, 'performSwipe', {'startX': sx, 'startY': sy, 'endX': ex, 'endY': ey});
  static Future<NativeResult> getWindowHierarchy() => call(accessibilityChannel, 'getWindowHierarchy');
  static Future<NativeResult> isAccessibilityEnabled() async {
    try {
      final result = await accessibilityChannel.invokeMethod('isEnabled');
      return NativeResult(success: true, message: result == true ? 'Enabled' : 'Disabled',
          data: {'enabled': result == true});
    } catch (e) {
      return NativeResult(success: true, message: 'Disabled', data: {'enabled': false});
    }
  }

  // Notifications
  static Future<NativeResult> getRecentNotifications() =>
      call(notificationChannel, 'getRecentNotifications');
  static Future<NativeResult> getNotificationsByApp(String packageName) =>
      call(notificationChannel, 'getNotificationsByApp', {'packageName': packageName});
  static Future<NativeResult> dismissNotification(String key) =>
      call(notificationChannel, 'dismissNotification', {'key': key});
  static Future<NativeResult> isNotificationListenerEnabled() async {
    try {
      final result = await notificationChannel.invokeMethod('isEnabled');
      return NativeResult(success: true, message: result == true ? 'Enabled' : 'Disabled',
          data: {'enabled': result == true});
    } catch (e) {
      return NativeResult(success: true, message: 'Disabled', data: {'enabled': false});
    }
  }

  // Web/Time (Flutter-side, uses launchApp on native)
  static Future<NativeResult> searchGoogle(String query) =>
      call(systemChannel, 'searchGoogle', {'query': query});
  static Future<NativeResult> getCurrentTime() async {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return NativeResult(success: true, message: 'Abhi $h:$m baj rahe hain');
  }
  static Future<NativeResult> openYouTube() =>
      call(systemChannel, 'launchApp', {'package': 'youtube'});
  static Future<NativeResult> openYouTubeSearch(String query) =>
      call(systemChannel, 'searchYouTube', {'query': query});

  // Shizuku & Root (handled via system channel on native side)
  static Future<NativeResult> getShizukuStatus() => call(systemChannel, 'getShizukuStatus');
  static Future<NativeResult> getRootStatus() => call(systemChannel, 'getRootStatus');

  // Application (extended)
  static Future<NativeResult> closeApp(String package) =>
      call(systemChannel, 'closeApp', {'package': package});
  static Future<NativeResult> getForegroundApp() =>
      call(systemChannel, 'getForegroundApp');
  static Future<NativeResult> openAppInfo(String package) =>
      call(systemChannel, 'openAppInfo', {'package': package});
  static Future<NativeResult> openAppNotificationSettings(String package) =>
      call(systemChannel, 'openAppNotificationSettings', {'package': package});
  static Future<NativeResult> openAppPermissionSettings(String package) =>
      call(systemChannel, 'openAppPermissionSettings', {'package': package});
  static Future<NativeResult> openDefaultAppSettings() =>
      call(systemChannel, 'openDefaultAppSettings');
  static Future<NativeResult> openUrl(String url) =>
      call(systemChannel, 'openUrl', {'url': url});
  static Future<NativeResult> openDeepLink(String uri) =>
      call(systemChannel, 'openDeepLink', {'uri': uri});
  static Future<NativeResult> shareText(String text) =>
      call(systemChannel, 'shareText', {'text': text});
  static Future<NativeResult> shareFile(String path) =>
      call(systemChannel, 'shareFile', {'path': path});

  // Contact (extended)
  static Future<NativeResult> openContact(String name) =>
      call(systemChannel, 'openContact', {'name': name});
  static Future<NativeResult> createContact(String name, {String phone = ''}) =>
      call(systemChannel, 'createContact', {'name': name, 'phone': phone});
  static Future<NativeResult> openContactPicker() =>
      call(systemChannel, 'openContactPicker');

  // Call (extended)
  static Future<NativeResult> redialLast() =>
      call(systemChannel, 'redialLast');
  static Future<NativeResult> openDialer() =>
      call(systemChannel, 'openDialer');

  // WhatsApp
  static Future<NativeResult> openWhatsAppChat(String contact) =>
      call(systemChannel, 'openWhatsAppChat', {'contact': contact});
  static Future<NativeResult> openWhatsAppChatById(String phone) =>
      call(systemChannel, 'openWhatsAppChatById', {'phone': phone});
  static Future<NativeResult> prepareWhatsAppMessage(String contact, String message) =>
      call(systemChannel, 'prepareWhatsAppMessage', {'contact': contact, 'message': message});
  static Future<NativeResult> whatsappAudioCall(String contact) =>
      call(systemChannel, 'whatsappAudioCall', {'contact': contact});
  static Future<NativeResult> whatsappVideoCall(String contact) =>
      call(systemChannel, 'whatsappVideoCall', {'contact': contact});
  static Future<NativeResult> openWhatsAppCamera() =>
      call(systemChannel, 'openWhatsAppCamera');

  // SMS (extended)
  static Future<NativeResult> openSmsComposer({String recipient = ''}) =>
      call(systemChannel, 'openSmsComposer', {'recipient': recipient});

  // Brightness (extended)
  static Future<NativeResult> increaseBrightness() =>
      call(systemChannel, 'increaseBrightness');
  static Future<NativeResult> decreaseBrightness() =>
      call(systemChannel, 'decreaseBrightness');
  static Future<NativeResult> setAutoBrightness(bool enabled) =>
      call(systemChannel, 'setAutoBrightness', {'enabled': enabled});

  // Torch (extended)
  static Future<NativeResult> getTorchState() =>
      call(systemChannel, 'getTorchState');

  // Media (extended)
  static Future<NativeResult> getCurrentMediaApp() =>
      call(systemChannel, 'getMediaApp');
  static Future<NativeResult> playMediaQuery(String query) =>
      call(systemChannel, 'playMediaQuery', {'query': query});

  // Alarm (extended)
  static Future<NativeResult> dismissAlarm() =>
      call(systemChannel, 'dismissAlarm');
  static Future<NativeResult> snoozeAlarm() =>
      call(systemChannel, 'snoozeAlarm');

  // Timer (extended)
  static Future<NativeResult> openTimer() =>
      call(systemChannel, 'openTimer');
  static Future<NativeResult> dismissTimer() =>
      call(systemChannel, 'dismissTimer');

  // Reminder
  static Future<NativeResult> createReminder(String title, {int? hour, int? minute, int? duration, String? relativeTime}) =>
      call(systemChannel, 'createReminder', {
        'title': title,
        if (hour != null) 'hour': hour,
        if (minute != null) 'minute': minute,
        if (duration != null) 'duration': duration,
        if (relativeTime != null) 'relativeTime': relativeTime,
      });
  static Future<NativeResult> listReminders() =>
      call(systemChannel, 'listReminders');

  // WiFi (extended)
  static Future<NativeResult> getWifiState() =>
      call(systemChannel, 'getWifiState');
  static Future<NativeResult> getConnectedWifi() =>
      call(systemChannel, 'getConnectedWifi');

  // Bluetooth (extended)
  static Future<NativeResult> getBluetoothState() =>
      call(systemChannel, 'getBluetoothState');
  static Future<NativeResult> getBondedDevices() =>
      call(systemChannel, 'getBondedDevices');

  // Network
  static Future<NativeResult> getNetworkState() =>
      call(systemChannel, 'getNetworkState');

  // Location
  static Future<NativeResult> getCurrentLocation() =>
      call(systemChannel, 'getCurrentLocation');
  static Future<NativeResult> getLocationState() =>
      call(systemChannel, 'getLocationState');
  static Future<NativeResult> navigateTo(String destination) =>
      call(systemChannel, 'navigateTo', {'destination': destination});
  static Future<NativeResult> searchPlace(String query) =>
      call(systemChannel, 'searchPlace', {'query': query});

  // Device (extended)
  static Future<NativeResult> getChargingState() =>
      call(systemChannel, 'getChargingState');
  static Future<NativeResult> getStorageInfo() =>
      call(systemChannel, 'getStorageInfo');
  static Future<NativeResult> getMemoryInfo() =>
      call(systemChannel, 'getMemoryInfo');

  // Screen Control
  static Future<NativeResult> wakeScreen() =>
      call(systemChannel, 'wakeScreen');
  static Future<NativeResult> keepScreenAwake(bool enabled) =>
      call(systemChannel, 'keepScreenAwake', {'enabled': enabled});
  static Future<NativeResult> getScreenState() =>
      call(systemChannel, 'getScreenState');

  // Rotation
  static Future<NativeResult> getRotationState() =>
      call(systemChannel, 'getRotationState');
  static Future<NativeResult> setAutoRotate(bool enabled) =>
      call(systemChannel, 'setAutoRotate', {'enabled': enabled});
  static Future<NativeResult> setOrientation(String orientation) =>
      call(systemChannel, 'setOrientation', {'orientation': orientation});

  // DND
  static Future<NativeResult> getDndState() =>
      call(systemChannel, 'getDndState');
  static Future<NativeResult> setDnd(bool enabled) =>
      call(systemChannel, 'setDnd', {'enabled': enabled});

  // Clipboard
  static Future<NativeResult> copyToClipboard(String text) =>
      call(systemChannel, 'copyToClipboard', {'text': text});
  static Future<NativeResult> getClipboardText() =>
      call(systemChannel, 'getClipboardText');
  static Future<NativeResult> clearClipboard() =>
      call(systemChannel, 'clearClipboard');

  // Camera
  static Future<NativeResult> openCamera({String facing = 'rear', String mode = 'photo'}) =>
      call(systemChannel, 'openCamera', {'facing': facing, 'mode': mode});

  // File
  static Future<NativeResult> openFile(String path) =>
      call(systemChannel, 'openFile', {'path': path});
  static Future<NativeResult> openDownloads() =>
      call(systemChannel, 'openDownloads');
  static Future<NativeResult> openDocumentPicker() =>
      call(systemChannel, 'openDocumentPicker');

  // Weather
  static Future<NativeResult> getWeather({String? city}) =>
      call(systemChannel, 'getWeather', city != null ? {'city': city} : null);
  static Future<NativeResult> getWeatherForecast({String? city}) =>
      call(systemChannel, 'getWeatherForecast', city != null ? {'city': city} : null);
}
