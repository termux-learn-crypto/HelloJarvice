enum EntityType {
  contact,
  phoneNumber,
  appName,
  packageName,
  message,
  time,
  duration,
  percentage,
  amount,
  city,
  url,
  query,
  direction,
  streamType,
  text,
  number,
  unknown,
}

class Entity {
  final EntityType type;
  final dynamic value;
  final int startIndex;
  final int endIndex;

  const Entity({
    required this.type,
    required this.value,
    this.startIndex = 0,
    this.endIndex = 0,
  });

  Entity copyWith({
    EntityType? type,
    dynamic value,
    int? startIndex,
    int? endIndex,
  }) {
    return Entity(
      type: type ?? this.type,
      value: value ?? this.value,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
    );
  }

  @override
  String toString() => 'Entity(${type.name}, $value)';

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'value': value,
  };
}

class EntityExtractor {
  static final _cities = [
    'delhi', 'mumbai', 'bangalore', 'bengaluru', 'chennai', 'hyderabad',
    'pune', 'ahmedabad', 'jaipur', 'lucknow', 'kolkata', 'nagpur',
    'aurangabad', 'nashik', 'goa', 'indore', 'bhopal', 'surat',
    'visakhapatnam', 'patna', 'chandigarh', 'coimbatore', 'kochi',
  ];

  static final _streamTypes = {
    'music': ['music', 'song', 'gaana', 'media', 'video'],
    'ring': ['ring', 'call', 'ringtone', 'phone', 'aawaz'],
    'alarm': ['alarm', 'timer'],
    'notification': ['notification', 'alert'],
    'system': ['system'],
    'voice': ['voice', 'call'],
  };

  static List<Entity> extract(String text) {
    final entities = <Entity>[];
    final lower = text.toLowerCase();

    _extractCities(lower, entities);
    _extractPercentages(lower, entities);
    _extractDurations(lower, entities);
    _extractTimes(lower, entities);
    _extractPhoneNumbers(text, entities);
    _extractStreamTypes(lower, entities);
    _extractUrls(lower, entities);
    _extractNumbers(lower, entities);

    return entities;
  }

  static void _extractCities(String text, List<Entity> entities) {
    for (final city in _cities) {
      final idx = text.indexOf(city);
      if (idx != -1) {
        entities.add(Entity(
          type: EntityType.city,
          value: city[0].toUpperCase() + city.substring(1),
          startIndex: idx,
          endIndex: idx + city.length,
        ));
      }
    }
  }

  static void _extractPercentages(String text, List<Entity> entities) {
    final patterns = [
      RegExp(r'(\d+)\s*%'),
      RegExp(r'(\d+)\s*percent'),
      RegExp(r'(\d+)\s*prasent'),
    ];
    for (final p in patterns) {
      for (final m in p.allMatches(text)) {
        final val = int.tryParse(m.group(1) ?? '');
        if (val != null && val >= 0 && val <= 100) {
          entities.add(Entity(
            type: EntityType.percentage,
            value: val,
            startIndex: m.start,
            endIndex: m.end,
          ));
        }
      }
    }
  }

  static void _extractDurations(String text, List<Entity> entities) {
    final patterns = [
      RegExp(r'(\d+)\s*(minute|min|mins)'),
      RegExp(r'(\d+)\s*(hour|ghante|ghanta|hrs?)'),
      RegExp(r'(\d+)\s*(second|sec|seconds)'),
    ];
    for (final p in patterns) {
      for (final m in p.allMatches(text)) {
        final val = int.tryParse(m.group(1) ?? '');
        final unit = m.group(2) ?? '';
        if (val != null) {
          int seconds;
          if (unit.startsWith('h') || unit.contains('ghant')) {
            seconds = val * 3600;
          } else if (unit.startsWith('s') || unit == 'sec') {
            seconds = val;
          } else {
            seconds = val * 60;
          }
          entities.add(Entity(
            type: EntityType.duration,
            value: seconds,
            startIndex: m.start,
            endIndex: m.end,
          ));
        }
      }
    }
  }

