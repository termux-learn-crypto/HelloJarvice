enum CapabilityCategory {
  application,
  contact,
  call,
  whatsapp,
  message,
  volume,
  brightness,
  torch,
  media,
  youtube,
  alarm,
  timer,
  reminder,
  datetime,
  weather,
  web,
  wifi,
  bluetooth,
  network,
  location,
  accessibility,
  screenInteraction,
  notification,
  device,
  settings,
  screenControl,
  rotation,
  dnd,
  clipboard,
  camera,
  file,
}

enum Operation {
  get,
  set,
  open,
  close,
  find,
  search,
  list,
  resolve,
  prepare,
  start,
  stop,
  enable,
  disable,
  toggle,
  read,
  dismiss,
  create,
  update,
  delete,
  increase,
  decrease,
  maximize,
  minimize,
  mute,
  unmute,
  share,
  copy,
  clear,
  wake,
  press,
  type,
  swipe,
  tap,
  click,
  longPress,
  navigate,
  call,
  dial,
  send,
  confirm,
  execute,
  check,
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

enum ServiceType {
  none,
  accessibility,
  notificationListener,
  voiceInteraction,
}

enum PrivilegeType {
  none,
  shizuku,
  root,
}

class Capability {
  final String id;
  final CapabilityCategory category;
  final String description;
  final Operation operation;
  final List<String> requiredParameters;
  final List<String> optionalParameters;
  final List<String> requiredPermissions;
  final ServiceType requiredService;
  final PrivilegeType requiredPrivilege;
  final RiskLevel riskLevel;
  final bool requiresConfirmation;

  const Capability({
    required this.id,
    required this.category,
    required this.description,
    required this.operation,
    this.requiredParameters = const [],
    this.optionalParameters = const [],
    this.requiredPermissions = const [],
    this.requiredService = ServiceType.none,
    this.requiredPrivilege = PrivilegeType.none,
    this.riskLevel = RiskLevel.low,
    this.requiresConfirmation = false,
  });

  bool get isAccessibilityRequired => requiredService == ServiceType.accessibility;
  bool get isNotificationListenerRequired => requiredService == ServiceType.notificationListener;
  bool get isHighRisk => riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical;
  bool get isPrivileged => requiredPrivilege != PrivilegeType.none;

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category.name,
    'description': description,
    'operation': operation.name,
    'requiredParameters': requiredParameters,
    'optionalParameters': optionalParameters,
    'requiredPermissions': requiredPermissions,
    'requiredService': requiredService.name,
    'requiredPrivilege': requiredPrivilege.name,
    'riskLevel': riskLevel.name,
    'requiresConfirmation': requiresConfirmation,
  };
}
