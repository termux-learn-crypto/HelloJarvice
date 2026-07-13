enum CapabilityStatus {
  success,
  failed,
  permissionRequired,
  accessibilityRequired,
  notificationListenerRequired,
  shizukuRequired,
  rootRequired,
  serviceUnavailable,
  userDenied,
  userCancelled,
  notFound,
  timeout,
  alreadyInState,
  needsConfirmation,
  partiallyCompleted,
}

class CapabilityResult {
  final CapabilityStatus status;
  final String message;
  final String spokenResponse;
  final Map<String, dynamic> data;
  final String? errorCode;
  final String? executedCapabilityId;

  const CapabilityResult({
    required this.status,
    required this.message,
    this.spokenResponse = '',
    this.data = const {},
    this.errorCode,
    this.executedCapabilityId,
  });

  bool get isSuccess => status == CapabilityStatus.success;
  bool get requiresUserAction =>
      status == CapabilityStatus.permissionRequired ||
      status == CapabilityStatus.accessibilityRequired ||
      status == CapabilityStatus.notificationListenerRequired ||
      status == CapabilityStatus.shizukuRequired ||
      status == CapabilityStatus.rootRequired ||
      status == CapabilityStatus.needsConfirmation;

  static CapabilityResult success(String message, {String? spokenResponse, Map<String, dynamic>? data, String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.success,
      message: message,
      spokenResponse: spokenResponse ?? message,
      data: data ?? const {},
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult failed(String message, {String? spokenResponse, String? errorCode, String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.failed,
      message: message,
      spokenResponse: spokenResponse ?? message,
      errorCode: errorCode,
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult permissionRequired(String permission, {String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.permissionRequired,
      message: 'Permission required: $permission',
      spokenResponse: 'Iske liye permission chahiye. Kya de sakta hoon?',
      data: {'permission': permission},
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult accessibilityRequired({String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.accessibilityRequired,
      message: 'Accessibility service required',
      spokenResponse: 'Iske liye Accessibility service chahiye. Settings mein jaake enable karo.',
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult notificationListenerRequired({String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.notificationListenerRequired,
      message: 'Notification listener required',
      spokenResponse: 'Notifications padhne ke liye Notification Listener service chahiye.',
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult notFound(String what, {String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.notFound,
      message: '$what not found',
      spokenResponse: 'Sorry, $what nahi mila.',
      data: {'query': what},
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult alreadyInState(String what, {String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.alreadyInState,
      message: '$what is already in the desired state',
      spokenResponse: '$what pehle se wahi hai.',
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult userDenied({String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.userDenied,
      message: 'User denied',
      spokenResponse: 'Theek hai, skip karte hain.',
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult needsConfirmation(String action, {String? capabilityId}) {
    return CapabilityResult(
      status: CapabilityStatus.needsConfirmation,
      message: 'Confirmation needed for: $action',
      spokenResponse: 'Tum sure ho? Bol do "haan" ya "nahi".',
      data: {'action': action},
      executedCapabilityId: capabilityId,
    );
  }

  static CapabilityResult fromNativeResult(dynamic nativeResult, {String? capabilityId}) {
    if (nativeResult is Map) {
      final success = nativeResult['success'] == true;
      final message = nativeResult['message']?.toString() ?? '';
      if (success) {
        return CapabilityResult.success(message, data: Map<String, dynamic>.from(nativeResult['data'] ?? {}), capabilityId: capabilityId);
      } else {
        return CapabilityResult.failed(message, errorCode: nativeResult['errorCode']?.toString(), capabilityId: capabilityId);
      }
    }
    return CapabilityResult.success(nativeResult?.toString() ?? 'Done', capabilityId: capabilityId);
  }

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'message': message,
    'spokenResponse': spokenResponse,
    'data': data,
    'errorCode': errorCode,
    'executedCapabilityId': executedCapabilityId,
  };
}
