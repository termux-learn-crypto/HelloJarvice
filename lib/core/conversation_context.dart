class ConversationContext {
  static final ConversationContext instance = ConversationContext._();
  ConversationContext._();

  String? _lastContactName;
  String? _lastPhoneNumber;
  String? _lastAppName;
  String? _lastPackageName;
  String? _lastMessage;
  String? _lastMedium;
  String? _lastAction;
  String? _lastCapabilityId;
  DateTime? _lastInteractionTime;
  final List<String> _recentContacts = [];
  final List<String> _recentApps = [];

  String? get lastContactName => _lastContactName;
  String? get lastPhoneNumber => _lastPhoneNumber;
  String? get lastAppName => _lastAppName;
  String? get lastPackageName => _lastPackageName;
  String? get lastMessage => _lastMessage;
  String? get lastMedium => _lastMedium;
  String? get lastAction => _lastAction;
  String? get lastCapabilityId => _lastCapabilityId;
  DateTime? get lastInteractionTime => _lastInteractionTime;
  List<String> get recentContacts => List.unmodifiable(_recentContacts);
  List<String> get recentApps => List.unmodifiable(_recentApps);

  bool get isStale {
    if (_lastInteractionTime == null) return true;
    return DateTime.now().difference(_lastInteractionTime!).inMinutes > 5;
  }

  void updateContact(String name, {String? phoneNumber}) {
    _lastContactName = name;
    if (phoneNumber != null) _lastPhoneNumber = phoneNumber;
    _recentContacts.remove(name);
    _recentContacts.insert(0, name);
    if (_recentContacts.length > 10) _recentContacts.removeLast();
    _lastInteractionTime = DateTime.now();
  }

  void updateApp(String appName, {String? packageName}) {
    _lastAppName = appName;
    if (packageName != null) _lastPackageName = packageName;
    _recentApps.remove(appName);
    _recentApps.insert(0, appName);
    if (_recentApps.length > 10) _recentApps.removeLast();
    _lastInteractionTime = DateTime.now();
  }

  void updateMessage(String message) {
    _lastMessage = message;
    _lastInteractionTime = DateTime.now();
  }

  void updateMedium(String medium) {
    _lastMedium = medium;
    _lastInteractionTime = DateTime.now();
  }

  void updateAction(String action, String capabilityId) {
    _lastAction = action;
    _lastCapabilityId = capabilityId;
    _lastInteractionTime = DateTime.now();
  }

  String? resolvePronoun(String text) {
    final lower = text.toLowerCase();
    if (lower.contains(RegExp(r'(usko|usse|uska|uski|that one|woh|that)'))) {
      return _lastContactName;
    }
    if (lower.contains(RegExp(r'(usme|usko open|that app|woh app)'))) {
      return _lastAppName;
    }
    if (lower.contains(RegExp(r'(wahi|same|phir se|dobara|again)')) && _lastCapabilityId != null) {
      return _lastCapabilityId;
    }
    return null;
  }

  Map<String, dynamic> getContext() => {
    'lastContactName': _lastContactName,
    'lastPhoneNumber': _lastPhoneNumber,
    'lastAppName': _lastAppName,
    'lastPackageName': _lastPackageName,
    'lastMessage': _lastMessage,
    'lastMedium': _lastMedium,
    'lastAction': _lastAction,
    'recentContacts': _recentContacts,
    'recentApps': _recentApps,
  };

  void clear() {
    _lastContactName = null;
    _lastPhoneNumber = null;
    _lastAppName = null;
    _lastPackageName = null;
    _lastMessage = null;
    _lastMedium = null;
    _lastAction = null;
    _lastCapabilityId = null;
    _lastInteractionTime = null;
    _recentContacts.clear();
    _recentApps.clear();
  }
}