  static void _extractTimes(String text, List<Entity> entities) {
    final patterns = [
      RegExp(r'(\d{1,2})\s*[:\.]\s*(\d{2})\s*(am|pm)?', caseSensitive: false),
      RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false),
      RegExp(r'(\d{1,2})\s*baje'),
    ];
    for (final p in patterns) {
      for (final m in p.allMatches(text)) {
        final hour = int.tryParse(m.group(1) ?? '');
        if (hour != null && hour >= 0 && hour <= 23) {
          int minute = 0;
          if (m.groupCount >= 2 && m.group(2) != null) {
            final minVal = int.tryParse(m.group(2) ?? '');
            if (minVal != null) minute = minVal;
          }
          final ampm = m.group(m.groupCount)?.toLowerCase();
          if (ampm == 'pm' && hour < 12) {
            entities.add(Entity(
              type: EntityType.time,
              value: {'hour': hour + 12, 'minute': minute},
              startIndex: m.start,
              endIndex: m.end,
            ));
          } else if (ampm == 'am' && hour == 12) {
            entities.add(Entity(
              type: EntityType.time,
              value: {'hour': 0, 'minute': minute},
              startIndex: m.start,
              endIndex: m.end,
            ));
          } else {
            entities.add(Entity(
              type: EntityType.time,
              value: {'hour': hour, 'minute': minute},
              startIndex: m.start,
              endIndex: m.end,
            ));
          }
        }
      }
    }
  }

  static void _extractPhoneNumbers(String text, List<Entity> entities) {
    final pattern = RegExp(r'\b(\d{10})\b');
    for (final m in pattern.allMatches(text)) {
      entities.add(Entity(
        type: EntityType.phoneNumber,
        value: m.group(1),
        startIndex: m.start,
        endIndex: m.end,
      ));
    }
  }

  static void _extractStreamTypes(String text, List<Entity> entities) {
    for (final entry in _streamTypes.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          entities.add(Entity(
            type: EntityType.streamType,
            value: entry.key,
          ));
          return;
        }
      }
    }
  }

  static void _extractUrls(String text, List<Entity> entities) {
    final pattern = RegExp(r'https?://[^\s]+');
    for (final m in pattern.allMatches(text)) {
      entities.add(Entity(
        type: EntityType.url,
        value: m.group(0),
        startIndex: m.start,
        endIndex: m.end,
      ));
    }
  }

  static void _extractNumbers(String text, List<Entity> entities) {
    final pattern = RegExp(r'\b(\d+)\b');
    for (final m in pattern.allMatches(text)) {
      final alreadyHas = entities.any(
        (e) => e.startIndex <= m.start && e.endIndex >= m.end,
      );
      if (!alreadyHas) {
        final val = int.tryParse(m.group(1) ?? '');
        if (val != null) {
          entities.add(Entity(
            type: EntityType.number,
            value: val,
            startIndex: m.start,
            endIndex: m.end,
          ));
        }
      }
    }
  }

  static String extractAppName(String text) {
    final lower = text.toLowerCase();
    final patterns = [
      RegExp(r'(?:kholo|chalao|open|launch|start|dikhao|chalu)\s+(.+?)(?:\s+ko|\s+pe|\s+me|\s+zara|\s+abhi|\s+please|\s+yaar|\s+jaldi|$)', caseSensitive: false),
      RegExp(r'(.+?)\s+(?:kholo|chalao|open|launch|start)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(lower);
      if (m != null) {
        final name = m.group(1)?.trim() ?? '';
        if (name.isNotEmpty && name.length > 1) {
          return name;
        }
      }
    }
    return '';
  }

  static String extractContactName(String text) {
    final lower = text.toLowerCase();
    final patterns = [
      RegExp(r'(?:call|phone|baat|bula|dial|contact|message|sms|whatsapp|text|bhejo|likho|bol|bolo)\s+(.+?)(?:\s+ko|\s+se|\s+ka|\s+ki|\s+pe|\s+me|\s+zara|\s+abhi|\s+please|\s+yaar|\s+jaldi|\s+na|\s+theek|$)', caseSensitive: false),
      RegExp(r'(.+?)\s+(?:ko\s+)?(?:call|phone|baat|bula|dial|message|sms|whatsapp|text|bhejo|likho)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(lower);
      if (m != null) {
        var name = m.group(1)?.trim() ?? '';
        name = name.replaceAll(RegExp(r'\b(please|mere liye|ek kaam karo|hey jarvis|jarvis|hey jarvice|jarvice|abhi|jaldi|zara|na|yaar|theek hai|kar do|karo)\b'), '').trim();
        if (name.isNotEmpty && name.length > 1 && !_isStopWord(name)) {
          return name[0].toUpperCase() + name.substring(1);
        }
      }
    }
    return '';
  }

  static String extractMessage(String text) {
    final patterns = [
      RegExp(r'(?:bhejo|likho|bolo|message|sms|text)\s+(?:ki|ke liye|hai ki)?\s*(.+)', caseSensitive: false),
      RegExp(r'(?:saying|ki|hai ki)\s+(.+)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text.toLowerCase());
      if (m != null) {
        var msg = m.group(1)?.trim() ?? '';
        msg = msg.replaceAll(RegExp(r'\b(please|mere liye|ek kaam karo|hey jarvis|jarvis|hey jarvice|jarvice|abhi|jaldi|zara|na|yaar|theek hai|kar do|karo)\b'), '').trim();
        if (msg.isNotEmpty) return msg;
      }
    }
    return '';
  }

  static String extractRelativeTime(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('kal')) return 'kal';
    if (lower.contains('parson') || lower.contains('parso')) return 'parson';
    if (lower.contains('subah')) return 'subah';
    if (lower.contains('dopahar')) return 'dopahar';
    if (lower.contains('shaam')) return 'shaam';
    if (lower.contains('raat')) return 'raat';
    if (lower.contains('abhi') || lower.contains('now')) return 'abhi';
    if (lower.contains('baad me') || lower.contains('baad')) return 'baad me';
    if (lower.contains('thodi der')) return 'thodi der baad';
    return '';
  }

  static bool _isStopWord(String word) {
    const stops = {
      'ko', 'se', 'ka', 'ki', 'ke', 'pe', 'me', 'aur', 'ya', 'hai',
      'karo', 'kar', 'do', 'ho', 'na', 'to', 'phir', 'wo', 'ye',
    };
    return stops.contains(word.toLowerCase());
  }
}
