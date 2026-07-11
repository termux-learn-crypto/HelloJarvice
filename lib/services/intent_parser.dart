class IntentResult {
  final String action;
  final Map<String, String> params;

  IntentResult({required this.action, required this.params});
}

class IntentParser {
  static final Map<String, List<RegExp>> _englishPatterns = {
    'CALL': [
      RegExp(r'call\s+(\w+)', caseSensitive: false),
      RegExp(r'phone\s+(\w+)', caseSensitive: false),
    ],
    'WHATSAPP': [
      RegExp(r'whatsapp\s+(\w+)\s+(.+)', caseSensitive: false),
      RegExp(r'whatsapp\s+(\w+)', caseSensitive: false),
    ],
    'WIFI_ON': [
      RegExp(r'wifi\s*on', caseSensitive: false),
      RegExp(r'turn\s*on\s*wifi', caseSensitive: false),
    ],
    'WIFI_OFF': [
      RegExp(r'wifi\s*off', caseSensitive: false),
      RegExp(r'turn\s*off\s*wifi', caseSensitive: false),
    ],
    'BLUETOOTH_ON': [
      RegExp(r'bluetooth\s*on', caseSensitive: false),
      RegExp(r'bt\s*on', caseSensitive: false),
    ],
    'BLUETOOTH_OFF': [
      RegExp(r'bluetooth\s*off', caseSensitive: false),
      RegExp(r'bt\s*off', caseSensitive: false),
    ],
    'FLASHLIGHT_ON': [
      RegExp(r'flashlight?\s*on', caseSensitive: false),
      RegExp(r'torch\s*on', caseSensitive: false),
      RegExp(r'light\s*on', caseSensitive: false),
    ],
    'FLASHLIGHT_OFF': [
      RegExp(r'flashlight?\s*off', caseSensitive: false),
      RegExp(r'torch\s*off', caseSensitive: false),
      RegExp(r'light\s*off', caseSensitive: false),
    ],
    'WEATHER': [
      RegExp(r'weather\s*(.*)', caseSensitive: false),
      RegExp(r'temperature\s*(.*)', caseSensitive: false),
    ],
    'TIME': [
      RegExp(r'what\s*time', caseSensitive: false),
      RegExp(r'time\s*now', caseSensitive: false),
      RegExp(r'current\s*time', caseSensitive: false),
    ],
    'ALARM': [
      RegExp(r'alarm\s*set\s*(.*)', caseSensitive: false),
      RegExp(r'set\s*alarm\s*(.*)', caseSensitive: false),
      RegExp(r'alarm\s*(.*)', caseSensitive: false),
    ],
    'SEARCH': [
      RegExp(r'search\s*for\s*(.*)', caseSensitive: false),
      RegExp(r'google\s*(.*)', caseSensitive: false),
      RegExp(r'search\s*(.*)', caseSensitive: false),
    ],
    'NOTE': [
      RegExp(r'note\s*(.*)', caseSensitive: false),
      RegExp(r'write\s*note\s*(.*)', caseSensitive: false),
    ],
    'OPEN': [
      RegExp(r'open\s*(\w+)', caseSensitive: false),
      RegExp(r'launch\s*(\w+)', caseSensitive: false),
    ],
  };

  static final Map<String, List<RegExp>> _hindiPatterns = {
    'CALL': [
      RegExp(r'(\w+)\s*ko\s*call\s*karo', caseSensitive: false),
      RegExp(r'(\w+)\s*ko\s*phone\s*karo', caseSensitive: false),
      RegExp(r'call\s*karo\s*(\w+)', caseSensitive: false),
    ],
    'WHATSAPP': [
      RegExp(r'whatsapp\s*karo\s*(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s*ko\s*whatsapp\s*karo', caseSensitive: false),
      RegExp(r'(\w+)\s*ko\s*message\s*karo\s*(.*)', caseSensitive: false),
    ],
    'WIFI_ON': [
      RegExp(r'wifi\s*on\s*karo', caseSensitive: false),
      RegExp(r'wifi\s*chal[oa]\s*do', caseSensitive: false),
    ],
    'WIFI_OFF': [
      RegExp(r'wifi\s*off\s*karo', caseSensitive: false),
      RegExp(r'wifi\s*band\s*karo', caseSensitive: false),
    ],
    'BLUETOOTH_ON': [
      RegExp(r'bluetooth\s*on\s*karo', caseSensitive: false),
    ],
    'BLUETOOTH_OFF': [
      RegExp(r'bluetooth\s*off\s*karo', caseSensitive: false),
    ],
    'FLASHLIGHT_ON': [
      RegExp(r'(flashlight|torch|light)\s*on\s*karo', caseSensitive: false),
      RegExp(r'(flashlight|torch)\s*chal[ao]\s*do', caseSensitive: false),
    ],
    'FLASHLIGHT_OFF': [
      RegExp(r'(flashlight|torch|light)\s*off\s*karo', caseSensitive: false),
      RegExp(r'(flashlight|torch)\s*band\s*karo', caseSensitive: false),
    ],
    'WEATHER': [
      RegExp(r'(mausam|weather)\s*kya\s*ha[ie]\s*(.*)', caseSensitive: false),
      RegExp(r'(mausam|weather)\s*(.*)', caseSensitive: false),
      RegExp(r'temperature\s*kya\s*ha[ie]', caseSensitive: false),
    ],
    'TIME': [
      RegExp(r'(time|samay|waqt)\s*kya\s*ha[ie]', caseSensitive: false),
      RegExp(r'(time|samay|waqt)\s*bat[ao]', caseSensitive: false),
    ],
    'ALARM': [
      RegExp(r'(alarm|alert)\s*(set|laga|ra)kho\s*(.*)', caseSensitive: false),
      RegExp(r'(alarm|alert)\s*(.*)\s*(baje|laga)', caseSensitive: false),
    ],
    'SEARCH': [
      RegExp(r'search\s*karo\s*(.*)', caseSensitive: false),
      RegExp(r'(search|dhoond|dhundo)\s*(.*)', caseSensitive: false),
      RegExp(r'google\s*pe\s*(.*)', caseSensitive: false),
    ],
    'NOTE': [
      RegExp(r'(note|likho|likhe)\s*(.*)', caseSensitive: false),
      RegExp(r'(yaad|reminder)\s*(.*)', caseSensitive: false),
    ],
    'OPEN': [
      RegExp(r'(open|kholo|khol|chalao|chala)\s*(\w+)', caseSensitive: false),
    ],
  };

  IntentResult parse(String text) {
    String lowerText = text.toLowerCase().trim();

    for (var entry in _englishPatterns.entries) {
      for (var pattern in entry.value) {
        var match = pattern.firstMatch(lowerText);
        if (match != null) {
          return _buildResult(entry.key, match);
        }
      }
    }

    for (var entry in _hindiPatterns.entries) {
      for (var pattern in entry.value) {
        var match = pattern.firstMatch(lowerText);
        if (match != null) {
          return _buildResult(entry.key, match);
        }
      }
    }

    return IntentResult(action: 'UNKNOWN', params: {'text': text});
  }

  IntentResult _buildResult(String action, RegExpMatch match) {
    Map<String, String> params = {};
    for (int i = 1; i < match.groupCount + 1; i++) {
      if (match.group(i) != null && match.group(i)!.isNotEmpty) {
        params['value$i'] = match.group(i)!;
      }
    }
    return IntentResult(action: action, params: params);
  }
}
