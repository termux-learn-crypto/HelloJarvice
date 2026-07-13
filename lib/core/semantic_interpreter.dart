import 'entity.dart';
import 'capability.dart';
import 'capability_registry.dart';

class Goal {
  final Operation operation;
  final CapabilityCategory? targetCategory;
  final String? targetName;
  final Map<String, dynamic> entities;
  final double confidence;

  const Goal({
    required this.operation,
    this.targetCategory,
    this.targetName,
    this.entities = const {},
    this.confidence = 1.0,
  });

  @override
  String toString() => 'Goal(op: ${operation.name}, cat: ${targetCategory?.name}, target: $targetName, entities: $entities)';
}

class SemanticInterpreter {
  static final SemanticInterpreter instance = SemanticInterpreter._();
  SemanticInterpreter._();

  static final _verbToOperation = <String, Operation>{
    'kholo': Operation.open, 'khol': Operation.open, 'open': Operation.open, 'launch': Operation.open,
    'chalao': Operation.open, 'chalu': Operation.start, 'start': Operation.start, 'dikhao': Operation.open,

    'band': Operation.close, 'band karo': Operation.close, 'close': Operation.close, 'quit': Operation.close,
    'exit': Operation.close, 'kill': Operation.close, 'force stop': Operation.close,

    'call': Operation.call, 'phone': Operation.call, 'bula': Operation.call, 'ring': Operation.call,
    'dial': Operation.dial, 'baat': Operation.call,

    'message': Operation.send, 'sms': Operation.send, 'bhejo': Operation.send, 'likho': Operation.prepare,
    'text': Operation.send, 'bolo': Operation.prepare,

    'whatsapp': Operation.open, 'what\'s app': Operation.open,

    'play': Operation.start, 'chala': Operation.start, 'resume': Operation.start, 'continue': Operation.start,
    'pause': Operation.stop, 'ruk': Operation.stop, 'rok': Operation.stop, 'stop': Operation.stop,
    'next': Operation.execute, 'agla': Operation.execute, 'pichla': Operation.execute,
    'previous': Operation.execute, 'skip': Operation.execute,

    'volume': Operation.set, 'awaaz': Operation.set, 'sound': Operation.set,
    'up': Operation.increase, 'badhao': Operation.increase, 'increase': Operation.increase, 'zyada': Operation.increase,
    'kam': Operation.decrease, 'down': Operation.decrease, 'ghatao': Operation.decrease, 'decrease': Operation.decrease,
    'mute': Operation.mute, 'chup': Operation.mute, 'silence': Operation.mute,
    'unmute': Operation.unmute, 'awaaz do': Operation.unmute,
    'max': Operation.maximize, 'full': Operation.maximize, 'poora': Operation.maximize,
    'min': Operation.minimize, 'low': Operation.minimize,

    'brightness': Operation.set, 'roshni': Operation.set, 'light': Operation.set,

    'torch': Operation.toggle, 'flashlight': Operation.toggle, 'torch on': Operation.start,
    'torch off': Operation.stop, 'flash': Operation.toggle,

    'alarm': Operation.create, 'ghanti': Operation.create, 'remind': Operation.create,
    'set': Operation.create, 'timer': Operation.create, 'countdown': Operation.create,

    'reminder': Operation.create, 'yaad': Operation.create, 'hidaayat': Operation.create,

    'weather': Operation.get, 'mausam': Operation.get, 'tapman': Operation.get, 'temperature': Operation.get,

    'search': Operation.search, 'dhoondo': Operation.search, 'find': Operation.find,
    'google': Operation.search, 'lookup': Operation.find,

    'time': Operation.get, 'waqt': Operation.get, 'kitne baje': Operation.get, 'time kya hai': Operation.get,
    'date': Operation.get, 'din': Operation.get, 'tareekh': Operation.get,

    'wifi': Operation.toggle, 'internet': Operation.toggle, 'network': Operation.get,
    'bluetooth': Operation.toggle, 'bt': Operation.toggle,

    'back': Operation.press, 'peeche': Operation.press, 'home': Operation.press, 'recents': Operation.press,
    'recent apps': Operation.press,

    'scroll': Operation.swipe, 'swipe': Operation.swipe, 'niche': Operation.swipe, 'upar': Operation.swipe,

    'tap': Operation.tap, 'click': Operation.tap, 'press': Operation.press, 'touch': Operation.tap,

    'copy': Operation.copy, 'paste': Operation.copy, 'clipboard': Operation.get,
    'paste karo': Operation.copy,

    'battery': Operation.get, 'charge': Operation.get, 'storage': Operation.get, 'memory': Operation.get,
    'ram': Operation.get,

    'settings': Operation.open, 'preferences': Operation.open, 'option': Operation.open,

    'camera': Operation.open, 'photo': Operation.open, 'picture': Operation.open, 'selfie': Operation.open,
    'video record': Operation.open,

    'share': Operation.share, 'forward': Operation.share,

    'wake': Operation.wake, 'screen on': Operation.wake, 'screen off': Operation.stop,

    'rotate': Operation.set, 'portrait': Operation.set, 'landscape': Operation.set,

    'dnd': Operation.enable, 'do not disturb': Operation.enable, 'silent': Operation.enable,

    'delete': Operation.delete, 'hatao': Operation.delete, 'remove': Operation.delete,

    'check': Operation.get, 'verify': Operation.get, 'batao': Operation.get, 'bata': Operation.get,
    'kitna': Operation.get, 'kitni': Operation.get,
  };

