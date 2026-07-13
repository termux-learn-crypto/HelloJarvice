import 'capability.dart';

class CapabilityRegistry {
  static final CapabilityRegistry instance = CapabilityRegistry._();
  CapabilityRegistry._();

  final Map<String, Capability> _capabilities = {};
  final Map<String, List<Capability>> _categoryIndex = {};
  final Map<String, List<Capability>> _operationIndex = {};

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _registerAll();
  }

  Capability? getCapability(String id) => _capabilities[id];

  List<Capability> getByCategory(CapabilityCategory category) =>
      _categoryIndex[category.name] ?? [];

  List<Capability> getByOperation(Operation op) =>
      _operationIndex[op.name] ?? [];

  List<Capability> get all => _capabilities.values.toList();

  List<Capability> findByKeywords(List<String> keywords) {
    final results = <Capability>[];
    final lower = keywords.map((k) => k.toLowerCase()).toList();
    for (final cap in _capabilities.values) {
      final descLower = cap.description.toLowerCase();
      final idLower = cap.id.toLowerCase();
      var match = false;
      for (final kw in lower) {
        if (descLower.contains(kw) || idLower.contains(kw)) {
          match = true;
          break;
        }
      }
      if (match) results.add(cap);
    }
    return results;
  }

  List<Capability> findByName(String name) {
    final lower = name.toLowerCase();
    return _capabilities.values.where((c) =>
      c.id.toLowerCase().contains(lower) ||
      c.description.toLowerCase().contains(lower)
    ).toList();
  }

  Map<String, dynamic> getStats() {
    final catCounts = <String, int>{};
    for (final cap in _capabilities.values) {
      final cat = cap.category.name;
      catCounts[cat] = (catCounts[cat] ?? 0) + 1;
    }
    return {
      'total': _capabilities.length,
      'byCategory': catCounts,
    };
  }

  void _register(Capability cap) {
    _capabilities[cap.id] = cap;
    _categoryIndex.putIfAbsent(cap.category.name, () => []).add(cap);
    _operationIndex.putIfAbsent(cap.operation.name, () => []).add(cap);
  }

  void _registerAll() {
    _registerApplication();
    _registerContact();
    _registerCall();
    _registerWhatsApp();
    _registerMessage();
    _registerVolume();
    _registerBrightness();
    _registerTorch();
    _registerMedia();
    _registerYouTube();
    _registerAlarm();
    _registerTimer();
    _registerReminder();
    _registerDateTime();
    _registerWeather();
    _registerWeb();
    _registerWifi();
    _registerBluetooth();
    _registerNetwork();
    _registerLocation();
    _registerAccessibility();
    _registerScreenInteraction();
    _registerNotification();
    _registerDevice();
    _registerSettings();
    _registerScreenControl();
    _registerRotation();
    _registerDnd();
    _registerClipboard();
    _registerCamera();
    _registerFile();
  }

  void _registerApplication() {
    const cat = CapabilityCategory.application;
    _register(const Capability(id: 'OPEN_APPLICATION', category: cat, description: 'Open an application by name', operation: Operation.open, requiredParameters: ['appName']));
    _register(const Capability(id: 'CLOSE_APPLICATION', category: cat, description: 'Close an application', operation: Operation.close, requiredParameters: ['appName']));
    _register(const Capability(id: 'FIND_INSTALLED_APPLICATION', category: cat, description: 'Check if an app is installed', operation: Operation.find, requiredParameters: ['appName']));
    _register(const Capability(id: 'LIST_INSTALLED_APPLICATIONS', category: cat, description: 'List all installed applications', operation: Operation.list));
    _register(const Capability(id: 'GET_FOREGROUND_APPLICATION', category: cat, description: 'Get currently running foreground app', operation: Operation.get));
    _register(const Capability(id: 'OPEN_APPLICATION_INFO', category: cat, description: 'Open app info page for an application', operation: Operation.open, requiredParameters: ['appName']));
    _register(const Capability(id: 'OPEN_APPLICATION_SETTINGS', category: cat, description: 'Open settings of an application', operation: Operation.open, requiredParameters: ['appName']));
    _register(const Capability(id: 'OPEN_APPLICATION_NOTIFICATION_SETTINGS', category: cat, description: 'Open notification settings for an app', operation: Operation.open, requiredParameters: ['appName']));
    _register(const Capability(id: 'OPEN_APPLICATION_PERMISSION_SETTINGS', category: cat, description: 'Open permission settings for an app', operation: Operation.open, requiredParameters: ['appName']));
    _register(const Capability(id: 'OPEN_DEFAULT_APPLICATION_SETTINGS', category: cat, description: 'Open default app settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_URL', category: cat, description: 'Open a URL in browser', operation: Operation.open, requiredParameters: ['url']));
    _register(const Capability(id: 'OPEN_DEEP_LINK', category: cat, description: 'Open a deep link URI', operation: Operation.open, requiredParameters: ['uri']));
    _register(const Capability(id: 'OPEN_FILE_WITH_APPLICATION', category: cat, description: 'Open a file with a specific app', operation: Operation.open, requiredParameters: ['filePath', 'appName']));
    _register(const Capability(id: 'SHARE_TEXT', category: cat, description: 'Share text content via system share sheet', operation: Operation.share, requiredParameters: ['text']));
    _register(const Capability(id: 'SHARE_FILE', category: cat, description: 'Share a file via system share sheet', operation: Operation.share, requiredParameters: ['filePath']));
  }

  void _registerContact() {
    const cat = CapabilityCategory.contact;
    _register(const Capability(id: 'FIND_CONTACT', category: cat, description: 'Find a contact by name', operation: Operation.find, requiredParameters: ['contactName']));
    _register(const Capability(id: 'SEARCH_CONTACTS', category: cat, description: 'Search contacts by query', operation: Operation.search, requiredParameters: ['query']));
    _register(const Capability(id: 'GET_CONTACT_PHONE_NUMBERS', category: cat, description: 'Get phone numbers for a contact', operation: Operation.get, requiredParameters: ['contactName']));
    _register(const Capability(id: 'RESOLVE_CONTACT', category: cat, description: 'Resolve a contact name to a phone number', operation: Operation.resolve, requiredParameters: ['contactName']));
    _register(const Capability(id: 'OPEN_CONTACT', category: cat, description: 'Open a contact in the contacts app', operation: Operation.open, requiredParameters: ['contactName']));
    _register(const Capability(id: 'CREATE_CONTACT', category: cat, description: 'Create a new contact', operation: Operation.create, requiredParameters: ['contactName'], optionalParameters: ['phoneNumber']));
    _register(const Capability(id: 'EDIT_CONTACT', category: cat, description: 'Edit an existing contact', operation: Operation.update, requiredParameters: ['contactName']));
    _register(const Capability(id: 'OPEN_CONTACT_PICKER', category: cat, description: 'Open contact picker for user selection', operation: Operation.open));
  }

  void _registerCall() {
    const cat = CapabilityCategory.call;
    _register(const Capability(id: 'DIAL_NUMBER', category: cat, description: 'Dial a phone number', operation: Operation.dial, requiredParameters: ['phoneNumber']));
    _register(const Capability(id: 'CALL_NUMBER', category: cat, description: 'Call a phone number directly', operation: Operation.call, requiredParameters: ['phoneNumber']));
    _register(const Capability(id: 'CALL_CONTACT', category: cat, description: 'Call a saved contact by name', operation: Operation.call, requiredParameters: ['contactName']));
    _register(const Capability(id: 'REDIAL_LAST_SUPPORTED_CALL', category: cat, description: 'Redial the last called number', operation: Operation.call, requiredPermissions: ['android.permission.READ_CALL_LOG']));
    _register(const Capability(id: 'OPEN_DIALER', category: cat, description: 'Open the phone dialer app', operation: Operation.open));
  }

  void _registerWhatsApp() {
    const cat = CapabilityCategory.whatsapp;
    _register(const Capability(id: 'OPEN_WHATSAPP', category: cat, description: 'Open WhatsApp application', operation: Operation.open));
    _register(const Capability(id: 'OPEN_WHATSAPP_CONTACT', category: cat, description: 'Open WhatsApp chat with a contact', operation: Operation.open, requiredParameters: ['contactName']));
    _register(const Capability(id: 'OPEN_WHATSAPP_CHAT', category: cat, description: 'Open WhatsApp chat by phone number', operation: Operation.open, requiredParameters: ['phoneNumber']));
    _register(const Capability(id: 'PREPARE_WHATSAPP_MESSAGE', category: cat, description: 'Compose a WhatsApp message for a contact', operation: Operation.prepare, requiredParameters: ['contactName', 'message']));
    _register(const Capability(id: 'SEND_WHATSAPP_MESSAGE', category: cat, description: 'Send a WhatsApp message to a contact', operation: Operation.send, requiredParameters: ['contactName', 'message'], riskLevel: RiskLevel.medium, requiresConfirmation: true));
    _register(const Capability(id: 'START_WHATSAPP_AUDIO_CALL', category: cat, description: 'Start a WhatsApp audio call', operation: Operation.call, requiredParameters: ['contactName']));
    _register(const Capability(id: 'START_WHATSAPP_VIDEO_CALL', category: cat, description: 'Start a WhatsApp video call', operation: Operation.call, requiredParameters: ['contactName']));
    _register(const Capability(id: 'OPEN_WHATSAPP_CAMERA', category: cat, description: 'Open WhatsApp camera', operation: Operation.open));
  }

  void _registerMessage() {
    const cat = CapabilityCategory.message;
    _register(const Capability(id: 'PREPARE_SMS', category: cat, description: 'Compose an SMS message', operation: Operation.prepare, requiredParameters: ['contactName', 'message']));
    _register(const Capability(id: 'SEND_SMS', category: cat, description: 'Send an SMS message', operation: Operation.send, requiredParameters: ['contactName', 'message'], riskLevel: RiskLevel.medium, requiresConfirmation: true));
    _register(const Capability(id: 'OPEN_SMS_COMPOSER', category: cat, description: 'Open SMS composer with optional recipient', operation: Operation.open, optionalParameters: ['contactName']));
    _register(const Capability(id: 'PREPARE_MESSAGE', category: cat, description: 'Compose a message via any messaging app', operation: Operation.prepare, requiredParameters: ['contactName', 'message']));
    _register(const Capability(id: 'CONFIRM_MESSAGE', category: cat, description: 'Confirm and send a pending composed message', operation: Operation.confirm, requiredParameters: ['contactName', 'message']));
    _register(const Capability(id: 'SHARE_MESSAGE', category: cat, description: 'Share a text message via share sheet', operation: Operation.share, requiredParameters: ['message']));
  }

  void _registerVolume() {
    const cat = CapabilityCategory.volume;
    _register(const Capability(id: 'GET_VOLUME', category: cat, description: 'Get current volume level', operation: Operation.get, optionalParameters: ['streamType']));
    _register(const Capability(id: 'SET_VOLUME', category: cat, description: 'Set volume to a specific percentage', operation: Operation.set, requiredParameters: ['percentage'], optionalParameters: ['streamType']));
    _register(const Capability(id: 'INCREASE_VOLUME', category: cat, description: 'Increase volume by one step', operation: Operation.increase, optionalParameters: ['streamType']));
    _register(const Capability(id: 'DECREASE_VOLUME', category: cat, description: 'Decrease volume by one step', operation: Operation.decrease, optionalParameters: ['streamType']));
    _register(const Capability(id: 'MUTE_VOLUME', category: cat, description: 'Mute the volume', operation: Operation.mute, optionalParameters: ['streamType']));
    _register(const Capability(id: 'UNMUTE_VOLUME', category: cat, description: 'Unmute the volume', operation: Operation.unmute, optionalParameters: ['streamType']));
    _register(const Capability(id: 'MAXIMIZE_VOLUME', category: cat, description: 'Set volume to maximum', operation: Operation.maximize, optionalParameters: ['streamType']));
    _register(const Capability(id: 'MINIMIZE_VOLUME', category: cat, description: 'Set volume to minimum (not mute)', operation: Operation.minimize, optionalParameters: ['streamType']));
    _register(const Capability(id: 'SET_MEDIA_VOLUME', category: cat, description: 'Set media playback volume', operation: Operation.set, requiredParameters: ['percentage']));
    _register(const Capability(id: 'SET_RING_VOLUME', category: cat, description: 'Set ringtone volume', operation: Operation.set, requiredParameters: ['percentage']));
    _register(const Capability(id: 'SET_ALARM_VOLUME', category: cat, description: 'Set alarm volume', operation: Operation.set, requiredParameters: ['percentage']));
  }

  void _registerBrightness() {
    const cat = CapabilityCategory.brightness;
    _register(const Capability(id: 'GET_BRIGHTNESS', category: cat, description: 'Get current screen brightness', operation: Operation.get));
    _register(const Capability(id: 'SET_BRIGHTNESS', category: cat, description: 'Set screen brightness to a percentage', operation: Operation.set, requiredParameters: ['percentage']));
    _register(const Capability(id: 'INCREASE_BRIGHTNESS', category: cat, description: 'Increase brightness by one step', operation: Operation.increase));
    _register(const Capability(id: 'DECREASE_BRIGHTNESS', category: cat, description: 'Decrease brightness by one step', operation: Operation.decrease));
    _register(const Capability(id: 'MAXIMIZE_BRIGHTNESS', category: cat, description: 'Set brightness to maximum', operation: Operation.maximize));
    _register(const Capability(id: 'MINIMIZE_BRIGHTNESS', category: cat, description: 'Set brightness to minimum', operation: Operation.minimize));
    _register(const Capability(id: 'ENABLE_AUTO_BRIGHTNESS', category: cat, description: 'Enable automatic brightness adjustment', operation: Operation.enable));
    _register(const Capability(id: 'DISABLE_AUTO_BRIGHTNESS', category: cat, description: 'Disable automatic brightness adjustment', operation: Operation.disable));
    _register(const Capability(id: 'OPEN_BRIGHTNESS_SETTINGS', category: cat, description: 'Open brightness display settings', operation: Operation.open));
  }

  void _registerTorch() {
    const cat = CapabilityCategory.torch;
    _register(const Capability(id: 'GET_TORCH_STATE', category: cat, description: 'Get current flashlight state', operation: Operation.get));
    _register(const Capability(id: 'TURN_TORCH_ON', category: cat, description: 'Turn on the flashlight', operation: Operation.start));
    _register(const Capability(id: 'TURN_TORCH_OFF', category: cat, description: 'Turn off the flashlight', operation: Operation.stop));
    _register(const Capability(id: 'TOGGLE_TORCH', category: cat, description: 'Toggle the flashlight on/off', operation: Operation.toggle));
  }

  void _registerMedia() {
    const cat = CapabilityCategory.media;
    _register(const Capability(id: 'MEDIA_PLAY', category: cat, description: 'Start or resume media playback', operation: Operation.start));
    _register(const Capability(id: 'MEDIA_PAUSE', category: cat, description: 'Pause media playback', operation: Operation.stop));
    _register(const Capability(id: 'MEDIA_RESUME', category: cat, description: 'Resume paused media playback', operation: Operation.start));
    _register(const Capability(id: 'MEDIA_STOP', category: cat, description: 'Stop media playback completely', operation: Operation.stop));
    _register(const Capability(id: 'MEDIA_NEXT', category: cat, description: 'Play next media track', operation: Operation.execute));
    _register(const Capability(id: 'MEDIA_PREVIOUS', category: cat, description: 'Play previous media track', operation: Operation.execute));
    _register(const Capability(id: 'GET_MEDIA_STATE', category: cat, description: 'Get current media playback state', operation: Operation.get));
    _register(const Capability(id: 'GET_CURRENT_MEDIA', category: cat, description: 'Get currently playing media info', operation: Operation.get));
    _register(const Capability(id: 'OPEN_MEDIA_APPLICATION', category: cat, description: 'Open the current media playback app', operation: Operation.open));
    _register(const Capability(id: 'SEARCH_MEDIA', category: cat, description: 'Search for media content', operation: Operation.search, requiredParameters: ['query']));
    _register(const Capability(id: 'PLAY_MEDIA_QUERY', category: cat, description: 'Play media by search query', operation: Operation.start, requiredParameters: ['query']));
  }

  void _registerYouTube() {
    const cat = CapabilityCategory.youtube;
    _register(const Capability(id: 'OPEN_YOUTUBE', category: cat, description: 'Open YouTube application', operation: Operation.open));
    _register(const Capability(id: 'SEARCH_YOUTUBE', category: cat, description: 'Search YouTube for a query', operation: Operation.search, requiredParameters: ['query']));
    _register(const Capability(id: 'PLAY_YOUTUBE_QUERY', category: cat, description: 'Play YouTube video by search query', operation: Operation.start, requiredParameters: ['query']));
    _register(const Capability(id: 'OPEN_YOUTUBE_URL', category: cat, description: 'Open a YouTube video by URL', operation: Operation.open, requiredParameters: ['url']));
  }

  void _registerAlarm() {
    const cat = CapabilityCategory.alarm;
    _register(const Capability(id: 'SET_ALARM', category: cat, description: 'Set an alarm at a specific time', operation: Operation.create, requiredParameters: ['hour', 'minute']));
    _register(const Capability(id: 'SHOW_ALARMS', category: cat, description: 'Show all active alarms', operation: Operation.list));
    _register(const Capability(id: 'OPEN_CLOCK_APPLICATION', category: cat, description: 'Open the Clock application', operation: Operation.open));
    _register(const Capability(id: 'DISMISS_SUPPORTED_ALARM', category: cat, description: 'Dismiss an active alarm', operation: Operation.dismiss));
    _register(const Capability(id: 'SNOOZE_SUPPORTED_ALARM', category: cat, description: 'Snooze an active alarm', operation: Operation.execute));
  }

  void _registerTimer() {
    const cat = CapabilityCategory.timer;
    _register(const Capability(id: 'SET_TIMER', category: cat, description: 'Set a countdown timer', operation: Operation.create, requiredParameters: ['duration']));
    _register(const Capability(id: 'SHOW_TIMERS', category: cat, description: 'Show all active timers', operation: Operation.list));
    _register(const Capability(id: 'OPEN_TIMER', category: cat, description: 'Open the Timer section in Clock app', operation: Operation.open));
    _register(const Capability(id: 'DISMISS_SUPPORTED_TIMER', category: cat, description: 'Dismiss an active timer', operation: Operation.dismiss));
  }

  void _registerReminder() {
    const cat = CapabilityCategory.reminder;
    _register(const Capability(id: 'CREATE_REMINDER', category: cat, description: 'Create a new reminder', operation: Operation.create, requiredParameters: ['title'], optionalParameters: ['time', 'date']));
    _register(const Capability(id: 'UPDATE_REMINDER', category: cat, description: 'Update an existing reminder', operation: Operation.update, requiredParameters: ['reminderId']));
    _register(const Capability(id: 'DELETE_REMINDER', category: cat, description: 'Delete a reminder', operation: Operation.delete, requiredParameters: ['reminderId']));
    _register(const Capability(id: 'GET_REMINDER', category: cat, description: 'Get details of a specific reminder', operation: Operation.get, requiredParameters: ['reminderId']));
    _register(const Capability(id: 'LIST_REMINDERS', category: cat, description: 'List all active reminders', operation: Operation.list));
    _register(const Capability(id: 'COMPLETE_REMINDER', category: cat, description: 'Mark a reminder as completed', operation: Operation.execute, requiredParameters: ['reminderId']));
    _register(const Capability(id: 'SNOOZE_REMINDER', category: cat, description: 'Snooze a reminder for later', operation: Operation.execute, requiredParameters: ['reminderId']));
  }

  void _registerDateTime() {
    const cat = CapabilityCategory.datetime;
    _register(const Capability(id: 'GET_CURRENT_TIME', category: cat, description: 'Get current time', operation: Operation.get));
    _register(const Capability(id: 'GET_CURRENT_DATE', category: cat, description: 'Get current date', operation: Operation.get));
    _register(const Capability(id: 'GET_DAY', category: cat, description: 'Get current day of the week', operation: Operation.get));
    _register(const Capability(id: 'PARSE_RELATIVE_TIME', category: cat, description: 'Parse a relative time expression', operation: Operation.get, requiredParameters: ['text']));
    _register(const Capability(id: 'PARSE_NATURAL_DATE_TIME', category: cat, description: 'Parse a natural date-time expression', operation: Operation.get, requiredParameters: ['text']));
  }

  void _registerWeather() {
    const cat = CapabilityCategory.weather;
    _register(const Capability(id: 'GET_WEATHER', category: cat, description: 'Get current weather', operation: Operation.get));
    _register(const Capability(id: 'GET_CURRENT_LOCATION_WEATHER', category: cat, description: 'Get weather at current location', operation: Operation.get, requiredPermissions: ['android.permission.ACCESS_FINE_LOCATION']));
    _register(const Capability(id: 'GET_CITY_WEATHER', category: cat, description: 'Get weather for a specific city', operation: Operation.get, requiredParameters: ['city']));
    _register(const Capability(id: 'GET_TEMPERATURE', category: cat, description: 'Get current temperature', operation: Operation.get));
    _register(const Capability(id: 'GET_WEATHER_FORECAST', category: cat, description: 'Get weather forecast for coming days', operation: Operation.get, optionalParameters: ['city']));
  }

  void _registerWeb() {
    const cat = CapabilityCategory.web;
    _register(const Capability(id: 'WEB_SEARCH', category: cat, description: 'Search the web via Google', operation: Operation.search, requiredParameters: ['query']));
    _register(const Capability(id: 'OPEN_SEARCH_RESULT', category: cat, description: 'Open a Google search result', operation: Operation.open, requiredParameters: ['query']));
    _register(const Capability(id: 'OPEN_BROWSER', category: cat, description: 'Open the default web browser', operation: Operation.open));
    _register(const Capability(id: 'SEARCH_QUERY', category: cat, description: 'General web search with a query', operation: Operation.search, requiredParameters: ['query']));
  }

  void _registerWifi() {
    const cat = CapabilityCategory.wifi;
    _register(const Capability(id: 'GET_WIFI_STATE', category: cat, description: 'Get current WiFi state', operation: Operation.get));
    _register(const Capability(id: 'ENABLE_WIFI_IF_SUPPORTED', category: cat, description: 'Turn on WiFi', operation: Operation.enable));
    _register(const Capability(id: 'DISABLE_WIFI_IF_SUPPORTED', category: cat, description: 'Turn off WiFi', operation: Operation.disable));
    _register(const Capability(id: 'OPEN_WIFI_PANEL', category: cat, description: 'Open WiFi quick settings panel', operation: Operation.open));
    _register(const Capability(id: 'OPEN_WIFI_SETTINGS', category: cat, description: 'Open WiFi settings page', operation: Operation.open));
    _register(const Capability(id: 'GET_CONNECTED_WIFI_INFORMATION', category: cat, description: 'Get details of connected WiFi network', operation: Operation.get));
  }

  void _registerBluetooth() {
    const cat = CapabilityCategory.bluetooth;
    _register(const Capability(id: 'GET_BLUETOOTH_STATE', category: cat, description: 'Get current Bluetooth state', operation: Operation.get));
    _register(const Capability(id: 'ENABLE_BLUETOOTH_IF_SUPPORTED', category: cat, description: 'Turn on Bluetooth', operation: Operation.enable));
    _register(const Capability(id: 'DISABLE_BLUETOOTH_IF_SUPPORTED', category: cat, description: 'Turn off Bluetooth', operation: Operation.disable));
    _register(const Capability(id: 'OPEN_BLUETOOTH_SETTINGS', category: cat, description: 'Open Bluetooth settings page', operation: Operation.open));
    _register(const Capability(id: 'OPEN_BLUETOOTH_PANEL', category: cat, description: 'Open Bluetooth quick settings panel', operation: Operation.open));
    _register(const Capability(id: 'GET_BONDED_DEVICES', category: cat, description: 'Get list of paired Bluetooth devices', operation: Operation.get));
  }

  void _registerNetwork() {
    const cat = CapabilityCategory.network;
    _register(const Capability(id: 'OPEN_MOBILE_NETWORK_SETTINGS', category: cat, description: 'Open mobile network settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_DATA_USAGE_SETTINGS', category: cat, description: 'Open data usage settings', operation: Operation.open));
    _register(const Capability(id: 'GET_NETWORK_STATE', category: cat, description: 'Get current network connectivity state', operation: Operation.get));
    _register(const Capability(id: 'GET_CONNECTION_TYPE', category: cat, description: 'Get type of current connection (WiFi/Mobile/None)', operation: Operation.get));
    _register(const Capability(id: 'OPEN_AIRPLANE_MODE_SETTINGS', category: cat, description: 'Open airplane mode settings', operation: Operation.open));
    _register(const Capability(id: 'SET_MOBILE_DATA_PRIVILEGED', category: cat, description: 'Toggle mobile data via Shizuku/Root', operation: Operation.set, requiredPrivilege: PrivilegeType.shizuku, riskLevel: RiskLevel.medium));
    _register(const Capability(id: 'SET_AIRPLANE_MODE_PRIVILEGED', category: cat, description: 'Toggle airplane mode via Shizuku/Root', operation: Operation.set, requiredPrivilege: PrivilegeType.shizuku, riskLevel: RiskLevel.high, requiresConfirmation: true));
  }

  void _registerLocation() {
    const cat = CapabilityCategory.location;
    _register(const Capability(id: 'GET_CURRENT_LOCATION', category: cat, description: 'Get current GPS location', operation: Operation.get, requiredPermissions: ['android.permission.ACCESS_FINE_LOCATION']));
    _register(const Capability(id: 'CHECK_LOCATION_STATE', category: cat, description: 'Check if GPS/location services are enabled', operation: Operation.get));
    _register(const Capability(id: 'OPEN_LOCATION_SETTINGS', category: cat, description: 'Open location settings page', operation: Operation.open));
    _register(const Capability(id: 'OPEN_MAP', category: cat, description: 'Open Google Maps', operation: Operation.open));
    _register(const Capability(id: 'NAVIGATE_TO_LOCATION', category: cat, description: 'Navigate to a location in Google Maps', operation: Operation.navigate, requiredParameters: ['destination']));
    _register(const Capability(id: 'SEARCH_PLACE', category: cat, description: 'Search for a place in Google Maps', operation: Operation.search, requiredParameters: ['query']));
  }

  void _registerAccessibility() {
    const cat = CapabilityCategory.accessibility;
    _register(const Capability(id: 'GO_BACK', category: cat, description: 'Press the back button', operation: Operation.press, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'GO_HOME', category: cat, description: 'Press the home button', operation: Operation.press, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'OPEN_RECENTS', category: cat, description: 'Open recent apps overview', operation: Operation.press, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'OPEN_NOTIFICATIONS', category: cat, description: 'Open the notification shade', operation: Operation.press, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'OPEN_QUICK_SETTINGS', category: cat, description: 'Open the quick settings panel', operation: Operation.press, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'SCROLL_UP', category: cat, description: 'Scroll up on the current screen', operation: Operation.swipe, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'SCROLL_DOWN', category: cat, description: 'Scroll down on the current screen', operation: Operation.swipe, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'SCROLL_LEFT', category: cat, description: 'Scroll left on the current screen', operation: Operation.swipe, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'SCROLL_RIGHT', category: cat, description: 'Scroll right on the current screen', operation: Operation.swipe, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'SWIPE_GESTURE', category: cat, description: 'Perform a custom swipe gesture', operation: Operation.swipe, requiredParameters: ['startX', 'startY', 'endX', 'endY'], requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'CLICK_VISIBLE_TEXT', category: cat, description: 'Click on visible text on screen', operation: Operation.click, requiredParameters: ['text'], requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'CLICK_VISIBLE_ELEMENT', category: cat, description: 'Click a visible UI element by description', operation: Operation.click, requiredParameters: ['elementDescription'], requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'LONG_CLICK_VISIBLE_ELEMENT', category: cat, description: 'Long-press a visible UI element', operation: Operation.longPress, requiredParameters: ['elementDescription'], requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'FOCUS_VISIBLE_ELEMENT', category: cat, description: 'Focus a visible UI element by description', operation: Operation.click, requiredParameters: ['elementDescription'], requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'SET_VISIBLE_TEXT', category: cat, description: 'Type text into a focused text field', operation: Operation.type, requiredParameters: ['text'], requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'CLEAR_VISIBLE_TEXT', category: cat, description: 'Clear text from a focused text field', operation: Operation.clear, requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'FIND_VISIBLE_TEXT', category: cat, description: 'Check if text is visible on current screen', operation: Operation.find, requiredParameters: ['text'], requiredService: ServiceType.accessibility));
    _register(const Capability(id: 'GET_CURRENT_WINDOW_TITLE', category: cat, description: 'Get the title of the current window', operation: Operation.get, requiredService: ServiceType.accessibility));
  }

  void _registerScreenInteraction() {
    const cat = CapabilityCategory.screenInteraction;
    _register(const Capability(id: 'TAP_COORDINATE', category: cat, description: 'Tap at screen coordinates', operation: Operation.tap, requiredParameters: ['x', 'y']));
    _register(const Capability(id: 'LONG_PRESS_COORDINATE', category: cat, description: 'Long-press at screen coordinates', operation: Operation.longPress, requiredParameters: ['x', 'y']));
    _register(const Capability(id: 'SWIPE_COORDINATES', category: cat, description: 'Swipe between two screen coordinates', operation: Operation.swipe, requiredParameters: ['startX', 'startY', 'endX', 'endY']));
    _register(const Capability(id: 'TYPE_TEXT_IN_FOCUSED_FIELD', category: cat, description: 'Type text into the currently focused field', operation: Operation.type, requiredParameters: ['text']));
    _register(const Capability(id: 'PRESS_ENTER', category: cat, description: 'Press the enter key', operation: Operation.press));
    _register(const Capability(id: 'PRESS_BACK', category: cat, description: 'Press the back button', operation: Operation.press));
    _register(const Capability(id: 'PRESS_HOME', category: cat, description: 'Press the home button', operation: Operation.press));
  }

  void _registerNotification() {
    const cat = CapabilityCategory.notification;
    _register(const Capability(id: 'LIST_NOTIFICATIONS', category: cat, description: 'List all current notifications', operation: Operation.list, requiredService: ServiceType.notificationListener));
    _register(const Capability(id: 'READ_NOTIFICATIONS', category: cat, description: 'Read content of current notifications', operation: Operation.read, requiredService: ServiceType.notificationListener));
    _register(const Capability(id: 'READ_APPLICATION_NOTIFICATIONS', category: cat, description: 'Read notifications from a specific app', operation: Operation.read, requiredParameters: ['appName'], requiredService: ServiceType.notificationListener));
    _register(const Capability(id: 'FIND_NOTIFICATION', category: cat, description: 'Find a notification matching a query', operation: Operation.find, requiredParameters: ['query'], requiredService: ServiceType.notificationListener));
    _register(const Capability(id: 'OPEN_NOTIFICATION', category: cat, description: 'Open/interact with a specific notification', operation: Operation.open, requiredParameters: ['notificationKey'], requiredService: ServiceType.notificationListener));
    _register(const Capability(id: 'DISMISS_NOTIFICATION', category: cat, description: 'Dismiss a specific notification', operation: Operation.dismiss, requiredParameters: ['notificationKey'], requiredService: ServiceType.notificationListener, riskLevel: RiskLevel.low));
    _register(const Capability(id: 'DISMISS_APPLICATION_NOTIFICATIONS', category: cat, description: 'Dismiss all notifications from an app', operation: Operation.dismiss, requiredParameters: ['appName'], requiredService: ServiceType.notificationListener, riskLevel: RiskLevel.low));
  }

  void _registerDevice() {
    const cat = CapabilityCategory.device;
    _register(const Capability(id: 'GET_BATTERY_LEVEL', category: cat, description: 'Get current battery percentage', operation: Operation.get));
    _register(const Capability(id: 'GET_CHARGING_STATE', category: cat, description: 'Get whether device is charging', operation: Operation.get));
    _register(const Capability(id: 'GET_DEVICE_MODEL', category: cat, description: 'Get device model name', operation: Operation.get));
    _register(const Capability(id: 'GET_ANDROID_VERSION', category: cat, description: 'Get Android version', operation: Operation.get));
    _register(const Capability(id: 'GET_STORAGE_INFORMATION', category: cat, description: 'Get device storage information', operation: Operation.get));
    _register(const Capability(id: 'GET_MEMORY_INFORMATION', category: cat, description: 'Get device memory/RAM information', operation: Operation.get));
    _register(const Capability(id: 'GET_NETWORK_INFORMATION', category: cat, description: 'Get network connectivity information', operation: Operation.get));
  }

  void _registerSettings() {
    const cat = CapabilityCategory.settings;
    _register(const Capability(id: 'OPEN_SETTINGS', category: cat, description: 'Open main settings app', operation: Operation.open));
    _register(const Capability(id: 'OPEN_DISPLAY_SETTINGS', category: cat, description: 'Open display settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_SOUND_SETTINGS', category: cat, description: 'Open sound settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_APPLICATION_SETTINGS', category: cat, description: 'Open app settings/management', operation: Operation.open));
    _register(const Capability(id: 'OPEN_ACCESSIBILITY_SETTINGS', category: cat, description: 'Open accessibility settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_NOTIFICATION_SETTINGS', category: cat, description: 'Open notification settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_BATTERY_SETTINGS', category: cat, description: 'Open battery settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_LOCATION_SETTINGS', category: cat, description: 'Open location settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_SECURITY_SETTINGS', category: cat, description: 'Open security settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_DATE_TIME_SETTINGS', category: cat, description: 'Open date and time settings', operation: Operation.open));
    _register(const Capability(id: 'OPEN_LANGUAGE_SETTINGS', category: cat, description: 'Open language and input settings', operation: Operation.open));
  }

  void _registerScreenControl() {
    const cat = CapabilityCategory.screenControl;
    _register(const Capability(id: 'WAKE_SCREEN', category: cat, description: 'Turn on/wake the screen', operation: Operation.wake));
    _register(const Capability(id: 'KEEP_SCREEN_AWAKE', category: cat, description: 'Keep screen on until manually locked', operation: Operation.enable));
    _register(const Capability(id: 'RELEASE_KEEP_SCREEN_AWAKE', category: cat, description: 'Release keep-screen-awake lock', operation: Operation.disable));
    _register(const Capability(id: 'GET_SCREEN_STATE', category: cat, description: 'Get screen on/off state', operation: Operation.get));
  }

  void _registerRotation() {
    const cat = CapabilityCategory.rotation;
    _register(const Capability(id: 'GET_ROTATION_STATE', category: cat, description: 'Get current rotation state', operation: Operation.get));
    _register(const Capability(id: 'ENABLE_AUTO_ROTATE', category: cat, description: 'Enable auto-rotation', operation: Operation.enable));
    _register(const Capability(id: 'DISABLE_AUTO_ROTATE', category: cat, description: 'Disable auto-rotation', operation: Operation.disable));
    _register(const Capability(id: 'SET_PORTRAIT_IF_SUPPORTED', category: cat, description: 'Lock screen to portrait orientation', operation: Operation.set));
    _register(const Capability(id: 'SET_LANDSCAPE_IF_SUPPORTED', category: cat, description: 'Lock screen to landscape orientation', operation: Operation.set));
  }

  void _registerDnd() {
    const cat = CapabilityCategory.dnd;
    _register(const Capability(id: 'GET_DND_STATE', category: cat, description: 'Get Do Not Disturb state', operation: Operation.get));
    _register(const Capability(id: 'ENABLE_DND', category: cat, description: 'Enable Do Not Disturb mode', operation: Operation.enable));
    _register(const Capability(id: 'DISABLE_DND', category: cat, description: 'Disable Do Not Disturb mode', operation: Operation.disable));
    _register(const Capability(id: 'OPEN_DND_ACCESS_SETTINGS', category: cat, description: 'Open DND access settings', operation: Operation.open));
  }

  void _registerClipboard() {
    const cat = CapabilityCategory.clipboard;
    _register(const Capability(id: 'COPY_TEXT', category: cat, description: 'Copy text to clipboard', operation: Operation.copy, requiredParameters: ['text']));
    _register(const Capability(id: 'GET_CLIPBOARD_TEXT', category: cat, description: 'Get text from clipboard', operation: Operation.get));
    _register(const Capability(id: 'CLEAR_CLIPBOARD', category: cat, description: 'Clear the clipboard', operation: Operation.clear));
  }

  void _registerCamera() {
    const cat = CapabilityCategory.camera;
    _register(const Capability(id: 'OPEN_CAMERA', category: cat, description: 'Open the default camera app', operation: Operation.open, requiredPermissions: ['android.permission.CAMERA']));
    _register(const Capability(id: 'OPEN_FRONT_CAMERA_IF_SUPPORTED', category: cat, description: 'Open front-facing camera', operation: Operation.open, requiredPermissions: ['android.permission.CAMERA']));
    _register(const Capability(id: 'OPEN_REAR_CAMERA_IF_SUPPORTED', category: cat, description: 'Open rear-facing camera', operation: Operation.open, requiredPermissions: ['android.permission.CAMERA']));
    _register(const Capability(id: 'OPEN_VIDEO_CAMERA', category: cat, description: 'Open camera in video mode', operation: Operation.open, requiredPermissions: ['android.permission.CAMERA', 'android.permission.RECORD_AUDIO']));
  }

  void _registerFile() {
    const cat = CapabilityCategory.file;
    _register(const Capability(id: 'OPEN_FILE', category: cat, description: 'Open a file with default app', operation: Operation.open, requiredParameters: ['filePath']));
    _register(const Capability(id: 'SHARE_FILE_CAPABILITY', category: cat, description: 'Share a file via share sheet', operation: Operation.share, requiredParameters: ['filePath']));
    _register(const Capability(id: 'OPEN_DOWNLOADS', category: cat, description: 'Open the Downloads folder', operation: Operation.open));
    _register(const Capability(id: 'OPEN_DOCUMENT_PICKER', category: cat, description: 'Open the system document picker', operation: Operation.open));
    _register(const Capability(id: 'SEARCH_USER_SELECTED_FILES', category: cat, description: 'Search within user-selected files', operation: Operation.search, requiredParameters: ['query']));
  }
}