  static final _categoryHints = <String, CapabilityCategory>{
    'app': CapabilityCategory.application, 'application': CapabilityCategory.application,
    'apps': CapabilityCategory.application, 'applications': CapabilityCategory.application,
    'contact': CapabilityCategory.contact, 'contacts': CapabilityCategory.contact,
    'call': CapabilityCategory.call, 'phone': CapabilityCategory.call, 'phone call': CapabilityCategory.call,
    'whatsapp': CapabilityCategory.whatsapp, 'wa': CapabilityCategory.whatsapp,
    'message': CapabilityCategory.message, 'sms': CapabilityCategory.message,
    'text message': CapabilityCategory.message,
    'volume': CapabilityCategory.volume, 'sound': CapabilityCategory.volume, 'audio': CapabilityCategory.volume,
    'ring': CapabilityCategory.volume, 'ringtone': CapabilityCategory.volume,
    'brightness': CapabilityCategory.brightness, 'screen brightness': CapabilityCategory.brightness,
    'torch': CapabilityCategory.torch, 'flashlight': CapabilityCategory.torch, 'flash': CapabilityCategory.torch,
    'media': CapabilityCategory.media, 'music': CapabilityCategory.media, 'song': CapabilityCategory.media,
    'video': CapabilityCategory.media, 'player': CapabilityCategory.media,
    'youtube': CapabilityCategory.youtube, 'yt': CapabilityCategory.youtube,
    'alarm': CapabilityCategory.alarm, 'clock': CapabilityCategory.alarm,
    'timer': CapabilityCategory.timer,
    'reminder': CapabilityCategory.reminder,
    'time': CapabilityCategory.datetime, 'date': CapabilityCategory.datetime, 'day': CapabilityCategory.datetime,
    'weather': CapabilityCategory.weather, 'mausam': CapabilityCategory.weather,
    'web': CapabilityCategory.web, 'browser': CapabilityCategory.web, 'google': CapabilityCategory.web,
    'search': CapabilityCategory.web, 'internet': CapabilityCategory.web,
    'wifi': CapabilityCategory.wifi, 'wi-fi': CapabilityCategory.wifi, 'internet connection': CapabilityCategory.wifi,
    'bluetooth': CapabilityCategory.bluetooth, 'bt': CapabilityCategory.bluetooth,
    'network': CapabilityCategory.network, 'mobile data': CapabilityCategory.network,
    'airplane': CapabilityCategory.network, 'flight mode': CapabilityCategory.network,
    'location': CapabilityCategory.location, 'gps': CapabilityCategory.location, 'map': CapabilityCategory.location,
    'maps': CapabilityCategory.location, 'navigation': CapabilityCategory.location,
    'back': CapabilityCategory.accessibility, 'home screen': CapabilityCategory.accessibility,
    'recent': CapabilityCategory.accessibility, 'notifications': CapabilityCategory.notification,
    'notification': CapabilityCategory.notification, 'alerts': CapabilityCategory.notification,
    'scroll': CapabilityCategory.accessibility, 'swipe': CapabilityCategory.accessibility,
    'tap': CapabilityCategory.screenInteraction, 'click': CapabilityCategory.screenInteraction,
    'battery': CapabilityCategory.device, 'charge': CapabilityCategory.device,
    'storage': CapabilityCategory.device, 'memory': CapabilityCategory.device, 'ram': CapabilityCategory.device,
    'model': CapabilityCategory.device, 'android': CapabilityCategory.device,
    'settings': CapabilityCategory.settings, 'setting': CapabilityCategory.settings,
    'camera': CapabilityCategory.camera, 'photo': CapabilityCategory.camera,
    'file': CapabilityCategory.file, 'folder': CapabilityCategory.file, 'downloads': CapabilityCategory.file,
    'clipboard': CapabilityCategory.clipboard, 'copy': CapabilityCategory.clipboard, 'paste': CapabilityCategory.clipboard,
    'rotate': CapabilityCategory.rotation, 'rotation': CapabilityCategory.rotation,
    'dnd': CapabilityCategory.dnd, 'do not disturb': CapabilityCategory.dnd,
    'screen': CapabilityCategory.screenControl, 'display': CapabilityCategory.screenControl,
  };

  static final _hinglishSynonyms = <String, String>{
    'chalao': 'open', 'kholo': 'open', 'dikhao': 'open',
    'band karo': 'close', 'hatao': 'remove', 'ruk jao': 'stop',
    'bhejo': 'send', 'bolo': 'tell', 'suno': 'listen',
    'ghatao': 'decrease', 'badhao': 'increase',
    'bajao': 'play', 'gaana': 'song', 'sangeet': 'music',
    'subah': 'morning', 'dopahar': 'afternoon', 'shaam': 'evening',
    'raat': 'night', 'abhi': 'now', 'jaldi': 'quickly',
    'please': '', 'yaar': '', 'na': '', 'theek hai': '',
    'ek kaam karo': '', 'mere liye': '', 'kar do': '', 'karo': '',
    'hey jarvice': '', 'jarvice': '',
  };

  String normalizeHinglish(String text) {
    var normalized = text.toLowerCase().trim();
    for (final entry in _hinglishSynonyms.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  List<Goal> interpret(String text) {
    final normalized = normalizeHinglish(text);
    final entities = EntityExtractor.extract(text);
    final entityMap = <String, dynamic>{};
    for (final e in entities) {
      entityMap[e.type.name] = e.value;
    }

    final goals = <Goal>[];

    _interpretVolume(normalized, entityMap, goals);
    _interpretAccessibility(normalized, goals);
    _interpretMedia(normalized, goals);
    _interpretContact(normalized, entityMap, goals);
    _interpretMessage(normalized, entityMap, goals);
    _interpretAlarm(normalized, entityMap, goals);
    _interpretTimer(normalized, entityMap, goals);
    _interpretReminder(normalized, entityMap, goals);
    _interpretWeb(normalized, entityMap, goals);
    _interpretSettings(normalized, goals);
    _interpretDevice(normalized, goals);
    _interpretClipboard(normalized, entityMap, goals);
    _interpretDateTime(normalized, goals);

    if (goals.isEmpty) {
      _interpretGeneric(normalized, entityMap, goals);
    }

    if (goals.isEmpty) {
      _interpretBroad(normalized, entityMap, goals);
    }

    return goals;
  }

  void _interpretVolume(String text, Map<String, dynamic> entities, List<Goal> goals) {
    final stream = (entities['streamType'] as String?) ?? 'music';
    final pct = entities['percentage'] as int?;

    if (text.contains(RegExp(r'mute|chup|silence|sannata'))) {
      goals.add(Goal(operation: Operation.mute, targetCategory: CapabilityCategory.volume, entities: {'streamType': stream}));
      return;
    }
    if (text.contains(RegExp(r'unmute|awaaz do|awaz do'))) {
      goals.add(Goal(operation: Operation.unmute, targetCategory: CapabilityCategory.volume, entities: {'streamType': stream}));
      return;
    }
    if (text.contains(RegExp(r'max volume|full volume|poora volume|poori awaaz'))) {
      goals.add(Goal(operation: Operation.maximize, targetCategory: CapabilityCategory.volume, entities: {'streamType': stream}));
      return;
    }
    if (text.contains(RegExp(r'min volume|low volume|minim')) && !text.contains(RegExp(r'volume'))) {
    } else if (text.contains(RegExp(r'min volume|low volume'))) {
      goals.add(Goal(operation: Operation.minimize, targetCategory: CapabilityCategory.volume, entities: {'streamType': stream}));
      return;
    }

    if (text.contains(RegExp(r'(volume|awaaz|sound).*(up|badhao|increase|zyada|bara|jyada)')) ||
        text.contains(RegExp(r'(up|badhao|increase|zyada|bara|jyada).*(volume|awaaz|sound)')) ||
        text.contains(RegExp(r'volume (badhao|increase|up)'))) {
      goals.add(Goal(operation: Operation.increase, targetCategory: CapabilityCategory.volume, entities: {'streamType': stream}));
      return;
    }
    if (text.contains(RegExp(r'(volume|awaaz|sound).*(down|kam|decrease|ghatao|chota)')) ||
        text.contains(RegExp(r'(down|kam|decrease|ghatao|chota).*(volume|awaaz|sound)')) ||
        text.contains(RegExp(r'volume (kam|decrease|down)'))) {
      goals.add(Goal(operation: Operation.decrease, targetCategory: CapabilityCategory.volume, entities: {'streamType': stream}));
      return;
    }

    if (pct != null && text.contains(RegExp(r'volume|awaaz|sound'))) {
      goals.add(Goal(operation: Operation.set, targetCategory: CapabilityCategory.volume, entities: {'percentage': pct, 'streamType': stream}));
      return;
    }

    if (text.contains(RegExp(r'volume|awaaz|sound|sunai'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.volume, entities: {'streamType': stream}));
    }
  }

  void _interpretAccessibility(String text, List<Goal> goals) {
    if (text.contains(RegExp(r'go back|back karo|peeche|pichhe'))) {
      goals.add(Goal(operation: Operation.press, targetCategory: CapabilityCategory.accessibility, targetName: 'GO_BACK'));
      return;
    }
    if (text.contains(RegExp(r'home|home screen|home page|ghar'))) {
      goals.add(Goal(operation: Operation.press, targetCategory: CapabilityCategory.accessibility, targetName: 'GO_HOME'));
      return;
    }
    if (text.contains(RegExp(r'recent|recent apps|multitask|app switch'))) {
      goals.add(Goal(operation: Operation.press, targetCategory: CapabilityCategory.accessibility, targetName: 'OPEN_RECENTS'));
      return;
    }
    if (text.contains(RegExp(r'notification (shade|bar|panel)|notification (kholo|dikhao)|upar se (niche|down)'))) {
      goals.add(Goal(operation: Operation.press, targetCategory: CapabilityCategory.accessibility, targetName: 'OPEN_NOTIFICATIONS'));
      return;
    }
    if (text.contains(RegExp(r'quick settings|quick panel|control center'))) {
      goals.add(Goal(operation: Operation.press, targetCategory: CapabilityCategory.accessibility, targetName: 'OPEN_QUICK_SETTINGS'));
      return;
    }
    if (text.contains(RegExp(r'scroll (up|niche|down)'))) {
      final dir = text.contains('up') ? 'up' : 'down';
      goals.add(Goal(operation: Operation.swipe, targetCategory: CapabilityCategory.accessibility, targetName: dir == 'up' ? 'SCROLL_UP' : 'SCROLL_DOWN'));
      return;
    }
    if (text.contains(RegExp(r'scroll (left|right)'))) {
      final dir = text.contains('left') ? 'left' : 'right';
      goals.add(Goal(operation: Operation.swipe, targetCategory: CapabilityCategory.accessibility, targetName: dir == 'left' ? 'SCROLL_LEFT' : 'SCROLL_RIGHT'));
      return;
    }
  }

  void _interpretMedia(String text, List<Goal> goals) {
    if (text.contains(RegExp(r'(play|chala|baja|resume|continue).*(music|song|gaana|media|video|playlist)')) ||
        text.contains(RegExp(r'(music|song|gaana|media|video).*(play|chala|baja)'))) {
      goals.add(Goal(operation: Operation.start, targetCategory: CapabilityCategory.media));
      return;
    }
    if (text.contains(RegExp(r'(pause|ruk|rok|stop).*(music|song|gaana|media|video)')) ||
        text.contains(RegExp(r'(music|song|gaana|media|video).*(pause|ruk|rok)'))) {
      goals.add(Goal(operation: Operation.stop, targetCategory: CapabilityCategory.media));
      return;
    }
    if (text.contains(RegExp(r'next (song|track|gaana)|agla (song|gaana)'))) {
      goals.add(Goal(operation: Operation.execute, targetCategory: CapabilityCategory.media, targetName: 'MEDIA_NEXT'));
      return;
    }
    if (text.contains(RegExp(r'prev(ious)? (song|track|gaana)|pichla (song|gaana)'))) {
      goals.add(Goal(operation: Operation.execute, targetCategory: CapabilityCategory.media, targetName: 'MEDIA_PREVIOUS'));
      return;
    }
    if (text.contains(RegExp(r'(youtube|yt).*(search|dhoondo|play|chala)')) ||
        text.contains(RegExp(r'(search|dhoondo|play|chala).*(youtube|yt)')) ||
        text.contains(RegExp(r'youtube (kholo|open)'))) {
      goals.add(Goal(operation: Operation.search, targetCategory: CapabilityCategory.youtube));
      return;
    }
    if (text.contains(RegExp(r'play.*youtube|youtube.*play'))) {
      goals.add(Goal(operation: Operation.start, targetCategory: CapabilityCategory.youtube));
      return;
    }
  }

  void _interpretContact(String text, Map<String, dynamic> entities, List<Goal> goals) {
    final contactName = EntityExtractor.extractContactName(text);

    if (text.contains(RegExp(r'(call|phone|baat|bula|dial).*(contact|number|ko|se)')) ||
        text.contains(RegExp(r'(contact|number).*(call|phone|bula)'))) {
      if (contactName.isNotEmpty) {
        goals.add(Goal(operation: Operation.call, targetCategory: CapabilityCategory.call, targetName: 'CALL_CONTACT', entities: {'contactName': contactName}));
      }
      final phone = entities['phoneNumber'] as String?;
      if (phone != null) {
        goals.add(Goal(operation: Operation.dial, targetCategory: CapabilityCategory.call, targetName: 'DIAL_NUMBER', entities: {'phoneNumber': phone}));
      }
      if (contactName.isEmpty && phone == null) {
        goals.add(Goal(operation: Operation.call, targetCategory: CapabilityCategory.call, targetName: 'CALL_CONTACT', entities: {}));
      }
      return;
    }

    if (text.contains(RegExp(r'whatsapp.*(call|phone|ring|baat|video)')) ||
        text.contains(RegExp(r'(call|phone|video).*(whatsapp|wa)'))) {
      if (contactName.isNotEmpty) {
        goals.add(Goal(operation: Operation.call, targetCategory: CapabilityCategory.whatsapp, targetName: 'START_WHATSAPP_AUDIO_CALL', entities: {'contactName': contactName}));
      }
      return;
    }

    if (text.contains(RegExp(r'whatsapp.*(video call|video)')) || text.contains(RegExp(r'video call.*(whatsapp|wa)'))) {
      if (contactName.isNotEmpty) {
        goals.add(Goal(operation: Operation.call, targetCategory: CapabilityCategory.whatsapp, targetName: 'START_WHATSAPP_VIDEO_CALL', entities: {'contactName': contactName}));
      }
      return;
    }
  }

  void _interpretMessage(String text, Map<String, dynamic> entities, List<Goal> goals) {
    final contactName = EntityExtractor.extractContactName(text);
    final message = EntityExtractor.extractMessage(text);

    if (text.contains(RegExp(r'whatsapp.*(message|bhejo|likho|text|send)')) ||
        text.contains(RegExp(r'(message|bhejo|likho|text|send).*(whatsapp|wa)'))) {
      if (contactName.isNotEmpty && message.isNotEmpty) {
        goals.add(Goal(operation: Operation.send, targetCategory: CapabilityCategory.whatsapp, targetName: 'PREPARE_WHATSAPP_MESSAGE', entities: {'contactName': contactName, 'message': message}));
      } else if (contactName.isNotEmpty) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.whatsapp, targetName: 'OPEN_WHATSAPP_CONTACT', entities: {'contactName': contactName}));
      }
      return;
    }

    if (text.contains(RegExp(r'(sms|message|bhejo|likho|text|send).*(ko|se|ko\b)')) ||
        text.contains(RegExp(r'(sms|message|text).*(bhej|send|likho)'))) {
      if (contactName.isNotEmpty && message.isNotEmpty) {
        goals.add(Goal(operation: Operation.send, targetCategory: CapabilityCategory.message, targetName: 'PREPARE_SMS', entities: {'contactName': contactName, 'message': message}));
      }
      return;
    }

    if (text.contains(RegExp(r'whatsapp (kholo|open|dikhao)'))) {
      if (contactName.isNotEmpty) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.whatsapp, targetName: 'OPEN_WHATSAPP_CONTACT', entities: {'contactName': contactName}));
      } else {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.whatsapp, targetName: 'OPEN_WHATSAPP'));
      }
      return;
    }
  }

  void _interpretAlarm(String text, Map<String, dynamic> entities, List<Goal> goals) {
    if (!text.contains(RegExp(r'alarm|ghanti|reminder|subah|utha'))) return;

    final time = entities['time'] as Map<String, dynamic>?;
    final hour = time?['hour'] as int?;
    final minute = time?['minute'] as int?;

    if (hour != null) {
      goals.add(Goal(operation: Operation.create, targetCategory: CapabilityCategory.alarm, targetName: 'SET_ALARM', entities: {'hour': hour, 'minute': minute ?? 0}));
    } else {
      goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.alarm, targetName: 'SHOW_ALARMS'));
    }
  }

  void _interpretTimer(String text, Map<String, dynamic> entities, List<Goal> goals) {
    if (!text.contains(RegExp(r'timer|countdown'))) return;

    final duration = entities['duration'] as int?;
    if (duration != null) {
      goals.add(Goal(operation: Operation.create, targetCategory: CapabilityCategory.timer, targetName: 'SET_TIMER', entities: {'duration': duration}));
    } else {
      goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.timer, targetName: 'SHOW_TIMERS'));
    }
  }

  void _interpretReminder(String text, Map<String, dynamic> entities, List<Goal> goals) {
    if (!text.contains(RegExp(r'reminder|yaad|dila|yaad dilao|yaad karo|hidaayat'))) return;

    final time = entities['time'] as Map<String, dynamic>?;
    final duration = entities['duration'] as int?;
    final relTime = EntityExtractor.extractRelativeTime(text);

    final remEntities = <String, dynamic>{};
    if (time != null) remEntities['time'] = time;
    if (duration != null) remEntities['duration'] = duration;
    if (relTime.isNotEmpty) remEntities['relativeTime'] = relTime;

    goals.add(Goal(operation: Operation.create, targetCategory: CapabilityCategory.reminder, targetName: 'CREATE_REMINDER', entities: remEntities));
  }

  void _interpretWeb(String text, Map<String, dynamic> entities, List<Goal> goals) {
    if (text.contains(RegExp(r'(google|search|dhoondo|khojo|search karo).*(for|pe|me|ko)')) ||
        text.contains(RegExp(r'(search|dhoondo|khojo)\s+\w+'))) {
      final query = _extractSearchQuery(text);
      if (query.isNotEmpty) {
        goals.add(Goal(operation: Operation.search, targetCategory: CapabilityCategory.web, targetName: 'WEB_SEARCH', entities: {'query': query}));
      }
      return;
    }
    if (text.contains(RegExp(r'(open|kholo|dikhao).*(browser|chrome|firefox)'))) {
      goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.web, targetName: 'OPEN_BROWSER'));
      return;
    }
  }

  void _interpretSettings(String text, List<Goal> goals) {
    if (text.contains(RegExp(r'(open|kholo|dikhao|jao).*(setting|option|preferences)'))) {
      if (text.contains('wifi') || text.contains('wi-fi')) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.settings, targetName: 'OPEN_SETTINGS'));
      } else if (text.contains('bluetooth')) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.bluetooth, targetName: 'OPEN_BLUETOOTH_SETTINGS'));
      } else if (text.contains('display') || text.contains('brightness') || text.contains('screen')) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.settings, targetName: 'OPEN_DISPLAY_SETTINGS'));
      } else if (text.contains('sound') || text.contains('volume')) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.settings, targetName: 'OPEN_SOUND_SETTINGS'));
      } else if (text.contains('location') || text.contains('gps')) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.settings, targetName: 'OPEN_LOCATION_SETTINGS'));
      } else if (text.contains('battery')) {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.settings, targetName: 'OPEN_BATTERY_SETTINGS'));
      } else {
        goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.settings, targetName: 'OPEN_SETTINGS'));
      }
      return;
    }

    if (text.contains(RegExp(r'(toggle|change|set|enable|disable).*(wifi|wi-fi)'))) {
      final enable = !text.contains(RegExp(r'disable|off|band|close|stop'));
      goals.add(Goal(operation: enable ? Operation.enable : Operation.disable, targetCategory: CapabilityCategory.wifi, entities: {'enable': enable}));
      return;
    }
    if (text.contains(RegExp(r'(toggle|change|set|enable|disable).*(bluetooth|bt)'))) {
      final enable = !text.contains(RegExp(r'disable|off|band|close|stop'));
      goals.add(Goal(operation: enable ? Operation.enable : Operation.disable, targetCategory: CapabilityCategory.bluetooth, entities: {'enable': enable}));
      return;
    }
    if (text.contains(RegExp(r'(toggle|change|set|enable|disable).*(dnd|do not disturb|silent)'))) {
      final enable = !text.contains(RegExp(r'disable|off|band|close|stop'));
      goals.add(Goal(operation: enable ? Operation.enable : Operation.disable, targetCategory: CapabilityCategory.dnd, entities: {'enable': enable}));
      return;
    }
    if (text.contains(RegExp(r'(toggle|change|set|enable|disable|auto).*(rotate|rotation|orientation)'))) {
      final enable = text.contains(RegExp(r'auto|enable|on|start'));
      goals.add(Goal(operation: enable ? Operation.enable : Operation.disable, targetCategory: CapabilityCategory.rotation, entities: {'enable': enable}));
      return;
    }

    if (text.contains(RegExp(r'wifi (on|kholo|enable|start)'))) {
      goals.add(Goal(operation: Operation.enable, targetCategory: CapabilityCategory.wifi));
      return;
    }
    if (text.contains(RegExp(r'wifi (off|band|close|disable|stop)'))) {
      goals.add(Goal(operation: Operation.disable, targetCategory: CapabilityCategory.wifi));
      return;
    }
    if (text.contains(RegExp(r'bluetooth (on|kholo|enable|start)'))) {
      goals.add(Goal(operation: Operation.enable, targetCategory: CapabilityCategory.bluetooth));
      return;
    }
    if (text.contains(RegExp(r'bluetooth (off|band|close|disable|stop)'))) {
      goals.add(Goal(operation: Operation.disable, targetCategory: CapabilityCategory.bluetooth));
      return;
    }
  }

  void _interpretDevice(String text, List<Goal> goals) {
    if (text.contains(RegExp(r'battery|charge|battery level|battery kitni'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.device, targetName: 'GET_BATTERY_LEVEL'));
      return;
    }
    if (text.contains(RegExp(r'device (info|model|name|kya hai)')) || text.contains(RegExp(r'phone (model|name|kya hai|ka naam)'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.device, targetName: 'GET_DEVICE_MODEL'));
      return;
    }
    if (text.contains(RegExp(r'android (version|konsi|kya hai)'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.device, targetName: 'GET_ANDROID_VERSION'));
      return;
    }
    if (text.contains(RegExp(r'storage|space|memory|ram|internal'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.device, targetName: 'GET_STORAGE_INFORMATION'));
      return;
    }
  }

  void _interpretClipboard(String text, Map<String, dynamic> entities, List<Goal> goals) {
    if (text.contains(RegExp(r'copy|copied|copy karo'))) {
      final textToCopy = entities['text'] as String? ?? _extractCopyText(text);
      if (textToCopy.isNotEmpty) {
        goals.add(Goal(operation: Operation.copy, targetCategory: CapabilityCategory.clipboard, targetName: 'COPY_TEXT', entities: {'text': textToCopy}));
      }
      return;
    }
    if (text.contains(RegExp(r'paste|paste karo|clipboard'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.clipboard, targetName: 'GET_CLIPBOARD_TEXT'));
      return;
    }
    if (text.contains(RegExp(r'clear clipboard|clipboard (saaf|clear|khatam)'))) {
      goals.add(Goal(operation: Operation.clear, targetCategory: CapabilityCategory.clipboard, targetName: 'CLEAR_CLIPBOARD'));
      return;
    }
  }

  void _interpretDateTime(String text, List<Goal> goals) {
    if (text.contains(RegExp(r'(time|waqt|kitne baje|time kya|samay).*(hai|bata|batao|kya)')) ||
        text.contains(RegExp(r'(bata|batao|kya).*(time|waqt|baje)')) ||
        text.contains(RegExp(r'kitne baje'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.datetime, targetName: 'GET_CURRENT_TIME'));
      return;
    }
    if (text.contains(RegExp(r'(date|tareekh|din|aaj).*(hai|bata|batao|kya)')) ||
        text.contains(RegExp(r'(bata|batao|kya).*(date|tareekh|din)')) ||
        text.contains(RegExp(r'aaj (kya|kaunsa|konsi|hai)'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.datetime, targetName: 'GET_CURRENT_DATE'));
      return;
    }
    if (text.contains(RegExp(r'(day|din).*(hai|bata|batao|kya|kaunsa)')) ||
        text.contains(RegExp(r'(kaunsa|konsa|konsi).*(day|din)'))) {
      goals.add(Goal(operation: Operation.get, targetCategory: CapabilityCategory.datetime, targetName: 'GET_DAY'));
      return;
    }
  }

  void _interpretGeneric(String text, Map<String, dynamic> entities, List<Goal> goals) {
    final appName = EntityExtractor.extractAppName(text);
    if (appName.isNotEmpty) {
      goals.add(Goal(operation: Operation.open, targetCategory: CapabilityCategory.application, targetName: 'OPEN_APPLICATION', entities: {'appName': appName}));
      return;
    }

    final contactName = EntityExtractor.extractContactName(text);
    if (contactName.isNotEmpty) {
      goals.add(Goal(operation: Operation.find, targetCategory: CapabilityCategory.contact, targetName: 'FIND_CONTACT', entities: {'contactName': contactName}));
      return;
    }
  }

  void _interpretBroad(String text, Map<String, dynamic> entities, List<Goal> goals) {
    for (final hint in _categoryHints.entries) {
      if (text.contains(hint.key)) {
        final caps = CapabilityRegistry.instance.getByCategory(hint.value);
        if (caps.isNotEmpty) {
          final operation = _verbToOperation.entries
              .where((e) => text.contains(e.key))
              .map((e) => e.value)
              .firstOrNull;
          if (operation != null) {
            final matching = caps.where((c) => c.operation == operation).toList();
            if (matching.isNotEmpty) {
              goals.add(Goal(operation: operation, targetCategory: hint.value));
              return;
            }
          }
          goals.add(Goal(operation: Operation.open, targetCategory: hint.value));
          return;
        }
      }
    }
  }

  String _extractSearchQuery(String text) {
    var query = text;
    final removePatterns = [
      RegExp(r'(google|search|dhoondo|khojo|pe|me|for|please|yaar|zara|abhi|jaldi|na)', caseSensitive: false),
    ];
    for (final p in removePatterns) {
      query = query.replaceAll(p, ' ');
    }
    query = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (query.isEmpty || query.split(' ').length < 2) return text;
    return query;
  }

  String _extractCopyText(String text) {
    final patterns = [
      RegExp(r'copy\s+(.+)', caseSensitive: false),
      RegExp(r'copied\s+(.+)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final extracted = m.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }
    }
    return '';
  }
}
